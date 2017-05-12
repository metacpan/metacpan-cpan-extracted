package Net::TPP;

# Module used to interact with the TPP API
# http://www.tppwholesale.com.au/documents/2012_TPPW_API_Specs.pdf

use warnings;
use strict;
use LWP;

our $VERSION = '0.02';

sub new {
    my ($class,%options) = @_;

    for my $option_key (keys %options) {
        my $new_option_key = _fix_case($option_key);
        if ($new_option_key ne $option_key) {
            $options{$new_option_key} = $options{$option_key};
            delete $options{$option_key};
        }
    }

    # Add credentials if passed to new()
    my $mode_map = _mode_map();
    my $self = { map { ($options{$_}) ? ($_ => $options{$_}) : () } @{$mode_map->{AUTHENTICATION}->{required_parameters}} };
    $self->{_url} = $options{URL} || 'https://theconsole.tppwholesale.com.au';
    # https://theconsole.tppwholesale.com.au/api/auth.pl?AccountNo=xxxx&UserId=xxxx&Password=xxxx
    $self->{_url} =~ s#/+$##;
    $self->{_auth_url} = $options{AuthURL} || '/api/auth.pl';
    $self->{_auth_url} =~ s#\?.*$##;
    $self->{_auth_url} =~ s#/+$##;
    $self->{_ua} ||= LWP::UserAgent->new();
    $self->{_ua}->agent( $options{UserAgent} || 'Mozilla/5.0 (Net::TPP perl/LWP)' );
    $self->{_error_codes} = _error_codes();
    $self->{_mode_map} = $mode_map;

    bless $self, $class;
    return $self;
}

sub error {
    my $self = shift;
    return $self->{error} || '';
}

sub call {
    # Note that this method (or those that call it like can_register_domain) will return a false value where it makes sense -
    # E.g. can_register_domain(domain => 'test.com') will return false if the domain exists, however can_register_domain(domain => ['test.com','test2.com']) might return 
    # a true value simply so that it can return specific output for all domains.
    my ($self,%options) = @_;

    # Check the mode
    my $mode = uc($options{mode}) || uc($options{Mode}) || do {
        $self->{error_code} = '';
        $self->{error} = 'No mode passed in';
        $self->{error_output} = '';
        return;
    };
    delete $options{mode};
    unless ($self->{_mode_map}->{$mode}) {
        $self->{error_code} = '';
        $self->{error} = 'Bad mode passed in '.$mode;
        $self->{error_output} = '';
        return;
    }

    # Convert parameters to appropriate case
    for my $option_key (keys %options) {
        my $new_option_key = _fix_case($option_key);
        if ($new_option_key ne $option_key) {
            $options{$new_option_key} = $options{$option_key};
            delete $options{$option_key};
        }
    }

    # Check for missing parameters
    if ($mode eq 'AUTHENTICATION') {
        for (@{$self->{_mode_map}->{$mode}->{required_parameters}}) {
            $options{$_} = $self->{$_} if ! $options{$_} && $self->{$_};
        }
    }
    if ($mode ne 'AUTHENTICATION' && ! $options{SessionID}) {
        if (! $self->{SessionID}) {
            # Login automatically
            return unless $self->login();
        }
        $options{SessionID} = $self->{SessionID};
    }

    my @missing_parameters = map { ($options{$_}) ? ()  : ($_) } @{$self->{_mode_map}->{$mode}->{required_parameters}};
    if (@missing_parameters) {
        $self->{error_code} = '';
        $self->{error} = "Missing parameters '".join("', '",@missing_parameters)."'";
        $self->{error_output} = '';
        return;
    }

    # Submit request to TPP
    my $response = $self->_request(
        url => $self->{_mode_map}->{$mode}->{url},
        %options
    );
    return unless $response;

    # Save the SessionID if need be.
    $self->{SessionID} = $response->{output_string} if $mode eq 'AUTHENTICATION' && ! $self->{SessionID} && $response->{output_string};

    return $response;
}

sub _fix_case {
    # If, like the author, you prefer underscores to camel case, this method is used to modify the parameters sent to TPP so that either can be used by this module.
    my $option_key = shift;
    if ($option_key eq lc($option_key)) {
        my $old_option_key = $option_key;
        $option_key =~ s/_id(\b|_)/ID$1/g;
        $option_key =~ s/_(\w)/\U$1/g;
        $option_key = ucfirst($option_key);
        $option_key =~ s/^UserID$/UserId/; # Different case for some reason
        $option_key =~ s/^Url$/URL/;
    }
    return $option_key;
}

