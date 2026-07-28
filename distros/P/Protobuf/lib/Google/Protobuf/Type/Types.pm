package Google::Protobuf::Type::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Syntax',
    as (Int | Str);

declare 'Type',
    as InstanceOf['Google::Protobuf::Type::Type'];

coerce 'Type',
    from HashRef, via { 'Google::Protobuf::Type::Type'->new($_) };

declare 'RepeatedType',
    as ArrayRef[Type()];

coerce 'RepeatedType',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Type::Type'->new($_) } @$_ ] };

declare 'MapStringType',
    as HashRef[Type()];

declare 'Field',
    as InstanceOf['Google::Protobuf::Type::Field'];

coerce 'Field',
    from HashRef, via { 'Google::Protobuf::Type::Field'->new($_) };

declare 'RepeatedField',
    as ArrayRef[Field()];

coerce 'RepeatedField',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Type::Field'->new($_) } @$_ ] };

declare 'MapStringField',
    as HashRef[Field()];

declare 'Kind',
    as (Int | Str);

declare 'Cardinality',
    as (Int | Str);

declare 'Enum',
    as InstanceOf['Google::Protobuf::Type::Enum'];

coerce 'Enum',
    from HashRef, via { 'Google::Protobuf::Type::Enum'->new($_) };

declare 'RepeatedEnum',
    as ArrayRef[Enum()];

coerce 'RepeatedEnum',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Type::Enum'->new($_) } @$_ ] };

declare 'MapStringEnum',
    as HashRef[Enum()];

declare 'EnumValue',
    as InstanceOf['Google::Protobuf::Type::EnumValue'];

coerce 'EnumValue',
    from HashRef, via { 'Google::Protobuf::Type::EnumValue'->new($_) };

declare 'RepeatedEnumValue',
    as ArrayRef[EnumValue()];

coerce 'RepeatedEnumValue',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Type::EnumValue'->new($_) } @$_ ] };

declare 'MapStringEnumValue',
    as HashRef[EnumValue()];

declare 'Option',
    as InstanceOf['Google::Protobuf::Type::Option'];

coerce 'Option',
    from HashRef, via { 'Google::Protobuf::Type::Option'->new($_) };

declare 'RepeatedOption',
    as ArrayRef[Option()];

coerce 'RepeatedOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Type::Option'->new($_) } @$_ ] };

declare 'MapStringOption',
    as HashRef[Option()];

1;

__END__

=head1 NAME

Google::Protobuf::Type::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
