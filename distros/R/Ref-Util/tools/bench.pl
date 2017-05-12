use strict;
use warnings;
use constant { 'AMOUNT' => 1e8 };

use Ref::Util qw<is_arrayref is_plain_arrayref is_plain_hashref>;
use Scalar::Util ();
use Data::Util ':check';
use Dumbbench;
use Dumbbench::Instance::PerlSub;

my $bench = Dumbbench->new(
    'target_rel_precision' => 0.005, # seek ~0.5%
    'initial_runs'         => 20,    # the higher the more reliable
);

my $amount = AMOUNT();
my $ref    = [];

no warnings;
$bench->add_instances(
    Dumbbench::Instance::PerlSub->new(
        'name' => 'Ref::Util::is_plain_arrayref (CustomOP)',
        'code' => sub { Ref::Util::is_plain_arrayref($ref) for ( 1 .. $amount ) },
    ),

    Dumbbench::Instance::PerlSub->new(
        'name' => 'ref(), reftype(), !blessed()',
        'code' => sub {
            ref $ref
                && Scalar::Util::reftype($ref) eq 'ARRAY'
                && !Scalar::Util::blessed($ref)
                for ( 1 .. $amount );
        },
    ),

    Dumbbench::Instance::PerlSub->new(
        'name' => 'ref()',
        'code' => sub { ref($ref) eq 'ARRAY' for ( 1 .. $amount ) },
    ),

    Dumbbench::Instance::PerlSub->new(
        'name' => 'Data::Util::is_array_ref',
        'code' => sub { is_array_ref($ref) for ( 1 .. $amount ) },
    ),

);

$bench->run;
$bench->report;
