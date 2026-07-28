package Google::Protobuf::Descriptor::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FileDescriptorSet',
    as InstanceOf['Google::Protobuf::Descriptor::FileDescriptorSet'];

coerce 'FileDescriptorSet',
    from HashRef, via { 'Google::Protobuf::Descriptor::FileDescriptorSet'->new($_) };

declare 'RepeatedFileDescriptorSet',
    as ArrayRef[FileDescriptorSet()];

coerce 'RepeatedFileDescriptorSet',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::FileDescriptorSet'->new($_) } @$_ ] };

declare 'MapStringFileDescriptorSet',
    as HashRef[FileDescriptorSet()];

declare 'FileDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::FileDescriptorProto'];

coerce 'FileDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::FileDescriptorProto'->new($_) };

declare 'RepeatedFileDescriptorProto',
    as ArrayRef[FileDescriptorProto()];

coerce 'RepeatedFileDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::FileDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringFileDescriptorProto',
    as HashRef[FileDescriptorProto()];

declare 'DescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::DescriptorProto'];

coerce 'DescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::DescriptorProto'->new($_) };

declare 'RepeatedDescriptorProto',
    as ArrayRef[DescriptorProto()];

coerce 'RepeatedDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::DescriptorProto'->new($_) } @$_ ] };

declare 'MapStringDescriptorProto',
    as HashRef[DescriptorProto()];

declare 'ExtensionRange',
    as InstanceOf['Google::Protobuf::Descriptor::DescriptorProto::ExtensionRange'];

coerce 'ExtensionRange',
    from HashRef, via { 'Google::Protobuf::Descriptor::DescriptorProto::ExtensionRange'->new($_) };

declare 'RepeatedExtensionRange',
    as ArrayRef[ExtensionRange()];

coerce 'RepeatedExtensionRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::DescriptorProto::ExtensionRange'->new($_) } @$_ ] };

declare 'MapStringExtensionRange',
    as HashRef[ExtensionRange()];

declare 'ReservedRange',
    as InstanceOf['Google::Protobuf::Descriptor::DescriptorProto::ReservedRange'];

coerce 'ReservedRange',
    from HashRef, via { 'Google::Protobuf::Descriptor::DescriptorProto::ReservedRange'->new($_) };

declare 'RepeatedReservedRange',
    as ArrayRef[ReservedRange()];

coerce 'RepeatedReservedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::DescriptorProto::ReservedRange'->new($_) } @$_ ] };

declare 'MapStringReservedRange',
    as HashRef[ReservedRange()];

declare 'ExtensionRangeOptions',
    as InstanceOf['Google::Protobuf::Descriptor::ExtensionRangeOptions'];

coerce 'ExtensionRangeOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::ExtensionRangeOptions'->new($_) };

declare 'RepeatedExtensionRangeOptions',
    as ArrayRef[ExtensionRangeOptions()];

coerce 'RepeatedExtensionRangeOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::ExtensionRangeOptions'->new($_) } @$_ ] };

declare 'MapStringExtensionRangeOptions',
    as HashRef[ExtensionRangeOptions()];

declare 'FieldDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::FieldDescriptorProto'];

coerce 'FieldDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::FieldDescriptorProto'->new($_) };

declare 'RepeatedFieldDescriptorProto',
    as ArrayRef[FieldDescriptorProto()];

coerce 'RepeatedFieldDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::FieldDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringFieldDescriptorProto',
    as HashRef[FieldDescriptorProto()];

declare 'Type',
    as (Int | Str);

declare 'Label',
    as (Int | Str);

declare 'OneofDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::OneofDescriptorProto'];

coerce 'OneofDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::OneofDescriptorProto'->new($_) };

declare 'RepeatedOneofDescriptorProto',
    as ArrayRef[OneofDescriptorProto()];

coerce 'RepeatedOneofDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::OneofDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringOneofDescriptorProto',
    as HashRef[OneofDescriptorProto()];

declare 'EnumDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::EnumDescriptorProto'];

coerce 'EnumDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::EnumDescriptorProto'->new($_) };

declare 'RepeatedEnumDescriptorProto',
    as ArrayRef[EnumDescriptorProto()];

coerce 'RepeatedEnumDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::EnumDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringEnumDescriptorProto',
    as HashRef[EnumDescriptorProto()];

declare 'EnumReservedRange',
    as InstanceOf['Google::Protobuf::Descriptor::EnumDescriptorProto::EnumReservedRange'];

coerce 'EnumReservedRange',
    from HashRef, via { 'Google::Protobuf::Descriptor::EnumDescriptorProto::EnumReservedRange'->new($_) };

