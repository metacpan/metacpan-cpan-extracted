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

plan tests => 4;

use PPIx::EditorTools::RenamePackageFromPath;

my $code = "package TestPackage;\nuse strict;\nBEGIN {
	$^W = 1;
}\n1;\n";

sub new_code {
	return sprintf "package %s;\nuse strict;\nBEGIN {
	$^W = 1;
}\n1;\n", shift;
}

my $munged = PPIx::EditorTools::RenamePackageFromPath->new->rename(
	code     => $code,
	filename => './lib/Test/Code/Path.pm',
);

eq_or_diff( $munged->code, new_code("Test::Code::Path"), 'simple package' );

eq_or_diff(
	PPIx::EditorTools::RenamePackageFromPath->new->rename(
		code     => $code,
		filename => './Test/Code/Path.pm',
		)->code,
	new_code("Test::Code::Path"),
	'no lib package'
);

eq_or_diff(
	PPIx::EditorTools::RenamePackageFromPath->new->rename(
		code     => $code,
		filename => 'lib/Test/./Code/Path.pm',
		)->code,
	new_code("Test::Code::Path"),
	'with /./ part'
);

TODO: {
	local $TODO = 'Does not support /../ path constructs yet';

	eq_or_diff(
		PPIx::EditorTools::RenamePackageFromPath->new->rename(
			code     => $code,
			filename => 'lib/Test/Ignore/../Code/Path.pm',
			)->code,
		new_code("Test::Code::Path"),
		'strip .. from package'
	);
}

__END__


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
    PPIx::EditorTools::RenameVariable->new( code => $code )
      ->replace_var( line => 15, column => 13, replacement => 'stuff', ),
    $stuff_replacement,
    'replace hash'
);

my $replacer = PPIx::EditorTools::RenameVariable->new( code => $code );
my $doc = $replacer->replace_var( line => 15, column => 13, replacement => 'stuff', );
my $token = $replacer->token;

isa_ok( $token, 'PPI::Token::Symbol' );
