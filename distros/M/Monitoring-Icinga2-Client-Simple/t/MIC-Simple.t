#!/usr/bin/perl
use strict;
use warnings;
use v5.10.1;
use utf8;
use open qw/ :encoding(UTF-8) :std /;
use Test::More;
use Test::Fatal;
use JSON::XS;
use Monitoring::Icinga2::Client::Simple;

my $LOGIN = getlogin || getpwuid($<);
my @START_END = (
    start_time => 1_234_567_890,
    end_time   => 1_234_567_890 + 60,
);

my $uri_base     = 'https://localhost:5665/v1';
my $uri_scheddt  = "$uri_base/actions/schedule-downtime";
my $uri_removedt = "$uri_base/actions/remove-downtime";
my $uri_custnot  = "$uri_base/actions/send-custom-notification";
my $uri_hosts    = "$uri_base/objects/hosts";
my $uri_services = "$uri_base/objects/services";
my $uri_app      = "$uri_base/objects/icingaapplications/app";
my $uri_status   = "$uri_base/status/IcingaApplication";

my $fil_host     = '"filter":"host.name==\"localhost\""';
my $fil_hostsrv  = '"filter":"host.name==\"localhost\" && service.name==\"myservice\""';

my $req_frag1 = '{"author":"admin","comment":"no comment","duration":null,"end_time":1234567950,"filter":"host.name==\"localhost\"';
my $req_frag2 = $req_frag1 . '","fixed":null,"joins":["host.name"],"start_time":1234567890,"type":';

my $req_dthost   = $req_frag2 . '"Host"}';
my $req_dtservs  = $req_frag2 . '"Service"}';
my $req_dtserv   = $req_frag1 . ' && service.name==\"myservice\"","fixed":null,"joins":["host.name"],"start_time":1234567890,"type":"Service"}';
(my $req_dthostu = $req_dthost) =~ s/admin/$LOGIN/;

isa_ok( newob(), 'Monitoring::Icinga2::Client::Simple', "new" );

like(
    exception { Monitoring::Icinga2::Client::Simple->new(1) },
    qr/^only hash-style args are supported/,
    'constructor catches wrong calling style'
);

like(
    exception { Monitoring::Icinga2::Client::Simple->new( foo => 1 ) },
    qr/^`server' arg is required/,
    'constructor catches missing server arg'
);

is(
    exception { Monitoring::Icinga2::Client::Simple->new( server => 'foo' ) },
    undef,
    'hostname is the only mandatory argument'
);

req_fail(
    'schedule_downtime',
    [ host => 'localhost' ],
    qr/^missing or undefined argument `start_time'/,
    "detects missing args"
);

req_ok(
    'schedule_downtime',
    [ host => 'localhost', @START_END, comment => 'no comment', author => 'admin', ],
    [ $uri_scheddt => $req_dthost ],
    "schedule_downtime"
);

req_ok(
    'schedule_downtime',
    [ host => 'localhost', @START_END, comment => 'no comment', author => 'admin', services => 1 ],
    [
        $uri_scheddt => $req_dthost,
        $uri_scheddt => $req_dtservs,
    ],
    "schedule_downtime w/services"
);

req_ok(
    'schedule_downtime',
    [ host => 'localhost', @START_END, comment => 'no comment', author => 'admin', service => 'myservice' ],
    [ $uri_scheddt => $req_dtserv ],
    "schedule_downtime w/single service"
);

req_ok(
    'schedule_downtime',
    [ host => 'localhost', @START_END, comment => 'no comment', author => 'admin', service => 'myservice', services => 1 ],
    [
        $uri_scheddt => $req_dthost,
        $uri_scheddt => $req_dtservs,
    ],
    "schedule_downtime w/both service and services specified"
);

req_ok(
    'schedule_downtime',
    [ host => 'localhost', @START_END, comment => 'no comment' ],
    [ $uri_scheddt => $req_dthostu ],
    "schedule_downtime w/o explicit author"
);

req_ok(
    'remove_downtime',
    [ host => 'localhost', service => 'myservice' ],
    [ $uri_removedt => '{' . $fil_hostsrv . ',"joins":["host.name"],"type":"Service"}' ],
    "remove_downtime w/single service"
);

