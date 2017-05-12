#! /usr/bin/perl -w
## ----------------------------------------------------------------------------
#  t/03-disable.t
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

&test01_default;
&test02_disable;
&test03_disable_enable;
#&test04_disable_enable_disable;

# -----------------------------------------------------------------------------
# test01_default.
#
sub test01_default
{
	my $invoked;
	{
		is($invoked, undef, "[default] initial state");
		
		my $o = scope_finalizer { $invoked = 1; };
		is($invoked, undef, "[default] code has delayed");
	};
	is($invoked, 1, "[default] finalizer was invoked");
}

# -----------------------------------------------------------------------------
# test02_disable.
#
sub test02_disable
{
	my $invoked;
	{
		is($invoked, undef, "[disable] initial state");
		
		my $o = scope_finalizer { $invoked = 1; };
		$o->disable();
		is($invoked, undef, "[disable] code has delayed");
	};
	is($invoked, undef, "[disable] finalizer was disabled");
}

# -----------------------------------------------------------------------------
# test03_disable_enable.
#
sub test03_disable_enable
{
	my $invoked;
	{
		is($invoked, undef, "[disable-enable] initial state");
		
		my $o = scope_finalizer { $invoked = 1; };
		$o->disable(1);
		$o->disable(0);
		is($invoked, undef, "[disable-enable] code has delayed");
	};
	is($invoked, 1, "[disable-enable] finalizer was invoked");
}

# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
