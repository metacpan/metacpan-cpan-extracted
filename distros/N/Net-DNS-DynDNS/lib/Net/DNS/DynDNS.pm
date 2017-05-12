package Net::DNS::DynDNS;

use warnings;
use strict;
use LWP();
use HTTP::Cookies();
use HTTP::Headers();
use Carp();
use English qw(-no_match_vars);
our $VERSION = '0.9993';

our @CARP_NOT = ('Net::DNS::DynDNS');
sub DEFAULT_TIMEOUT                      { return 60 }
sub NUMBER_OF_OCTETS_IN_IP_ADDRESS       { return 4; }
sub MAXIMUM_VALUE_OF_AN_OCTET            { return 256; }
sub FIRST_BYTE_OF_10_PRIVATE_RANGE       { return 10; }
sub FIRST_BYTE_OF_172_16_PRIVATE_RANGE   { return 172; }
sub SECOND_BYTE_OF_172_16_PRIVATE_RANGE  { return 16; }
sub FIRST_BYTE_OF_192_168_PRIVATE_RANGE  { return 192; }
sub SECOND_BYTE_OF_192_168_PRIVATE_RANGE { return 168; }
sub LOCALHOST_RANGE                      { return 127; }
sub MULTICAST_RESERVED_LOWEST_RANGE      { return 224; }

sub new {
    my ( $class, $user_name, $password, $params ) = @_;
    my $self    = {};
    my $timeout = DEFAULT_TIMEOUT();
    if ( ( ref $user_name ) && ( ref $user_name eq 'SCALAR' ) ) {
        if ( not( ( ref $password ) && ( ref $password eq 'SCALAR' ) ) ) {
            Carp::croak('No password supplied');
        }
    }
    elsif ( ( ref $user_name ) && ( ( ref $user_name ) eq 'HASH' ) ) {
        $params    = $user_name;
        $user_name = undef;
        $password  = undef;
    }
    if ( exists $params->{timeout} ) {
        if ( ( $params->{timeout} ) && ( $params->{timeout} =~ /^\d+$/xsm ) ) {
            $timeout = $params->{timeout};
        }
        else {
            Carp::croak(q[The 'timeout' parameter must be a number]);
        }
    }
    my $name = "Net::DNS::DynDNS $VERSION "
      ;    # a space causes the default LWP User Agent to be appended.
    if ( exists $params->{user_agent} ) {
        if ( ( $params->{user_agent} ) && ( $params->{user_agent} =~ /\S/xsm ) )
        {
            $name = $params->{user_agent};
        }
    }
    my $ua = LWP::UserAgent->new( timeout => $timeout )
      ; # no sense in using keep_alive => 1 because updates and checks are supposed to happen infrequently
    $ua->env_proxy();
    $ua->agent($name);
    my $cookie_jar = HTTP::Cookies->new( hide_cookie2 => 1 );
    $ua->cookie_jar($cookie_jar);
    $ua->requests_redirectable( ['GET'] );
    $self->{_ua} = $ua;
    my $headers = HTTP::Headers->new();

    if ( ($user_name) && ($password) ) {
        $headers->authorization_basic( $user_name, $password );
    }
    $self->{_headers}   = $headers;
    $self->{server}     = $params->{server} || 'dyndns.org';
    $self->{dns_server} = $params->{dns_server} || 'members.dyndns.org';
    $self->{check_ip}   = $params->{check_ip} || 'checkip.dyndns.org';
    bless $self, $class;
    $self->update_allowed(1);
    return $self;
}

sub _get {
    my ( $self, $uri ) = @_;
    my $ua      = $self->{_ua};
    my $headers = $self->{_headers};
    my $request = HTTP::Request->new( 'GET' => $uri, $headers );
    my $response;
    eval {
        local $SIG{'ALRM'} =
          sub { Carp::croak "Timeout when retrieving $uri"; };
        alarm $ua->timeout();
        $response = $ua->request($request);
        alarm 0;
        1;
    } or do {
        chomp $EVAL_ERROR;
        Carp::croak "Failed to get a response from '$uri':$EVAL_ERROR";
    };
    return $response;
}

