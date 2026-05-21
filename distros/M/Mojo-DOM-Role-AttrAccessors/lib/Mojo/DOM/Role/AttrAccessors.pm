use strict;
use warnings;
package Mojo::DOM::Role::AttrAccessors;

use Mojo::Base -role;

sub AUTOLOAD {
    my ($self, $val) = @_;
    our $AUTOLOAD;
    my $attr = $AUTOLOAD =~ s/.*:://r;  # strip package name

    return if $attr eq 'DESTROY';
    return $self->attr($attr) unless defined $val;
    return $self->attr($attr => $val);
}

sub data {
    my ($self, $key, $val) = @_;

    if (defined $val) {
        my $stored = ref $val ? Mojo::JSON::encode_json($val) : $val;
        return $self->attr("data-$key" => $stored);
    }

    my $raw = $self->attr("data-$key");
    return undef unless defined $raw;

    # if (my $decoded = eval { Mojo::JSON::decode_json($raw) }) {
    #     return ref $decoded ? $decoded : $raw;
    # }
    my $decoded = eval { Mojo::JSON::decode_json($raw) };
    if (!$@) {
	return ref $decoded ? $decoded : $raw;
    }
    return $raw;
}

1;


=encoding utf8

=head1 NAME

Mojo::DOM::Role::AttrAccessors - Attribute accessors for Mojo::DOM

=head1 SYNOPSIS

  use Mojo::DOM;

  my $dom = Mojo::DOM->with_roles('+AttrAccessors')
                     ->new('<a href="https://example.com">Example</a>')
                     ->at('a');

  # Read an attribute
  my $href = $dom->href;

  # Write an attribute
  $dom->href('https://mojolicious.org');

  # Chain
  $dom->href('https://mojolicious.org')->id('main-link');

  # Structured data via data-* attributes
  $dom->data('config', { foo => 1 });
  my $config = $dom->data('config');    # returns hashref

  # Plain strings pass through untouched
  $dom->data('label', 'hello');
  my $label = $dom->data('label');      # returns "hello"

=head1 DESCRIPTION

L<Mojo::DOM::Role::AttrAccessors> is a L<Mojo::Role> that adds autoloaded
attribute accessors to L<Mojo::DOM> nodes. Any HTML attribute can be read or
written as a method call directly on the node, without going through
L<Mojo::DOM/attr>.

The role also provides a L</data> method for ergonomic access to C<data-*>
attributes, with automatic JSON serialisation for reference values.

=head1 METHODS

L<Mojo::DOM::Role::AttrAccessors> implements the following methods.

=head2 data

  my $val = $dom->data('key');
  $dom->data('key', 'plain string');
  $dom->data('key', { structured => 'data' });
  $dom->data('key', [1, 2, 3]);

Read or write a C<data-*> attribute on the node. The following encoding
rules apply:

=over 4

=item Inbound

If the value is a reference it is JSON-encoded before storing. Plain scalars
are stored as-is.

=item Outbound

If the stored value is valid JSON and decodes to a reference, the reference
is returned. Otherwise the raw string is returned. This means plain strings
and bare JSON scalars (C<42>, C<true>) are always returned as strings.

=head3 CAVEAT

JSON boolean values (C<true>, C<false>) are returned as
L<Mojo::JSON> boolean objects, which evaluate correctly in boolean
context. Note that storing C<\1> or C<\0> will round-trip as these
boolean objects rather than the original scalar references.

=back

=head2 AUTOLOAD

  my $val = $dom->href;
  $dom->href('https://mojolicious.org');

Any method call not defined by this role or L<Mojo::DOM> is intercepted and
treated as an attribute accessor. The method name is used directly as the
attribute name.

Note that HTML attributes containing hyphens (such as C<data-foo> or
C<aria-label>) are not accessible via AUTOLOAD since hyphens are not valid
in Perl method names. Use L<Mojo::DOM/attr> directly for those:

  $dom->attr('aria-label');
  $dom->attr('data-foo');

Or use L</data> for C<data-*> attributes specifically.

=head1 CAVEATS

If a future version of L<Mojo::DOM> introduces a method whose name clashes
with an HTML attribute you are accessing via AUTOLOAD, the real method will
take precedence and AUTOLOAD will not fire. Use L<Mojo::DOM/attr> directly
in that case.

=head1 SEE ALSO

L<Mojo::DOM>, L<Mojo::Role>

=head1 AUTHOR

Simone Cesano <scesano@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Simone Cesano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
