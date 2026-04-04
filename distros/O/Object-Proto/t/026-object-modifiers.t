#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Object::Proto;

# Test Method Modifiers (zero overhead)

our @log;

# Define a class with a method
package Counter;

sub increment {
    my ($self) = @_;
    $self->count($self->count + 1);
    push @main::log, "increment called";
    return $self->count;
}

package main;

Object::Proto::define('Counter', 'count:Int:default(0)');

# Test 1: Method works without modifiers
my $c = Counter->new();
@log = ();
is($c->increment, 1, 'Method works normally');
is_deeply(\@log, ['increment called'], 'Original method ran');

# Test 2: Add a before modifier
Object::Proto::before('Counter::increment', sub {
    push @main::log, "before increment";
});

$c = Counter->new();
@log = ();
is($c->increment, 1, 'Method still returns correctly after before');
is_deeply(\@log, ['before increment', 'increment called'], 'Before runs first');

# Test 3: Add an after modifier
Object::Proto::after('Counter::increment', sub {
    push @main::log, "after increment";
});

$c = Counter->new();
@log = ();
is($c->increment, 1, 'Method returns correctly with before+after');
is_deeply(\@log, ['before increment', 'increment called', 'after increment'], 
          'Before -> Original -> After order');

# Test 4: around modifier
package Calculator;

sub double {
    my ($self, $n) = @_;
    return $n * 2;
}

package main;

Object::Proto::define('Calculator', 'name:Str');

Object::Proto::around('Calculator::double', sub {
    my ($orig, $self, @args) = @_;
    push @main::log, "around: before";
    my $result = $self->$orig(@args);
    push @main::log, "around: after, result=$result";
    return $result + 100;  # Modify the result
});

my $calc = Calculator->new(name => 'calc');
@log = ();
my $result = $calc->double(5);
is($result, 110, 'Around modified the result (5*2 + 100)');
is_deeply(\@log, ['around: before', 'around: after, result=10'], 'Around wrapper ran');

# Test 5: Multiple before modifiers (run in reverse order of registration)
package Logger;

sub log_msg {
    my ($self, $msg) = @_;
    push @main::log, "LOG: $msg";
    return $msg;
}

package main;

Object::Proto::define('Logger', 'prefix:Str');

before('Logger::log_msg', sub {
    push @main::log, "before 1";
});
before('Logger::log_msg', sub {
    push @main::log, "before 2";
});

my $logger = Logger->new(prefix => '>>');
@log = ();
$logger->log_msg("test");
# Before modifiers run in stack order (most recent first)
is_deeply(\@log, ['before 2', 'before 1', 'LOG: test'], 
          'Multiple befores run in reverse order');

# Test 6: Multiple after modifiers (run in order of registration)
Object::Proto::after('Logger::log_msg', sub {
    push @main::log, "after 1";
});
Object::Proto::after('Logger::log_msg', sub {
    push @main::log, "after 2";
});

@log = ();
$logger->log_msg("test2");
is_deeply(\@log, ['before 2', 'before 1', 'LOG: test2', 'after 1', 'after 2'],
          'Multiple afters run in order');

# Test 7: Class without modifiers has zero overhead
package Simple;
sub greet { return "hello" }
package main;

Object::Proto::define('Simple', 'name:Str');
my $simple = Simple->new(name => 'test');
ok(!exists $Simple::{__MODIFIERS__}, 'No modifier overhead for unmodified class');
is($simple->greet, 'hello', 'Unmodified method works');

done_testing();
