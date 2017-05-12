#!perl

use strict;
use warnings;

sub IO::Handle::DESTROY {}

END{
	print "done.\n";
}
BEGIN{
	if(!eval "use Devel::LeakTrace::Fast; 1"){
		exit;
	}
}

print "Memory leak test, using Devel::LeakTrace::Fast.\n";

sub foo{}

use PerlIO::code;

my $var = 'foo';
{
	open my $io, '>', \&foo, $var or die $!;

}

{
	open my $io, '>', \&foo, $var or die $!;
	print $io "foo";
}

{
	open my $io, '<', sub{  }, $var or die $!;
	my $s = <$io>;
}

{
	open my $io, '<', sub{ "foo\n" }, $var or die $!;
	my $s = <$io>;
}