sub default_ip_address {
    my ( $proto, $params ) = @_;
    my ($self);
    if ( ref $proto ) {
        $self = $proto;
    }
    else {
        $self = $proto->new($params);
    }
    my ($check_ip_uri) = $self->_check_ip_address_uri($params);

    # user_name / password is not necessary for checkip.
    # therefore don't send user_name / password

    my $headers = $self->{_headers};
    my ( $user_name, $password ) = $headers->authorization_basic();
    $headers->remove_header('Authorization');

    my ( $response, $network_error );
    eval { $response = $self->_get($check_ip_uri); } or do {
        $network_error = $EVAL_ERROR;
    };

    # restore user_name / password

    if ( ($user_name) && ($password) ) {
        $headers->authorization_basic( $user_name, $password );
    }

    if ($network_error) {
        chomp $network_error;
        Carp::croak($network_error);
    }
    return $self->_parse_ip_address( $check_ip_uri, $response );
}

sub _check_ip_address_uri {
    my ( $self, $params ) = @_;
    my $protocol = 'http'
      ; # default protocol is http because no user_name / passwords are required
    if ( exists $params->{protocol} ) {
        if ( ( defined $params->{protocol} ) && ( $params->{protocol} ) ) {
            $params->{protocol} = lc( $params->{protocol} );
            if (   ( $params->{protocol} ne 'http' )
                && ( $params->{protocol} ne 'https' ) )
            {
                Carp::croak(
                    q[The 'protocol' parameter must be one of 'http' or 'https']
                );
            }
        }
        else {
            Carp::croak(
                q[The 'protocol' parameter must be one of 'http' or 'https']);
        }
        $protocol = $params->{protocol};
    }
    if ( $protocol eq 'https' ) {
        eval { require Net::HTTPS; } or do {
            Carp::croak(q[Cannot load Net::HTTPS]);
        };
    }
    return $protocol . '://' . $self->{check_ip};
}

sub _parse_ip_address {
    my ( $self, $check_ip_uri, $response ) = @_;
    my $ip_address;
    if ( $response->is_success() ) {
        my $content = $response->content();
        if ( $content =~ /Current\sIP\sAddress:\s(\d+.\d+.\d+.\d+)/xsm ) {
            $ip_address = $1;
        }
        else {
            Carp::croak("Failed to parse response from '$check_ip_uri'");
        }
    }
    else {
        my $content = $response->content();
        $content =~ s/\s*$//smx;
        if ( $content =~ /Can't\sconnect\sto\s$self->{check_ip}/xsm ) {
            Carp::croak("Failed to connect to '$check_ip_uri'");
        }
        else {
            Carp::croak(
"Failed to get a success type response from '$check_ip_uri':$content"
            );
        }
    }
    return $ip_address;
}

sub _validate_update {
    my ( $self, $hostnames, $ip_address, $params ) = @_;
    my $headers = $self->{_headers};
    my ( $user_name, $password ) = $headers->authorization_basic();
    if ( not $self->update_allowed() ) {
        Carp::croak(
"$self->{server} has forbidden updates until the previous error is corrected"
        );
    }
    if ( not( ($user_name) && ($password) ) ) {
        Carp::croak(q[Username and password must be supplied for an update]);
    }
    if ( not($hostnames) ) {
        Carp::croak(q[The update method must be supplied with a hostname]);
    }
    if (
        not( $hostnames =~
            /^(?:(?:[[:alpha:]\d\-]+[.])+[[:alpha:]\d\-]+,?)+$/xsm )
      )
    {
        Carp::croak(
"The hostnames do not seem to be in a valid format.  Try 'test.$self->{server}'"
        );
    }
    $self->_validate_ip_address($ip_address);
    if ( ( ref $params ) && ( ( ref $params ) eq 'HASH' ) ) {
        $self->_check_wildcard($params);
        $self->_check_mx($params);
        $self->_check_backmx($params);
        $self->_check_offline($params);
        if ( exists $params->{protocol} ) {
            $self->_check_protocol($params);
        }
        else {
            $params->{protocol} = 'https';
        }
    }
    elsif ($params) {
        Carp::croak(
            q[Extra parameters must be passed in as a reference to a hash]);
    }
    return;
}

