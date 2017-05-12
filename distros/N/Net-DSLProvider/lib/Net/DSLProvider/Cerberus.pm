package Net::DSLProvider::Cerberus;
use strict;
use base 'Net::DSLProvider';
use Net::DSLProvider::Cerberus::soap;
use Carp;
use Time::Piece;
use Time::Seconds;
use Date::Holidays::EnglandWales;
use LWP;
__PACKAGE__->mk_accessors(qw/clientid dslcheckuser dslcheckpass/);

my %fields = (
    Wsfinddslline => [ qw/ cli clientid / ],
    Wsdslgetstats => [ qw/ cli clientid / ],
    Wsupdateprofile => [ qw/ cli clientid "interleave-code" "snr-code" / ],
    Wssubmitorder => [ qw/ cli "client-ref" forename surname company
        street city postcode sex email ordertype "losing-isp" mac
        "prod-id" "inst-id" "ip-id" "maint-id" "serv-id" "del-pref"
        contract devices "ripe-justification" "skip-line-check" / ],
    Wsrequestcancellation => [ qw/ cli clientid crd / ],
    Wsrequestmac => [ qw/ cli clientid / ],
    Wsgetexchangeevents => [qw/ cli clientid / ],
        );

sub _credentials {
    my $self = shift;
    return SOAP::Header->new(
      name =>'AuthenticatedUser',
      attr => { xmlns => "http://nc.cerberusnetworks.co.uk/NetCONNECT" },
      value => {username => $self->{user}, password => $self->{pass} },
    );
}

sub _call { 
    my ($self, $method, @args) = @_;
    Net::DSLProvider::Cerberus::soap->$method(@args, $self->_credentials);
}

sub _make_request {
    my ($self, $method, %args) = @_;

    my @args = ();

    for my $key ( @{$fields{$method}} ) {
        if ( $key eq 'clientid' ) {
            # The clientid parameter needs to be passed in the right order
            push @args, $self->clientid;
            next;
        }
        push @args, $args{$key};
    }

    my $resp = Net::DSLProvider::Cerberus::soap->$method(@args, $self->_credentials);
    return $resp;
}

=head2 order

Place an order. See the Cerberus docs for details of required params

=cut

sub order {
    my ($self, %args) = @_;

    # Go through the parameters below and remove those that are not mandatory
    # and those which are covered in the base package sigs{} definition.
    $self->_check_params(\%args, qw/cli client-ref forename surname company
        street city postcode sex email ordertype losing-isp mac prod-id
        inst-id ip-id maint-id serv-id del-pref contract devices
        ripe-justification skip-line-check /);

    my %resp = $self->_make_request("Wssubmitorder", %args);
    return unless $resp->{Xml_order_submission_dsl}->{Xml_Result} == 1;
    return 1;
}

=head2 cease

Cease order management. 

If the crd parameter is passed and no cease order is already in place a
new cease order is placed against the specified cli.

If a cease order is already in place on the specified cli and a crd is 
passed an attempt is made to change the cease date however this will only
succeed if the order state is not already "Committed".

If the crd parameter is not passed and a cease order is already in 
progress this method will return details of the existing cease order.

Parameters:
    cli (mandatory)
    crd (optional) Must be at least 5 working days in the future

Returns a hash containing the following:

    status : either "Confirmed" or "Committed"
    requested_date : date the cease order was placed in ISO format
    service_cease : date the service will cease in ISO format
    billing_cease : date the billing for the service will end (ISO format)

=cut

sub cease {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/cli/);

    if ( $args{crd} ) {
        my $d = Time::Piece->new($args{crd}, "%F");
        $args{crd} = $d->strftime("%d/%m/%Y");
    }

    my %resp = $self->_make_request("Wsrequestcancellation", %args);

    my $result = $resp->{Xml_cancellations}->{A_Result};
    if ( $result == 11 ) {
        croak "No active line found";
    } elsif ( $result == 12 || $result == 22 ) {
        croak "crd invalid";
    } elsif ( $result == 13 ) {
        croak "Line is secondary. Cease must be placed on primary line";
    } elsif ( $result == 21 ) {
        croak "Existing cease order cannot be amended";
    }
        
        /^1$/   &&  { $result = 

    croak "Cease not possible" unless $resp->{Xml_cancellations}->{A_Result} == 1;
    my %rv = ();
    $rv{status} = $resp->{Xml_cancellations}->{A_Status};

    my $r = Time::Piece->strptime($resp->{Xml_cancellations}->{D_RequestReceived}, "%d/%m/%Y");
    $rv{requested_date} = $r->ymd;

    my $s = Time::Piece->strptime($resp->{Xml_cancellations}->{D_ServiceCease}, "%d/%m/%Y");
    $rv{service_cease} = $s->ymd;

    my $b = Time::Piece->strptime($resp->{Xml_cancellations}->{D_BillingCease}, "%d/%m/%Y");
    $rv{billing_cease} = $b->ymd;

    return %rv;
}

