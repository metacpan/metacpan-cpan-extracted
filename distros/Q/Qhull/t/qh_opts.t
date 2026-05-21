#! perl

use v5.10;

use Test2::V0;
use Test::TempDir::Tiny;
use Path::Tiny;

use Qhull 'qhull';
use Qhull::Options;

my $datadir = path( 't', 'data', 'qhull' );

my $input  = $datadir->child( 'qhull.in' )->absolute;
my $dir    = tempdir( 'files' );
my $output = path( $dir, 'qhull.out' );

subtest 'accepts options object' => sub {

    my @qh_opts = ( TI => $input, TO => $output, 'Fx' );
    my $qh_opts = Qhull::Options->new_from_options( \@qh_opts );

    my ( $raw_index ) = qhull( { qh_opts => \@qh_opts } );
    my ( $obj_index ) = qhull( { qh_opts => $qh_opts } );

    is( $raw_index, $obj_index );
};

subtest 'filters stripped options from arrayref and object' => sub {

    my @qh_opts = ( TI => $input, 'G' );
    my $qh_opts = Qhull::Options->new_from_options( \@qh_opts );

    my ( $array_index ) = qhull( { qh_opts => \@qh_opts } );
    my ( $obj_index )   = qhull( { qh_opts => $qh_opts } );

    is( $obj_index, $array_index, 'object options are filtered like arrayref options' );

    my $array_raw = qhull( { raw => 1, qh_opts => \@qh_opts } );
    my $obj_raw   = qhull( { raw => 1, qh_opts => $qh_opts } );

    is( $obj_raw, $array_raw, 'raw output uses the same filtered options' );
};

done_testing;
