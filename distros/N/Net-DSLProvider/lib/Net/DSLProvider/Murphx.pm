package Net::DSLProvider::Murphx;
use strict;
use warnings;
use HTML::Entities qw(encode_entities_numeric);
use base 'Net::DSLProvider';
use constant ENDPOINT => "https://xml.xps.murphx.com/";
use LWP::UserAgent;
use XML::Simple;
use Time::Piece;
my $ua = LWP::UserAgent->new;
__PACKAGE__->mk_accessors(qw/clientid/);

my %formats = (
    selftest => { sysinfo => { type => "text" }},
    availability => { cli => "phone", detailed => "yesno", ordertype =>
    "text", postcode => "postcode"},
    leadtime => { "product-id" => "counting", "order-type" => "text" },
    order_status => {"order-id" => "counting" },
    order_eventlog_history => { "order-id" => "counting" },
    order_eventlog_changes => { "date" => "datetime" },
    woosh_request_oneshot => {  "service-id" => "counting",
        "fault-type" => "text", "has-worked" => "yesno", "disruptive" => "yesno",
        "fault-time" => "datetime" },
    woosh_list => { "service-id" => "counting" },
    woosh_response => { "woosh-id" => "counting" },
    change_password => { "service-id" => "counting", "password" => "password" },
    service_actions => { "service-id" => "counting" },
    service_details => { "service-id" => "counting", "detailed" => "yesno" },
    service_status => { "service-id" => "counting", "order-id" => "counting" },
    service_view => { "service-id" => "counting" },
    service_usage_summary => { "service-id" => "counting", 
        "year" => "counting", "month" => "text" },
    service_auth_log => { "service-id" => "counting", "rows" => "counting" },
    service_session_log => { "service-id" => "counting", "rows" => "counting" },
    service_eventlog_changes => { "start-date" => "datetime", "stop-date" => "datetime" },
    service_eventlog_history => { "service-id" => "counting" },
    service_terminate_session => { "service-id" => "counting" },
    services_overusage => { "period" => "text", "limit" => "counting" },
    speed_limit_enable => { "upstream-limit" => "counting", 
        "downstream-limit" => "counting", "service-id" => "counting" },
    speed_limit_disable => { "service-id" => "counting" },
    speed_limit_status => { "service-id" => "counting" },
    service_suspend => { "service-id" => "counting", "reason" => "text" },
    service_unsuspend => { "service-id" => "counting" },
    walledgarden_status => { "service-id" => "counting" },
    walledgarden_enable => { "service-id" => "counting", "redirect-to" => "ip-address" },
    walledgarden_disable => { "service-id" => "counting" },
    change_carelevel => { "service-id" => "counting", "care-level" => "text" },
    requestmac => { "service-id" => "counting", "reason" => "text" },
    modify_options => { "service-id" => "counting" },
    cease => {
        order => {
            "service-id" => "counting", "reason" => "text",
            "client-ref" => "text", "crd" => "datetime", "accepts-charges" => "yesno" 
        }
    },
    modify => {
        order => {
            "service-id" => "counting", "client-ref" => "text", "crd" => "date",
            "prod-id" => "counting", "cli" => "phone",
            attributes => { "care-level" => "text", "inclusive-transfer" => "counting",
                "test-mode" => "yesno" },
        }
    },
    provide => { 
        order => {   
            "client-ref" => "text", cli => "phone", "prod-id" => "counting",
            crd => "datetime", username => "text", 
            attributes => {
                password => "password", realm => "text", 
                "fixed-ip" => "yesno", "routed-ip" => "yesno", 
                "allocation-size" => "counting", "care-level" => "text",
                "hardware-product" => "counting", 
                "max-interleaving" => "text", "test-mode" => "yesno",
                "inclusive-transfer" => "counting", "pstn-order-id" => "text"
            }
        }, customer => { 
            (map { $_ => "text" } qw/title forename surname company building
                street city county sub-premise/),
            postcode => "postcode", telephone => "phone", 
            mobile => "phone", fax => "phone", email => "email"
        }
    },
    migrate => { 
        order => {   
            "client-ref" => "text", cli => "phone", "prod-id" => "counting",
            crd => "datetime", username => "text", 
            attributes => {
                password => "password", realm => "text", 
                "fixed-ip" => "yesno", "routed-ip" => "yesno", 
                "allocation-size" => "counting", "care-level" => "text",
                "hardware-product" => "counting", 
                "max-interleaving" => "text", "test-mode" => "yesno",
                "mac" => "text", "losing-isp" => "text",
                "inclusive-transfer" => "counting", "pstn-order-id" => "text"
            }
        }, customer => { 
            (map { $_ => "text" } qw/title forename surname company building
                street city county sub-premise/),
            postcode => "postcode", telephone => "phone", 
            mobile => "phone", fax => "phone", email => "email"
        }
    },
    case_new => {
        "service-id" => "counting", "service-type" => "text", 
        "appsource" => "text", "cli" => "phone", "client-id" => "counting",
        "customer-id" => "counting", "experienced" => "datetime",
        "hardware-product" => "text", "os" => "text", "priority" => "text",
        "problem-type" => "text", "reported" => "text", 
        "username" => "text",
    },
    case_view => { "case-id" => "counting" },
    case_update => { "case-id" => "counting", "reason" => "text",
        "priority" => "text"
    },
    case_history => { "case-id" => "counting" },
    case_search => { "case-id" => "counting", "service-id" => "counting",
        "customer-id" => "counting", "service-type" => "text", 
        "username" => "text", "partial-cli" => "text", engineer => "text",
        "problem-type" => "text", "priority" => "text", status => "text",
        },
    customer_details => { "service-id" => "counting", "detailed" => "yesno" },
    product_details => { "product-id" => "counting", "detailed" => "yesno" },
);