sub _stringify_parameter {
    # Join multiple values if an array ref is passed in.
    my %options = @_;
    my $key_equals = (defined $options{key}) ? $options{key} .'=' : '';
    if (ref $options{value} && ref $options{value} eq 'ARRAY') {
        return join (($options{delimiter} || '&'),map { $key_equals.$_ } @{$options{value}});
    } elsif (! ref $options{value}) {
        return $key_equals.$options{value}
    } else {
        die "Invalid input - only strings or array refs can be passed in, however ".($options{key} || '')." is a ".ref($options{value}).":\n";
    }
}

sub _request {
    my ($self,%options) = @_;

    # Create request and submit
    my $q_string = join ('&',map { ($_ ne 'url') ? (_stringify_parameter(key => $_,value => $options{$_}, delimiter => '&')) : () } keys %options);
    my $req = HTTP::Request->new(POST => $self->{_url}.$options{url}.'?'.$q_string);
    $req->content($q_string);
    my $res = $self->{_ua}->request($req);
    
    if ($res->is_success) {
        # Certain query responses may have the value of an option passed in prefixing the OK/ERR response code, we check for those here.
        my $value_prefixes = join('|',
          map { (defined $options{$_}) ? (_stringify_parameter(value => $options{$_}, delimiter => '|')) : () }
          (qw(Domain OrderID)));
        $value_prefixes = '('.$value_prefixes.')' if $value_prefixes;

        if ($res->content =~ m#^($value_prefixes:\s)?(?<status>OK|ERR):\s*(?<value>.*)#s) {
            my %output = %+;
            chomp($output{value});
            if ($output{status} eq 'ERR') {
                $self->{error_code} = $output{value};
                $self->{error_code} =~ tr/0-9//cd;
                $self->{error_output} = $res->content;
                $self->{error} = $self->{_error_codes}->{ $self->{error_code} } || 'Unknown Error.';
                $self->{error}.=' '.$output{value};
                return;
            } else {
                return { OK => 1, output_string => $output{value}, output => _create_output($res->content), raw_output => $res->content };
            }
        } else {
            $self->{error} = "Cannot read output: ".$res->content;
            $self->{error_code} = '';
            $self->{error_output} = '';
            return;
        }
    } else {
        $self->{error} = "Failed: ".$res->status_line;
        $self->{error_code} = '';
        $self->{error_output} = '';
        return;
    }
}

sub _create_output {
    # This method will handle the different types of output generated by API responses to create a generic output data structure that makes sense.
    my $output = shift;
    my %output_hash;
    for my $output_line (split(/[\r\n]+/,$output)) {
        chomp($output_line);
        if ($output_line =~ m#^(?<type>\S+):\s*(?<status>OK|ERR):\s*(?<value>.*)#s) {
            my ($type,$status,$value) = ($+{type},$+{status},$+{value});
            $value =~ s/^\s+//; $value =~ s/\s+$//;
            if ($status eq 'ERR' && $value =~ s/^(\d\d\d)\b(,\s+)?//) {
                $output_hash{$type} = _add_output_values($output_hash{$type},_get_output_values($value),status => $status, code => $1);
            } else {
                $output_hash{$type} = _add_output_values($output_hash{$type},_get_output_values($value),status => $status);
            }
        } elsif ($output_line =~ m#^(?<type>[^\s\=]+)=(?<value>.*)#) {
            my ($type,$value) = ($+{type},$+{value});
            $value =~ s/^\s+//; $value =~ s/\s+$//;
            $output_hash{$type} = _add_output_values($output_hash{$type},_get_output_values($value));
        } elsif ($output_line =~ m#^OK:\s*$#) {
            # OK then.
        } elsif ($output !~ /[\r\n]/ && $output_line =~ m#^OK: (.+)$#) {
            # OK: 1234567
            return $1;
        } else {
            # This is not a key-value output. Exit the loop early, split into an array or just one string if necessary.
            if ($output =~ /[\r\n]/s) {
                return [ split(/[\r\n]+/,$output) ];
            } else {
                return $output;
            }
        }
    }
    if (scalar keys %output_hash == 1) {
        %output_hash = (%{$output_hash{(keys %output_hash)[0]}}); # Remove the top level hash key if it is not necessary.
    }
    return \%output_hash;
}

