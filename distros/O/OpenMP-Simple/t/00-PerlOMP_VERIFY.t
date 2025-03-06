#!/usr/bin/env perl

use strict;
use warnings;
use OpenMP::Simple;
use Inline (
    C                 => 'DATA',
    with              => qw/OpenMP::Simple/,
);
use Test::More;
use Test::Exception;

my $valid_1d_int = [1, 2, 3, 4, 5];
my $valid_1d_float = [1.1, 2.2, 3.3, 4.4, 5.5];
my $valid_1d_string = ["ant", "bat", "cat", "dog"];

my $valid_2d_int = [[1, 2], [3, 4], [5, 6]];
my $valid_2d_float = [[1.1, 2.2], [3.3, 4.4], [5.5, 6.6]];
my $valid_2d_string = [["ark", "bar"], ["car", "day"], ["egg", "fly"]];

my $invalid_scalar = 42;
my $invalid_1d_array = { key => "value" };

# Verify 1D arrays
dies_ok { _PerlOMP_VERIFY_1D_Array($invalid_scalar) } "Scalar should not be a valid 1D array";
lives_ok { _PerlOMP_VERIFY_1D_Array($valid_1d_int) } "Valid 1D array passes verification";

lives_ok { _PerlOMP_VERIFY_1D_INT_ARRAY($valid_1d_int) } "Valid 1D integer array";
dies_ok { _PerlOMP_VERIFY_1D_INT_ARRAY($valid_1d_float) } "Float 1D array should fail int verification";

lives_ok { _PerlOMP_VERIFY_1D_FLOAT_ARRAY($valid_1d_float) } "Valid 1D float array";
dies_ok { _PerlOMP_VERIFY_1D_FLOAT_ARRAY($valid_1d_int) } "Int 1D array should fail float verification";

lives_ok { _PerlOMP_VERIFY_1D_STRING_ARRAY($valid_1d_string) } "Valid 1D string array";
dies_ok { _PerlOMP_VERIFY_1D_STRING_ARRAY($valid_1d_int) } "Int 1D array should fail string verification";

# Verify 2D arrays
dies_ok { _PerlOMP_VERIFY_2D_AoA($invalid_scalar) } "Scalar should not be a valid 2D array";
lives_ok { _PerlOMP_VERIFY_2D_AoA($valid_2d_int) } "Valid 2D array passes verification";

lives_ok { _PerlOMP_VERIFY_2D_INT_ARRAY($valid_2d_int) } "Valid 2D integer array";
dies_ok { _PerlOMP_VERIFY_2D_INT_ARRAY($valid_2d_float) } "Float 2D array should fail int verification";

lives_ok { _PerlOMP_VERIFY_2D_FLOAT_ARRAY($valid_2d_float) } "Valid 2D float array";
dies_ok { _PerlOMP_VERIFY_2D_FLOAT_ARRAY($valid_2d_int) } "Int 2D array should fail float verification";

lives_ok { _PerlOMP_VERIFY_2D_STRING_ARRAY($valid_2d_string) } "Valid 2D string array";
dies_ok { _PerlOMP_VERIFY_2D_STRING_ARRAY($valid_2d_int) } "Int 2D array should fail string verification";

done_testing();

__DATA__
__C__

void _PerlOMP_VERIFY_1D_Array(SV* array) { PerlOMP_VERIFY_1D_Array(array); }
void _PerlOMP_VERIFY_1D_INT_ARRAY(SV* array) { PerlOMP_VERIFY_1D_INT_ARRAY(array); }
void _PerlOMP_VERIFY_1D_FLOAT_ARRAY(SV* array) { PerlOMP_VERIFY_1D_FLOAT_ARRAY(array); }
void _PerlOMP_VERIFY_1D_STRING_ARRAY(SV* array) { PerlOMP_VERIFY_1D_STRING_ARRAY(array); }
void _PerlOMP_VERIFY_2D_AoA(SV* array) { PerlOMP_VERIFY_2D_AoA(array); }
void _PerlOMP_VERIFY_2D_INT_ARRAY(SV* array) { PerlOMP_VERIFY_2D_INT_ARRAY(array); }
void _PerlOMP_VERIFY_2D_FLOAT_ARRAY(SV* array) { PerlOMP_VERIFY_2D_FLOAT_ARRAY(array); }
void _PerlOMP_VERIFY_2D_STRING_ARRAY(SV* array) { PerlOMP_VERIFY_2D_STRING_ARRAY(array); }
