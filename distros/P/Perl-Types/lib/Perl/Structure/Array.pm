# [[[ HEADER ]]]
package Perl::Structure::Array;
use strict;
use warnings;
use Perl::Types;
our $VERSION = 0.009_000;

# [[[ OO INHERITANCE ]]]
use parent qw(Perl::Structure);
use Perl::Structure;

use Carp;

# [[[ SUB-TYPES BEFORE INCLUDES ]]]
use Perl::Structure::Array::SubTypes;
use Perl::Structure::Array::SubTypes1D;
use Perl::Structure::Array::SubTypes2D;
use Perl::Structure::Array::SubTypes3D;

# [[[ INCLUDES ]]]
# for type-checking via SvIOKp(), SvNOKp(), and SvPOKp(); inside INIT to delay until after 'use MyConfig'
#INIT { Perl::diag("in Array.pm, loading C++ helper functions for type-checking...\n"); }
INIT {
    use Perl::HelperFunctions_cpp;
    Perl::HelperFunctions_cpp::cpp_load();
}

use Perl::Type::Void;
use Perl::Type::Boolean;
use Perl::Type::NonsignedInteger;
use Perl::Type::Integer;
use Perl::Type::Number;
use Perl::Type::Character;
use Perl::Type::String;
use Perl::Type::Scalar;
use Perl::Type::Unknown;
use Perl::Structure::Hash;

# [[[ EXPORTS ]]]
# DEV NOTE: avoid "Undefined subroutine &main::integer_to_string called"
use Exporter 'import';
our @EXPORT = ( @Perl::Type::Void::EXPORT, 
                @Perl::Type::Boolean::EXPORT, 
                @Perl::Type::NonsignedInteger::EXPORT, 
                @Perl::Type::Integer::EXPORT, 
                @Perl::Type::Number::EXPORT, 
                @Perl::Type::Character::EXPORT, 
                @Perl::Type::String::EXPORT, 
                @Perl::Type::Scalar::EXPORT, 
                @Perl::Type::Unknown::EXPORT, 
                @Perl::Structure::Hash::EXPORT);

# DEV NOTE, CORRELATION #rp018: Perl::Structure::Array & Hash can not 'use RPerl;' so *__MODE_ID() subroutines are hard-coded here
package main;
use strict;
use warnings;
sub Perl__Structure__Array__MODE_ID { return 0; }

1;  # end of class
