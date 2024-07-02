use 5.012;
use strict;
use warnings;
local $| = 1;

use Statistics::Descriptive::PDL::SampleWeighted;

use Test::More;
require_ok ('Sereal') or skip_all ('no sereal');

use Sereal::Encoder qw /encode_sereal/;
use Sereal::Decoder qw /decode_sereal/;
use Scalar::Util qw /refaddr/;
#use PDL::IO::Sereal;
use Test::PDL;


my $object = Statistics::Descriptive::PDL::SampleWeighted->new;
$object->add_data ([1..10],[reverse 1..10]);

my $sereal = encode_sereal ($object);
my $cloned = decode_sereal ($sereal);
#diag $cloned;
#use Data::Printer;
#p $cloned;
#say STDERR $cloned->{piddle};
#say STDERR $cloned->{weights_piddle};

is_pdl $cloned->{piddle}, $object->{piddle}, 'data match';
is_pdl $cloned->{weights_piddle}, $object->{weights_piddle}, 'wts match';
isnt refaddr ($cloned->{piddle}), refaddr ($object->{piddle}), 'data refs differ';
isnt refaddr ($cloned->{weights_piddle}), refaddr ($object->{weights_piddle}), 'wts refs differ';
done_testing();
