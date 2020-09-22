#!perl
use 5.006;
use strict;
use warnings;
use Test::More tests => 11;

use FindBin;
use lib "$FindBin::Bin/lib";
use File::Temp qw(tempfile);
use Mock::Plasp;

## no critic (BuiltinFunctions::ProhibitStringyEval)

my ( $script, $parsed_object, $compiled_object, $package, $subid );
my ( $fh, $filename );

# Initially setup Mock object
mock_asp( XMLSubsMatch => 'parser:[\w\-]+' );

# Test simple compilation
$script        = q|<% 'foobar' %>|;
$parsed_object = mock_asp->parse( \$script );
$package       = mock_asp->GlobalASA->package;
$subid         = mock_asp->compile( $parsed_object->{data}, "$package\::bar" );
is( $subid, "$package\::bar", 'Successfully compiled an ASP script called foo' );
is( eval "$subid", 'foobar', 'Able to run compiled ASP script and get expected return value' );
mock_asp->_undefine_sub( $subid );
is( eval "$subid", undef, 'Able to undefine compiled ASP script' );

# Test compilation of ASP script
( $fh, $filename ) = tempfile;
$fh->autoflush( 1 );
print $fh $script;
$subid = join( '', mock_asp->GlobalASA->package, '::', mock_asp->file_id( $filename ), 'xINC' );
$compiled_object = mock_asp->compile_file( $filename );
ok( $compiled_object->{is_perl}, 'Compiler detected perl code' );
is( $compiled_object->{file}, $filename, 'Compiler saved name of file' );
ok( mock_asp->_get_compiled_include( $subid ), 'Cached compiled file' );
is( mock_asp->_get_compiled_include( $subid )->{perl}, $compiled_object->{perl}, 'Cached file code is the same' );
$subid = $compiled_object->{code};
is( eval "$subid", 'foobar', 'Able to run compiled ASP file and get expected return value' );
mock_asp->_undefine_sub( $subid );
is( eval "$subid", undef, 'Able to undefine compiled ASP file' );

# Test compilation of ASP include
$compiled_object = mock_asp->compile_include( 'templates/some_template.inc' );
$subid           = $compiled_object->{code};
is( eval "$subid", "I've been included!", 'Able to run compiled ASP include and get expected return value' );
mock_asp->_undefine_sub( $subid );
is( eval "$subid", undef, 'Able to undefine compiled ASP include' );