sub _validate_ip_address {
    my ( $self, $ip_address ) = @_;
    if ( defined $ip_address ) {
        my @bytes = split /[.]/xsm, $ip_address;
        if ( ( scalar @bytes ) != NUMBER_OF_OCTETS_IN_IP_ADDRESS() ) {
            Carp::croak(q[Bad IP address]);
        }
        foreach my $byte (@bytes) {
            if ( not( $byte =~ /^\d+$/xsm ) ) {
                Carp::croak(q[Bad IP address.  Each byte must be numeric]);
            }
            if ( ( $byte >= MAXIMUM_VALUE_OF_AN_OCTET() ) || ( $byte < 0 ) ) {
                Carp::croak(q[Bad IP address.  Each byte must be within 0-255]);
            }
        }
        if (
               ( $bytes[0] == 0 )
            || ( $bytes[0] == LOCALHOST_RANGE() )
            || ( $bytes[0] == FIRST_BYTE_OF_10_PRIVATE_RANGE() )
            || (   ( $bytes[0] == FIRST_BYTE_OF_172_16_PRIVATE_RANGE() )
                && ( $bytes[1] == SECOND_BYTE_OF_172_16_PRIVATE_RANGE() ) )
            ||    # private
            (
                   ( $bytes[0] == FIRST_BYTE_OF_192_168_PRIVATE_RANGE() )
                && ( $bytes[1] == SECOND_BYTE_OF_192_168_PRIVATE_RANGE() )
            )
            ||    # private
            ( $bytes[0] >= MULTICAST_RESERVED_LOWEST_RANGE() )
          )       # multicast && reserved
        {
            Carp::croak(
q[Bad IP address.  The IP address is in a range that is not publically addressable]
            );
        }
    }
}

sub _check_wildcard {
    my ( $self, $params ) = @_;
    if ( exists $params->{wildcard} ) {
        if ( ( defined $params->{wildcard} ) && ( $params->{wildcard} ) ) {
            $params->{wildcard} = uc( $params->{wildcard} );
            if (   ( $params->{wildcard} ne 'ON' )
                && ( $params->{wildcard} ne 'OFF' )
                && ( $params->{wildcard} ne 'NOCHG' ) )
            {
                Carp::croak(
q[The 'wildcard' parameter must be one of 'ON','OFF' or 'NOCHG']
                );
            }
        }
        else {
            Carp::croak(
                q[The 'wildcard' parameter must be one of 'ON','OFF' or 'NOCHG']
            );
        }
    }
}

sub _check_mx {
    my ( $self, $params ) = @_;
    if ( exists $params->{mx} ) {
        if ( ( defined $params->{mx} ) && ( $params->{mx} ) ) {
            if (
                not( $params->{mx} =~
                    /^(?:(?:[[:alpha:]\d\-]+[.])+[[:alpha:]\d\-]+,?)+$/xsm )
              )
            {
                Carp::croak(
"The 'mx' parameter does not seem to be in a valid format.  Try 'test.$self->{server}'"
                );
            }
        }
        else {
            Carp::croak(
q[The 'mx' parameter must be a valid fully qualified domain name]
            );
        }
    }
    else {
        if ( exists $params->{backmx} ) {
            Carp::croak(
q[The 'backmx' parameter cannot be set without specifying the 'mx' parameter]
            );
        }
    }
}

sub _check_backmx {
    my ( $self, $params ) = @_;
    if ( exists $params->{backmx} ) {
        if ( ( defined $params->{backmx} ) && ( $params->{backmx} ) ) {
            $params->{backmx} = uc( $params->{backmx} );
            if (   ( $params->{backmx} ne 'YES' )
                && ( $params->{backmx} ne 'NO' ) )
            {
                Carp::croak(
                    q[The 'backmx' parameter must be one of 'YES' or 'NO']);
            }
        }
        else {
            Carp::croak(q[The 'backmx' parameter must be one of 'YES' or 'NO']);
        }
    }
}

