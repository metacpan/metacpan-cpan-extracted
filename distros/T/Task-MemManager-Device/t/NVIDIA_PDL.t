use strict;
use warnings;
use Test::More;
use Config;
use boolean;
use feature 'say';

# This is supposed to run ONLY if the PDL View is installed
BEGIN {
    eval { require PDL::NiceSlice; };
    if ($@) {
        plan skip_all => "PDL::NiceSlice is not installed";
    }

    eval { require Task::MemManager::View::PDL; };
    if ($@) {
        plan skip_all => "Task::MemManager::View::PDL is not installed";
    }
    else {
        plan tests => 2;
    }

    use Task::MemManager
      Allocator => 'CMalloc',
      View      => 'PDL',
      Device    => 'NVIDIA_GPU';
}

use Inline (
    C => Config => ccflags => "-fno-stack-protector -fcf-protection=none "
      . " -fopenmp  -Iinclude -std=c11 -fPIC "
      . " -Wall -Wextra -Wno-unused-function -Wno-unused-variable"
      . " -Wno-unused-but-set-variable ",
    lddlflags => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
    ccflagsex => " -fopenmp ",
    libs      => q{ -lm -foffload=-lm },
    optimize  => "-O3 -march=native",
);

use Inline ( C => 'DATA' );

subtest 'Memory Broadcasting to PDL ndarray' => sub {
    my $buffer_length = 50;
    my $size_in_bytes = $buffer_length * 4;   # 4 bytes per float
                                              # Create a Task::MemManager buffer
    my $buffer =
      Task::MemManager->new( $buffer_length, 4, { allocator => 'CMalloc' } );
    my $pdl_view = $buffer->create_view( 'PDL',
        { view_name => 'my_pdl_view', pdl_type => 'float' } );

    $buffer->device_movement( action => 'enter', direction => "to" );
    assign_as_float( $buffer->get_buffer, $buffer->get_buffer_size );
    $buffer->device_movement( action => 'update', direction => "from" );
    my @values     = list $pdl_view;
    my $test_based = true;
    while ( my ( $i, $val ) = each @values ) {
        if ( $val != ( $i * 2.0 ) ) {
            $test_based = false;
            last;
        }
    }
    is( $test_based, true, 'Float values are as expected after assignment' );

    # Create a double PDL view
    my $pdl_view_double = $buffer->create_view( 'PDL',
        { view_name => 'my_pdl_view_double', pdl_type => 'double' } );
    assign_as_double( $buffer->get_buffer, $buffer->get_buffer_size );
    $buffer->device_movement( action => 'exit', direction => "from" );
    my @double_values     = list $pdl_view_double;
    my $test_based_double = true;
    while ( my ( $i, $val ) = each @double_values ) {
        if ( $val != ( $i * 4.0 ) ) {
            $test_based_double = false;
            last;
        }
    }
    is( $test_based, true, 'Double values are as expected after assignment' );
};

subtest 'Distribute Calculations between PDL and the GPU' => sub {
    my $buffer_length = 10;
    my $size_in_bytes = $buffer_length * 4;   # 4 bytes per float
                                              # Create a Task::MemManager buffer
    my $buffer =
      Task::MemManager->new( $buffer_length, 4, { allocator => 'CMalloc' } );

    # Create a  PDL view and fill it (and thus the buffer) with random values
    my $pdl_view = $buffer->create_view( 'PDL',
        { view_name => 'my_pdl_view', pdl_type => 'float' } );
    $pdl_view->inplace->random;
    my $cloned_view = $buffer->clone_view('my_pdl_view');    # bona fide copy

    # Test PDL and buffer contents are identical before GPU movement
    my @values =
      unpack( "f*", $buffer->extract_buffer_region( 0, $size_in_bytes - 1 ) );
    my @pdl_values       = list $pdl_view;
    my $equal_pdl_buffer = true;
    while ( my ( $i, $val ) = each @values ) {
        if ( $val != $pdl_values[$i] ) {
            $equal_pdl_buffer = false;
            last;
        }
    }
    is( $equal_pdl_buffer, true,
        'PDL view and buffer contents are identical before GPU movement' );

    #Move and modify on GPU
    $buffer->device_movement( action => 'enter', direction => "to" );
    mod_as_float( $buffer->get_buffer, $buffer->get_buffer_size );
    $buffer->device_movement( action => 'exit', direction => "from" );

    # Check PDL and buffer contents are identical after GPU movement
     @values =
      unpack( "f*", $buffer->extract_buffer_region( 0, $size_in_bytes - 1 ) );
    @pdl_values = list $pdl_view;
    my $equal_pdl_buffer_after = true;
    while ( my ( $i, $val ) = each @values ) {
        if ( $val != $pdl_values[$i] ) {
            $equal_pdl_buffer_after = false;
            last;
        }
    }
    is( $equal_pdl_buffer_after, true,
        'PDL view and buffer contents are identical after GPU movement' );

    # Final test - are values as expected?
    my $test_based = true;
    while ( my ( $i, $val ) = each @values ) {
        if ( $val != $cloned_view->at($i) * 2.0 ) {
            $test_based = false;
            last;
        }
    }

    is( $test_based, true, 'Modification of the buffer contents is as expected' );



};

done_testing();

__DATA__

__C__
/* Basic tests */
#include "omp.h"
#include "math.h"

void assign_as_float(unsigned long arr, size_t n) {
    float *array_addr = (float *)arr;
    size_t len = n / sizeof(float);
    #pragma omp target
    for (int i = 0; i < len; i++) {
        array_addr[i]  = (float)i * 2.0f;
    }
}


void assign_as_double(unsigned long arr, size_t n) {
    double *array_addr = (double *)arr;
    size_t len = n / sizeof(double);
    #pragma omp target
    for (int i = 0; i < len; i++) {
        array_addr[i] = (double)i * 4.0;
    }
}

void mod_as_float(unsigned long arr, size_t n) {
    float *array_addr = (float *)arr;
    size_t len = n / sizeof(float);
    #pragma omp target
    for (int i = 0; i < len; i++) {
        array_addr[i]  *= 2.0f;
    }
}