sub _request_xml {
    my ($self, $method, $data) = @_;
    my $id = time.$$;
    my $xml = qq{<?xml version="1.0"?>
    <Request module="XPS" call="$method" id="$id" version="2.0.1">
        <block name="auth">
            <a name="client-id" format="counting">@{[$self->clientid]}</a>
            <a name="username" format="text">@{[$self->user]}</a>
            <a name="password" format="password">@{[$self->pass]}</a>
        </block>
        };

    my $recurse;
    $recurse = sub {
        my ($format, $data) = @_;
        while (my ($key, $contents) = each %$format) {
            if (ref $contents eq "HASH") {
                if ($key) { $xml .= "\t<block name=\"$key\">\n"; }
                $recurse->($contents, $data->{$key});
                if ($key) { $xml .= "\t</block>\n"; }
            } else {
                $xml .= qq{\t\t<a name="$key" format="$contents">}.encode_entities_numeric($data->{$key})."</a>\n" 
                if $data->{$key};
            }
        }
    };
    $recurse->($formats{$method}, $data); 
    $xml .= "</Request>\n";

    return $xml;
}

sub _make_request {
    my ($self, $method, $data) = @_;
    my $xml = $self->_request_xml($method, $data);
    my $request = HTTP::Request->new(POST => ENDPOINT);
    $request->content_type('text/xml');
    $request->content($xml);
    if ($self->debug) { warn "Sending request: \n".$request->as_string;}
    my $resp = $ua->request($request);
    die "Request for Murphx method $method failed: " . $resp->message if $resp->is_error;
    if ($self->debug) { warn "Got response: \n".$resp->content;}
    my $resp_o = XMLin($resp->content);
    if ($resp_o->{status}{no} > 0) { die  $resp_o->{status}{text} };

    my $recurse = undef;
    $recurse = sub {
        my $input = shift;
        while ( my ($oldkey, $contents) = each %$input ) {
            my $newkey = $oldkey;
            $newkey =~ s/-/_/g;
            $recurse->($contents) if ref $contents eq 'HASH';
            if ( ref $contents eq "ARRAY" ) {
                for my $r ( @{$contents} ) {
                    $recurse->($r);
                }
            }
            $input->{$newkey} = $contents;
            delete $input->{$oldkey} if $oldkey =~ /-/;
        }
    };
    $recurse->($resp_o);

    return $resp_o;
}

=head2 services_available

    $murphx->services_available( cli => "02071112222" );

Returns an hash showing the available services and line qualifications
as follows:

  ( qualification => {
        classic => '2048000',
        max => '4096000',
        2plus => '5120000',
        fttc => {
            'up' => '6348800',
            'down' => '27750400'
        },
        'first_date' => '2011-03-01'
    },
    product_id => {
        'first_date' => '2011-03-01',
        'max_speed' => '4096000',
        'product_name' => 'DSL Product Name'
    },
    ...
  )

=cut

sub services_available {
    my ($self, %args) = @_;
    $self->_check_params(\%args);

    %args = ( %args, detailed => "Y", ordertype => "migrate" );

    my $response = $self->_make_request("availability", \%args);

    my %crd = ();
    while ( my $a = pop @{$response->{block}->{leadtimes}->{block}} ) {
        my $pid = $a->{a}->{'product_id'}->{content};
        $crd{$pid} = $a->{a}->{'first_date_text'}->{content};
    }

    my %rv = ();

    my $a = $response->{block}->{availability}->{block};
    foreach (qw/classic max 2plus fttc/) {
        my $q = $a->{$_.'_qualification'};
        if ( $_ ne 'fttc' ) {
            $rv{qualification}->{$_} = $q->{a}->{'likely_max_speed'}->{content};
            if ( $_ eq '2plus' && $q->{block}->{'name'} eq 'annex-m' ) {
                $rv{qualification}->{$_.'_m_up'} = $q->{block}->{a}->{'likely_max_speed_up'}->{content};
                $rv{qualification}->{$_.'_m_down'} = $q->{block}->{a}->{'likely_max_speed_down'}->{content};
            }
            $rv{qualification}->{top} = $rv{qualification}->{$_};
        }
        else {
            $rv{qualification}->{$_}->{'down'} = $q->{a}->{'likely_max_speed_down'}->{content};
            $rv{qualification}->{$_}->{'up'} = $q->{a}->{'likely_max_speed_up'}->{content};
        }
    }
    return if ! $rv{qualification}->{classic} > 0; # There is no data to report!

    $rv{qualification}->{first_date} = $crd{1317}; # ADSL MAX Classic first available CRD

    # Now return the list of actual services available
    while ( my $a = pop @{$response->{block}->{products}->{block}} ) {
        $rv{$a->{a}->{'product_id'}->{content}} = {
              first_date   => $crd{$a->{a}->{'product_id'}->{content}},
              product_name => $a->{a}->{'product_name'}->{content},
              max_speed => $a->{a}->{'service_speed'}->{content},
            };
    }
    return %rv;
}

=head2 modify

    $murphx->modify(
        "service-id" => "12345", "client-ref" => "myref", "prod-id" => "1000",
        "crd" => "2009-12-31", "care-level" => "standard" "inclusive-transfer" => "3",
        "test-mode" = "N" );

Modify the service specificed in service-id. Parameters are as per the Murphx documentation

Returns order-id for the modify order.

=cut

sub modify {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id client-ref myref prod-id 
                        crd care-level inclusive-transfer test-mode / );

    my $response = $self->_make_request("modify", \%args);

    return $response->{a}->{"order_id"}->{content};
}

=head2 change_password 

    $murphx->change_password( "service-id" => "12345", "password" => "secret" );

Changes the password for the ADSL login on the given service.

Requires service-id and password

Returns 1 for successful password change.

=cut

sub change_password {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id password/);

    my $response = $self->_make_request("change_password", \%args);

    return 1;
}

