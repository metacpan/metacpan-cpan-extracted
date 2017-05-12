#!/usr/bin/perl

use strict;
use warnings;

use threads;
use threads::shared;

use Pots::Thread::MethodServer;

$|=1;

# Class that will be exposed
package Some::Class;

use base qw(Pots::SharedObject);

sub method1 {
    my $self = shift;

    print "method1 called with ", join(' ', @_), "\n";

    return 42;
}

1;

package main;

my $ms = Pots::Thread::MethodServer->new(cclass => 'Some::Class');
$ms->start() or die "MethodServer failed to start\n";

my $cli = $ms->client();

my $ret = $cli->method1("foo", 1234, "bar");
print "MAIN: ret = $ret\n";

sleep(5);
$ms->stop();
