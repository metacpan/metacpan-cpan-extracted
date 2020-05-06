#!/usr/bin/perl

use strict;
use warnings;
use OPTIMADE::Filter::Property;
use Test::More tests => 4;

my $property = OPTIMADE::Filter::Property->new( "Some", "Property" );
is( $property->to_filter, 'some.property' );
is( $property->to_SQL, "'Some'.'Property'" );
is( $property, $property );

my $error = '';
eval {
    push @$property, 'HAS SPACES';
    my $filter = $property->to_filter;
    print STDERR $filter;
};
$error = $@ if $@;
ok( $error =~ /^name 'has spaces' does not match/ );