=head2 woosh_response

    $murphx->woosh_response( "12345" );

Obtains the results of a Woosh test, previously requested using
request_woosh(). Takes the ID of the woosh test as its only parameter.
Note that this will only return results for completed Woosh tests. Use
woosh_list() to determine if the woosh test is completed.

Returns an hash containing a hash for each set of test results. See
Murphx documentation for details of the test result fields.

=cut

sub woosh_response {
    my ($self, $id) = @_;
    die "You must provide the woosh-id parameter" unless $id;
    my $response = $self->_make_request("woosh_response", { "woosh-id" => $id });

    my %results = ();
    foreach ( keys %{$response->{block}->{block}} ) {
        my $b = $_;
        foreach ( keys %{$response->{block}->{block}->{$b}->{a}} ) {
            $results{$b}{$_} = $response->{block}->{block}->{$b}->{a}->{$_}->{content};
        }
    }
    return \%results;
}

=head2 woosh_list

    $murphx->woosh_list( "12345" );

Obtain a list of all woosh tests requested for the given service-id and
their status.

Requires service-id as the single parameter.

Returns an array, each element of which is a hash containing the
following fields for each requested Woosh test:

    service-id woosh-id start-time stop-time status

The array elements are sorted by date with the most recent being first.

=cut

sub woosh_list {
    my ($self, $id) = @_;
    die "You must provide the woosh-id parameter" unless $id;
    my $response = $self->_make_request("woosh_list", { "woosh-id" => $id });

    my @list = ();
    if ( ref $response->{block}->{block} eq "ARRAY" ) {
        while ( my $b = shift @{$response->{block}->{block}} ) {
            my %a = ();
            foreach ( keys %{$b->{a}} ) {
                $a{$_} = $b->{a}->{$_}->{content};
            }
            push @list, \%a;
        }
    } else {
        my %a = ();
        foreach ( keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
        }
        push @list, \%a;
    }

    return @list;
}

=head2 request_woosh

    $murphx->request_woosh( "service-id" => "12345", "fault-type" => "EPP",
        "has-worked" => "Y", "disruptive" => "Y", "fault-time" => "2007-01-04 15:33:00");

Alias to woosh_request_oneshot

=cut

sub request_woosh { goto &woosh_request_oneshot; }

=head2 woosh_request_oneshot

    $murphx->woosh_request_oneshot( "service-id" => "12345", "fault-type" => "EPP",
        "has-worked" => "Y", "disruptive" => "Y", "fault-time" => "2007-01-04 15:33:00");

Places a request for  Woosh test to be run on the given service.
Parameters are passed as a hash which must contain:

    service-id - ID of the service
    fault-type - Type of fault to check. See Murphx documentation for available types
    has-worked - Y if the service has worked in the past, N if it has not
    disruptive - Y to allow Woosh to run a test which will be disruptive to the service.
    fault-time - date and time (ISO format) the fault occured

Returns a scalar which is the id of the woosh test. Use woosh_response
with this id to get the results of the Woosh test.

=cut

sub woosh_request_oneshot {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id fault-type has-worked 
                            disruptive fault-time /);

    my $response = $self->_make_request("woosh_request_oneshot", \%args);

    return $response->{a}->{"woosh_id"}->{content};
}

=head2 order_updates_since

    $murphx->order_updates_since( "date" => "2007-02-01 16:10:05" );

Alias to order_eventlog_changes

=cut

sub order_updates_since { goto &order_eventlog_changes; }

=head2 order_eventlog_changes

    $murphx->order_eventlog_changes( "date" => "2007-02-01 16:10:05" );

Returns a list of events that have occurred on all orders since the provided date/time.

The return is an date/time sorted array of hashes each of which contains the following fields:
    order-id date name value

=cut

sub order_eventlog_changes {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/date/);

    my $response = $self->_make_request("order_eventlog_changes", \%args);

    my @updates = ();

    if ( ref $response->{block}->{block} eq "ARRAY" ) {
        while (my $b = shift @{$response->{block}->{block}} ) {
            my %a = ();
            foreach ( keys %{$b->{a}} ) {
                $a{$_} = $b->{a}->{$_}->{content};
                if ( $_ eq 'date' && $args{dateformat} ) {
                    my $d = Time::Piece->strptime($a{$_}, "%Y-%m-%d %H:%M:%S");
                    $a{$_} = $d->strftime($args{dateformat});
                }
            }
            push @updates, \%a;
        }
    } else {
        my %a = ();
        foreach (keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
            if ( $_ eq 'date' && $args{dateformat} ) {
                my $d = Time::Piece->strptime($a{$_}, "%Y-%m-%d %H:%M:%S");
                $a{$_} = $d->strftime($args{dateformat});
            }
        }
        push @updates, \%a;
    }
    return @updates;
}

=head2 auth_log

    $murphx->auth_log( "service-id" => '12345', "rows" => "5" );

Alias for service_auth_log

=cut

sub auth_log { goto &service_auth_log; }

=head2 service_auth_log

    $murphx->service_auth_log( "service-id" => '12345', "rows" => "5" );

Gets the last n rows, as specified in the rows parameter, of authentication log entries for the service

Returns an array, each element of which is a hash containing:
    auth-date, username, result and, if the login failed, error-message

=cut

