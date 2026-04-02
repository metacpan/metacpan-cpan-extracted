#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Object::Proto;

# Define a singleton class
package Counter;
BEGIN {
    Object::Proto::define('Counter', 'count');
    Object::Proto::singleton('Counter');
}

sub BUILD {
    my ($self) = @_;
    $self->count(0);
}

sub increment {
    my ($self) = @_;
    $self->count($self->count + 1);
}

package main;

# Test basic singleton behavior
my $c1 = Counter->instance;
isa_ok($c1, 'Counter', 'instance returns Counter object');

my $c2 = Counter->instance;
isa_ok($c2, 'Counter', 'second instance also returns Counter');

is($c1, $c2, 'both instances are the same object (singleton)');

# Test that BUILD was called
is($c1->count, 0, 'BUILD was called - count initialized to 0');

# Test state persistence across instance calls
$c1->increment;
is($c1->count, 1, 'count incremented to 1');

my $c3 = Counter->instance;
is($c3->count, 1, 'new instance() call returns same object with preserved state');

$c2->increment;
is($c1->count, 2, 'all references share state');

# Test with a more complex singleton
package Logger;
BEGIN {
    Object::Proto::define('Logger', 'messages', 'level');
    Object::Proto::singleton('Logger');
}

sub BUILD {
    my ($self) = @_;
    $self->messages([]);
    $self->level('info');
}

sub log {
    my ($self, $msg) = @_;
    push @{$self->messages}, $msg;
}

package main;

my $log1 = Logger->instance;
isa_ok($log1, 'Logger', 'Logger singleton created');

is($log1->level, 'info', 'Logger BUILD set default level');
is_deeply($log1->messages, [], 'Logger BUILD initialized messages array');

$log1->log('first message');
$log1->log('second message');

my $log2 = Logger->instance;
is_deeply($log2->messages, ['first message', 'second message'],
    'second instance has same messages (singleton)');

$log2->level('debug');
is($log1->level, 'debug', 'level change visible through all references');

# Test singleton with function-style accessors
package Config;
BEGIN {
    Object::Proto::define('Config', 'debug_mode', 'host', 'port');
    Object::Proto::import_accessors('Config');
    Object::Proto::singleton('Config');
}

sub BUILD {
    my ($self) = @_;
    debug_mode $self, 0;
    host $self, 'localhost';
    port $self, 8080;
}

package main;

my $cfg = Config->instance;
is($cfg->debug_mode, 0, 'method-style accessor works with singleton');
is($cfg->host, 'localhost', 'host default set');
is($cfg->port, 8080, 'port default set');

$cfg->port(9000);
my $cfg2 = Config->instance;
is($cfg2->port, 9000, 'method-style setter persists in singleton');

# Test function-style from within the package
package Config;
sub get_host { host(shift) }
sub set_port { port($_[0], $_[1]) }

package main;
is(Config::get_host($cfg), 'localhost', 'function-style accessor from within package works');
Config::set_port($cfg, 3000);
is($cfg->port, 3000, 'function-style setter from within package works');

done_testing;
