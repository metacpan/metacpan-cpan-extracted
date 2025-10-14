use strict;
use warnings;
use Test::More;
use Config;
use Task::MemManager::Device;
use boolean;

# Test the Task::MemManager::Device module

use feature 'say';

use Inline (
    C => Config => ccflags => "-fno-stack-protector -fcf-protection=none "
      . " -fopenmp  -Iinclude -std=c11 -fPIC "
      . " -Wall -Wextra -Wno-unused-function -Wno-unused-variable"
      . " -Wno-unused-but-set-variable ",
    lddlflags => join( q{ }, $Config::Config{lddlflags}, q{-fopenmp} ),
    ccflagsex => " -fopenmp ",
    libs      => q{ },
    optimize  => "-O3 -march=native",
);

use Inline ( C => 'DATA' );

subtest 'Memory Mapping' => sub {
    my $buffer_length = 250000;
    my $size_in_bytes = $buffer_length * 4;   # 4 bytes per float
                                              # Create a Task::MemManager buffer
    my $buffer        = Task::MemManager->new( $buffer_length, 4 );

    ## Move and modify on GPU
    $buffer->device_movement( action => 'enter', direction => "to" );
    assign_as_float( $buffer->get_buffer, $buffer->get_buffer_size );
    $buffer->device_movement( action => 'update', direction => "from" );
    my @values =
      unpack( "f*", $buffer->extract_buffer_region( 0, $size_in_bytes - 1 ) );
    my $test_based = true;
    while ( my ( $i, $val ) = each @values ) {
        if ( $val != ( $i * 2.0 ) ) {
            $test_based = false;
            last;
        }
    }
    is( $test_based, true, 'Float values are as expected after assignment' );

    assign_as_double( $buffer->get_buffer, $buffer->get_buffer_size );
    $buffer->device_movement( action => 'exit', direction => "from" );
    my @double_values =
      unpack( "d*", $buffer->extract_buffer_region( 0, $size_in_bytes - 1 ) );
    my $test_based_double = true;
    while ( my ( $i, $val ) = each @double_values ) {
        if ( $val != ( $i * 4.0 ) ) {
            $test_based_double = false;
            last;
        }
    }
    is( $test_based, true, 'Double values are as expected after assignment' );
};

subtest 'Memory Allocation' => sub {
    my $buffer_length = 1000000;
    my $size_in_bytes = $buffer_length * 4;   # 4 bytes per float
                                              # Create a Task::MemManager buffer
    my $buffer        = Task::MemManager->new( $buffer_length, 4 );


    $buffer->device_movement( action => 'enter', direction => "alloc" );
    alloc_as_float( $buffer->get_buffer, $buffer->get_buffer_size );
    $buffer->device_movement( action => 'exit', direction => "from" );
    my @values =
      unpack( "f*", $buffer->extract_buffer_region( 0, $size_in_bytes - 1 ) );
    my $test_based = true;
    while ( my ( $i, $val ) = each @values ) {
        if ( $val != ( $i * 3.0 ) ) {
            $test_based = false;
            last;
        }
    }
    is( $test_based, true, 'Float values are as expected after allocation' );

};

done_testing();

__DATA__

__C__
/* Basic tests */
#include "omp.h"

void assign_as_float(unsigned long arr, size_t n) {
    float *array_addr = (float *)arr;
    size_t len = n / sizeof(float);
    #pragma omp target
    for (int i = 0; i < len; i++) {
        array_addr[i] = (float)i * 2.0f;
    }
}

void alloc_as_float(unsigned long arr, size_t n) {
    float *array_addr = (float *)arr;
    size_t len = n / sizeof(float);
    #pragma omp target
    for (int i = 0; i < len; i++) {
        array_addr[i] = (float)i * 3.0f;
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

