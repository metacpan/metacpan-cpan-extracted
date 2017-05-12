#!/usr/bin/perl
# $Id$
use strict;
use warnings;
our $VERSION = sprintf '0.%d.%d', '\$Revision: 1.1 $' =~ /(\d+)\.(\d+)/xm;
use English qw(-no_match_vars);

#use Test::More qw(no_plan);
use Test::More tests => 11;

my $class;

BEGIN {
    $class = 'Rsync::Config::Blank';
    use_ok($class) or BAIL_OUT('RIP.');
}

for my $method (qw[name value]) {
    eval { $class->$method };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
    eval {
        no strict 'refs';    ## no critic
        &{"${class}::${method}"}( bless {}, 'Foobar' );
    };
    like( $EVAL_ERROR->error, qr/object/i, 'method abuse' );
}

my $blank = eval { $class->new };
isa_ok( $blank, $class )
    or BAIL_OUT("Cannot create $class object: $EVAL_ERROR");

isa_ok( $blank, 'Rsync::Config::Renderer' );
can_ok( $blank, qw(name value to_string) );
is( $blank->name,  undef,  'no name' );
is( $blank->value, undef,  'no value' );
is( $blank,        qq{\n}, 'stringification' );
