package Google::Protobuf::Timestamp::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Timestamp',
    as InstanceOf['Google::Protobuf::Timestamp::Timestamp'];

coerce 'Timestamp',
    from HashRef, via { 'Google::Protobuf::Timestamp::Timestamp'->new($_) };

declare 'RepeatedTimestamp',
    as ArrayRef[Timestamp()];

coerce 'RepeatedTimestamp',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Timestamp::Timestamp'->new($_) } @$_ ] };

declare 'MapStringTimestamp',
    as HashRef[Timestamp()];

1;

__END__

=head1 NAME

Google::Protobuf::Timestamp::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
