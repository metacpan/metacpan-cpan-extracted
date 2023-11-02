package String::Binary::Interpolation;

use strict;
use warnings;

# Yuck, semver. I give in, the stupid cult that doesn't understand
# what the *number* bit of *version number* means has won.
our $VERSION = '1.0.1';

sub import {
    my $victim = (caller(0))[0];
    foreach my $byte (0 .. 255) {
        no strict 'refs';
        *{sprintf('%s::b%08b', $victim, $byte)} = \chr($byte);
    }
}

1;

=head1 NAME

String::Binary::Interpolation - make it easier to interpolate binary bytes into a string

=head1 SYNOPSIS

Where you would previously have had to write something like this ...

    my $binary = "ABC@{[chr(0b01000100)]}E"

or ...

    my $binary = 'ABC'.chr(0b01000100).'E';

to interpolate some random byte into a string you can now do this ...

    use String::Binary::Interpolation;

    my $binary = "ABC${b01000100}E";

which I think you'll agree is much easier to read.

=head1 BUT WHY!?!?!?

Bit-fields, dear reader. If you are writing data to a binary file, and that
file contains bytes (or even longer words) which are bit-fields, it is easier
to have the bits of the bit-field right there in your string instead of having
to glue the string together from various parts, and it's far easier to read
than the frankly evil hack of embedding an array-ref.

=head1 OK, SO WHAT DOES IT DO?

When you C<use> the module all it does is create a bunch of varliables in
your namespace. They are named from C<$b00000000> to C<$b11111111> and their
values are the corresponding characters. NB that when writing files containing
characters with the high-bit set you need to be careful that you read and write
B<bytes> and not some unicode jibber-jabber.

=head1 SOURCE CODE REPOSITORY

L<https://github.com/DrHyde/perl-modules-String-Binary-Interpolation>

=head1 BUGS

Bug reports and requests for extra features should be made on Github.

=head1 AUTHOR

David Cantrell E<lt>david@cantrell.org.ukE<gt>

=head1 COPYRIGHT and LICENCE

Copyright (c) 2020 David Cantrell. This program is free software; you can
redistribute it and/or modify it under the terms of the Artistic Licence
or the GNU General Public Licence version 2, the full text of which is
included in this distribution, in the files ARTISTIC.txt and GPL2.txt.

=head1 SEE ALSO

L<perlop>'s section on quote and quote-like operators

