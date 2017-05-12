#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

{
    package Currency;
    use Moose;
    use MooseX::Types::Locale::Currency qw( CurrencyCode );

    has code  => (
        is => 'ro',
        isa => CurrencyCode,
    );

    __PACKAGE__->meta->make_immutable;
}

my $c = Currency->new({ code => 'USD' });

is( $c->code, 'USD', 'check currency code returns' );

done_testing;
