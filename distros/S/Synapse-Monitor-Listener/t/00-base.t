# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Synapse-Object.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use lib ('../lib', './lib');
use Test::More;
use YAML::XS;
use strict;
no warnings;

for (qw /Synapse::Monitor::Listener Synapse::Monitor::Listener::Action Synapse::Monitor::Listener::State/) {
    eval "use $_";
    my $ok = $@ ? 0 : 1;
    ok ($ok, "use $_");
}

$Synapse::CLI::Config::BASE_DIR          = "./t/config";
$Synapse::CLI::Config::ALIAS->{type}     = 'Synapse::CLI::Config::Type';
$Synapse::CLI::Config::ALIAS->{action}   = 'Synapse::Monitor::Listener::Action';
$Synapse::CLI::Config::ALIAS->{state}    = 'Synapse::Monitor::Listener::State';
$Synapse::CLI::Config::ALIAS->{listener} = 'Synapse::Monitor::Listener';
$Synapse::Logger::BASE_DIR = "./t/log";

mkdir "./t/config";
mkdir "./t/config/Synapse-Monitor-Listener-State";
mkdir "./t/config/Synapse-Monitor-Listener-Action";
mkdir "./t/config/Synapse-Monitor-Listener";
map { Synapse::Monitor::Listener::State->new($_)->remove() } Synapse::Monitor::Listener::State->list();
map { Synapse::Monitor::Listener::Action->new($_)->remove() } Synapse::Monitor::Listener::Action->list();
map { Synapse::Monitor::Listener->new($_)->remove() } Synapse::Monitor::Listener->list();


# let's create an 'ASR' listener...
my $res = Synapse::CLI::Config::execute (qw/type listener create asr ASR listener/);
ok (ref $res);
is (ref $res, 'Synapse::Monitor::Listener');
is ($res->label(), 'ASR listener');
is ($res->name(), 'asr');

$res = Synapse::CLI::Config::execute (qw /listener asr action WARN.DOWN OK asr-email-goodjob/);
ok ($res);
ok ($res->{action});
ok ($res->{action}->{WARN});
ok ($res->{action}->{WARN}->{OK});
ok ($res->{action}->{WARN}->{OK}->[0]);
is ($res->{action}->{WARN}->{OK}->[0], 'asr-email-goodjob');
ok ($res->{action}->{DOWN});
ok ($res->{action}->{DOWN}->{OK});
ok ($res->{action}->{DOWN}->{OK}->[0]);
is ($res->{action}->{DOWN}->{OK}->[0], 'asr-email-goodjob');

$res = Synapse::CLI::Config::execute (qw /listener asr action OK WARN asr-email-warning/);
ok ($res);
ok ($res->{action});
ok ($res->{action}->{OK});
ok ($res->{action}->{OK}->{WARN});
ok ($res->{action}->{OK}->{WARN}->[0]);
is ($res->{action}->{OK}->{WARN}->[0], 'asr-email-warning');

$res = Synapse::CLI::Config::execute (qw /listener asr action OK.WARN DOWN asr-email-down suspend-route/);
ok ($res);
ok ($res->{action});
ok ($res->{action}->{OK});
ok ($res->{action}->{OK}->{DOWN});
ok ($res->{action}->{OK}->{DOWN}->[0]);
is ($res->{action}->{OK}->{DOWN}->[0], 'asr-email-down');
ok ($res->{action}->{OK}->{DOWN}->[1]);
is ($res->{action}->{OK}->{DOWN}->[1], 'suspend-route');
ok ($res->{action}->{WARN});
ok ($res->{action}->{WARN}->{DOWN});
ok ($res->{action}->{WARN}->{DOWN}->[0]);
is ($res->{action}->{WARN}->{DOWN}->[0], 'asr-email-down');
ok ($res->{action}->{WARN}->{DOWN}->[1]);
is ($res->{action}->{WARN}->{DOWN}->[1], 'suspend-route');

my $listener = $res;


# now let's create corresponding actions
Synapse::CLI::Config::execute (qw/type action create asr-email-goodjob GOODJOB/);
Synapse::CLI::Config::execute (qw/type action create asr-email-warning WARNING./);
Synapse::CLI::Config::execute (qw/type action create asr-email-down DOWN/);
Synapse::CLI::Config::execute (qw/type action create suspend-route SUSPEND/);


# we don't *really* want to system() anything
# let's put the commands in some buffer instead
*Synapse::Monitor::Listener::Action::system_execute = sub { $::SYSTEM_EXE = shift };


my $oldState = 'WARN';
my $newState = 'OK';
my $event = {
    foo => 'bar'
};

$listener->process ('WARN', 'OK', $event);
like ($::SYSTEM_EXE, qr/GOODJOB/);

$listener->process ('OK', 'DOWN');
like ($::SYSTEM_EXE, qr/SUSPEND/);


# let's set EVTDIR and create a few event files...
$Synapse::Monitor::Listener::EVTDIR  = '/tmp';
$Synapse::Monitor::Listener::EVTEXT  = '.evt.yml';


# first pass : we create an event and set it to OK
open FP, ">$Synapse::Monitor::Listener::EVTDIR/test.evt.yml" or die "cannot write test.evt.yml";
print FP Dump { id => 'myevent', state => 'OK', listener => 'asr' };
close FP; 

# run first loop
Synapse::Monitor::Listener->runonce();

# this should create a state object with proper status
my $oldState = Synapse::Monitor::Listener::State->new ('myevent');
is ($oldState->label(), 'OK');

$::SYSTEM_EXE = undef;

# second pass : we create same and set it to WARN
open FP, ">$Synapse::Monitor::Listener::EVTDIR/test.evt.yml" or die "cannot write test.evt.yml";
print FP Dump { id => 'myevent', state => 'WARN', listener => 'asr' };
close FP; 

# run loop
Synapse::Monitor::Listener->runonce();

# now state should be 'WARN'
my $oldState = Synapse::Monitor::Listener::State->new ('myevent');
is ($oldState->label(), 'WARN');

# and executed command should be 'WARNING'
like ($::SYSTEM_EXE, qr/WARNING/);


# third pass : we create same and set it back to OK
open FP, ">$Synapse::Monitor::Listener::EVTDIR/test.evt.yml" or die "cannot write test.evt.yml";
print FP Dump { id => 'myevent', state => 'OK', listener => 'asr' };
close FP; 

# run loop
Synapse::Monitor::Listener->runonce();

# now state should be 'OK'
my $oldState = Synapse::Monitor::Listener::State->new ('myevent');
is ($oldState->label(), 'OK');

# wow, good job, it's back up!
like ($::SYSTEM_EXE, qr/GOODJOB/);

map { Synapse::Monitor::Listener::State->new($_)->remove() } Synapse::Monitor::Listener::State->list();
map { Synapse::Monitor::Listener::Action->new($_)->remove() } Synapse::Monitor::Listener::Action->list();
map { Synapse::Monitor::Listener->new($_)->remove() } Synapse::Monitor::Listener->list();


Test::More::done_testing();


__END__
