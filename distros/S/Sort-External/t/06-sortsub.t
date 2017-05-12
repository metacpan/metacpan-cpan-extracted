#!/usr/bin/perl

use Test::More tests => 2;

package Foo;

use strict;
use warnings;

use Test::More;
use Sort::External;

no warnings 'once';

my $sortex = Sort::External->new(
    cache_size => 5,
    sortsub    => sub { $Sort::External::b <=> $Sort::External::a },
);

my @correct = reverse( 1 .. 100 );

$sortex->feed($_) for 21 .. 40;
$sortex->feed($_) for 1 .. 20;
$sortex->feed($_) for 41 .. 100;

$sortex->finish;
my @out;
while ( defined( $_ = $sortex->fetch ) ) {
    push @out, $_;
}
is_deeply( \@out, \@correct );

package main;
use strict;
use warnings;

no warnings 'once';
$sortex = Sort::External->new(
    cache_size => 5,
    sortsub    => sub { $Sort::External::b <=> $Sort::External::a },
);

$sortex->feed($_) for 21 .. 40;
$sortex->feed($_) for 1 .. 20;
$sortex->feed($_) for 41 .. 100;
$sortex->finish;

@out = ();
while ( defined( $_ = $sortex->fetch ) ) {
    push @out, $_;
}
is_deeply( \@out, \@correct );
