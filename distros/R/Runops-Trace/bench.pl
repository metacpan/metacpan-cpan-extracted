#!/usr/bin/perl

use strict;
use warnings;

use Benchmark qw(cmpthese countit timestr :hireswallclock);
use Runops::Trace;

our $obj = bless {};

sub method { shift() . " ftw!!1one" }

sub foo {
	return [ @_[2,4] ];
}

sub waste_time {
	our $j;
	$j++;
	foo(1 .. 5) for ( 1 .. 10 );
	my $obj = bless({}, "main");
	$obj->method(\"arg") for ( 1 .. 100 );
};

my %setup = (
	normal => sub {
		warn "not reg runloop, skipping" if $INC{"Runops/Trace.pm"};
        return;
	},
	disabled => sub {
		Runops::Trace::disable_tracing();
        return 1;
	},
	null_c_cb => sub {
		Runops::Trace::clear_tracer();
		Runops::Trace::enable_tracing();
        return 1;
	},
	mask_null_c_cb => sub {
		Runops::Trace::mask_all();
		Runops::Trace::unmask_op(qw(entersub method_named));
		Runops::Trace::clear_tracer();
		Runops::Trace::enable_tracing();
        return 1;
	},
	mask => sub {
		Runops::Trace::set_trace_threshold(0);
		Runops::Trace::mask_all();
		Runops::Trace::unmask_op(qw(entersub method_named));
		Runops::Trace::set_tracer(sub { our $j++ });
		Runops::Trace::enable_tracing();
        return 1;
	},
	threshold => sub {
		Runops::Trace::clear_mask();
		Runops::Trace::set_trace_threshold(5);
		Runops::Trace::mask_op(qw(enteriter enterloop));
		Runops::Trace::set_tracer(sub { our $j++ });
		Runops::Trace::enable_tracing();
        return 1;
	},
	mask_and_threshold => sub {
		Runops::Trace::set_trace_threshold(5);
		Runops::Trace::mask_all();
		Runops::Trace::unmask_op(qw(entersub refgen method_named));
		Runops::Trace::set_tracer(sub {our $j++ });
		Runops::Trace::enable_tracing();
        return 1;
	},
	perl_hook => sub {
		Runops::Trace::clear_mask();
		Runops::Trace::mask_op(qw(enteriter enterloop));
		Runops::Trace::set_trace_threshold(0);
		Runops::Trace::set_tracer(sub { our $j++ });
		Runops::Trace::enable_tracing();
        return 1;
	},
);

my %res;

waste_time();

foreach my $test qw(normal disabled null_c_cb mask_null_c_cb mask threshold mask_and_threshold perl_hook) {
    $setup{$test}->() || next;
    our $j = undef;

    eval {
        my $res = countit(2, \&waste_time);
        $res{$test} = $res;
        print "$test: " . timestr($res), "\n";
    };

    warn "test $test failed: $@" if $@;

    $setup{disabled}->();
}

cmpthese(\%res);

