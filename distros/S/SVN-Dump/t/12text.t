use strict;
use warnings;
use Test::More;
use t::Utils;

use SVN::Dump::Text;

plan tests => 5;

# create a text block
my $t = SVN::Dump::Text->new( 'clash sock swish bam' );

isa_ok( $t, 'SVN::Dump::Text' );
is( $t->get(), 'clash sock swish bam', 'Got the text' );
is( $t->set( 'urkkk whamm' ), 'urkkk whamm', 'Changed the text');
is( $t->get(), 'urkkk whamm', 'Changed the text');
is( $t->as_string(), $t->get(), 'as_string()' );

