package Google::Protobuf::Compiler::Plugin::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Version',
    as InstanceOf['Google::Protobuf::Compiler::Plugin::Version'];

coerce 'Version',
    from HashRef, via { 'Google::Protobuf::Compiler::Plugin::Version'->new($_) };

declare 'RepeatedVersion',
    as ArrayRef[Version()];

coerce 'RepeatedVersion',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Compiler::Plugin::Version'->new($_) } @$_ ] };

declare 'MapStringVersion',
    as HashRef[Version()];

declare 'CodeGeneratorRequest',
    as InstanceOf['Google::Protobuf::Compiler::Plugin::CodeGeneratorRequest'];

coerce 'CodeGeneratorRequest',
    from HashRef, via { 'Google::Protobuf::Compiler::Plugin::CodeGeneratorRequest'->new($_) };

declare 'RepeatedCodeGeneratorRequest',
    as ArrayRef[CodeGeneratorRequest()];

coerce 'RepeatedCodeGeneratorRequest',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Compiler::Plugin::CodeGeneratorRequest'->new($_) } @$_ ] };

declare 'MapStringCodeGeneratorRequest',
    as HashRef[CodeGeneratorRequest()];

declare 'CodeGeneratorResponse',
    as InstanceOf['Google::Protobuf::Compiler::Plugin::CodeGeneratorResponse'];

coerce 'CodeGeneratorResponse',
    from HashRef, via { 'Google::Protobuf::Compiler::Plugin::CodeGeneratorResponse'->new($_) };

declare 'RepeatedCodeGeneratorResponse',
    as ArrayRef[CodeGeneratorResponse()];

coerce 'RepeatedCodeGeneratorResponse',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Compiler::Plugin::CodeGeneratorResponse'->new($_) } @$_ ] };

declare 'MapStringCodeGeneratorResponse',
    as HashRef[CodeGeneratorResponse()];

declare 'Feature',
    as (Int | Str);

declare 'File',
    as InstanceOf['Google::Protobuf::Compiler::Plugin::CodeGeneratorResponse::File'];

coerce 'File',
    from HashRef, via { 'Google::Protobuf::Compiler::Plugin::CodeGeneratorResponse::File'->new($_) };

declare 'RepeatedFile',
    as ArrayRef[File()];

coerce 'RepeatedFile',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Compiler::Plugin::CodeGeneratorResponse::File'->new($_) } @$_ ] };

declare 'MapStringFile',
    as HashRef[File()];

1;

__END__

=head1 NAME

Google::Protobuf::Compiler::Plugin::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
