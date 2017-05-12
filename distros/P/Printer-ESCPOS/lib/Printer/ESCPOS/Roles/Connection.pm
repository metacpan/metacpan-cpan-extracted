use strict;
use warnings;

package Printer::ESCPOS::Roles::Connection;

# PODNAME: Printer::ESCPOS::Roles::Connection
# ABSTRACT: Role for Connection Classes for L<Printer::ESCPOS>
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

has _buffer => (
    is      => 'rw',
    default => '',
);


sub write {
    my ( $self, $raw ) = @_;

    $self->_buffer( $self->_buffer . $raw );
}


sub print {
    my ( $self, $raw ) = @_;
    my @chunks;

    my $printString;
    if ( defined $raw ) {
        $printString = $raw;
    }
    else {
        $printString = $self->_buffer;
        $self->_buffer('');
    }
    my $n = 64;    # Size of each chunk in bytes

    @chunks = unpack "a$n" x ( ( length($printString) / $n ) - 1 ) . "a*",
      $printString;
    for my $chunk (@chunks) {
        $self->_connection->write($chunk);
    }
}

1;

__END__

=pod

=head1 NAME

Printer::ESCPOS::Roles::Connection - Role for Connection Classes for L<Printer::ESCPOS>

=head1 VERSION

version 1.006

=head1 METHODS

=head2 write

Writes prepared data to the module buffer. This data is dispatched to printer with print() method. The print method
takes care of buffer control issues.

=head2 print

If a string is passed then it passes the string to the printer else passes the buffer data to the printer and clears
the buffer.

    $device->printer->print(); # Prints and clears the Buffer.
    $device->printer->print($raw); # Prints $raw

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
