#!/usr/bin/perl 

use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );

use Search::QueryParser;

my $qp = Search::QueryParser->new(
    rxAnd => qr{AND|ET|UND|E}i,
    rxOr  => qr{OR|OU|ODER|O}i,
    rxNot => qr{NOT|PAS|NICHT|NON}i,

);

for my $query (@ARGV) {
    carp "query: $query";
    my $p = $qp->parse( $query, 1 );
    carp dump($p);
    carp "unparsed: " . $qp->unparse($p);
}
