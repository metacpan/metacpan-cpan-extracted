#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/01-basic.t
# -----------------------------------------------------------------------------
# Mastering programmed by YAMASHINA Hio
#
# Copyright 2006 YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id$
# -----------------------------------------------------------------------------
use strict;
use warnings FATAL => 'all';
use Test::More tests => 9;

use Sub::ScopeFinalizer qw(scope_finalizer);

&test01_basic;
&test02_raise;
&test03_wrong;

# -----------------------------------------------------------------------------
# test01_basic.
#
sub test01_basic
{
	my $invoked = 0;
	{
		is($invoked, 0, "[basic] initial state");
		
		my $o = scope_finalizer { $invoked = 1; };
		is($invoked, 0, "[basic] code has delayed");
	};
	is($invoked, 1, "[basic] code is invoked with exiting scope");
}

# -----------------------------------------------------------------------------
# test02_raise.
#
sub test02_raise
{
	my $invoked = 0;
	{
		is($invoked, 0, "[raise] initial state");
		
		my $o = scope_finalizer { $invoked += shift || 1; };
		is($invoked, 0, "[raise] code has delayed");
		
		$o->raise({ args => [2] });
		is($invoked, 2, "[raise] wake up");
	};
	is($invoked, 2, "[raise] invoked only once");
}

# -----------------------------------------------------------------------------
# test03_wrong.
#
sub test03_wrong
{
	my $invoked = 0;
	{
		is($invoked, 0, "[wrong] initial state");
		
		scope_finalizer { $invoked = 1; }; # no bind. this is wrong.
		is($invoked, 1, "[wrong] without bind, code wake up immediately");
	};
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
