#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;

use PPI;
use File::Temp qw(tempdir);

my $tempdir = tempdir( CLEANUP => 1 );

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

plan tests => 17;

use PPIx::EditorTools::RenameVariable;

my $code = read_file('t/rename_variable/1.in');
my $shiny_replacement =  read_file('t/rename_variable/1.out');

eq_or_diff(
	eval {
		PPIx::EditorTools::RenameVariable->new->rename(
			code        => $code,
			line        => 8,
			column      => 12,
			replacement => 'shiny',
		)->code;
	}
		|| "",
	$shiny_replacement,
	'replace scalar'
);

test_cli($code, "--RenameVariable --line 8 --column 12 --replacement shiny", $shiny_replacement, 'replace scalar on command line');



eq_or_diff(
	PPIx::EditorTools::RenameVariable->new->rename(
		code        => $code,
		line        => 11,
		column      => 9,
		replacement => 'shiny',
		)->code,
	$shiny_replacement,
	'replace scalar'
);

test_cli($code, "--RenameVariable --line 11 --column 9 --replacement shiny", $shiny_replacement, 'replace scalar on command line');

my $stuff_replacement = <<'STUFF_REPLACEMENT';
use MooseX::Declare;

class Test {
    has a_var => ( is => 'rw', isa => 'Str' );
    has b_var => ( is => 'rw', isa => 'Str' );

    method some_method {
        my $x_var = 1;

        print "Do stuff with ${x_var}\n";
        $x_var += 1;

        my %stuff;
        for my $i (1..5) {
            $stuff{$i} = $x_var;
        }
    }
}
STUFF_REPLACEMENT

eq_or_diff(
	PPIx::EditorTools::RenameVariable->new->rename(
		code        => $code,
		line        => 15,
		column      => 13,
		replacement => 'stuff',
		)->code,
	$stuff_replacement,
	'replace hash'
);
test_cli($code, "--RenameVariable --line 15 --column 13 --replacement stuff", $stuff_replacement, 'replace hash on command line');

my $munged = PPIx::EditorTools::RenameVariable->new->rename(
	code        => $code,
	line        => 15,
	column      => 13,
	replacement => 'stuff',
);

isa_ok( $munged,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $munged->element, 'PPI::Token::Symbol' );


# tests for camel casing
$code = <<'END_CODE';
sub foo {
    my $x_var = 1;

    print "Do stuff with ${x_var}\n";
    $x_var += 1;

    my $_someVariable = 2;
    $_someVariable++;
}
END_CODE

my $xvar_replacement = $code;
$xvar_replacement =~ s/x_var/xVar/g; # yes, this is simple

eq_or_diff(
	PPIx::EditorTools::RenameVariable->new->rename(
		code          => $code,
		line          => 2,
		column        => 8,
		to_camel_case => 1,
		)->code,
	$xvar_replacement,
	'camelCase xVar'
);
test_cli($code, "--RenameVariable --line 2 --column 8 --to-camel-case 1", $xvar_replacement, 'camelCase xVar on command line');

$xvar_replacement =~ s/x_?var/XVar/gi; # yes, this is simple

eq_or_diff(
	PPIx::EditorTools::RenameVariable->new->rename(
		code          => $code,
		line          => 2,
		column        => 8,
		to_camel_case => 1,
		'ucfirst'     => 1,
		)->code,
	$xvar_replacement,
	'camelCase xVar (ucfirst)'
);


my $yvar_replacement = $code;
$yvar_replacement =~ s/_someVariable/_some_variable/g;

eq_or_diff(
	PPIx::EditorTools::RenameVariable->new->rename(
		code            => $code,
		line            => 7,
		column          => 8,
		from_camel_case => 1,
		)->code,
	$yvar_replacement,
	'from camelCase _some_variable'
);

$yvar_replacement =~ s/_some_variable/_Some_Variable/g;

eq_or_diff(
	PPIx::EditorTools::RenameVariable->new->rename(
		code            => $code,
		line            => 7,
		column          => 8,
		from_camel_case => 1,
		'ucfirst'       => 1
		)->code,
	$yvar_replacement,
	'from camelCase _some_variable (ucfirst)'
);

# exerimental test code for experimental command line tool
sub test_cli {
	my ($original, $params, $expected, $title) = @_;

	my $file = "$tempdir/source.pl";

	open my $out, '>', $file or die;
	print $out $original;
	close $out;

	my $cmd = "$^X -Ilib script/ppix_editortools --inplace $params $file";
	#diag $cmd;
	is system($cmd), 0, 'system';

	open my $in, '<', $file or die;
	my $result = do {local $/ = undef; <$in>; };
	close $in;

	eq_or_diff($result, $expected, $title);
}


sub read_file {
	my $file = shift;
	open my $fh, '<', $file or die;
	local $/ = undef;
	my $code = scalar <$fh>;
	$code =~ s/\xD//g;  # remove carrige return
	return $code;
}
