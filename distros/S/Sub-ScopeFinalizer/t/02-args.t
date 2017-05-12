#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/02-args.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

use Sub::ScopeFinalizer qw(scope_finalizer);

&test01_args;
&test02_raise_with_args;

# -----------------------------------------------------------------------------
# test01_args.
#
sub test01_args
{
	my $invoked = 0;
	{
		is($invoked, 0, "[args] initial state");
		
		my $o = scope_finalizer { $invoked = shift; } { args => [99] };
		is($invoked, 0, "[args] code has delayed");
	};
	is($invoked, 99, "[args] finalizer was invoked with arguments");
}

# -----------------------------------------------------------------------------
# test02_raise_with_args.
#
sub test02_raise_with_args
{
	my $recv;
	{
		is_deeply($recv, undef, "[raise_with_args] initial state");
		
		my $o = scope_finalizer { push(@$recv, @_); } { args => [1..3] };
		is_deeply($recv, undef, "[raise_with_args] code has delayed");
		
		$o->raise({ args => [qw(a b c)] });
		is_deeply($recv, [qw(a b c)], "[raise_with_args] wake up");
	};
	is_deeply($recv, [qw(a b c)], "[raise_with_args] invoked only once");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
