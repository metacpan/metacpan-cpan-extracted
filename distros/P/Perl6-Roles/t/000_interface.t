use strict;
use warnings;

use Test::More tests => 7;

my $CLASS = 'Perl6::Roles';
use_ok( $CLASS )
    or Test::More->builder->BAILOUT( "Cannot load $CLASS" );

# Test plan:
# 1) Verify that the API is correct. This will serve as documentation for which methods
#    should be part of which kind of API.
# 2) Verify that all methods in $CLASS have been classified appropriately

my %existing_methods = do {
    no strict 'refs';
    map {
        $_ => undef
    } grep {
        /^[a-zA-Z_]+$/
    } grep {
        exists &{${ $CLASS . '::'}{$_}}
    } keys %{ $CLASS . '::'}
};

my %methods = (
    class => [ qw(
        apply
    )],
    public => [ qw(
    )],
    private => [ qw(
        _check_isa _get_all_roles
    )],
    book_keeping => [qw(
    )],
    imported => [qw(
        blessed refaddr
        uniq
    )],
);

for my $type ( qw( class public private book_keeping imported ) ) {
    if ( @{$methods{$type}} ) {
        can_ok( $CLASS, @{ $methods{ $type } } );
        delete @existing_methods{@{$methods{ $type }}};
    }
    else {
        ok( 1, "No methods fall under the '$type' category" );
    }
}

if ( my @k = keys %existing_methods ) {
    ok( 0, "We need to account for '" . join ("','", @k) . "'" );
}
else {
    ok( 1, "We've accounted for everything." );
}