sub service_auth_log {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id rows/);

    my $response = $self->_make_request("service_auth_log", \%args);

    my @auth = ();
    if ( ref $response->{block} eq "ARRAY" ) {
        while ( my $r = shift @{$response->{block}} ) {
            my %a = ();
            foreach ( keys %{$r->{block}->{a}} ) {
                $a{$_} = $r->{block}->{a}->{$_}->{content};
                if ( $_ eq 'auth_date' && $args{dateformat} ) {
                    my $d = Time::Piece->strptime($r->{block}->{a}->{$_}->{content}, "%Y-%m-%d %H:%M:%S");
                    $a{$_} = $d->strftime($args{dateformat});
                }
            }
            push @auth, \%a;
        }
    } else {
        my %a = ();
        foreach (keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
            if ( $_ eq 'auth_date' && $args{dateformat} ) {
                my $d = Time::Piece->strptime($response->{block}->{block}->{a}->{$_}->{content}, "%Y-%m-%d %H:%M:%S");
                $a{$_} = $d->strftime($args{dateformat});
            }
        }
        push @auth, \%a;
    }

    return @auth;
}

=head2 session_log 

    $murphx->session_log( { } );

Alias for service_session_log

=cut

sub session_log { goto &service_session_log; }

=head2 service_session_log

    $murphx->service_session_log( "session-id" => "12345", "rows" => "5" );

Gets the last entries in the session log for the service. The number of
entries is specified in the "rows" parameter.

Returns an array each element of which is a hash containing:

    start-time stop-time download upload termination-reason

=cut

sub service_session_log {
    my ($self, %args) = @_;
    for (qw/service-id rows/) {
        if (!$args{$_}) { die "You must provide the $_ parameter"; }
    }

    my $response = $self->_make_request("service_session_log", \%args);

    my @sessions = ();
    if ( ref $response->{block} eq "ARRAY" ) {
        while ( my $r = shift @{$response->{block}} ) {
            my %a = ();

            foreach ( keys %{$r->{block}->{a}} ) {
                $a{$_} = $r->{block}->{a}->{$_}->{content};
                if ( $args{dateformat} && ($_ eq 'start_time' || $_ eq "stop_time") ) {
                    my $d = Time::Piece->strptime($a{$_}, "%Y-%m-%d %H:%M:%S");
                    $a{$_} = $d->strftime($args{dateformat});
                }
            }


            $a{"download"} = delete $a{"output-octets"};
            $a{"upload"} = delete $a{"input-octets"};
            push @sessions, \%a;
        }
    } else {
        my %a = ();
        foreach (keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
            if ( $args{dateformat} && ($_ eq 'start_time' || $_ eq "stop_time") ) {
                my $d = Time::Piece->strptime($a{$_}, "%Y-%m-%d %H:%M:%S");
                $a{$_} = $d->strftime($args{dateformat});
            }
        }

        $a{"download"} = delete $a{"output_octets"};
        $a{"upload"} = delete $a{"input_octets"};
        push @sessions, \%a;
    }
    return @sessions;
}

=head2 usage_summary 

    $murphx->usage_summary( "service-id" =>'12345', "year" => '2009', "month" => '01' );

Alias for service_usage_summary()

=cut 

sub usage_summary { goto &service_usage_summary; }

=head2 service_usage_summary

    $murphx->service_usage_summary( "service-id" =>'12345', "year" => '2009', "month" => '01' );

Gets a summary of usage in the given month. Inputs are service-id, year, month.

Returns a hash with the following fields:

    year, month, username, total-sessions, total-session-time,
    total-input-octets, total-output-octets

Input octets are upload bandwidth. Output octets are download bandwidth.

Be warned that the total-input-octets and total-output-octets fields
returned appear to be MB rather than octets contrary to the Murphx
documentation. 

=cut

sub service_usage_summary {
    my ($self, %args) = @_;
    for (qw/ service-id year month /) {
        if ( ! $args{$_} ) { die "You must provide the $_ parameter"; }
    }

    my $response = $self->_make_request("service_usage_summary", \%args);

    my %usage = ();
    foreach ( keys %{$response->{block}->{a}} ) {
        $usage{$_} = $response->{block}->{a}->{$_}->{content};
    }
    return %usage;
}

=head2 service_terminate_session

    $murphx->service_terminate_session( "12345" );

Terminates the current session on the given service-id.

Returns 1 if successful

=cut

sub service_terminate_session {
    my ($self, $id) = @_;
    die "You must provide the service-id parameter" unless $id;

    my $response = $self->_make_request("service_terminate_session",
        {"service-id" => $id});

    return 1;
}

=head2 cease

    $murphx->cease( "service-id" => 12345, "reason" => "This service is no longer required"
        "client-ref" => "ABX129", "crd" => "1970-01-01", "accepts-charges" => 'Y' );

Places a cease order to terminate the ADSL service completely. Takes input as a hash.

Required parameters are : service-id, crd, client-ref

Returns order-id which is the ID of the cease order for tracking purposes.

=cut

sub cease {
    my ($self, %args) = @_;
    for (qw/service-id crd client-ref reason/) {
        if (!$args{$_}) { die "You must provide the $_ parameter"; }
    }

    # The cease method parameters have to be passed inside $data->{order}
    my $data = { };
    foreach (keys %args) {
        $data->{order}{$_} = $args{$_};
    }

    my $response = $self->_make_request("cease", $data);
    return $response->{"order_id"}->{content};
}

=head2 request_mac

    $murphx->requestmac( "service-id" => '12345', "reason" => "EU wishes to change ISP" );

Obtains a MAC for the given service. Parameters are service-id and
reason the customer wants a MAC. 

Returns a hash comprising: mac, expiry-date

=cut

sub request_mac {
    my ($self, %args) = @_;
    for (qw/service-id reason/) {
        if ( ! $args{$_} ) { die "You must provide the $_ parameter"; }
        }

    my $response = $self->_make_request("requestmac", \%args);

    return (
        mac => $response->{a}->{"mac"}->{content},
        "expiry_date" => $response->{a}->{"expiry_date"}->{content}
    );
}

=head2 service_status

    $murphx->service_status( "12345" );

Gets the current status for the given service id.

Returns a hash containing:

    live, username, ip-address, session-established, session-start-date,
    ping-test, average-latency

=cut

