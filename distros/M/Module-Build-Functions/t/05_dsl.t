#!/usr/bin/perl

# Tests for Module::Build::Functions::DSL

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 5;

# Load the DSL module
require_ok( 'inc::Module::Build::Functions::DSL' );

# Generate code from a simple dsl block
my $code = Module::Build::Functions::DSL::dsl2code(<<'END_DSL');
all_from lib/My/Module.pm
requires perl 5.008
requires Carp 0
requires Win32 if win32
dist_author         'Curtis  Jewell <csjewell@cpan.org>'
dist_author         "Curtis Jewell   <perl@csjewell.fastmail.us>"
test_requires Test::More 1.2
install_share
END_DSL

is( $code, <<'END_PERL', 'dsl2code generates the expected code' );
all_from 'lib/My/Module.pm';
requires 'perl', '5.008';
requires 'Carp', '0';
requires 'Win32' if win32;
dist_author 'Curtis Jewell <csjewell@cpan.org>';
dist_author "Curtis Jewell <perl@csjewell.fastmail.us>";
test_requires 'Test::More', '1.2';
install_share;
END_PERL

#================================================================================================================================================================================================================================================
$code = Module::Build::Functions::DSL::dsl2code(<<'END_DSL');
test_requires 'Test::More'
END_DSL

is( $code, <<'END_PERL', 'dsl2code generates the expected code' );
test_requires 'Test::More';
END_PERL



#================================================================================================================================================================================================================================================
$code = Module::Build::Functions::DSL::dsl2code(<<'END_DSL');
test_requires 'Test::More'
END_DSL

is( $code, <<'END_PERL', 'dsl2code generates the expected code' );
test_requires 'Test::More';
END_PERL



#================================================================================================================================================================================================================================================
$code = Module::Build::Functions::DSL::dsl2code(<<'END_DSL');
test_requires 'Test::More' "1.2"
END_DSL

is( $code, <<'END_PERL', 'dsl2code generates the expected code' );
test_requires 'Test::More', "1.2";
END_PERL


