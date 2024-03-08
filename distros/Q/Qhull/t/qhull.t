#! perl

use v5.10;

use Test2::V0;

use Qhull 'qhull';
use Test::TempDir::Tiny;
use Path::Tiny;

my $datadir = path( 't', 'data', 'qhull' );

my $input    = $datadir->child( 'qhull.in' )->absolute;
my $expected = $datadir->child( 'qhull.out' )->absolute;

subtest 'input:file, output:file' => sub {

    my $dir    = tempdir( 'files' );
    my $output = path( $dir, 'qhull.out' );

    my ( $index ) = qhull( { qh_opts => [ TI => $input, TO => $output, 'Fx' ] } );

    my @expected = $expected->lines( { chomp => 1 } );
    my @got      = $output->lines( { chomp => 1 } );

    is( \@expected, \@got, 'output files match' );

    # first line is # of nodes
    shift @expected;
    is( $index, \@expected, 'returned values match' );
};

subtest 'input:fh output:file' => sub {

    my $dir    = tempdir( 'files' );
    my $output = path( $dir, 'qhull.out' );

    my ( @x, @y );
    for my $line ( $input->lines( { chomp => 1 } ) ) {
        my ( $x, $y ) = split( /\h+/, $line );
        push @x, $x;
        push @y, $y;
    }
    splice( @x, 0, 2 );
    splice( @y, 0, 2 );

    my ( $index ) = qhull( \@x, \@y, { qh_opts => [ TO => $output, 'Fx' ] } );

    my @expected = $expected->lines( { chomp => 1 } );
    my @got      = $output->lines( { chomp => 1 } );

    is( \@expected, \@got, 'output files match' );

    # first line is # of nodes
    shift @expected;
    is( $index, \@expected, 'returned values match' );
};

subtest 'input:fh output:fh' => sub {

    my $dir = tempdir( 'files' );

    my ( @x, @y );
    for my $line ( $input->lines( { chomp => 1 } ) ) {
        my ( $x, $y ) = split( /\h+/, $line );
        push @x, $x;
        push @y, $y;
    }
    splice( @x, 0, 2 );
    splice( @y, 0, 2 );

    my ( $index ) = qhull( \@x, \@y );

    my @expected = $expected->lines( { chomp => 1 } );
    # first line is # of nodes
    shift @expected;
    is( $index, \@expected, 'returned values match' );
};


done_testing;