req_ok(
    'remove_downtime',
    [ host => 'localhost' ],
    [ $uri_removedt => '{' . $fil_host . ',"joins":["host.name"],"type":"Host"}' ],
    "remove_downtime w/host only"
);

req_ok(
    'remove_downtime',
    [ name => 'foobar' ],
    [ "$uri_removedt\\?downtime=foobar" => '{"type":"Downtime"}' ],
    "remove_downtime by name"
);

req_ok(
    'send_custom_notification',
    [ comment => 'mycomment', author => 'admin', host => 'localhost' ],
    [ $uri_custnot => '{"author":"admin","comment":"mycomment","filter":"host.name==\"localhost\"","type":"Host"}' ],
    "send custom notification for host"
);

req_ok(
    'send_custom_notification',
    [ comment => 'mycomment', author => 'admin', service => 'myservice' ],
    [ $uri_custnot => '{"author":"admin","comment":"mycomment","filter":"service.name==\"myservice\"","type":"Service"}' ],
    "send custom notification for service"
);

req_ok(
    'send_custom_notification',
    [ comment => 'mycomment', service => 'myservice' ],
    [ $uri_custnot => '{"author":"' . $LOGIN . '","comment":"mycomment","filter":"service.name==\"myservice\"","type":"Service"}', ],
    "send custom notification w/o explicit author"
);

req_ok(
    'set_notifications',
    [ state => 1, host => 'localhost' ],
    [ $uri_hosts => '{"attrs":{"enable_notifications":"1"},"filter":"host.name==\"localhost\""}' ],
    "enable notifications for host"
);

req_ok(
    'set_notifications',
    [ state => 0, host => 'localhost', service => 'myservice' ],
    [ $uri_services => '{"attrs":{"enable_notifications":""},'. $fil_hostsrv .'}' ],
    "enable notifications for service"
);

req_fail(
    'set_notifications',
    [ state => 1, service => 'myservice' ],
    qr/^missing or undefined argument `host' to Monitoring::Icinga2::Client::Simple::set_notifications()/,
    "catches missing host argument"
);

req_fail(
    'set_notifications',
    [ ],
    qr/^missing or undefined argument `state'/,
    "catches missing state"
);

req_ok(
    'query_app_attrs',
    [ ],
    [ $uri_status => '' ],
    "query application attributes"
);

req_ok(
    'set_app_attrs',
    [ flapping => 1, notifications => 0, perfdata => 1 ],
    [ $uri_app => '{"attrs":{"enable_flapping":"1","enable_notifications":"","enable_perfdata":"1"}}' ],
    "set application attributes"
);

req_fail(
    'set_app_attrs',
    [ foo => 1 ],
    qr/^need at least one argument of/,
    "detects missing valid args"
);

req_fail(
    'set_app_attrs',
    [ foo => 1, notifications => 0, bar => 'qux' ],
    qr/^Unknown attributes: bar,foo; legal attributes are: event_handlers,/,
    "detects invalid arg"
);

req_ok(
    'set_global_notifications',
    [ 1 ],
    [ $uri_app => '{"attrs":{"enable_notifications":"1"}}' ],
    "enable global notifications"
);

req_ok(
    'query_hosts',
    [ hosts => [qw/ localhost otherhost /] ],
    [ $uri_hosts => '{"filter":"host.name in [\"localhost\",\"otherhost\"]"}' ],
    "query host"
);

req_ok(
    'query_host',
    [ host => 'localhost' ],
    [ $uri_hosts => '{"filter":"host.name==\"localhost\""}' ],
    "query host"
);

req_ok(
    'query_child_hosts',
    [ host => 'localhost' ],
    [ $uri_hosts => '{"filter":"\"localhost\" in host.vars.parents"}' ],
    "query child hosts"
);

req_ok(
    'query_parent_hosts',
    [ host => 'localhost' ],
    [ $uri_hosts => '{"filter":"host.name==\"localhost\""}' ],
    "query parent hosts"
);