sub _add_output_values {
    my ($hashref,$value,%options) = @_;
    if (defined $hashref && $hashref) {
        if (ref $hashref eq 'ARRAY') {
            push @{$hashref},$value;
        } else {
            $hashref = [ $hashref, $value ];
        }
    } else {
        $hashref = $value if defined $value && $value ne '';
    }
    if (scalar keys %options) {
        if (! ref $hashref) {
            my $message = ''.($hashref || '');
            undef $hashref;
            $hashref->{message} = $message;
        }
        $hashref->{$_} = $options{$_} for keys %options;
    }
    return $hashref || '';
}

sub _get_output_values {
    my $value = shift;
    my $output_value;
    if ($value =~ /&[^\&]+=/) { # query string type values
        for my $single_value (split(/\&/,$value)) {
            my ($query_key,$query_value) = split(/=/,$single_value,2);
            $output_value->{$query_key} = _add_output_values($output_value->{$query_key},$query_value);
        }
        return $output_value;
    } elsif ($value =~ /^(?<query_key>[^=]+)=(?<query_value>.*)/) {
        my ($query_key,$query_value) = ($+{query_key},$+{query_value});
        $output_value->{$query_key} = _add_output_values($output_value->{$query_key},$query_value);
        return $output_value;
    } else {
        return $value;
    }
}

sub _mode_map {
    # A map of basic information for each mode.
    my $default_parameters = [qw(SessionID Type Object Action)];
    return {
        AUTHENTICATION => {
            url => '/api/auth.pl',
            required_parameters => [qw(AccountNo UserId Password)],
        },
        ORDER => {
            url => '/api/order.pl',
            required_parameters => $default_parameters,
        },
        QUERY => {
            url => '/api/query.pl',
            required_parameters => $default_parameters,
        },
        RESOURCE => {
            url => '/api/resource.pl',
            required_parameters => $default_parameters,
        }
    }
}

sub _error_codes {
    my $error_codes =  {
        '100' => 'Missing required parameters.',
        '101' => 'API Site not currently functioning.',
        '102' => 'Cannot authenticate user. AccountNo/UserID/Password/SessionID does not match or session has timed out.',
        '103' => 'Account has been disabled.',
        '104' => 'Request coming from incorrect IP addressIP Lock error.',
        '105' => 'IP lockdown. API request is coming from an IP other than the IPs specified in API settings.',
        '108' => 'Invalid or not supplied "Type" parameter.',
        '201' => 'Your Account has not been enabled for this ‘Type’.',
        '202' => 'Missing "Type" URL parameter or the value of “Type” parameter is not "Domains".',
        '203' => 'Invalid or not supplied Action/Object parameter(s), or the API call has not been implemented.',
        '301' => 'Invalid OrderID or order does not belong to your reseller account',
        '302' => 'Domain name is either invalid or not supplied.',
        '303' => 'Domain pricings are not setted up for this TLD. If the TLD is disabled in the Reseller Portal, you cannot register the domain.',
        '304' => 'Domain is already registered, or there is an incomplete domain registration order for this domain already.',
        '305' => "There's an existing renewal order for this domain, or a new order cannot be created.",
        '306' => 'Domain is not registered; or is the process of being transferred; or is already with TPP Wholesale; or status prevents it from being transferrred.',
        '307' => 'Incorrect Domain Password.',
        '308' => 'Domain UserID or Password not supplied.',
        '309' => 'Registration for the supplied TLD is not supported.',
        '310' => 'Domain does not exist, has been deleted or transferred away.',
        '311' => 'Domain does not exist in your reseller account.',
        '312' => 'Invalid LinkDomain UserID and/or Password.',
        '313' => 'The account specified by AccountID does not exist in your reseller profile.',
        '401' => 'Cannot check for domain availability. Registry connection failed.',
        '500' => 'Pre-Paid balance is not enough to cover order cost.',
        '501' => 'Invalid credit card type. See Appendix H for a list of valid credit card types.',
        '502' => "Invalid credit card number or credit card number doesn't match credit card type.",
        '503' => 'Invalid credit card expiry date.',
        '504' => 'Credit Card amount plus current pre-paid balance is not sufficient to cover the cost of the order.',
        '505' => 'Error with credit card transaction at bank.Please Note: This error code will always be followed by a comma then a description of the error.',
        '600' => 'Missing mandatory fields or field values are invalid.',
        '601' => 'Missing mandatory fields.',
        '602' => 'Invalid hosts have been supplied.',
        '603' => 'Invalid eligibility fields supplied.',
        '604' => 'Error with one or more fields associated with aNameserver.Please Note: This error code will always befollowed by a comma then a space separatedlist of fields that have failed.',
        '610' => 'Registry connection failed.',
        '611' => 'Domain cannot be renewed,',
        '612' => 'Domain lock/unlock is not supported',
        '614' => 'Domain lock/unlock failed.',
        '615' => 'Delegation failed.',
    };
    return $error_codes;
}

