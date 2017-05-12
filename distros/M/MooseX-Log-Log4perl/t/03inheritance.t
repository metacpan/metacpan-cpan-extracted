use strict;
use warnings;

use IO::Scalar;
use Log::Log4perl;

use Test::More tests => 3;

BEGIN {
	my $cfg = <<__ENDCFG__;
log4perl.rootLogger = TRACE, Console

log4perl.appender.Console        = Log::Log4perl::Appender::Screen
log4perl.appender.Console.stderr = 1
log4perl.appender.Console.layout = Log::Log4perl::Layout::PatternLayout
log4perl.appender.Console.layout.ConversionPattern = %p [%c] [%M] %m%n
__ENDCFG__
	Log::Log4perl->init(\$cfg);
}

{
	package Parent;

	use Moo;
	with 'MooseX::Log::Log4perl';

	sub overridden { shift->log->warn('Parent overridden');	}
	sub parentonly { shift->log->warn('Parent parentonly'); }
}

{
	package Child;

	use Moo;
	extends 'Parent';
	with 'MooseX::Log::Log4perl';

	sub overridden { shift->log->warn('Child overridden');	}
}

{
	my $p = Parent->new();
	isa_ok( $p, 'Parent' );
	my $c = Child->new();
	isa_ok( $c, 'Child' );

	tie *STDERR, 'IO::Scalar', \my $err;
	local $SIG{__DIE__} = sub { untie *STDERR; die @_ };

	$p->overridden;
	$c->overridden;
	$p->parentonly;
	$c->parentonly;

	untie *STDERR;

	# Cleanup log output line-endings
	$err =~ s/\r\n/\n/gm;

	my $expect = <<__ENDLOG__;
WARN [Parent] [Parent::overridden] Parent overridden
WARN [Child] [Child::overridden] Child overridden
WARN [Parent] [Parent::parentonly] Parent parentonly
WARN [Child] [Parent::parentonly] Parent parentonly
__ENDLOG__

	is( $err, $expect, "Log messages for overridden and non-overridden methods are correct" );
}
