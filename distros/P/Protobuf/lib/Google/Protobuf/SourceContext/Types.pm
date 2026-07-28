package Google::Protobuf::SourceContext::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'SourceContext',
    as InstanceOf['Google::Protobuf::SourceContext::SourceContext'];

coerce 'SourceContext',
    from HashRef, via { 'Google::Protobuf::SourceContext::SourceContext'->new($_) };

declare 'RepeatedSourceContext',
    as ArrayRef[SourceContext()];

coerce 'RepeatedSourceContext',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::SourceContext::SourceContext'->new($_) } @$_ ] };

declare 'MapStringSourceContext',
    as HashRef[SourceContext()];

1;

__END__

=head1 NAME

Google::Protobuf::SourceContext::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