# Some convenience methods

sub login {
    my ($self,%options) = @_;
    return $self->call(mode => 'AUTHENTICATION', %options);
}

sub get_domain_details {
    my ($self,%options) = @_;
    return $self->call(mode => 'QUERY', Type => 'Domains', Object => 'Domain', Action => 'Details', %options);
}

sub get_order_status {
    my ($self,%options) = @_;
    return $self->call(mode => 'QUERY', Type => 'Domains', Object => 'Order', Action => 'OrderStatus', %options);
}

sub can_renew_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'QUERY', Type => 'Domains', Object => 'Domain', Action => 'Renewal', %options);
}

sub renew_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'Renewal', %options);
}

sub can_register_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'QUERY', Type => 'Domains', Object => 'Domain', Action => 'Availability', %options);
}

sub register_domain {
    # Note 'Host' parameter (for name servers) should be an array ref. "If there is less than 2 hosts attached to a domain, the domain will be inactive."
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'Create', %options);
}

sub can_transfer_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'QUERY', Type => 'Domains', Object => 'Domain', Action => 'Transfer', %options);
}

sub transfer_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'TransferRequest', %options);
}

sub update_hosts {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'UpdateHosts', %options);
}

sub replace_hosts {
    # The same as update_hosts but we pass in an extra parameter that TPP recognises that replaces all name servers.
    # We also check if a domain is locked first, and temporary unlock in order to change the hosts/name servers
    my ($self,%options) = @_;


    my $domain_locked = 0;
    # Check if domain is locked and unlock if necessary
    my $this_domain = $options{Domain} || $options{domain};
    if ($this_domain) {
        my $domain_details = $self->get_domain_details(Domain => $this_domain);
        if ($domain_details && $domain_details->{output} && defined $domain_details->{output}->{LockStatus} && $domain_details->{output}->{LockStatus} == 2) {
            $domain_locked = 1;
            $self->unlock_domain(Domain => $this_domain);
        }
    }

    # Make NS update
    my $ns_output = $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'UpdateHosts', RemoveHost => 'ALL', %options);

    # Re-lock the domain if necessary
    if ($domain_locked) {
        $self->lock_domain(Domain => $this_domain);
    }
    return $ns_output;
}

sub unlock_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'UpdateDomainLock', DomainLock => 'Unlock', %options);
}

sub lock_domain {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'UpdateDomainLock', DomainLock => 'Lock', %options);
}

sub create_contact {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Contact', Action => 'Create', %options);
}

sub update_contact {
    my ($self,%options) = @_;
    return $self->call(mode => 'ORDER', Type => 'Domains', Object => 'Domain', Action => 'UpdateContacts', %options);
}

*update_name_servers = \&update_hosts;

*replace_name_servers = \&replace_hosts;

1;

__END__

=pod

=head1 NAME

Net::TPP - A simple perl interface to the TPP API. http://www.tppwholesale.com.au/api.php

=head1 SYNOPSIS

  use Net::TPP;
  use warnings;
  use strict;
  
  # Create $tpp object and set login details
  my $tpp = Net::TPP->new(
      AccountNo => '12345',
      UserId => 'Foo',
      Password => 'Bar'
  );
  
  # Register a domain if it is available
  if ($tpp->can_register_domain(Domain => 'tppwholesale.com.au')) {
      my $domain_order_details = $tpp->register_domain(
          Domain => 'tppwholesale.com.au',
          # Other values ..
      );
  }
  
  # Check order status
  my $order_status = $tpp->get_order_status(OrderID => 1234567, Domain => 'tppwholesale.com.au');
  
  # Check details of a domain you own
  my $domain_details = $tpp->get_domain_details(Domain => 'tppwholesale.com.au');

=head1 DESCRIPTION

Net::TPP is a simple module to provide an object-oriented interface to use the TPP API with your TPP account for various domain functions - registering, transferring & managing domains, etc.

=head1 METHODS (main)

=head2 new

Instantiate a new TPP object

  my $tpp = Net::TPP->new(
      AccountNo => '12345',
      UserId => 'Foo',
      Password => 'Bar'
  );