declare 'RepeatedEnumReservedRange',
    as ArrayRef[EnumReservedRange()];

coerce 'RepeatedEnumReservedRange',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::EnumDescriptorProto::EnumReservedRange'->new($_) } @$_ ] };

declare 'MapStringEnumReservedRange',
    as HashRef[EnumReservedRange()];

declare 'EnumValueDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::EnumValueDescriptorProto'];

coerce 'EnumValueDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::EnumValueDescriptorProto'->new($_) };

declare 'RepeatedEnumValueDescriptorProto',
    as ArrayRef[EnumValueDescriptorProto()];

coerce 'RepeatedEnumValueDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::EnumValueDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringEnumValueDescriptorProto',
    as HashRef[EnumValueDescriptorProto()];

declare 'ServiceDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::ServiceDescriptorProto'];

coerce 'ServiceDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::ServiceDescriptorProto'->new($_) };

declare 'RepeatedServiceDescriptorProto',
    as ArrayRef[ServiceDescriptorProto()];

coerce 'RepeatedServiceDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::ServiceDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringServiceDescriptorProto',
    as HashRef[ServiceDescriptorProto()];

declare 'MethodDescriptorProto',
    as InstanceOf['Google::Protobuf::Descriptor::MethodDescriptorProto'];

coerce 'MethodDescriptorProto',
    from HashRef, via { 'Google::Protobuf::Descriptor::MethodDescriptorProto'->new($_) };

declare 'RepeatedMethodDescriptorProto',
    as ArrayRef[MethodDescriptorProto()];

coerce 'RepeatedMethodDescriptorProto',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::MethodDescriptorProto'->new($_) } @$_ ] };

declare 'MapStringMethodDescriptorProto',
    as HashRef[MethodDescriptorProto()];

declare 'FileOptions',
    as InstanceOf['Google::Protobuf::Descriptor::FileOptions'];

coerce 'FileOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::FileOptions'->new($_) };

declare 'RepeatedFileOptions',
    as ArrayRef[FileOptions()];

coerce 'RepeatedFileOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::FileOptions'->new($_) } @$_ ] };

declare 'MapStringFileOptions',
    as HashRef[FileOptions()];

declare 'OptimizeMode',
    as (Int | Str);

declare 'MessageOptions',
    as InstanceOf['Google::Protobuf::Descriptor::MessageOptions'];

coerce 'MessageOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::MessageOptions'->new($_) };

declare 'RepeatedMessageOptions',
    as ArrayRef[MessageOptions()];

coerce 'RepeatedMessageOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::MessageOptions'->new($_) } @$_ ] };

declare 'MapStringMessageOptions',
    as HashRef[MessageOptions()];

declare 'FieldOptions',
    as InstanceOf['Google::Protobuf::Descriptor::FieldOptions'];

coerce 'FieldOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::FieldOptions'->new($_) };

declare 'RepeatedFieldOptions',
    as ArrayRef[FieldOptions()];

coerce 'RepeatedFieldOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::FieldOptions'->new($_) } @$_ ] };

declare 'MapStringFieldOptions',
    as HashRef[FieldOptions()];

declare 'CType',
    as (Int | Str);

declare 'JSType',
    as (Int | Str);

declare 'OneofOptions',
    as InstanceOf['Google::Protobuf::Descriptor::OneofOptions'];

coerce 'OneofOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::OneofOptions'->new($_) };

declare 'RepeatedOneofOptions',
    as ArrayRef[OneofOptions()];

coerce 'RepeatedOneofOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::OneofOptions'->new($_) } @$_ ] };

declare 'MapStringOneofOptions',
    as HashRef[OneofOptions()];

declare 'EnumOptions',
    as InstanceOf['Google::Protobuf::Descriptor::EnumOptions'];

coerce 'EnumOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::EnumOptions'->new($_) };

declare 'RepeatedEnumOptions',
    as ArrayRef[EnumOptions()];

coerce 'RepeatedEnumOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::EnumOptions'->new($_) } @$_ ] };

declare 'MapStringEnumOptions',
    as HashRef[EnumOptions()];

declare 'EnumValueOptions',
    as InstanceOf['Google::Protobuf::Descriptor::EnumValueOptions'];

coerce 'EnumValueOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::EnumValueOptions'->new($_) };

declare 'RepeatedEnumValueOptions',
    as ArrayRef[EnumValueOptions()];

coerce 'RepeatedEnumValueOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::EnumValueOptions'->new($_) } @$_ ] };

