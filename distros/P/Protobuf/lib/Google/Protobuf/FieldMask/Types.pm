package Google::Protobuf::FieldMask::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'FieldMask',
    as InstanceOf['Google::Protobuf::FieldMask::FieldMask'];

coerce 'FieldMask',
    from HashRef, via { 'Google::Protobuf::FieldMask::FieldMask'->new($_) };

declare 'RepeatedFieldMask',
    as ArrayRef[FieldMask()];

coerce 'RepeatedFieldMask',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::FieldMask::FieldMask'->new($_) } @$_ ] };

declare 'MapStringFieldMask',
    as HashRef[FieldMask()];

1;

__END__

=head1 NAME

Google::Protobuf::FieldMask::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
