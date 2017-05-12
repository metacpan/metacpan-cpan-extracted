package Pod::Abstract::Serial;
use strict;
our $VERSION = '0.20';

my $serial_number = 0;

=head1 NAME

Pod::Abstract::Serial - generate a global sequence of serial numbers.

=head1 DESCRIPTION

Used to number Pod::Abstract::Node elements for identification.

=head1 BUGS

This will cause problems with Pod::Abstract documents frozen to disk
using Data::Dumper etc, unless C<set> is used to bump the number above
the highest number read.

Or just serialise your document with C<< $node->pod >> instead!

=cut

sub next {
    return ++$serial_number;
}

sub last {
    return $serial_number;
}

sub set {
    $serial_number = shift;
}

=head1 AUTHOR

Ben Lilburne <bnej@mac.com>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 Ben Lilburne

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