declare 'MapStringEnumValueOptions',
    as HashRef[EnumValueOptions()];

declare 'ServiceOptions',
    as InstanceOf['Google::Protobuf::Descriptor::ServiceOptions'];

coerce 'ServiceOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::ServiceOptions'->new($_) };

declare 'RepeatedServiceOptions',
    as ArrayRef[ServiceOptions()];

coerce 'RepeatedServiceOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::ServiceOptions'->new($_) } @$_ ] };

declare 'MapStringServiceOptions',
    as HashRef[ServiceOptions()];

declare 'MethodOptions',
    as InstanceOf['Google::Protobuf::Descriptor::MethodOptions'];

coerce 'MethodOptions',
    from HashRef, via { 'Google::Protobuf::Descriptor::MethodOptions'->new($_) };

declare 'RepeatedMethodOptions',
    as ArrayRef[MethodOptions()];

coerce 'RepeatedMethodOptions',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::MethodOptions'->new($_) } @$_ ] };

declare 'MapStringMethodOptions',
    as HashRef[MethodOptions()];

declare 'IdempotencyLevel',
    as (Int | Str);

declare 'UninterpretedOption',
    as InstanceOf['Google::Protobuf::Descriptor::UninterpretedOption'];

coerce 'UninterpretedOption',
    from HashRef, via { 'Google::Protobuf::Descriptor::UninterpretedOption'->new($_) };

declare 'RepeatedUninterpretedOption',
    as ArrayRef[UninterpretedOption()];

coerce 'RepeatedUninterpretedOption',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::UninterpretedOption'->new($_) } @$_ ] };

declare 'MapStringUninterpretedOption',
    as HashRef[UninterpretedOption()];

declare 'NamePart',
    as InstanceOf['Google::Protobuf::Descriptor::UninterpretedOption::NamePart'];

coerce 'NamePart',
    from HashRef, via { 'Google::Protobuf::Descriptor::UninterpretedOption::NamePart'->new($_) };

declare 'RepeatedNamePart',
    as ArrayRef[NamePart()];

coerce 'RepeatedNamePart',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::UninterpretedOption::NamePart'->new($_) } @$_ ] };

declare 'MapStringNamePart',
    as HashRef[NamePart()];

declare 'SourceCodeInfo',
    as InstanceOf['Google::Protobuf::Descriptor::SourceCodeInfo'];

coerce 'SourceCodeInfo',
    from HashRef, via { 'Google::Protobuf::Descriptor::SourceCodeInfo'->new($_) };

declare 'RepeatedSourceCodeInfo',
    as ArrayRef[SourceCodeInfo()];

coerce 'RepeatedSourceCodeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::SourceCodeInfo'->new($_) } @$_ ] };

declare 'MapStringSourceCodeInfo',
    as HashRef[SourceCodeInfo()];

declare 'Location',
    as InstanceOf['Google::Protobuf::Descriptor::SourceCodeInfo::Location'];

coerce 'Location',
    from HashRef, via { 'Google::Protobuf::Descriptor::SourceCodeInfo::Location'->new($_) };

declare 'RepeatedLocation',
    as ArrayRef[Location()];

coerce 'RepeatedLocation',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::SourceCodeInfo::Location'->new($_) } @$_ ] };

declare 'MapStringLocation',
    as HashRef[Location()];

declare 'GeneratedCodeInfo',
    as InstanceOf['Google::Protobuf::Descriptor::GeneratedCodeInfo'];

coerce 'GeneratedCodeInfo',
    from HashRef, via { 'Google::Protobuf::Descriptor::GeneratedCodeInfo'->new($_) };

declare 'RepeatedGeneratedCodeInfo',
    as ArrayRef[GeneratedCodeInfo()];

coerce 'RepeatedGeneratedCodeInfo',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::GeneratedCodeInfo'->new($_) } @$_ ] };

declare 'MapStringGeneratedCodeInfo',
    as HashRef[GeneratedCodeInfo()];

declare 'Annotation',
    as InstanceOf['Google::Protobuf::Descriptor::GeneratedCodeInfo::Annotation'];

coerce 'Annotation',
    from HashRef, via { 'Google::Protobuf::Descriptor::GeneratedCodeInfo::Annotation'->new($_) };

declare 'RepeatedAnnotation',
    as ArrayRef[Annotation()];

coerce 'RepeatedAnnotation',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Descriptor::GeneratedCodeInfo::Annotation'->new($_) } @$_ ] };

declare 'MapStringAnnotation',
    as HashRef[Annotation()];

1;

__END__

=head1 NAME

Google::Protobuf::Descriptor::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
