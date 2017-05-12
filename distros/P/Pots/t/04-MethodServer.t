use Test::More tests => 6;

use strict;
use warnings;

use threads;
use threads::shared;

package Some::Class;

sub new {
    my $class = shift;

    my %hself : shared = ();
    return bless(\%hself, ref($class) || $class);
}

sub testmeth {
    my $self = shift;
    my $arg = shift;

    return ($arg * 2);
}

1;

package main;

use_ok('Pots::Thread::MethodServer');
can_ok('Pots::Thread::MethodServer',
       qw(new start stop postmsg getmsg)
);

my $ms = Pots::Thread::MethodServer->new(
    cclass => 'Some::Class'
);
is($ms->start(), 1, "MethodServer start");
isa_ok($ms, 'Pots::Thread::MethodServer');
my $cli = $ms->client();
isa_ok($cli, 'Pots::Thread::MethodClient::Object::Some::Class');
my $ret = $cli->testmeth(2);
is($ret, 4, "Method call with result");

$ms->stop();
