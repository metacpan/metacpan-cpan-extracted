package Template::Plugin::Ligature;

use 5.006;
use strict;
use warnings;
use parent qw( Template::Plugin::Filter );
use Text::Ligature qw( to_ligatures );

our $VERSION = '0.04';

use constant FILTER_NAME => 'ligature';

sub init {
    my ($self) = @_;

    $self->install_filter(FILTER_NAME);

    return $self;
}

sub filter {
    my ($self, $text) = @_;

    return to_ligatures($text);
}

1;

__END__

=encoding utf8

=head1 NAME

Template::Plugin::Ligature - Typographic ligature filter for TT

=head1 VERSION

This document describes Template::Plugin::Ligature version 0.04.

=head1 SYNOPSIS

Template:

    [% USE Ligature %]

    [% FILTER ligature %]
    Offloading floral offices refines effectiveness.
    [% END %]

Output:

    Oﬄoading ﬂoral oﬃces reﬁnes eﬀectiveness.

=head1 DESCRIPTION

This is a L<Template::Toolkit> plugin to filter text, replacing sequences of
characters with corresponding typographic ligatures using L<Text::Ligature>.

When using this filter in HTML templates, one of the following steps will also
need to be performed in order to properly display these Unicode ligatures.

=over

=item * Set the C<charset> to C<UTF-8> in the HTTP response C<Content-Type>
header

    Content-Type: text/html; charset="UTF-8"

=item * Set the C<charset> to C<UTF-8> in the HTML C<Content-Type> meta
element

    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

=item * Convert the ligatures to HTML entities using the C<html_entity> filter

    [% $content | ligature | html_entity %]

=back

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2011, 2012 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
