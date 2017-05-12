#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;

use File::Temp qw(tempdir);
use File::Spec ();

my $dir = tempdir( CLEANUP => 1 );

#diag $dir;

my $out = "$dir/out";
my $err = "$dir/err";
my $cmd = "$^X -wc " . File::Spec->catfile( 'bin', 'check_perldiag' ) . "> $out 2> $err";

#diag $cmd;
system $cmd;

ok( -e $out, 'out file exists' );
is( -s $out, 0, 'out file is empty' );
ok( -e $err, 'err file exists' );

my $err_data = slurp($err);
like( $err_data, qr{^bin[/\\]+check_perldiag syntax OK$}, 'syntax ok' );

sub slurp {
	my $file = shift;
	if ( open my $fh, '<', $file ) {
		local $/ = undef;
		return <$fh>;
	} else {
		warn $!;
		return;
	}
}

