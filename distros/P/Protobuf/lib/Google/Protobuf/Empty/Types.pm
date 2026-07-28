package Google::Protobuf::Empty::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Empty',
    as InstanceOf['Google::Protobuf::Empty::Empty'];

coerce 'Empty',
    from HashRef, via { 'Google::Protobuf::Empty::Empty'->new($_) };

declare 'RepeatedEmpty',
    as ArrayRef[Empty()];

coerce 'RepeatedEmpty',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Empty::Empty'->new($_) } @$_ ] };

declare 'MapStringEmpty',
    as HashRef[Empty()];

1;

__END__

=head1 NAME

Google::Protobuf::Empty::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
