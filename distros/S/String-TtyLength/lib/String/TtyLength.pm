package String::TtyLength;
$String::TtyLength::VERSION = '0.01';
use 5.006;
use strict;
use warnings;
use parent 'Exporter';

our @EXPORT_OK = qw/ tty_length /;

my $cursor_position     = qr/\e\[[0-9]+;[0-9]+[Hf]/;
my $cursor_movement     = qr/\e\[[0-9]+[ABCD]/;
my $save_restore_cursor = qr/\e\[[su]/;
my $clear_screen        = qr/\e\[2J/;
my $erase_line          = qr/\e\[K/;
my $graphics_mode       = qr/\e\[[0-9]+(;[0-9]+)*m/;
my $ansi_code           = qr/
                            (
                              $cursor_position
                            | $cursor_movement
                            | $save_restore_cursor
                            | $clear_screen
                            | $erase_line
                            | $graphics_mode
                            )
                            /x;

                            

sub tty_length
{
    my $string = shift;
    return length(remove_ansi_codes($string));
}

# might make this an exportable function
# as well, but not sure what the right name is :-)
sub remove_ansi_codes
{
    my $string = shift;
    $string =~ s/$ansi_code//mosg;
    return $string;
}

1;

__END__

=pod

=encoding utf8

=head1 NAME

String::TtyLength - calculate length of string excluding ANSI tty codes

=head1 SYNOPSIS

 use Text::Table::Tiny / tty_length /;
 $length = tty_length("\e[1mbold text\e[0m");
 print "length = $length\n";

 # 9

=head1 DESCRIPTION

This module provides a single function, C<tty_length>,
which returns the length of a string excluding any ANSI
tty / terminal escape codes.
I.e. the number of characters that will appear on screen.
This is useful if you're working out the width of columns,
or aligning text.

=head2 tty_length( STRING )

Takes a single string,
and returns the length of the string,
excluding any escape sequences.

Note: the escape sequences could include cursor movement,
so the length returned by this function might not be the
number of characters that would be visible on screen.
But C<length_of_string_excluding_escape_sequences()>
was just too long.


=head1 REPOSITORY

L<https://github.com/neilb/String-TtyLength>


=head1 AUTHOR

Neil Bowers <neilb@cpan.org>


=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Neil Bowers.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