sub _check_offline {
    my ( $self, $params ) = @_;
    if ( exists $params->{offline} ) {
        if ( ( defined $params->{offline} ) && ( $params->{offline} ) ) {
            $params->{offline} = uc( $params->{offline} );
            if (   ( $params->{offline} ne 'YES' )
                && ( $params->{offline} ne 'NO' ) )
            {
                Carp::croak(
                    q[The 'offline' parameter must be one of 'YES' or 'NO']);
            }
        }
        else {
            Carp::croak(
                q[The 'offline' parameter must be one of 'YES' or 'NO']);
        }
    }
}

sub _check_protocol {
    my ( $self, $params ) = @_;
    if ( ( defined $params->{protocol} ) && ( $params->{protocol} ) ) {
        $params->{protocol} = lc( $params->{protocol} );
        if (   ( $params->{protocol} ne 'http' )
            && ( $params->{protocol} ne 'https' ) )
        {
            Carp::croak(
                q[The 'protocol' parameter must be one of 'http' or 'https']);
        }
    }
    else {
        Carp::croak(
            q[The 'protocol' parameter must be one of 'http' or 'https']);
    }
}

sub update_allowed {
    my ( $self, $allowed ) = @_;
    my $old;
    if ( ( exists $self->{update_allowed} ) && ( $self->{update_allowed} ) ) {
        $old = $self->{update_allowed};
    }
    if ( defined $allowed ) {
        $self->{update_allowed} = $allowed;
    }
    return $old;
}

sub _error {
    my ( $self, $code, $content ) = @_;
    $self->update_allowed(0);
    my %errors = (
        'badauth' => 'The username and password pair do not match a real user',
        '!donator' =>
'An option available only to credited users (such as offline URL) was specified, but the user is not a credited user',
        'notfqdn' =>
'The hostname specified is not a fully-qualified domain name (not in the form hostname.dyndns.org or domain.com)',
        'nohost' =>
          'The hostname specified does not exist in this user account',
        'numhost' => 'Too many hosts (more than 20) specified in an update',
        'abuse'   => 'The hostname specified is blocked for update abuse',
        'badagent' =>
          'The user agent was not sent or HTTP method is not permitted',
        'dnserr' => 'DNS error encountered',
        '911'    => 'There is a problem or scheduled maintenance on our side',
    );
    Carp::croak( $errors{$code} || "Unknown error:$code:$content" );
}

sub update {
    my ( $self, $hostnames, $ip_address, $params ) = @_;
    if ( ( ref $ip_address ) && ( ref $ip_address eq 'HASH' ) ) {
        $params     = $ip_address;
        $ip_address = undef;
    }
    $self->_validate_update( $hostnames, $ip_address, $params );
    my $protocol =
      'https';    # default protocol is https to protect user_name / password
    if ( $params->{protocol} ) {
        $protocol = $params->{protocol};
    }
    if ( $protocol eq 'https' ) {
        eval { require Net::HTTPS; } or do {
            Carp::croak(q[Cannot load Net::HTTPS]);
        };
    }
    my $update_uri =
      $protocol . "://$self->{dns_server}/nic/update?hostname=" . $hostnames;
    if ( defined $ip_address ) {
        $update_uri .= '&myip=' . $ip_address;
    }
    if ( exists $params->{wildcard} ) {
        $update_uri .= '&wildcard=' . $params->{wildcard};
    }
    if ( exists $params->{mx} ) {
        $update_uri .= '&mx=' . $params->{mx};
    }
    if ( exists $params->{backmx} ) {
        $update_uri .= '&backmx=' . $params->{backmx};
    }
    if ( exists $params->{offline} ) {
        $update_uri .= '&offline=' . $params->{offline};
    }
    my $response = $self->_get($update_uri);
    my $content  = $response->content();
    my $result   = $self->_parse_content( $update_uri, $content );
    return $result;
}

