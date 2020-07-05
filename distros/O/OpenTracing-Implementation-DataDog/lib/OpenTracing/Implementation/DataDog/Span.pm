package OpenTracing::Implementation::DataDog::Span;

=head1 NAME

OpenTracing::Implementation::DataDog::Span - A DataDog Implementation for a Span

=cut

our $VERSION = 'v0.41.2';

use syntax 'maybe';

use Moo;

with 'OpenTracing::Role::Span';

use aliased 'OpenTracing::Implementation::DataDog::SpanContext';

use Types::Standard qw/Str/;
use Ref::Util qw/is_plain_hashref/;
use Carp;

=head1 DESCRIPTION

This is a L<OpenTracing Span|OpenTracing::Interface::Span> compliant
implementation whit DataDog specific extentions

=cut



=head1 EXTENDED ATTRIBUTES

=cut



=head2 C<operation_name>

DataDog requires that its length should not exceed 100 characters.

=cut

has '+operation_name' => (
    isa => Str->where( 'length($_) <= 100' ),
);



=head2 C<context>

Add coercion from plain hashref

=cut

has '+context' => (
    coerce
    => sub { is_plain_hashref $_[0] ? SpanContext->new( %{$_[0]} ) : $_[0] },
    default
    => sub { croak "Can not construct a default SpanContext" },
);

# OpenTracing does not provide any public method to instantiate a SpanContext.
# But rootspans do need to have a context which comes from
# the `$TRACER->extract_context` call, or it returns `undef` if there was no
# such context.
# Passing in a plain hash reference instead of a SpanContext will
# instantiate such context with a 'fresh' `trace_id`



=head1 SEE ALSO

=over

=item L<OpenTracing::Implementation::DataDog>

Sending traces to DataDog using Agent.

=item L<OpenTracing::Role::Span>

Role for OpenTracing Implementations.

=back



=head1 AUTHOR

Theo van Hoesel <tvanhoesel@perceptyx.com>



=head1 COPYRIGHT AND LICENSE

'OpenTracing::Implementation::DataDog'
is Copyright (C) 2019 .. 2020, Perceptyx Inc

This library is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.

This package is distributed in the hope that it will be useful, but it is
provided "as is" and without any express or implied warranties.

For details, see the full text of the license in the file LICENSE.


=cut

1;