req_ok(
    'query_parent_hosts',
    [ host => 'localhost', expand => 1 ],
    [
        $uri_hosts => '{"filter":"host.name==\"localhost\""}',
        $uri_hosts => '{"filter":"host.name in [\"parent1\",\"parent2\"]"}'
    ],
    "query parent hosts with expansion"
);

req_ok(
    'query_services',
    [ service => 'myservice' ],
    [ $uri_services => '{"filter":"service.name==\"myservice\""}' ],
    "query service"
);

req_ok(
    'query_services',
    [ services => [ qw/ myservice otherservice / ] ],
    [ $uri_services => '{"filter":"service.name in [\"myservice\",\"otherservice\"]"}' ],
    "query services (synonymous arg)"
);

# Check that _mic_author is always set
is( newob()->{_mics_author}, $LOGIN, "_mics_author set with useragent" );
is( Monitoring::Icinga2::Client::Simple->new( server => 'localhost' )->{_mics_author}, $LOGIN, "_mics_author set w/o useragent" );

done_testing;

# Check that a request succeeds and has both the right URI and the
# correct postdata.
# Args:
# * method to call
# * arguments as an arrayref
# * expected requests as uri => postdata pairs in a an arrayref
# * description of this test
sub req_ok {
    my ($method, $margs, $req_cont, $desc) = @_;
    my $c = newob();
    is(
        exception { $c->$method( @$margs ) },
        undef,
        "$desc: arg check passes for $method",
    ) and _checkreq( $c, $req_cont, $desc );
}

# Check that a request fails (i.e. dies) when it is supposed to,
# e.g. to catch wrong or missing arguments
sub req_fail {
    my ($method, $margs, $except_re, $desc) = @_;
    my $c = newob();
    like(
        exception { $c->$method( @$margs ) },
        $except_re,
        "$method fails: $desc",
    );
}

sub _checkreq {
    my ($c, $req_contents, $desc) = @_;

    my $calls = $c->{ua}->calls;

    my $i = 1;
    for my $req ( grep { $_->{method} eq 'FakeUA::request' } @$calls ) {
        my ($uri, $content) = splice @$req_contents, 0, 2;
        # Fix up URI to account for a concatenation bug that might get fixed
        $uri =~ s!/v1/!/v1//?!;
        like( $req->{args}[0]->uri, qr/^$uri$/, "$desc (uri $i)" );
        is( _canon_json( $req->{args}[0]->content ), $content, "$desc (req $i)" );
        $i++;
    }
}

# Construct a new object with the fake UserAgent that collects call stats
sub newob {
    return Monitoring::Icinga2::Client::Simple->new(
        server => 'localhost',
        useragent => FakeUA->new,
    );
}

# Canonicalize a JSON string by decoding and subsequent encoding
sub _canon_json {
    my $s = shift;
    return $s unless defined $s and length $s;
    my $codec = JSON::XS->new->canonical;
    return $codec->encode(
        $codec->decode( $s )
    );
}

package FakeUA;
use Clone 'clone';
use strict;
use warnings;

sub new {
    return bless {
        calls => [],
    }, shift;
}

sub credentials { _logcall(@_); }
sub default_header { _logcall(@_) }

sub request {
    my $self = shift;
    my $req = $_[0];
    $self->_logcall( @_ );

    my $content = '{"results":[]}';
    if( $req->uri =~ m!/status/IcingaApplication$! ) {
        $content = '{"results":[{"status":{"icingaapplication":{"app":[]}}}]}'
    } elsif( _incallers(qr/query_parent_hosts/) ) {
        $content = '{"results":[{"attrs":{"vars":{"parents":["parent1","parent2"]}}}]}'
    }
    return HTTP::Response->new( 200, 'OK', undef, $content );
}

sub calls {
    return shift->{calls};
}

sub _incallers {
    my $re = shift;
    my $f=1;
    my $caller;
    while(1) {
        $caller = (caller( $f++ ))[3] // return;
        return 1 if $caller =~ $re;
    };
    return;
}

sub _logcall {
    my $self = shift;
    my $sub = ( caller(1) )[3];
    push @{ $self->{calls} }, {
        method => $sub,
        args => clone(\@_),
    };
}
