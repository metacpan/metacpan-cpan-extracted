#!/usr/bin/perl

=head1 NAME

Options.t - Test commandline options and such

=cut

package FooServer;

use strict;
use FindBin qw($Bin);
use lib $Bin;
use NetServerTest qw(prepare_test ok is use_ok skip like);
prepare_test({n_tests => 73, plan_only => 1});

use_ok('Net::Server');
@FooServer::ISA = qw(Net::Server);

### override-able options for this package
sub options {
  my $self     = shift;
  my $prop     = $self->{'server'};
  my $template = shift;

  ### setup options in the parent classes
  $self->SUPER::options($template);

  $template->{'my_option'} = \$prop->{'my_option'};

  $prop->{'an_arrayref_item'} ||= [];
  $template->{'an_arrayref_item'} = $prop->{'an_arrayref_item'};
}

### provide default values
sub default_values {
    return {
        group => 'defaultgroup',
        allow => ['127.0.0.1', '192.169.0.1'],
    };
}

#sub proto_object {
#    my ($self, $host, $port, $proto) = @_;
#    #debug $host, $port, $proto;
#    #return $self->SUPER::proto_object($host, $port, $proto);
#    return "Blah";
#}

### override these to make run not run
### this will allow all configuration cycles to be run
sub bind {}
sub post_bind {}
sub loop {}
sub log {}
sub server_close {
    my $self = shift;
    return $self;
}

###----------------------------------------------------------------###

my $obj = eval { FooServer->new };
ok($obj, "Got an object ($@)");

my $server = eval { FooServer->run };
ok($server, "Got a server ($@)");
my $prop = eval { $server->{'server'} } || {};
is($prop->{'log_level'}, 2,  "Correct default log_level");
is($prop->{'log_file'}, "", "Correct default log_file");
ok(! $prop->{'user'},          "Correct default user");
my $configured_ports = scalar(@{ $prop->{'_bind'} });
ok($configured_ports == 1 || $configured_ports == 2, "Had correct configured ports ($configured_ports)");
my @socks = @{ $prop->{'sock'} };
is(scalar(@socks), scalar(@{ $prop->{'_bind'} }), "Sockets matched ports");
my $sock = $socks[0];
if ($sock->NS_ipv == 4) {
    is(eval { $sock->NS_host  }, '0.0.0.0',   "Right host");
} else {
    is(eval { $sock->NS_host  }, '::',   "Right host");
}
is(eval { $sock->NS_port  }, 20203, "Right port");
is(eval { $sock->NS_proto }, 'TCP', "Right proto");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(port => 2201)->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{ $prop->{'port'} }), 1,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(port => [2201, 2202])->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{ $prop->{'port'} }), 2,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");
is($prop->{'port'}->[1], 2202, "Right port");

###----------------------------------------------------------------###

$prop = eval { FooServer->run({port => 2201})->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'port'} }), 1,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");

###----------------------------------------------------------------###

$prop = eval { FooServer->new(port => 2201)->run->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'port'} }), 1,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");

###----------------------------------------------------------------###

$prop = eval { FooServer->new({port => 2201})->run->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'port'} }), 1,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");

###----------------------------------------------------------------###

$prop = eval { local @ARGV = ('--port', '2201'); FooServer->run->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'port'} }), 1,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");

###----------------------------------------------------------------###

$prop = eval { local @ARGV = ('--port', '2201', '--port=2202'); FooServer->run->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'port'} }), 2,    "Had 1 configured ports");
is($prop->{'port'}->[0], 2201, "Right port");
is($prop->{'port'}->[1], 2202, "Right port");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(conf_file => __FILE__.'.conf')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'port'} }), 3,    "Had 1 configured ports");
is($prop->{'port'}->[0], 5401, "Right port");
is($prop->{'port'}->[1], 5402, "Right port");
is($prop->{'port'}->[2], 5403, "Right port");
is($prop->{'user'}, 'foo',     "Right user");

###----------------------------------------------------------------###

$prop = eval { local @ARGV = ('--user=cmdline'); FooServer->run(conf_file => __FILE__.'.conf', user => 'runargs')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'user'}, 'cmdline', "Right user \"$prop->{'user'}\"");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(conf_file => __FILE__.'.conf', user => 'runargs')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'user'}, 'runargs', "Right user \"$prop->{'user'}\"");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(my_option => 'wow')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'my_option'}, 'wow', 'Could use custom options');

###----------------------------------------------------------------###

