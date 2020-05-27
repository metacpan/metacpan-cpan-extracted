use strict;
use Test::More 0.98;

use String::Secret;
use Scalar::Util qw/refaddr/;
use Data::Dumper;

# set config
$Data::Dumper::Terse = 1;
$Data::Dumper::Indent = 0;
$Data::Dumper::Sortkeys = 1;

my $secret = String::Secret->new('mysecret');

my $dumped = eval { Data::Dumper::Dumper($secret) };
is $@, '', 'dump successful';
unlike $dumped, qr/mysecret/m, 'masked';
note 'dumped = ', $dumped;

subtest 'serializable' => sub {
    my $serializable_secret = $secret->to_serializable();

    my $dumped = eval { Data::Dumper::Dumper($dumped) };
    is $@, '', 'dump successful';
    unlike $dumped, qr/mysecret/m, 'masked';
    note 'dumped = ', $dumped;
};

subtest '$DISABLE_MASK = 1' => sub {
    local $String::Secret::DISABLE_MASK = 1;

    my $dumped = eval { Data::Dumper::Dumper($dumped) };
    is $@, '', 'dump successful';
    unlike $dumped, qr/mysecret/m, 'masked';
    note 'dumped = ', $dumped;
};

done_testing;