sub service_status {
    my ($self, $id) = @_;
    die "You must provide the service-id parameter" unless $id;
    my $response = $self->_make_request("service_status", 
        { "service-id" => $id });

    my %status = ();
    foreach ( keys %{$response->{block}->{a}} ) {
        $status{$_} = $response->{block}->{a}->{$_}->{content};
    }
    return %status
}

=head2 service_history

   $murphx->service_history( "12345" );

Returns the full history for the given service as an array each element
of which is a hash:

    order-id name date value

=cut

sub service_history { goto &service_eventlog_history; }

=head2 service_eventlog_history

$murphx->service_eventlog_history( "12345" );

Returns the full history for the given service as an array each element
of which is a hash:

    order-id name date value

=cut

sub service_eventlog_history {
    my ($self, $id) = @_;
    die "You must provide the service-id parameter" unless $id;
    my @history = ();

    my $response = $self->_make_request("service_eventlog_history",
        {"service-id" => $id });

    if ( ref $response->{block}->{block} eq "ARRAY" ) {
        while ( my $a = pop @{$response->{block}->{block}} ) {
            my %a = ();
            foreach (keys %{$a->{a}}) {
                $a{$_} = $a->{'a'}->{$_}->{'content'};
            }
            push @history, \%a;
        }
    } else {
        my %a = ();
        foreach (keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{'content'};
        }
        push @history, \%a;
    }
    return @history;
}

=head2 services_history

    $murphx->services_history( "start-date" => "2007-01-01", "stop-date" => "2007-02-01" );

Returns an array each element of which is a hash continaing the following data:

    service-id order-id date name value

=cut

sub services_history { goto &service_eventlog_changes; }

=head2 service_eventlog_changes

    $murphx->service_eventlog_changes( "start-date" => "2007-01-01", "stop-date" => "2007-02-01" );

Returns an array each element of which is a hash continaing the following data:

    service-id order-id date name value

=cut

sub service_eventlog_changes {
    my ($self, %args) = @_;
    for ( qw/ start-date stop-date /) {
        if (!$args{$_}) { die "You must provide the $_ parameter"; }
    }

    my $response = $self->_make_request("service_eventlog_changes", \%args);

    my @changes = ();
    if ( ref $response->{block}->{block} eq 'ARRAY' ) {
        while ( my $a = shift @{$response->{block}->{block}} ) {
            my %u = ();
            foreach (keys %{$a->{a}}) {
                $u{$_} = $a->{'a'}->{$_}->{content};
            }
            push(@changes, \%u);
        }
    } else {
        my %u = ();
        foreach ( keys %{$response->{block}->{block}->{a}} ) {
            $u{$_} = $response->{block}->{block}->{'a'}->{$_}->{content};
        }
        push(@changes, \%u);
    }
    return @changes;
}


=head2 order_status

    $murphx->order_status( '12345' );

Gets status of an order. Input is the order-id from Murphx

Returns a hash containing a hash order and a hash customer
The order hash contains:

    order-id, service-id, client-ref, order-type, cli, service-type, service,
    username, status, start, finish, last-update

The customer hash contains:

    forename, surname, address, city, county, postcode, telephone, building

=cut

sub order_status {
    my ($self, $id) = @_;
    die "You must provide the order-id parameter" unless $id;
    
    my $response = $self->_make_request("order_status", { "order-id" => $id });

    my %order = ();
    foreach (keys %{$response->{block}->{order}->{a}} ) {
        $order{order}{$_} = $response->{block}->{order}->{a}->{$_}->{content};
        }
    foreach (keys %{$response->{block}->{customer}->{a}} ) {
        $order{customer}{$_} = $response->{block}->{customer}->{a}->{$_}->{content};
        }
    return %order;
}

=head2 service_view

    $murphx->service_view ( "service-id" => '12345' );

Combines the data from service_details, service_history and service_options

Returns a hash as follows:

    %service = (    "service-details" => {
                        service-id => "", product-id => "", 
                        ... },
                    "service-options" => {
                        "speed-limit" => "", "suspended" => "",
                        ... },
                    ""service-history" => {
                        [ 
                            { "event-date" => "", ... },
                            ...
                        ] },
                    "customer-details" => {
                        "title" => "", "forename", ... }
                )

See Murphx documentation for full details

=cut

sub service_view {
    my ($self, %args) = @_;
    die "You must provide the service-id parameter" unless $args{"service-id"};
    
    my $response = $self->_make_request("service_view", \%args);

    my %actions = $self->service_actions(%args);

    my %service = ();
    foreach ( keys %{$response->{block}} ) {
        my $b = $_;
        if ( $response->{block}->{$b}->{block} ) {
            my @history = ();
            while ( my $h = pop @{$response->{block}->{$b}->{block}} ) {
                my %a = ();
                foreach ( keys %{$h->{a}} ) {
                    next if ( $_ =~ /(event_id|operator|operator_id)/ );
                    $a{$_} = $h->{a}->{$_}->{content};
                }
                push @history, \%a;
            }
            $service{$b} = \@history;
        }
        else {
            foreach ( keys %{$response->{block}->{$b}->{a}} ) {
                $service{$b}{$_} = $response->{block}->{$b}->{a}->{$_}->{content};
            }
        }
    }
    $service{"service_actions"} = \%actions;
    return %service;
}

=head2 service_details 

    $murphx->service_details( '12345' );

Obtains details of the service identified by "service-id" from Murphx

Returns a hash with details including (but not limited to):
    activation-date, cli, care-level, technology-type, service-id
    username, password, live, product-name, ip-address, product-id
    cidr

=cut

sub service_details {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id/);

    my $data = { detailed => 'Y', "service-id" => $args{"service-id"} };

    my $response = $self->_make_request("service_details", $data);

    my %details = ();
    foreach (keys %{$response->{block}->{a}} ) {
        $details{$_} = $response->{block}->{a}->{$_}->{content};
        }
    return %details;
}

