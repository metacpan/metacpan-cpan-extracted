use strict;
use warnings;

use String::Random qw/random_string/;
use Test::Most;
use Test::Mojo;
use Mojolicious::Quick;

dies_ok { Mojolicious::Quick->new( { '/foo/bar' => sub {} } ) } 'Dies with hashref';

done_testing;
