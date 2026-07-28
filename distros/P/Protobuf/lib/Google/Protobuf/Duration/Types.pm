package Google::Protobuf::Duration::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Duration',
    as InstanceOf['Google::Protobuf::Duration::Duration'];

coerce 'Duration',
    from HashRef, via { 'Google::Protobuf::Duration::Duration'->new($_) };

declare 'RepeatedDuration',
    as ArrayRef[Duration()];

coerce 'RepeatedDuration',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Duration::Duration'->new($_) } @$_ ] };

declare 'MapStringDuration',
    as HashRef[Duration()];

1;

__END__

=head1 NAME

Google::Protobuf::Duration::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
