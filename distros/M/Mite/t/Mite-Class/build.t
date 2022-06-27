#!/usr/bin/perl

use lib 't/lib';

use Test::Mite;

tests "BUILD" => sub {
    mite_load <<'CODE';
package main;
no warnings 'once';
our @BUILD;

package PPP;
use Mite::Shim;
sub BUILD {
    my ( $self, @args ) = @_;
    push @::BUILD, [ __PACKAGE__, ref($self), @args ];
}

package CCC;
use Mite::Shim;
extends 'PPP';
sub BUILD {
    my ( $self, @args ) = @_;
    push @::BUILD, [ __PACKAGE__, ref($self), @args ];
}

1;
CODE

    no warnings 'once';

    my $o = CCC->new;
    is_deeply(
        \@::BUILD,
        [
            [ 'PPP', 'CCC', {} ],
            [ 'CCC', 'CCC', {} ],
        ],
        'expected results',
    );
};

done_testing;
