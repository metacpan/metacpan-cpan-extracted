#!perl -T
use 5.006;
use strict;
use utf8;
use warnings FATAL => 'all';
use Test::More;

plan tests => 7;

use_ok('Search::MultiMatch') || print "Bail out!\n";

my $smm = Search::MultiMatch->new();

sub make_key {
    [[split(' ', lc($_[0]))]];
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
    my @matches = search('some values here');
    my @expect  = ({match => 'some values here', score => 1});
    is_deeply(\@matches, \@expect);
}

#
## Best matching
#
{
    my @matches = search('my first', keep => 'best');
    my @expect  = ({match => 'My First Lover', score => 1});
    is_deeply(\@matches, \@expect);
}

#
## Best matching
#
{
    my @matches = search('The', keep => 'best');
    my @expect  = ({match => 'The Lookout (2007)', score => 1}, {match => 'The Mothman Prophecies', score => 1},);
    is_deeply(\@matches, \@expect);
}

#
## Any matching
#
{
    my @matches = search('The', keep => 'any');
    my @expect  = ({match => 'The Lookout (2007)', score => 1}, {match => 'The Mothman Prophecies', score => 1},);
    is_deeply(\@matches, \@expect);
}

#
## Any matching
#
{
    my @matches = search('love berlin', keep => 'any');
    my @expect  = ();
    is_deeply(\@matches, \@expect);
}

#
## Default matching
#
{
    my @matches = search('love berlin');
    is($#matches, -1);
}
