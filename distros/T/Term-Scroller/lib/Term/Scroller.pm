package Term::Scroller;

use 5.020;
use strict;
use warnings;

use feature 'unicode_strings';

our $VERSION = '1.3';

=head1 NAME

Term::Scroller - Display text in a scrolling viewport in your terminal

=head1 SYNOPSIS

    use Term::Scroller;
    
    # Default options
    my $scroll = Term::Scroller->new();
    print $scroll "blah blah blah\n" for (1..100);
    # You should always call the end() method when you're done
    $scroll->end();

    # Some more options (limited window size, with a border)
    $scroll = scroller(width => 40, height => 5, window => '-#-#-#-#');
    print $scroll "beee daah booo\n" for (1..100);
    $scroll->end();

    # See the rest of the documentation for more options!

=head1 DESCRIPTION

B<Term::Scroller> provides you with a way to view a large stream of text
inside a small, scrolling viewport on your terminal. The size and borders of
the viewport/window can be customized along with a number of other control
options.

For a command-line program that uses this to display the output of commands
see L<scroller>.

=cut

use IO::Handle;

use Carp;
use Symbol qw(qualify_to_ref);
use Scalar::Util qw(openhandle);
use List::Util qw(any);

use IO::Pty;
use Term::ReadKey qw(GetTerminalSize);

use Term::Scroller::Linefeed qw(linefeed);

our @ISA = qw(IO::Pty);

=head1 Methods

=head2 new

Returns a new scroller instance. The scroller is a filehandle 
(actually an instance of L<IO::Pty>) where anything written to 
it is displayed in the scrolling window. The scroller will sanitize any
cursor-related ANSI escape sequences so text that expects them to work might
look garbled, but at least it should be very difficult to escape or break the
window. color-related ANSI sequences are left untouched though so colored
text will still work inside the window.

I<Don't forget to call the 'end' method when you're done with it!>

The arguments to B<scroller> are interpreted as a hash and can contain the
following options:

=head3 Size & Styling Options

=over 4

=item * B<height>

Integer representing the maximum height (in lines) of the viewport. The window
will grow as more lines of input come in and start scrolling once it reaches
this height. (B<Default>: 10)

=item * B<width>

