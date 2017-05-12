#!/usr/bin/perl
use strict;
use warnings;
use TAP::Harness;
use TAP::Formatter::Event;

die "Provide a list of tests to run, e.g.\n perl examples/simple.pl examples/simpletest.t\n" unless @ARGV;

my $harness = TAP::Harness->new({
	formatter => (my $formatter = TAP::Formatter::Event->new( {
		verbosity => 1,
	})),
	merge => 1,
});
my $file; my %passed;
$formatter->add_handler_for_event(
  test_failed => sub {
    my ($self, $session, $test) = @_;
    warn "Test failed: " . $test->description . "\n";
  },
  new_session => sub {
    my ($self, $session) = @_;
    $file = $session->name;
    warn "Started session for [$file]\n";
    return $self;
  },
  test_passed => sub {
    my ($self, $session, $test) = @_;
    warn "Test passed: " . $test->description . "\n";
    ++$passed{$file};
    $self;
  },
);

$harness->runtests(@ARGV);
warn $passed{$_} . " passed in $_\n" for sort keys %passed;

