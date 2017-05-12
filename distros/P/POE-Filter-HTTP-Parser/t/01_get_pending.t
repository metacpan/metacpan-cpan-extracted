use strict;
use warnings;
use Test::More tests => 1;
use_ok('POE::Filter::HTTP::Parser');

my $filter = POE::Filter::HTTP::Parser->new( type => 'request' );

$filter->get_pending();