Integer representing the maximum width (in columns) of the viewport. Input lines
will truncated at this width, not including ANSI escape sequences.
(B<Default>: the width of the connected terminal, or 80 if the width
couldn't be determined for some reason).

=item * B<tabwidth>

Integer representing the width of tabs (in characters) when viewed in the
viewport. For consistent printing, tabs are replaced with this number of
spaces. (B<Default>: 4)

=item * B<style>

A string representing an ANSI color escape sequence used to style the text
displayed inside the window. If this is set, it will override any color
escape sequences in the input text. This can be a raw escape sequence (e.g
"\033[2m" for faded text) or a constant from the L<Term::ANSIColor> module.
(B<Default>: undef).

=item * B<window>

A string specifying the characters to use when drawing a border around the
window. See the B<WINDOW DRAWING> section for how to create a border
specification. The documentation for L<scroller> also has some examples you
can copy from. (B<Default>: undef, so no borders, if only we could live
in such a world)

=back

=head3 Control Options

=over 4

=item * B<out>

Filehandle to write/draw the window to. Naturally, this should be connected to
a terminal. (B<Default>: the currently selected filehandle, so C<STDOUT> unless
you selected something else first).

=item * B<hide>

If true, the window will be erased once its done (i.e. once you close the
input filehandle). Otherwise, the window remains with the last lines of text
still visible. (B<Default>: False).

=item * B<passthrough>

If this is an open filehandle, input text will also be passed through to this
filehandle completely unaltered. Useful if you want a record of all the text
that went through the window.

=back

=cut

sub new {
    my $class = shift;

    my %params = @_;
    my $outfh       = $params{out}          // qualify_to_ref(select);
    my $buf_height  = $params{height}       // 10;
    my $buf_width   = $params{width}        // (GetTerminalSize $outfh)[0] // 80;
    my $tab_width   = $params{tabwidth}     // 4;
    my $style       = $params{style};
    my $windowspec  = $params{window};
    my $hide        = $params{hide}         // 0;
    my $passthru    = $params{passthrough};

    my $pty     = IO::Pty->new;

    defined(my $pid = fork)     or croak "unable to fork: $!";

    # Parent: Return the new scroller
    if ($pid) {
        bless $pty => $class;
        ${*$pty}{'term_scroller_pid'} = $pid;
        return $pty;
    }

    ################################################
    # Forked child: reads pty and writes to output
    ################################################

    close $pty;
    select $outfh;

    my @buf;

    my $tab = " "x$tab_width;

    # Parse window
    my $line_end   = "";
    my $line_start = "";
    my $window_top;
    my $window_bot;
    my $window_extra_height = 0; # Height of window top + bottom

    if (defined $windowspec) {
        my %window  = _parse_window_spec($windowspec);
        $line_start = $window{left}  // "";
        $line_end   = $window{right} // "";

        if ($window{hastop}) {
            $window_extra_height++;
            $window_top = ( $window{topleft}  // " " ) .
                          ( $window{top}      // " " ) x ($buf_width-2) .
                          ( $window{topright} // " " );
        }
        if ($window{hasbot}) {
            $window_extra_height++;
            $window_bot = ( $window{botleft}  // " " ) .
                          ( $window{bot}      // " " ) x ($buf_width-2) .
                          ( $window{botright} // " " );
        }

        $buf_width -= ( length($line_start) + length($line_end) );
    }

    my $firstline = 1;

    while (my $line = linefeed($pty)) {

        print $passthru $line if openhandle($passthru);

        if ($firstline) {
            print "$window_top\n" if defined $window_top;
            print "$window_bot\n" if defined $window_bot;
            $firstline = 0;
        }

        chomp $line;
        $line =~ s/\t/$tab/g;
        my $to_print = "";

        if (defined $style) {
            # Remove all escape sequences
            $line =~ s/\033\[\d*(?>(;\d*)+)*[A-HJKSTfm]//g;
            # Pad
            if (length $line < $buf_width and $line_end) {
                $line .= " " x ($buf_width - length $line);
            }
            # Crop to buffer, add style
            $to_print = $style . (substr $line, 0, $buf_width) . "\033[0m";
        }
        else {
            # Remove cursor-changing escape sequences
            $line =~ s/\033\[\d*(?>(;\d*)+)*[A-HJKSTf]//g;
            # Crop to buffer, keeping remaining escapes intact
            $to_print = _crop_to_width($line, $buf_width, $line_end ? " " : "");
        }

        $to_print = $line_start . $to_print . $line_end;

        # Uncomment to just print line
        #print "$to_print\n"; next;

        # Print next frame:
        my $height = @buf + $window_extra_height;     # Reset cursor back to top
        print "\033[$height;F" if $height > 0; 
        push @buf, $to_print;                         # Add line to buffer and rotate
        shift @buf if @buf > $buf_height;   
        print "$window_top\n" if defined $window_top; # Print frame
        print "$_\033[K\n"  for (@buf);     
        print "\033[0m";
        print "$window_bot\n" if defined $window_bot;
    }

    close $passthru if openhandle($passthru);

    if ($hide) {
        # Erase buffer
        print "\033[1;F\033[K" for (1..@buf+$window_extra_height)
    }

    exit
}

=head2 pid

Every scroller instance uses a forked child process that reads the
psuedoterminal and draws the window to the terminal. This method returns the
pid of an instance's associated fork.
=cut
sub pid {
    my $self = shift;
    return ${*$self}{'term_scroller_pid'};
}

=head2 end

This is the preferred way to stop using a scroller. Simply closing the
filehandle will immediately destroy the allocated pty which means any text that
the window hasn't drawn yet will be lost. This method will safely wait for the
child process to catch up before closing by sending an explicit C<EOF> to the
pty, waiting on the child process and then finally closing the filehandle.
Returns the exit status of the instance's child process.
=cut
sub end {
    my $self = shift;
    print $self "\04\n\04";
    $self->flush;
    waitpid($self->pid, 0);
    return $?;
}

=head1 WINDOW DRAWING

A window specification is a string up to 8 characters long indicating which character
to use for a part of the window, in clockwise order. That is, the characters
specify the top side, top-right corner, right side, bottom-right corner,
bottom side, bottom-left corner, left side and top-left corner respectively.
If any character is a whitespace or is missing (due to the string not being
long enough), then that part of the window will not be drawn.

=cut

#_crop_to_width STRING, LENGTH, PADDING
#
#Cut the given string down to LENGTH characters while keeping any 
#SGR ANSI esccape sequences intact. Return the new string.
#If PADDING is specified, the final string will be padded with the
#value of PADDING to reach the length of the buffer.
sub _crop_to_width {
    my $in  = shift;
    my $len = shift;
    my $pad = shift;

    # We need to crop the line to the width of the buffer, but keep
    # any SGR (color/text-style) escape sequences intact. To do this,
    # we split the input line into chunks consisting of a run of
    # non-escape sequence characters optionally followed by one escape
    # sequence. We use these to rebuild the line that we're gonna print,
    # keeping all escape sequences, but stopping the regular text
    # at the width of the buffer.

    my $out    = "";   # line that will eventually get printed
    my $text_length = 0;    # length of text sequences so far
    my $sgr_split = qr{     # regex to split into text+sgr sequences
        (?<TEXT> .*? ) 
        (?<SGR>  \033\[\d+(?>(;\d*)+)*m )?
    }x;

    # Iterate through matches
    while ($in =~ m/$sgr_split/cg) {
        my $text = $+{TEXT} // "";
        my $sgr  = $+{SGR}  // "";

        # Add text if we haven't yet passed the buffer width
        if ($text_length < $len) {
            $text_length += length($text);
            # Crop to buffer width if we went over
            if ($text_length > $len) {
                $text = substr $text, 0, -( $text_length - $len );
                $text_length = $len;
            }
        # If we've already passed the buffer width, no more text
        } else {
            $text = "";
        }

        $out .= $text.$sgr;
    }

    if ($pad and $text_length < $len) {
        $out .= $pad x ( $len - $text_length );
    }

    return $out;
}

#_parse_window_spec EXPR
#
#Parse a window spec string and return a hash with the following fields for
#the pieces of the window (in clockwise order): top, topright, right, botright,
#bot, botleft, left, topleft. Any one of these fields may be undefined to
#indicate that it should be blank.
#
#The hash also has fields for each side of the window with a boolean value
#indicating whether that side is to be drawn (at least one of its side and
#two corners are specified): hastop, hasright, hasbot, hasleft.
sub _parse_window_spec {
    my $spec = shift;

    my %window;
    @window{qw' top topright right botright bot botleft left topleft '} = 
        map { m/\s/ ? undef : $_ } split(//, $spec);

    @window{qw' hastop hasright hasbot hasleft '} =
        map { any {defined $window{$_} } @$_ } (
            [qw' topleft    top     topright '], # top side
            [qw' topright   right   botright '], # right side
            [qw' botright   bot     botleft  '], # bottom side
            [qw' botleft    left    topleft  ']  # left side
        );

    return %window;
}

1;

=head1 SEE ALSO

L<scroller>

=head1 AUTHOR

Cameron Tauxe C<camerontauxe@gmail.com>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020 by Cameron Tauxe.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
