use strict;
use warnings;
use Test::More
    skip_all => 'no reason'
    # tests => 1
    ; 
use Test::Moose;
use Data::Dumper;
use Scalar::Util qw(blessed);
use MooseX::Semantic::Test::Person;
use URI;

my $p = MooseX::Semantic::Test::Person->new;
