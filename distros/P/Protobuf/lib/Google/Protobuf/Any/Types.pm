package Google::Protobuf::Any::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Any',
    as InstanceOf['Google::Protobuf::Any::Any'];

coerce 'Any',
    from HashRef, via { 'Google::Protobuf::Any::Any'->new($_) };

declare 'RepeatedAny',
    as ArrayRef[Any()];

coerce 'RepeatedAny',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Any::Any'->new($_) } @$_ ] };

declare 'MapStringAny',
    as HashRef[Any()];

1;

__END__

=head1 NAME

Google::Protobuf::Any::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
