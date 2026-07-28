package Google::Protobuf::Api::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;
use Types::Standard -types;

declare 'Api',
    as InstanceOf['Google::Protobuf::Api::Api'];

coerce 'Api',
    from HashRef, via { 'Google::Protobuf::Api::Api'->new($_) };

declare 'RepeatedApi',
    as ArrayRef[Api()];

coerce 'RepeatedApi',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Api::Api'->new($_) } @$_ ] };

declare 'MapStringApi',
    as HashRef[Api()];

declare 'Method',
    as InstanceOf['Google::Protobuf::Api::Method'];

coerce 'Method',
    from HashRef, via { 'Google::Protobuf::Api::Method'->new($_) };

declare 'RepeatedMethod',
    as ArrayRef[Method()];

coerce 'RepeatedMethod',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Api::Method'->new($_) } @$_ ] };

declare 'MapStringMethod',
    as HashRef[Method()];

declare 'Mixin',
    as InstanceOf['Google::Protobuf::Api::Mixin'];

coerce 'Mixin',
    from HashRef, via { 'Google::Protobuf::Api::Mixin'->new($_) };

declare 'RepeatedMixin',
    as ArrayRef[Mixin()];

coerce 'RepeatedMixin',
    from ArrayRef[HashRef], via { [ map { 'Google::Protobuf::Api::Mixin'->new($_) } @$_ ] };

declare 'MapStringMixin',
    as HashRef[Mixin()];

1;

__END__

=head1 NAME

Google::Protobuf::Api::Types - Type definitions and coercions

=head1 DESCRIPTION

Auto-generated Type::Tiny definitions and coercions for Protocol Buffers.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Google LLC

This program is released under the Apache 2.0 license.

=cut
