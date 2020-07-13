package Termbox::Event {
    use 5.020;
    use strictures 2;
    use warnings;
    our $VERSION = "0.10";
    #
    use FFI::Platypus::Record;
    record_layout_1(
        qw[
            uint8_t  type
            uint8_t  mod
            uint16_t key
            uint32_t ch
            int32_t  w
            int32_t  h
            int32_t  x
            int32_t  y
            ]
    );
}

1;

__END__

=encoding utf-8

=head1 NAME

Termbox::Event - A Single User Interaction

=head1 SYNOPSIS

=head2 Description

This class represents an event or single interaction from the user.

=over

=item The C<mod( )> and C<ch( )> values are valid if C<type( )> is C<TB_EVENT_KEY>.

=item The C<w( )> and C<h( )> values are valid if C<type( )> is C<TB_EVENT_RESIZE>.

=item The C<x( )> and C<y( )> values are valid if C<type( )> is C<TB_EVENT_MOUSE>.

=item The C<key( )> value is valid if C<type( )> is either C<TB_EVENT_KEY> or C<TB_EVENT_MOUSE>.

=item The C<key( )> and <ch( )> values are mutually exclusive; only one of them can be non-zero at a time.

=back

=head1 Methods

Events are loaded with a lot of data... user these methods to access it:

=head2 C<type( )>

The type of event. Please see the C<:type> import tag from Termbox.

=head2 C<mod( )>

Modifiers to either C<key( )> or C<ch( )> below.

=head2 C<key( )>

One of the C<TB_KEY_.+> constants imported from Termobx with the C<:key> tag.

=head2 C<ch( )>

A single unicode character, if available.

=head2 C<w( )>

The width of the event.

=head2 C<h( )>

The height of the event.

=head2 C<x( )>

The horizontal position of the event.

=head2 C<y( )>

The vertical position of the event.

=head1 Author

Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2020 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See
http://www.perlfoundation.org/artistic_license_2_0.  For clarification, see
http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