=head2 request_mac

Request a MAC for the specified connection.

If the MAC is available it is returned along with the expiry date in a
hash as follows:

    mac
    expiry_date

If the MAC has been sucessfully requested the hash will contain only a
mac_requested key.

If the MAC cannot be requested the method will croak an error message 
stating why it cannot be provided.

=cut

sub request_mac {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/cli/);

    my %resp = $self->_make_request("Wsrequestmac", %args);

    my $result = $resp->{Xml_cancellations}->{A_Result};
    my %rv = ();

    if ( $result == 14 ) {
        croak "No active line found";
    } elsif ( $result == 15 ) {
        croak "MAC not available for this network";
    } elsif ( $result == 1 || $result == 11 ) {
        $rv{mac} = $resp->{Xml_macs}->{A_MAC};
        my $e = Time::Piece->strptime($resp->{Xml_macs}->{D_Expiry}, "%d/%m/%Y");
        $rv{expiry_date} = $e->ymd;
    } elsif ( $result == 2 || $result == 12 ) {
        %rv = ( "mac_requested" => 1 );
    } elsif ( $result == 3 || $result == 13 ) {
        croak "MAC Request Failed. Please contact support";
    }

    return %rv;
}

=head2 interleaving

Changes the interleaving option for the specified connection.

Parameters:
    cli (mandatory)
    interleave-code (mandatory)
    snr-code (mandatory)

Returns 1 if successful

=cut

sub interleaving {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/cli interleave-code snr-code/);

    my %resp = $self->_make_request("Wsupdateprofile", %args);

    my $result = $resp->{Xml_update_profile}->{ResultCode};
    croak "Cannot change interleaving" if $result > 1;

    return 1;
}



=head2 terms_and_conditions

Returns the terms-and-conditions to be presented to the user for signup
of a broadband product.

=cut

sub terms_and_conditions {
    return "XXX Get terms and conditions dynamically, or just put them here";
}

sub services_available {
    my ($self, %args) = @_;

    # Note that this function is different to all the others as it uses a
    # call via LWP to get the data rather than submitting via XML as all 
    # the others do.

    my $ua = new LWP::UserAgent;
    my $agent = __PACKAGE__ . '/0.1 ';
    my $url = 'http://checker.cerberusnetworks.co.uk/cgi-bin/externaldslcheck.cgi?pstn='.$args{cli}.'&user='.$self->{dslcheckuser}.'&pass='.$self->{dslcheckpass};
    my $req = new HTTP::Request 'GET' => $url;
    my $res = $ua->request($req);

    my ($up, $down, $status, $line_length) = split(/ /, $res->content);
    $up =~ s/ADSL2PLUS_ANNEXA_UP_ESTIMATE=(.*)/$1/;
    $down =~ s/ADSL2PLUS_ANNEXA_DOWN_ESTIMATE=(.*)/$1/;
    $status =~ s/ADSL2PLUS_STATUS=(\d+)/$1/;
    $line_length =~ s/BT_LINE_LENGTH=(\d+)/$1/;

    die "No service available" unless $status < 2;

    my $t = Time::Piece->new();
    $t += ONE_WEEK;
    while ( is_uk_holiday($t->ymd) || ($t->wday == 1 || $t->wday == 7) ) {
        $t += ONE_DAY;
    }

    my %rv = ( qualification => {
            'first_date' => $t->ymd,
            '2plus' => $down } );
    return %rv;    
}

sub service_view {
    my ($self, %args) = @_;
    foreach ( @{$fields{Wsfinddslline}} ) {
        die "Provide the $_ parameter" unless $args{$_};
    }

    # my %input = $self->convert_input(%args);

    my $resp = $self->_make_request("Wsfinddslline", %args);

    return %{$resp->{Xml_DSLLines}};
}

1;
