#!/usr/bin/perl

use strict;
use warnings;
use PerlIO::code;

use Benchmark qw(timethese cmpthese);

{
	package T;
	sub TIEHANDLE{
		bless {};
	}
	sub PRINT{
		my($buf) = @_;
	}
	sub READLINE{
		"foo\n";
	}
}


tie *TH, 'T' or die $!;
open OC, ">", \&T::PRINT or die $!;
open IC, "<", \&T::READLINE  or die $!;

cmpthese timethese -1, {
	WriteTie => sub{
		print TH "foo";
	},
	WriteLayer => sub{
		print OC "foo";
	},
};

cmpthese timethese -1, {
	ReadTie => sub{
		my $foo = <TH>;
	},
	ReadLayer => sub{
		my $foo = <IC>;
	},
};