sub _parse_content {
    my ( $self, $update_uri, $content ) = @_;
    my @lines = split /\015?\012/xsm, $content;
    my $result;
    foreach my $line (@lines) {
        if (
            $line =~ m{ 
			( \S + )  # response code
			\s+
			(\S.*) $ # ip address (possible)
			}xsm
          )
        {
            my ( $code, $additional ) = ( $1, $2 );
            if (
                   ( $code eq 'good' )
                || ( $code eq 'nochg' )
                || ( $code eq '200'
                ) # used by http://www.changeip.com/accounts/knowledgebase.php?action=displayarticle&id=47
              )
            {
                if ($result) {
                    if ( $result ne $additional ) {
                        Carp::croak(
                            "Could not understand multi-line response\n$content"
                        );
                    }
                }
                else {
                    $result = $additional;
                }
            }
            else {
                $self->_error( $code, $content );
            }
        }
        elsif (
            $line =~ m{
                ^ ( \S + ) $ # if this line of the response is a single code word
              }xsm
          )
        {
            my ($code) = ($1);
            $self->_error( $code, $content );
        }
        else {
            Carp::croak(
                "Failed to parse response from '$update_uri'\n$content");
        }
    }
    return $result;
}

1;

__END__
=head1 NAME

Net::DNS::DynDNS - Update dyndns.org with correct ip address for your domain name

=head1 VERSION
 
Version 0.9993

=head1 SYNOPSIS

  print Net::DNS::DynDNS->default_ip_address();
  print Net::DNS::DynDNS->new('user', 'password')->update('test.dyndns.org,test.homeip.net');

=head1 DESCRIPTION

This module allows automated updates to your dyndns.org domain name to your
current ip address.  This is useful for people running servers that operate 
off dynamic ip addresses.  

=head1 SUBROUTINES/METHODS

=head2 default_ip_address

returns your current ip address according to dyndns.org.  This function should
not be used more than once every 10 minutes according to terms of usage for
dyndns.org.

=head2 new( $username, $password, $params )

returns a new object for updating dyndns.org entries.  The username and password
parameters are from your dyndns.org account.

   Parameter            Default
   server               dyndns.org
   dns_server           members.dyndns.org
   check_ip             checkip.dyndns.org

=head2 update_allowed ( $setting )

returns whether the object is permitted to make another update to dyndns.org without 
human intervention.  There are a list of return codes at 
http://www.dyndns.org/developers/specs/return.html that require this behaviour.  To
signal that human intervention has allowed updating to continue, pass a true value 
in the parameter list.

=head2 update( $hostnames, $ip_address, $params )

returns the ip address that has been assigned to the hostnames.  The hostnames should be
fully qualified domain names.  If there is more than one hostname to be updated, they should
be separated with a comma.  The ip_address argument is optional.  It specifies which ip 
address should be assigned to the hostnames argument.  If the ip_address argument is not 
supplied, dyndns.org will assign your current ip address to the hostnames.  The optional
params argument is a hashref that may contain the following values

   Parameter            Default   Values
   wildcard             none      ON | OFF | NOCHG 
   mx                   none      any valid fully qualified hostname 
   backmx               none      YES | NO
   offline              none      YES | NO
   protocol             https     http | https

Further information about each of these parameters is available at
http://www.dyndns.org/developers/specs/syntax.html

=head1 CONFIGURATION AND ENVIRONMENT
 
Net::DNS::DynDNS requires no configuration files or environment variables.  It will use the http_* Environment Variables to determine a proxy server

=head1 DEPENDENCIES
 
Net::DNS::DynDNS requires the following non-core Perl modules
 
=over
 
=item *
L<LWP|LWP>
 
=item *
L<Net::HTTPS|Net::HTTPS>
 
=item *
L<HTTP::Cookies|HTTP::Cookies>
 
=item *
L<HTTP::Headers|HTTP::Headers>

=back

=head1 INCOMPATIBILITIES
 
None reported

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 BUGS AND LIMITATIONS

None known at this point.

Interested in receiving patches to make this compatible with other DDNS providers
 
=head1 LICENSE AND COPYRIGHT

Copyright 2015 David Dick.
 
This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.
 
See http://dev.perl.org/licenses/ for more information.

=cut