=head2 call

Call a specific API operation directly. Consult TPP API documention for the parameters required.
Note that authentication parameters will be passed in automatically (such as SessionID)

  my $domain_details = $tpp->call(
      Mode   => 'QUERY',
      Type   => 'Domains',
      Object => 'Domain',
      Action => 'Details',
      Domain => 'tppwholesale.com.au'
  );

This method (and the convenience methods below that use this method) will return a hashref when successful. The hashref content may change depending on which specific call is made, however it typically contains:

  {
      OK         => 1,        # A true value if the call succeeded.
      output     => $VAR,     # A string or a hashref with relevant output, depending on what call was made
      output_raw => 'string'  # A string of the raw response from TPP
  }

=head2 error

Return the last error that occured.
If necessary, you can check the error code with $tpp->{error_code}

=head1 METHODS (convenience)

There are a number of convenience methods with names that are fairly self-descriptive.
These methods simply execute the call method with the appropriate parameters.

=head2 login

This method does not really need to be called. It will be called automatically by the object if login is required.

=head2 get_domain_details

Returns various details about the domain you own in a hash reference in {output}.

  my $domain_details = $tpp->get_domain_details(Domain => 'tppwholesale.com.au');
  if ($domain_details && $domain_details->{OK}) {
      printf "This is the expiry date %s\n",$domain_details->{output}->{ExpiryDate};
      printf "Here are the nameservers %s\n",join(', ',@{$domain_details->{output}->{Nameserver}});
  }

=head2 get_order_status

Returns information about an order you have previously placed, perhaps for a domain registration or a transfer.

  my $order_status = $tpp->get_order_status(OrderID => '1234567', Domain => 'tppwholesale.com.au');
  
  print Dumper($order_status->{output});
  
  # Example content of {output} hashref:
  
  # # Pending transfer:
  # '60xxxxx' => {  # This is the OrderID passed as input
  #     'status' => 'OK',
  #     'message' => 'Scheduled,transfer requested (awaiting registry response)'
  # },
  # 'domain.org' => { # This is the Domain passed as input
  #     'status' => 'OK',
  #     'message' => 'icannTransfer2,Scheduled,transfer requested (awaiting registry response)'
  # }
  #
  # # Completed transfer
  # '60xxxxx' => {
  #     'status' => 'OK',
  #     'message' => 'Complete'
  # },
  # 'domain.org' => {
  #     'status' => 'OK',
  #     'message' => ''
  # }
  # 
  # # Or if only order id was specified, output is not be divided into domain and order id. It will just be:
  # {
  #     'status' => 'OK',
  #     'message' => 'Complete'
  # };

=head2 can_renew_domain

Check if a domain can be renewed.

  my $can_renew_domain = $tpp->can_renew_domain(Domain => 'tppwholesale.com.au');
  print Dumper($can_renew_domain);
  
  # Example output
  
  # 'output' => {
  #     'Maximum' => '2',  # Maximum years for which you can renew
  #     'ExpiryDate' => '2013-08-06',
  #     'Minimum' => '2'   # Minimum years
  # }

=head2 renew_domain

Renew a domain you own with TPP that is due to expire soon.

  $tpp->renew_domain(Domain => 'tppwholesale.com.au', Period => 2); # Renew for 2 years

=head2 can_register_domain

Check if a domain is available to be registered

  if ($tpp->can_register_domain(Domain => 'tppwholesale.com.au')) {
      print "Yes we can register this domain\n";
  }

=head2 register_domain

Register a domain. There are many required fields, it's best to consult the TPP API documentation.

  my $results = $tpp->register_domain(
      Domain => 'tppwholesale.com.au',
      Period => 2,
      # AccountOption - Default value (if omitted) creates a new account rather than specify an AccountID.
      OwnerContactID          => 'xxxxxx', A contact ID that you have set up previously.
      AdministrationContactID => 'xxxxxx', A contact ID that you have set up previously.
      BillingContactID        => 'xxxxxx', A contact ID that you have set up previously.
      TechnicalContactID      => 'xxxxxx', A contact ID that you have set up previously.
      Host                    => [qw(ns1.tppwholesale.com.au ns2.tppwholesale.com.au)], # Name Servers
      RegistrantName          => 'BUSINESS NAME PTY LTD', # Legal entity
      RegistrantID            => 'xxxxxxxxxxx', #ABN/ACN etc
      RegistrantIDType        => 2,  # ABN in this case.
      EligibilityID           => 'xxxxxxxxxxx', # Establish eligibility for the domain name
      EligibilityIDType       => 12, # ABN in this case
      EligibilityType         => 5,  # Company in this case
      EligibilityReason       => 2,  # Close and substantial connection between the domain name and the operations of your Entity
  );
  
  print Dumper($results);
  
  # $VAR1 = {
  #     # ...
  #     'OK' => 1,
  #     'output' => '1234567', # Order number
  # };

