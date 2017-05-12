#!/usr/bin/env perl
use strict; use warnings;
use lib '../lib' ;
use Test::More;

use_ok ( 'Term::ReadLine::Perl5::OO' );
use_ok ( 'Term::ReadLine::Perl5' );
my $term;
eval { $term=Term::ReadLine::Perl5->new("test"); };
# See https://github.com/rocky/p5-Term-ReadLine-Perl5/issues/8
if ($term) {
    ok $term->OUT || 1;
}

done_testing;