=head2 interleaving_status

    $murphx->interleaving_status( "service-id" => 12345 );

Returns current interleaving status if available or undef;

If not undef status can be one of:

    'opt-in', 'opt-out' or 'auto'

=cut

sub interleaving_status {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id/);

    my %d = $self->service_details( %args );
    return $d{"max_interleaving"};
}

=head2 order_history

    $murphx->order_history( 12345 );

Alias to C<order_eventlog_history>

=cut


sub order_history { goto &order_eventlog_history; }

=head2 order_eventlog_history
    
    $murphx->order_eventlog_history( 12345 );

Gets order history

Returns an array, each element of which is a hash showing the next
update in date sorted order. The hash keys are date, name and value.

=cut

sub order_eventlog_history {
    my ($self, $order) = @_;
    return undef unless $order;
    my $response = $self->_make_request("order_eventlog_history", { "order-id" => $order });

    my @history = ();

    while ( my $a = shift @{$response->{block}{block}} ) {
        foreach (keys %{$a}) {
            my %u = ();
            $u{date} = $a->{'a'}->{'date'}->{'content'};
            $u{name} = $a->{'a'}->{'name'}->{'content'};
            $u{value} = $a->{'a'}->{'value'}->{'content'};

            push(@history, \%u);
        }
    }
    return @history;
}

=head2 services_overusage

    $murphx->services_overusage( "period" => "", "limit" => "100" );

Returns an array each element of which is a hash detailing each service which has
exceeded its usage cap. See the Murphx documentation for details.

=cut

sub services_overusage {
    my ($self, %args) = @_;
    die "You must provide the period parameter" unless $args{"period"};

    my $response = $self->_make_request("services_overusage", \%args);

    my @services = ();
    if ( ref $response->{block} eq "ARRAY" ) {
        while ( my $b = shift @{$response->{block}} ) {
        my %a = ();
            foreach (keys %{$b->{block}->{a}}) {
                $a{$_} = $b->{block}->{a}->{$_}->{content};
            }
            push @services, \%a;
        }
    } else {
        my %a = ();
        foreach ( keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
        }
        push @services, \%a;
    }
    return @services;
}

=head2 speed_limit_status

    $murphx->speed_limit_status( 12345 );

Returns either a hash reference or a description of the speed limit
status.

=cut

sub speed_limit_status {
    my ($self, $id) = @_;
    die "You must provide the service-id parameter" unless $id;

    my $response = $self->_make_request("speed_limit_status",
        {"service-id" => $id});

    if ( $response->{a}->{content} ) { return $response->{a}->{content}; }
    else {
        my %status = ();
        foreach (keys %{$response->{a}} ) {
            $status{$_} = $response->{a}->{$_}->{content};
        }
        return \%status;
    }
}

=head2 speed_limit_enable

    $murphx->speed_limit_enable( "service-id" => 12345,
        "upstream-limit" => "768",
        "downstream-limit" => "768",
    );

Set speed limits for the given service.

=cut

sub speed_limit_enable {
    my ($self, %args) = @_;
    for ( qw/service-id upstream-limit downstream-limit/ ) {
        die "You must provide the $_ parameter" unless $args{$_};
    }

    my $response = $self->_make_request("speed_limit_enable", \%args);
    return 1;
}

=head2 speed_limit_disable

    $murphx->speed_limit_disable( 12345 );

Turn off speed limits for the given service.

=cut

sub speed_limit_disable {
    my ($self, %args) = @_;
    die "You must provide the service-id parameter" unless $args{"service-id"};

    my $response = $self->_make_request("speed_limit_disable", \%args);
    return 1;
}

=head2 service_unsuspend

    $murphx->service_unsuspend( 12345 );

Unsuspend this broadband service.

=cut

sub service_unsuspend {
    my ($self, %args) = @_;
    die "You must provide the service-id parameter" unless $args{"service-id"};

    my $response = $self->_make_request("service_unsuspend", \%args);
    return 1;
}

=head2 service_suspend

    $murphx->service_suspend( "service-id" => 12345, 
                              reason => "I don't like them");

Suspend this broadband service for the given reason.

=cut

sub service_suspend {
    my ($self, %args) = @_;
    for ( qw/service-id reason/) {
        die "You must provide the $_ parameter" unless $args{$_};
    }

    my $response = $self->_make_request("service_suspend", \%args);
    return 1;
}

=head2 walledgarden_status

    $murphx->walledgarden_status( "service-id" => 12345 );

Returns true is the current service is subject to walled garden 
restrictions or undef if not.

=cut

sub walledgarden_status {
    my ($self, %args) = @_;
    die "You must provide the service-id parameter" unless $args{"service-id"};

    my $response = $self->_make_request("walledgarden_status", \%args);

    return 1 if $response->{a}->{walledgarden}->{content} eq 'enabled';
    return undef;
}

=head2 walledgarden_enable

    $murphx->walledgarden_enable( "service-id" => 12345, "ip-address" -> '192.168.1.1' );

Redirects all (http and https) traffic to the specified IP address

=cut

sub walledgarden_enable {
    my ($self, %args) = @_;
    for ( qw/service-id ip-address/) {
        die "You must provide the $_ parameter" unless $args{$_};
    }

    my $response = $self->_make_request("walledgarden_enable", \%args);
    return 1;
}

=head2 walledgarden_disable

    $murphx->walledgarden_disable( "service-id" => 12345 );

Disables the "walled garden" restriction on the service

=cut

sub walledgarden_disable {
    my ($self, %args) = @_;
    die "You must provide the service-id parameter" unless $args{"service-id"};

    my $response = $self->_make_request("walledgarden_disable", \%args);
    return 1;
}

