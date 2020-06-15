#!perl -T
use 5.006;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More;

plan tests => 6;

use_ok('Search::MultiMatch') || print "Bail out!\n";

my $smm = Search::MultiMatch->new();

sub make_key {
    [map { [$_] } split(' ', lc($_[0]))];
}

my @movies = (
              'some values here',
              'My First Lover',
              'A Lot Like Love',
              'Funny Games (2007)',
              'Cinderella Man (2005)',
              'Pulp Fiction (1994)',
              'Don\'t Say a Word (2001)',
              'Secret Window (2004)',
              'The Lookout (2007)',
              '88 Minutes (2007)',
              'The Mothman Prophecies',
              'Love Actually (2003)',
              'From Paris with Love (2010)',
              'P.S. I Love You (2007)',
             );

foreach my $movie (@movies) {
    $smm->add(make_key($movie), $movie);
}

sub search {
    my ($key, %opt) = @_;
    $smm->search(make_key($key), %opt);
}

#
## Default matching
#
{
    my @matches = search('i love');

    my @expect = (
                  {match => 'P.S. I Love You (2007)',      score => 2},
                  {match => 'A Lot Like Love',             score => 1},
                  {match => 'Love Actually (2003)',        score => 1},
                  {match => 'From Paris with Love (2010)', score => 1},
                 );

    is_deeply(\@matches, \@expect);
}

#
## Best matching
#
{
    my @matches = search('i love', keep => 'best');
    my @expect  = ({match => 'P.S. I Love You (2007)', score => 2});
    is_deeply(\@matches, \@expect);
}

#
## Best matching
#
{
    my @matches = search('actually love', keep => 'best');
    my @expect  = ({match => 'Love Actually (2003)', score => 2});
    is_deeply(\@matches, \@expect);
}

#
## Any matching
#
{
    my @matches = search('love berlin', keep => 'any');
    my @expect = (
                  {match => "A Lot Like Love",             score => 1},
                  {match => "Love Actually (2003)",        score => 1},
                  {match => "From Paris with Love (2010)", score => 1},
                  {match => "P.S. I Love You (2007)",      score => 1},
                 );
    is_deeply(\@matches, \@expect);
}

#
## Default matching
#
{
    my @matches = search('love berlin');
    is($#matches, -1);
}
