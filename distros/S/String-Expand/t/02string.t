#!/usr/bin/perl -w

use strict;

use Test::More tests => 7;
use Test::Exception;

use String::Expand qw(
   expand_string
);

my $s;

$s = expand_string( "hello world", {} );
is( $s, "hello world", 'Plain string' );

$s = expand_string( "value of \$FOO", { FOO => 'expansion' } );
is( $s, "value of expansion", 'String with $FOO' );

$s = expand_string( "All the leaves are \${A_LONG_VAR_NAME_HERE}", { A_LONG_VAR_NAME_HERE => "brown" } );
is( $s, "All the leaves are brown", 'String with $A_LONG_VAR_NAME_HERE' );

$s = expand_string( "Some \${delimited}_text", { delimited => "delimited" } );
is( $s, "Some delimited_text", 'String with ${delimited}_text' );

dies_ok( sub { expand_string( "\${someunknownvariable}", {} ) },
         'Undefined variable raises exception' );

$s = expand_string( "Some literal text \\\$here", {} );
is( $s, "Some literal text \$here", 'Variable with literal \$dollar' );

$s = expand_string( "This has \\\\literal \\\$escapes and \$EXPANSION", { EXPANSION => "text expansion" } );
is( $s, "This has \\literal \$escapes and text expansion", 'Variable with literals and expansions' );
