#!perl

use strict;
use warnings;

use Test::More tests => 8;

use PerlIO::code;


open my $fh, '<', sub{
	my($arg) = @_;

	is scalar(@_), 1, 'narg == 1';
	is $arg, 42, 'an argument supplied';

	return "foo\n";
}, 42 or die $!;

is scalar(<$fh>), "foo\n", 'read with an argument';

ok close($fh), 'close';

open $fh, '>', sub{
	my($arg, $buf) = @_;

	is scalar(@_), 2, 'narg == 2';
	is $arg, 42, 'an argument supplied';

	is $buf, "bar\n", 'write with an argument';
}, 42;

print $fh "bar\n";

ok close($fh), 'close';
