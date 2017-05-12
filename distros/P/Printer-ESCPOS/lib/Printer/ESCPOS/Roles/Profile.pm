use strict;
use warnings;

package Printer::ESCPOS::Roles::Profile;

# PODNAME: Printer::ESCPOS::Roles::Profile
# ABSTRACT: Role for all Printer Profiles for L<Printer::ESCPOS>
#
# This file is part of Printer-ESCPOS
#
# This software is copyright (c) 2017 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '1.006'; # VERSION

# Dependencies
use 5.010;
use Moo::Role;
requires 'init';


has driver => (
    is       => 'rw',
    required => 1,
);


has usePrintMode => (
    is      => 'rw',
    default => '0',
);


has fontStyle => (
    is      => 'rw',
    default => 'a',
);


has emphasizedStatus => (
    is      => 'rw',
    default => 0,
);


has heightStatus => (
    is      => 'rw',
    default => 0,
);


has widthStatus => (
    is      => 'rw',
    default => 0,
);


has underlineStatus => (
    is      => 'rw',
    default => 0,
);


sub text {
    my ( $self, $text ) = @_;
    $self->driver->write($text);
}


sub print {
    my ( $self, $text ) = @_;
    $self->driver->print($text);
}


sub read {
    my ( $self, $bytes ) = @_;
    if ( $self->driver->can('read') ) {
        return $self->driver->read($bytes);
    }
    else {
        die
"read is not supported by the Printer Driver in use use a different driverType $!";
    }
}

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Roles::Profile - Role for all Printer Profiles for L<Printer::ESCPOS>

=head1 VERSION

version 1.006

=head1 ATTRIBUTES

=head2 driver

Stores the connection object from the Printer::ESCPOS::Connections::*. In any normal use case you must not modify this
attribute.

=head2 usePrintMode

Use Print mode to set font, underline, double width, double height and emphasized if false uses the individual command
ESC M n for font "c" ESC M is forced irrespective of this flag

=head2 fontStyle

Set ESC-POS Font pass "a" "b" or "c". Note "c" is not supported across all printers.

=head2 emphasizedStatus

Set/unset emphasized property

=head2 heightStatus

set unset double height property

=head2 widthStatus

set unset double width property

=head2 underlineStatus

Set/unset underline property

=head1 METHODS

=head2 text

Sends raw text to the local buffer ready for sending this to the printer. This would contain a set of strings to print
or ESCPOS Codes.

    $device->printer->text("Hello World\n");

=head2 print

prints data in the buffer

=head2 read

Reads n bytes from the printer. This function is used internally to get printer statuses when supported.

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