=head2 can_transfer_domain

Check if a domain can be transferred

  my $can_transfer_domain = $tpp->can_transfer_domain(Domain => 'tppwholesale.com.au');
  
  if ($can_transfer_domain) {
      print "Yes we can transfer this domain\n";
      print Dumper($can_transfer_domain);
  
      # 'output' => {
      #     'RequirePassword' => '1'
      # }
      #
      # # Or different output with a DomainPassword specified:
      # output => {
      #     'Maximum' => '10',
      #     'Owner' => 'Business X Limited',
      #     'status' => 'OK',
      #     'ExpiryDate' => '2013-10-01',
      #     'Minimum' => '',
      #     'OwnerEmail' => 'email@address',
      # };
  }

=head2 transfer_domain

Transfer a domain from another registrar to TPP under your account.

  my $domain_transfer = $tpp->transfer_domain(
      Domain                  => 'tppwholesale.com.au',
      DomainPassword          => '12345678',
      OwnerContactID          => 1234567,
      AdministrationContactID => 1234567,
      TechnicalContactID      => 1234567,
      BillingContactID        => 1234567,
  );
  
  print Dumper($domain_transfer);
  
  # Example output. - note that this might give an OK even though the domain password is wrong
  # output => {
  #   ...
  #   'OK' => 1,
  #   'output' => '61xxxxx' # Order ID
  # };

Note that no option exists to change the name servers as part of the transfer.
Name server changes need to be made before or after the transfer.

=head2 update_hosts

Add name servers to the list of current name servers for a domain.
Note that you may want to use replace_hosts instead of this method.

  $tpp->update_hosts(
      Domain   => 'tppwholesale.com.au',
      AddHost => [qw(ns3.tppwholesale.com.au ns4.tppwholesale.com.au)],
  );

=head2 update_name_servers

An alias for update_hosts

=head2 replace_hosts

Similar to update_hosts except that the current name servers will be removed from the domain first.
If required, it will also unlock a domain temporarily in order to set these name servers.

  $tpp->replace_hosts(
      Domain   => 'tppwholesale.com.au',
      AddHost => [qw(ns3.tppwholesale.com.au ns4.tppwholesale.com.au)],
  );

Note that this simply calls the UpdateHosts operation with the extra parameter: RemoveHost => 'ALL'

=head2 replace_name_servers

An alias for replace_hosts

=head2 lock_domain

This will lock the domain within TPP. Note that name servers cannot be updated while domains are locked, however replace_hosts will unlock if necessary.

=head2 unlock_domain

This will unlock the domain within TPP. Note that name servers cannot be updated while domains are locked, however replace_hosts will unlock if necessary.

=head2 create_contact

Create a contact under your TPP account.

  $tpp->create_contact(
      FirstName        => 'Person',
      LastName         => 'OfInterest',
      Address1         => '123 Fake St',
      City             => 'Sydney',
      Region           => 'NSW',
      PostalCode       => '2000',
      CountryCode      => 'AU',
      PhoneCountryCode => '61',
      PhoneAreaCode    => '02',
      PhoneNumber      => '99999999',
      Email            => 'email@address',
  );

  # Example output:
  # {
  #     ..
  #     'OK' => 1,
  #     'output' => '1234567' # Order number
  # };

=head2 update_contact

Update an existing contact under your TPP account for a specific domain.

  $tpp->update_contact(
      Domain => 'tppwholesale.com.au',
      TechnicalContactID => 1234567,
  );

=head1 CAVEATS

=head2 C<no test mode>

TPP have confirmed that test-mode does not work on their system, despite mentions in some versions of the documentation.
This makes it difficult to properly test all usage cases, and as such only major functions have been tested. 

=head2 C<no ip lock down>

The IP lockdown is not enabled by default - no IP address needs to be specified for use with the API.
TPP have confirmed, however, that they lock an IP when 'the system detects any threat from a specific IP'

=head1 VERSION

0.02

=head1 AUTHOR

Matt Vink <matt.vink@gmail.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Matt Vink, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

This module comes without warranty of any kind.

=cut