=head2 change_carelevel

    $murphx->change_carelevel( "service-id" -> 12345, "care-level" => "enhanced" );

Changes the care-level associated with a given service. 

care-level can be set to either standard or enhanced.

Returns true is successful.

=cut

sub change_carelevel {
    my ($self, %args) = @_;
    $self->_check_params( \%args );

    my $response = $self->_make_request("change_carelevel", \%args);
    return 1;
}

=head2 care_level

    $murphx->carei_level( "service-id" -> 12345, "care-level" => "enhanced" );

Changes the care-level associated with a given service. 

care-level can be set to either standard or enhanced.

Returns true is successful.

=cut


sub care_level {
    my ($self, %args) = @_;
    $self->_check_params( \%args );

    $self->change_carelevel( %args );
}

=head2 service_actions

    $murphx->service_actions( "service-id" -> 12345 );

Returns a hash detailing which actions can be taken on the given service.

Each action has a corresponding function in this module.

=cut

sub service_actions {
    my ($self, %args) = @_;

    die "You must provide the service-id parameter" unless $args{"service-id"};

    my $response = $self->_make_request("service_actions", \%args);

    my %ret = ();
    foreach ( keys %{$response->{block}->{a}} ) {
        $ret{$_} = $response->{block}->{a}->{$_}->{content};
    }
    return %ret;
}

=head2 product_details

    $murphx->product_details( $product-id );

Returns full product details for the given product id

=cut

sub product_details {
    my ($self, $id) = @_;
    die "You cannot must provide the product-id" unless $id;

    my $response = $self->_make_request("product_details",
        { "product-id" => $id, "detailed" => 'Y' });

    my %a = ();
    foreach ( keys %{$response->{block}->{a}} ) {
        $a{$_} = $response->{block}->{a}->{$_}->{content};
    }
    return %a
}

=head2 customer_details

    $murphx->customer_details($serviceId);

Returns the customer details for a given service ID

=cut

sub customer_details {
    my ($self, $id) = @_;

    die "You cannot call _get_customer_id without the service-id" unless $id;

    my $response = $self->_make_request("customer_details", 
        { "service-id"=> $id, "detailed" => 'Y' });

    my %a = ();
    foreach (keys %{$response->{block}->{a}}) {
        $a{$_} = $response->{block}->{a}->{$_}->{content};
    }
    return %a;
}

=head2 case_new

    $murphx->case_new( "service-id" => 12345, "service-type" => "adsl",
        "username" => "username@realm", "cli" => "02071112222", 
        "os" => "Linux", "hardware-product" => "Other", 
        "problem-type" => "Connection", "experienced" => "2010-01-01",
        "reported" => "User does not have sync", "priority" => "High"  );

=cut

sub case_new {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/service-id problem-type 
        experienced reported priority/);

    $args{"client-id"} = $self->clientid;
    $args{"appsource"} = "XPS";
    $args{"service-type"} = "adsl";

    my %service = $self->service_details( %args );

    $args{username} = $service{username};
    $args{cli} = $service{cli};

    my $response = $self->_make_request("case_new", \%args);

# This is not finished. I need to determine the correct part of $response to return

    return $response;
}

=head2 case_view

    $murphx->case_view( "case-id" => "12345" );

Returns a hash containing details of an existing case

=cut

sub case_view {
    my ($self, %args) = @_;
    $self->_check_params(\%args, qw/case-id/);

    my $response = $self->_make_request("case_view", \%args);
    
    my %case = ();
    foreach (keys %{$response->{block}->{a}}) {
        $case{$_} = $response->{block}->{a}->{$_}->{content};
    }
    return %case;
}

=head2 case_search

    $murphx->case_search( "service-id" => 12345 );

Returns basic details of all cases matching a given search.

Search parameters can include the following (and must include at least
one of them):

    case-id, service-id, customer-id, service-type, username, partial-cli,
    engineer, problem-type, priority or status

Returns an array, each element of which is a hash providing basic
details of the case. Use case_view and case_history to get more details.

=cut 

sub case_search {
    my ($self, %args) = @_;
    my $args = join('|', keys %{$formats{case_search}});
    $self->_check_params(\%args, ($args));

    my $response = $self->_make_request("case_search", \%args);

    my @cases = ();

    if ( ref $response->{block}->{block} eq "ARRAY" ) {
        while ( my $b = shift @{$response->{block}->{block}} ) {
            my %a = ();
            foreach (keys %{$b->{a}} ) {
                $a{$_} = $b->{a}->{$_}->{content};
            }
            push @cases, \%a;
        }
    }
    else {
        my %a = ();
        foreach (keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
        }
        push @cases, \%a;
    }

    return @cases;
}

=head2 case_history

    $murphx->case_history( "case-id" => "12345" );

Returns a full history for the given case-id. 

Return is an array, each element of which is a hash detailing a
specific update to the case.

=cut 

sub case_history {
    my ( $self, %args ) = @_;
    $self->_check_params( \%args, qw/case-id/ );

    my $response = $self->_make_request( "case_history", \%args );

    my @cases = ();

    if ( ref $response->{block}->{block} eq "ARRAY" ) {
        while ( my $b = shift @{$response->{block}->{block}} ) {
            my %a = ();
            foreach (keys %{$b->{a}} ) {
                $a{$_} = $b->{a}->{$_}->{content};
            }
            push @cases, \%a;
        }
    }
    else {
        my %a = ();
        foreach (keys %{$response->{block}->{block}->{a}} ) {
            $a{$_} = $response->{block}->{block}->{a}->{$_}->{content};
        }
        push @cases, \%a;
    }

    return @cases;
}

=head2 case_update

    $murphx->case_update( "case-id" => "12345", "priority" => "High",
        "reason" => "More information about problem" );

Updates the given case with update given in "reason".

Returns 1 if update completed.

=cut

