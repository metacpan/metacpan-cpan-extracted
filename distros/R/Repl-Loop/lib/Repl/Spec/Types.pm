package Repl::Spec::Types;

use strict;
use warnings;

use Repl::Spec::Type::WhateverType;
use Repl::Spec::Type::DefinedType;
use Repl::Spec::Type::ScalarType;
use Repl::Spec::Type::BooleanType;
use Repl::Spec::Type::IntegerType;
use Repl::Spec::Type::InstanceType;
use Repl::Spec::Type::CheckedArrayType;
use Repl::Spec::Type::CheckedHashType;
use Repl::Spec::Type::IntegerRangeType;
use Repl::Spec::Type::PatternType;
use Repl::Spec::Type::StringEnumType;
use Repl::Spec::Type::NumberType;
use Repl::Spec::Type::FileType;

use Repl::Spec::Args::StdArgList;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
    WHATEVER_TYPE DEFINED_TYPE
    SCALAR_TYPE
    BOOLEAN_TYPE INTEGER_TYPE NUMBER_TYPE HASH_TYPE ARRAY_TYPE PAIR_TYPE LAMBDA_TYPE
    HASH_HASH_TYPE
    ARRAY_NUMBER_TYPE
    MONTH_TYPE DAY_TYPE HOUR_TYPE MINUTE_TYPE SECOND_TYPE
    EMAIL_TYPE
    READABLEFILE_TYPE ARRAY_READABLEFILE_TYPE
    
    NO_ARGS);
    
our @EXPORT_OK = qw();

use constant WHATEVER_TYPE => new Repl::Spec::Type::WhateverType();
use constant DEFINED_TYPE => new Repl::Spec::Type::DefinedType();
use constant SCALAR_TYPE => new Repl::Spec::Type::ScalarType();
use constant BOOLEAN_TYPE => new Repl::Spec::Type::BooleanType();
use constant INTEGER_TYPE => new Repl::Spec::Type::IntegerType();
use constant NUMBER_TYPE => new Repl::Spec::Type::NumberType();
use constant HASH_TYPE => new Repl::Spec::Type::InstanceType("HASH");
use constant ARRAY_TYPE => new Repl::Spec::Type::InstanceType("ARRAY");
use constant PAIR_TYPE => new Repl::Spec::Type::InstanceType("Repl::Core::Pair");
use constant LAMBDA_TYPE => new Repl::Spec::Type::InstanceType("Repl::Core::Lambda");

use constant HASH_HASH_TYPE => new Repl::Spec::Type::CheckedHashType(HASH_TYPE);
use constant ARRAY_NUMBER_TYPE => new Repl::Spec::Type::CheckedArrayType(NUMBER_TYPE);

use constant MONTH_TYPE => new Repl::Spec::Type::IntegerRangeType(1, 12);
use constant DAY_TYPE => new Repl::Spec::Type::IntegerRangeType(1, 31);
use constant HOUR_TYPE => new Repl::Spec::Type::IntegerRangeType(0, 23);
use constant MINUTE_TYPE => new Repl::Spec::Type::IntegerRangeType(0, 59);
use constant SECOND_TYPE => new Repl::Spec::Type::IntegerRangeType(0, 59);

use constant EMAIL_TYPE => new Repl::Spec::Type::PatternType('email address', '^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$');

use constant READABLEFILE_TYPE => new Repl::Spec::Type::FileType(ISFILE=>1, READABLE=>1);
use constant ARRAY_READABLEFILE_TYPE => new Repl::Spec::Type::CheckedArrayType(READABLEFILE_TYPE);

use constant NO_ARGS => new Repl::Spec::Args::StdArgList([], [], []);

1;

__END__

=head1 NAME

Repl::Spec::Types - A module with common type guards.

=head1 SYNOPSIS

This module contains a number of commonly used type guards which
can be used throughout the batch framework.
         
=head1 SEE ALSO

L<Repl::Spec::Type::BooleanType>
L<Repl::Spec::Type::CheckedArrayType>
L<Repl::Spec::Type::CheckedHashType>
L<Repl::Spec::Type::InstanceType>
L<Repl::Spec::Type::IntegerRangeType>
L<Repl::Spec::Type::IntegerType>
L<Repl::Spec::Type::PatternType>
L<Repl::Spec::Type::StringEnumType>

=cut
