#!/usr/bin/perl

use strict;

BEGIN {
	$^W = 1;
}

use Test::More;
use Test::Differences;
use PPI;

BEGIN {
	if ( $PPI::VERSION =~ /_/ ) {
		plan skip_all => "Need released version of PPI. You have $PPI::VERSION";
		exit 0;
	}
}

plan tests => 5;

use PPIx::EditorTools::RenamePackage;

my $munged = PPIx::EditorTools::RenamePackage->new->rename(
	code => "package TestPackage;\nuse strict;\nBEGIN {
	$^W = 1;
}\n1;\n",
	replacement => 'NewPackage'
);

isa_ok( $munged,          'PPIx::EditorTools::ReturnObject' );
isa_ok( $munged->element, 'PPI::Statement::Package' );
eq_or_diff(
	$munged->code,
	"package NewPackage;\nuse strict;\nBEGIN {
	$^W = 1;
}\n1;\n",
	'simple package'
);
eq_or_diff(
	$munged->ppi->serialize,
	"package NewPackage;\nuse strict;\nBEGIN {
	$^W = 1;
}\n1;\n",
	'simple package'
);

my $code = <<'END_CODE';
use MooseX::Declare;

class Test {
    has a_var => ( is => 'rw', isa => 'Str' );
    has b_var => ( is => 'rw', isa => 'Str' );

    method some_method {
        my $x_var = 1;

        print "Do stuff with ${x_var}\n";
        $x_var += 1;

        my %hash;
        for my $i (1..5) {
            $hash{$i} = $x_var;
        }
    }
}
END_CODE

my $shiny_replacement = <<'SHINY_REPLACEMENT';
use MooseX::Declare;

class NewPackage {
    has a_var => ( is => 'rw', isa => 'Str' );
    has b_var => ( is => 'rw', isa => 'Str' );

    method some_method {
        my $x_var = 1;

        print "Do stuff with ${x_var}\n";
        $x_var += 1;

        my %hash;
        for my $i (1..5) {
            $hash{$i} = $x_var;
        }
    }
}
SHINY_REPLACEMENT

TODO: {
	local $TODO = 'RenamePackage does not support MooseX::Declare yet';

	# The unimplemented stuff throws warnings
	local $^W = 0;

	my $result = eval {
		my $munged = PPIx::EditorTools::RenamePackage->new->rename(
			code        => $code,
			replacement => 'NewPackage',
		);
		$munged->code;
	};
	eq_or_diff( $result, $shiny_replacement, 'replace scalar' );

}