$prop = eval { FooServer->run(an_arrayref_item => 'wow')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is(scalar(@{  $prop->{'an_arrayref_item'} }), 1,     "Had 1 configured custom array option");
is($prop->{'an_arrayref_item'}->[0], 'wow', "Right value");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(conf_file => __FILE__.'.conf', user => 'runargs')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'my_option'}, 'bar', "Right my_option \"$prop->{'my_option'}\"");
is(scalar(@{  $prop->{'an_arrayref_item'} }), 3,     "Had 3 configured custom array option");
is($prop->{'an_arrayref_item'}->[0], 'one',   "Right value");
is($prop->{'an_arrayref_item'}->[1], 'three', "Right value");
is($prop->{'an_arrayref_item'}->[2], 'two',   "Right value");

###----------------------------------------------------------------###

$prop = eval { local @ARGV = ('--group=cmdline'); FooServer->run(conf_file => __FILE__.'.conf', group => 'runargs')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'group'}, 'cmdline', "Right group \"$prop->{'group'}\"");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(conf_file => __FILE__.'.conf', group => 'runargs')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'group'}, 'runargs', "Right group \"$prop->{'group'}\"");

###----------------------------------------------------------------###

$prop = eval { FooServer->run(conf_file => __FILE__.'.conf')->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'group'}, 'confgroup', "Right group \"$prop->{'group'}\"");

###----------------------------------------------------------------###

$prop = eval { FooServer->run->{'server'} };
ok($prop, "Loaded server");
$prop ||= {};
is($prop->{'group'}, 'defaultgroup', "Right group \"$prop->{'group'}\"");
is(scalar(@{ $prop->{'allow'} }), 2, "Defaults for allow are set also");

###----------------------------------------------------------------###

{
    package BarServer;
    @BarServer::ISA = qw(FooServer);
    sub default_values {
        return {
            conf_file => __FILE__.'.conf'
        };
    }
}

$prop = eval { BarServer->run->{'server'} };
$prop ||= {};
is($prop->{'group'}, 'confgroup', "Right group \"$prop->{'group'}\"");

###----------------------------------------------------------------###

$prop = eval { FooServer->new({
    conf_file => __FILE__.'.conf', # arguments passed to new win
})->run({
    conf_file => 'somefile_that_doesnot_exist',
})->{'server'} };
$prop ||= {};
is($prop->{'group'}, 'confgroup', "Right group \"$prop->{'group'}\"");



###----------------------------------------------------------------###

if (!$ENV{'TEST_LOG4PERL'}) {
  SKIP: { skip("TEST_LOG4PERL not set - skipping Log::Log4perl tests", 7) };
} elsif (!eval { require Log::Log4perl; require File::Temp }) {
  SKIP: { skip("Log::Log4perl not installed: $@", 7) };
} else {

    $prop = eval { FooServer->run(
        log_file => "Log::Log4perl"
    ) };
    like("$@", qr/Must specify a log4perl_conf file/, "Got error due to missing log4perl_conf");

    my ($log_fh, $log4perl_file) = File::Temp::tempfile(SUFFIX => '.log', UNLINK => 1);
    unlink $log4perl_file;

    my $conf = << "EOF";
log4perl.logger.tester = WARN, FileAppndr1

log4perl.appender.FileAppndr1 = Log::Log4perl::Appender::File
log4perl.appender.FileAppndr1.filename = ${log4perl_file}
log4perl.appender.FileAppndr1.layout = Log::Log4perl::Layout::SimpleLayout
EOF

    my ($conf_fh, $conf_file) = File::Temp::tempfile(SUFFIX => '.log4perl', UNLINK => 1);
    print $conf_fh $conf;
    close $conf_fh;

    # This log file is same as specified in Options.t.log4perl
    open my $old_stdout, ">&", STDOUT; # save this off because setting a log_file is going to force close STDIN and STDOUT
    $prop = eval { FooServer->run(
        log_file => "Log::Log4perl",
        log4perl_conf => $conf_file,
        log4perl_logger => "tester",
    )->{'server'} };
    my $err = "$@";
    open STDOUT, ">&", $old_stdout; # restore it

    # There was a test for a bad log4perl_conf file, but log4perl only allows you to initialise once
    # so subsequent initialisations always had the bad filename
    #like( $@, qr/Cannot open config file '.*?'/, "Got error due to missing log4perl_conf file" );
    ok(!$err, "No Log4perl errors");
    is(ref($prop->{'log_function'}), "CODE", "Log4perl initialised with function created");
    ok(-e $log4perl_file, "Log file $log4perl_file found");
    ok(! -s $log4perl_file, "Log file is 0 bytes");

    $prop->{'log_function'}->(1, "A test message");
    ok(-s $log4perl_file, "Log file now has data");

    open my $fh, '<', $log4perl_file;
    my $data = <$fh>;
    is($data, "ERROR - A test message\n", "Got expected log message");
}