sub case_update {
    my ( $self, %args ) = @_;
    $self->_check_params(\%args, qw/case-id priority reason/);

    my $response = $self->_make_request("case_update", \%args);

    return 1;
}

=head2 regrade_options

    $murphx->regrade_options( "service-id" => "12345" );

Returns an array containing details of the regrade options avaiulable on the
given service using the module. Each element of the array is a hash with
the same specification as returned by services_available

=cut

sub regrade_options {
    my ($self, %args) = @_;

    my $response = $self->_make_request("modify_options", \%args);

    my %crd = ();
    my @options = ();
    while ( my $l = shift @{$response->{block}->{leadtimes}->{block}} ) {
        $crd{$l->{a}->{"product-id"}->{content}} = $l->{a}->{"first-date-text"}->{content};
    }

    while ( my $p = shift @{$response->{block}->{products}->{block}} ) {
        push @options, { 
            product_id => $p->{a}->{"product_id"}->{content},
            "product_name" => $p->{a}->{"product_name"}->{content},
            "first_date" => $crd{$p->{a}->{"product_id"}->{content}},
            "max_speed" => $p->{a}->{"service_speed"}->{content}
        };
    }
    return @options;
}

=head2 regrade

    $murphx->regrade( "service-id" => "12345",
                      "prod-id" => 1595,
                      "crd" => "2010-02-01" );

Places an order to regrade the specified service to the defined prod-id
on the crd specified. Use regrade_options first to determine which
products are available and the earliest crd available.

The parameters you may pass to this function are the same as for the 
modify function. See Murphx documentation for details.

=cut

sub regrade {
    my ($self, %args) = @_;
    $args{'client-ref'} = $args{'service-id'}."-regrade" unless $args{'client-ref'};
    $args{'care-level'} = "standard" unless $args{'care-level'};

    return $self->modify(%args);
}

=head2 order

    $murphx->order(
        # Customer details
        forename => "Clara", surname => "Trucker", 
        building => "123", street => "Pigeon Street", city => "Manchester", 
        county => "Greater Manchester", postcode => "M1 2JX",
        telephone => "01614960213", 
        # Order details
        clid => "01614960213", "client-ref" => "claradsl", 
        "prod-id" => $product, crd => $leadtime, username => "claraandhugo",
        password => "skyr153", "care-level" => "standard", 
        realm => "surfdsl.net"
    );

Submits an order for DSL to be provided to the specified phone line.
Note that all the parameters above must be supplied. CRD is the
requested delivery date in YYYY-mm-dd format; you are responsible for
computing dates after the minimum lead time. The product ID should have
been supplied to you by Murphx.

Additional parameters are listed below and described in the integration
guide:

    title street company mobile email fax sub-premise fixed-ip routed-ip
    allocation-size hardware-product max-interleaving test-mode
    inclusive-transfer

If a C<mac> and C<losing-isp> is passed, then the order is understood as a
migration rather than a provision.

Returns a hash describing the order.

=cut

sub order {
    my ($self, %data_in) = @_;
    # We expect it "flat" and arrange it into the right blocks as we check it
    my $data = {};
    for (qw/forename surname building city county postcode telephone/) {
        if (!$data_in{$_}) { die "You must provide the $_ parameter"; }
        $data->{customer}{$_} = $data_in{$_};
    }
    defined $data_in{$_} and $data->{customer}{$_} = $data_in{$_} 
        for qw/title street company mobile email fax sub-premise/;

    for (qw/cli client-ref prod-id crd username/) {
        if (!$data_in{$_}) { die "You must provide the $_ parameter"; }
        $data->{order}{$_} = $data_in{$_};
    }

    for (qw/password realm care-level/) {
        if (!$data_in{$_}) { die "You must provide the $_ parameter"; }
        $data->{order}{attributes}{$_} = $data_in{$_};
    }
    defined $data_in{$_} and $data->{order}{attributes}{$_} = $data_in{$_} 
        for qw/fixed-ip routed-ip allocation-size hardware-product pstn-order-id
            max-interleaving test-mode inclusive-transfer mac losing-isp/;

    my $response = undef;
    if ( defined $data_in{"mac"} && defined $data_in{"losing-isp"} ) {
        $response = $self->_make_request("migrate", $data);
    } else {
        $response = $self->_make_request("provide", $data);
    }

    my %order = ();
    foreach ( keys %{$response->{a}} ) {
        $order{$_} = $response->{a}->{$_}->{content};
    }
    return %order;
}

=head2 terms_and_conditions

Returns the terms-and-conditions to be presented to the user for signup
of a broadband product.

=cut

sub terms_and_conditions {
    return "XXX Get terms and conditions dynamically, or just put them here";
}

=head2 first_crd

    $murphx->first_crd( "order-type" => "provide", "product-id" => "1595" );

Returns the first possible date in ISO format an order of the specified 
may be placed for.

Required Parameters:

    order-type : provide, migrate in, modify or cease
    product-id : the Murphx product ID

=cut

sub first_crd {
    my ($self, %args) = @_;

    my %leadtime = $self->leadtime(%args);

    return $leadtime{"first_date_text"};
}

=head2 leadtime

    $murphx->leadtime( "order-type" => "provide", "product-id" => "1595" );

Returns a hash detailing the leadtime and first date for an order of the
given type and for the given product. 

Required Parameters:

    order-type : provide, migrate in, modify or cease
    product-id : the Murphx product ID

Returns:

    leadtime        : number of leadtime days
    first-date-int  : first date as seconds since unix epoch
    first-date-text : first date in ISO format

=cut

sub leadtime {
    my ($self, %args) = @_;

    my $response = $self->_make_request("leadtime", \%args);

    my %lead = ();

    foreach (keys %{$response->{a}}) {
        $lead{$_} = $response->{a}->{$_}->{content};
    }

    return %lead;
}

1;
