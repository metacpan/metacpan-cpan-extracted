#!/usr/bin/env perl
#*
#* Name: Params/Dry/Types.pm.t
#* Info: Test for Params::Dry::Types
#* Author: Pawel Guspiel (neo77) <neo@cpan.org>
#*

use strict;
use warnings;
use utf8;

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

use Test::Most;    # last test to print

use FindBin '$Bin';
use lib $Bin. '/../lib';

use constant PASS => 1;    # pass test
use constant FAIL => 0;    # test fail

my $tb = Test::Most->builder;
$tb->failure_output( \*STDERR );
$tb->todo_output( \*STDERR );
$tb->output( \*STDOUT );

sub test_function {
    my %p_ = @_;

    my $p_function_name   = $p_{ 'function_name' };
    my $p_function        = $p_{ 'function' };
    my $p_function_params = $p_{ 'function_params' } || [];
    my $p_value           = $p_{ 'value' };
    my $p_expected        = $p_{ 'expected' };
    ok( &$p_function( $p_value, @$p_function_params ) eq $p_expected, "'" . ( $p_value // 'undef' ) . "' " . ( $p_expected ? 'is a' : 'is NOT a' ) . " $p_function_name" );

} #+ end of: sub test_function

use_ok( 'Params::Dry::Types' );
use_ok( 'Params::Dry::Types::Number' );
use_ok( 'Params::Dry::Types::String' );
use_ok( 'Params::Dry::Types::Ref' );
use_ok( 'Params::Dry::Types::Object' );
use_ok( 'Params::Dry::Types::DateTime' );

#*----------
#*  String
#*----------
test_function(
               function_name   => 'String',
               function        => \&Params::Dry::Types::String,
               function_params => undef,
               value           => 'Plepleple',
               expected        => PASS,
);
test_function(
               function_name   => 'String[5]',
               function        => \&Params::Dry::Types::String,
               function_params => [5],
               value           => 'Plep',
               expected        => PASS,
);
test_function(
               function_name   => 'String[5]',
               function        => \&Params::Dry::Types::String,
               function_params => [5],
               value           => 'PlePl',
               expected        => PASS,
);
test_function(
               function_name   => 'String[5]',
               function        => \&Params::Dry::Types::String,
               function_params => [5],
               value           => 'PlePle',
               expected        => FAIL,
);
test_function(
               function_name   => 'String[5]',
               function        => \&Params::Dry::Types::String,
               function_params => [5],
               value           => 'PlePź',
               expected        => PASS,
);
test_function(
               function_name   => 'String',
               function        => \&Params::Dry::Types::String,
               function_params => undef,
               value           => [],
               expected        => FAIL,
);

#*----------
#*  Object
#*----------
test_function(
               function_name   => 'Object',
               function        => \&Params::Dry::Types::Object,
               function_params => undef,
               value           => 'Plepleple',
               expected        => FAIL,
);
test_function(
               function_name   => 'Object',
               function        => \&Params::Dry::Types::Object,
               function_params => undef,
               value           => '1',
               expected        => FAIL,
);
test_function(
               function_name   => 'Object',
               function        => \&Params::Dry::Types::Object,
               function_params => undef,
               value           => [],
               expected        => FAIL,
);
test_function(
               function_name   => 'Object',
               function        => \&Params::Dry::Types::Object,
               function_params => ['Params::Dry::Types'],
               value           => ( bless {}, 'Params::Dry::Types' ),
               expected        => PASS,
);

#*-----------------------------------
#*  Ref (Scalar, Array, Hash, Code)
#*-----------------------------------
test_function(
               function_name   => 'Ref',
               function        => \&Params::Dry::Types::Ref,
               function_params => undef,
               value           => 'Plepleple',
               expected        => FAIL,
);
test_function(
               function_name   => 'Ref',
               function        => \&Params::Dry::Types::Ref,
               function_params => undef,
               value           => ['Plepleple'],
               expected        => PASS,
);
test_function(
               function_name   => 'Ref(ARRAY)',
               function        => \&Params::Dry::Types::Ref,
               function_params => ['ARRAY'],
               value           => ['Plepleple'],
               expected        => PASS,
);
test_function(
               function_name   => 'Ref(HASH)',
               function        => \&Params::Dry::Types::Ref,
               function_params => ['HASH'],
               value           => ['Plepleple'],
               expected        => FAIL,
);
test_function(
               function_name   => 'Array',
               function        => \&Params::Dry::Types::Array,
               function_params => undef,
               value           => ['Plepleple'],
               expected        => PASS,
);
test_function(
               function_name   => 'Hash',
               function        => \&Params::Dry::Types::Hash,
               function_params => undef,
               value           => { 'Plepleple' => 1 },
               expected        => PASS,
);
test_function(
               function_name   => 'Code',
               function        => \&Params::Dry::Types::Code,
               function_params => undef,
               value           => sub { 'Plepleple' },
               expected        => PASS,
);
test_function(
               function_name   => 'Scalar',
               function        => \&Params::Dry::Types::Scalar,
               function_params => undef,
               value           => \'Plepleple',
               expected        => PASS,
);
test_function(
               function_name   => 'Regexp',
               function        => \&Params::Dry::Types::Regexp,
               function_params => undef,
               value           => qr/\w+/,
               expected        => PASS,
);

#*---------
#*  Value
#*---------
test_function(
               function_name   => 'Value',
               function        => \&Params::Dry::Types::Value,
               function_params => undef,
               value           => qr/\w+/,
               expected        => FAIL,
);
test_function(
               function_name   => 'Value',
               function        => \&Params::Dry::Types::Value,
               function_params => undef,
               value           => 'Some string',
               expected        => PASS,
);

#*-----------
#*  Defined
#*-----------
test_function(
               function_name   => 'Defined',
               function        => \&Params::Dry::Types::Defined,
               function_params => undef,
               value           => undef,
               expected        => FAIL,
);
test_function(
               function_name   => 'Defined',
               function        => \&Params::Dry::Types::Defined,
               function_params => undef,
               value           => 'Some string',
               expected        => PASS,
);
test_function(
               function_name   => 'Defined',
               function        => \&Params::Dry::Types::Defined,
               function_params => undef,
               value           => ['Some array'],
               expected        => PASS,
);

#*------------------
#*  Int,Float,Bool
#*------------------
test_function(
               function_name   => 'Int',
               function        => \&Params::Dry::Types::Int,
               function_params => undef,
               value           => '10',
               expected        => PASS,
);
test_function(
               function_name   => 'Float',
               function        => \&Params::Dry::Types::Float,
               function_params => undef,
               value           => '10.2',
               expected        => PASS,
);
test_function(
               function_name   => 'Bool',
               function        => \&Params::Dry::Types::Bool,
               function_params => undef,
               value           => '1',
               expected        => PASS,
);

#*-------------------------------
#*  Params::Dry::Types::Numeric
#*-------------------------------

test_function(
               function_name   => 'Number::Int',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => undef,
               value           => 'Plepleple',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Int',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => undef,
               value           => '10',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Int',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => undef,
               value           => '10.01',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Int',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => undef,
               value           => '+10',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Int',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => undef,
               value           => '-10',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Int[3]',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => [3],
               value           => '101',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Int[3]',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => [3],
               value           => '1012',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Int[3]',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => [3],
               value           => '+101',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Int',
               function        => \&Params::Dry::Types::Number::Int,
               function_params => undef,
               value           => [],
               expected        => FAIL,
);

#*----------
#*  Float
#*----------
test_function(
               function_name   => 'Number::Float',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => undef,
               value           => 'Plepleple',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Float',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => undef,
               value           => '10',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => undef,
               value           => '10.01',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => undef,
               value           => '+10',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => undef,
               value           => '-10',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float[3]',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => [3],
               value           => '101',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float[3]',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => [3],
               value           => '1012',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Float[3]',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => [3],
               value           => '+101',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => undef,
               value           => [],
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Float[5,2]',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => [ 5, 2 ],
               value           => '+11.23',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Float[4,2]',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => [ 4, 2 ],
               value           => '+11.23',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Float[5,1]',
               function        => \&Params::Dry::Types::Number::Float,
               function_params => [ 5, 1 ],
               value           => '+11.23',
               expected        => FAIL,
);

#*----------
#*  Bool
#*----------
test_function(
               function_name   => 'Number::Bool',
               function        => \&Params::Dry::Types::Number::Bool,
               function_params => undef,
               value           => 'Plepleple',
               expected        => FAIL,
);
test_function(
               function_name   => 'Number::Bool',
               function        => \&Params::Dry::Types::Number::Bool,
               function_params => undef,
               value           => '1',
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Bool',
               function        => \&Params::Dry::Types::Number::Bool,
               function_params => undef,
               value           => 0,
               expected        => PASS,
);
test_function(
               function_name   => 'Number::Bool',
               function        => \&Params::Dry::Types::Number::Bool,
               function_params => undef,
               value           => [],
               expected        => FAIL,
);

#*---------------------------
#*  Params::Dry::Types::Ref
#*---------------------------
test_function(
               function_name   => 'Scalar',
               function        => \&Params::Dry::Types::Ref::Scalar,
               function_params => undef,
               value           => \'Plepleple',
               expected        => PASS,
);
test_function(
               function_name   => 'Array',
               function        => \&Params::Dry::Types::Ref::Array,
               function_params => undef,
               value           => ['Plepleple'],
               expected        => PASS,
);
test_function(
               function_name   => 'Hash',
               function        => \&Params::Dry::Types::Ref::Hash,
               function_params => undef,
               value           => { 'Plepleple' => 1 },
               expected        => PASS,
);
test_function(
               function_name   => 'Code',
               function        => \&Params::Dry::Types::Ref::Code,
               function_params => undef,
               value           => sub { 'Plepleple' },
               expected        => PASS,
);
test_function(
               function_name   => 'Glob',
               function        => \&Params::Dry::Types::Ref::Glob,
               function_params => undef,
               value           => \*STDIN,
               expected        => PASS,
);

test_function(
               function_name   => 'Ref',
               function        => \&Params::Dry::Types::Ref::Ref,
               function_params => undef,
               value           => \*STDIN{ IO },
               expected        => PASS,
);
test_function(
               function_name   => 'LValue',
               function        => \&Params::Dry::Types::Ref::LValue,
               function_params => undef,
               value           => \pos(),
               expected        => PASS,
);
format STDOUT_TOP =
                         Passwd File
                          Name                Login    Office   Uid   Gid Home
                           ------------------------------------------------------------------
.
test_function(
               function_name   => 'Format',
               function        => \&Params::Dry::Types::Ref::Format,
               function_params => undef,
               value           => *STDOUT_TOP{ FORMAT },
               expected        => PASS,
);
test_function(
               function_name   => 'VString',
               function        => \&Params::Dry::Types::Ref::VString,
               function_params => undef,
               value           => \v10.2.3,
               expected        => PASS,
);
test_function(
               function_name   => 'Regexp',
               function        => \&Params::Dry::Types::Ref::Regexp,
               function_params => undef,
               value           => qr/\w+/,
               expected        => PASS,
);

ok( 'yes', 'yes' );

done_testing();
