#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

#use Test::More qw(no_plan);
use Test::More tests => 18;

my $class;

BEGIN {
    $class = 'Rsync::Config::Atom';
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
like( $EVAL_ERROR->error, qr/Invalid name/, 'proper exception' );

eval { $class->new( value => q{100} ) };
like( $EVAL_ERROR->error, qr/Invalid name/, 'proper exception' );

eval { $class->new( name => q{foo} ) };
like( $EVAL_ERROR->error, qr/Invalid value/, 'proper exception' );

my $atom = $class->new( name => 'uid', value => '100' );
isa_ok( $atom, $class );
isa_ok( $atom, 'Rsync::Config::Blank' );
isa_ok( $atom, 'Rsync::Config::Renderer' );

is( $atom->name,         'uid',           'name: accessor' );
is( $atom->name('gid'),  'gid',           'name: mutator' );
is( $atom->value,        '100',           'value: accessor' );
is( $atom->value('200'), '200',           'value: mutator' );
is( $atom,               qq{gid = 200\n}, 'stringification' );

eval { $atom->value(q{}) };
like( $EVAL_ERROR->error, qr/Invalid value/, 'proper exception' );
is( $atom->value, q{200}, 'value still ok' );

eval { $atom->name(q{}) };
like( $EVAL_ERROR->error, qr/Invalid name/, 'proper exception' );
is( $atom->name, q{gid}, 'name still ok' );
