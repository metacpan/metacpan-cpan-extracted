#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

#use Test::More qw(no_plan);
use Test::More tests => 14;

my $class;

BEGIN {
    $class = 'Rsync::Config::Comment';
    use_ok($class) or BAIL_OUT('RIP.');
}

for my $method (qw[to_string]) {
    eval { $class->$method };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
    eval {
        no strict 'refs';    ## no critic
        &{"${class}::${method}"}( bless {}, 'Foobar' );
    };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
}

eval { $class->new };
like( $EVAL_ERROR->error, qr/Invalid value/, 'proper exception' );

my $comment = eval { $class->new( value => q{foo} ) };
isa_ok( $comment, $class )
    or BAIL_OUT("Cannot create $class object: $EVAL_ERROR");

isa_ok( $comment, 'Rsync::Config::Renderer' );

is( $comment->name,          undef,       'no name' );
is( $comment->value,         q{foo},      'value: accessor' );
is( $comment->value(q{bar}), q{bar},      'value: mutator' );
is( $comment,                qq{# bar\n}, 'stringification' );

eval { $comment->value(q{}) };
like( $EVAL_ERROR->error, qr/Invalid value/, 'proper exception' );
is( $comment->value, q{bar}, 'value still ok' );

my $c2 = $class->new( value => q{# foo} );
is( $c2, qq{# foo\n}, 'already has dash' );

my $c3 = $class->new( value => q{  # foo} );
is( $c3, qq{  # foo\n}, 'keep leading blanks when dash is present' );
