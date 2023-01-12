package Termbox::Cell 0.12 {
    use 5.020;
    use strictures 2;
    use warnings;
    #
    use FFI::Platypus::Record;
    record_layout_1(
        qw[
            uint32_t ch
            uint16_t fg
            uint16_t bg
        ]
    );
}
#
1;
__END__

=encoding utf-8

=head1 NAME

Termbox::Cell - A Single Conceptual Entity on the Terminal Screen

=head1 SYNOPSIS

=head2 Description

The terminal screen is basically a 2d array of cells.

=head1 Methods

Each cell contains the following values:

=head2 C<ch( )>

A single Unicode character, if available.

=head2 C<fg( )>

The foreground color within the cell.

=head2 C<bg( )>

The background color within the cell.

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
