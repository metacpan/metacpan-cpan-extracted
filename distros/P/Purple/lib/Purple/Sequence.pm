package Purple::Sequence;

use strict;
use warnings;

sub increment_nid {
    my $old_nid = shift;

    my @oldValues = split('', $old_nid);
    my @newValues;
    my $carryBit = 1;

    foreach my $char (reverse(@oldValues)) {
        if ($carryBit) {
            my $newChar;
            ($newChar, $carryBit) = _incChar($char);
            push(@newValues, $newChar);
        } else {
            push(@newValues, $char);
        }
    }
    push(@newValues, '1') if ($carryBit);
    return join('', (reverse(@newValues)));
}

sub _incChar {
    my $char = shift;

    if ($char eq 'Z') {
        return '0', 1;
    }
    if ($char eq '9') {
        return 'A', 0;
    }
    if ($char =~ /[A-Z0-9]/) {
        return chr(ord($char) + 1), 0;
    }
}

1;

=head1 NAME

Purple::Sequence - Generate the next NID in a Sequence of NIDs

=head1 SYNOPSIS

This module contains the code for calculating the next NID 
in a sequence of Purple Numbers.

    my $next_nid = Purple::Sequence::increment_nid($current_nid);

=head1 FUNCTIONS

=head2 increment_nid($current_nid)

Returns the next NID after $current_nid.

=head1 AUTHORS

Chris Dent, E<lt>cdent@burningchrome.comE<gt>

Eugene Eric Kim, E<lt>eekim@blueoxen.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-purple@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Purple>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 COPYRIGHT & LICENSE

(C) Copyright 2006 Blue Oxen Associates, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Purple::Sequence
