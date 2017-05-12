#!perl

use strict;
use warnings;

use Test::More tests => 6;

use Number::AnyBase;

my @alphabet = ('a'..'z', 0..9, 'A'..'Z');
my %inverted_alphabet;
$inverted_alphabet{ $alphabet[$_] } = $_ foreach 0..$#alphabet;

{
    my $base = Number::AnyBase->new( @alphabet, qw(a a a), qw(z 9 Z) );
    
    is_deeply $base->alphabet, \@alphabet,
        'Init from list, check alphabet';
    is_deeply $base->_inverted_alphabet, \%inverted_alphabet,
        'Init from list, check inverted index'
}

{
    my $base = Number::AnyBase->new( [ @alphabet, qw(a a a), qw(z 9 Z) ] );
    
    is_deeply $base->alphabet, \@alphabet,
        'Init from list ref, check alphabet';
    is_deeply $base->_inverted_alphabet, \%inverted_alphabet,
        'Init from list ref, check inverted index'
}

{
    my $base = Number::AnyBase->new( join( '', @alphabet, qw(a a a), qw(z 9 Z) ) );
    
    is_deeply $base->alphabet, \@alphabet,
        'Init from string, check alphabet';
    is_deeply $base->_inverted_alphabet, \%inverted_alphabet,
        'Init from string, check inverted index'
}
