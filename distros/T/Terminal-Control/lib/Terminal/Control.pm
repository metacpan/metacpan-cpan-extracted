package Terminal::Control;

# Load the Perl pragmas.
use 5.030000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use Exporter;

# Load Perl modules.
use bytes;

# Declare global variable
my $is_eval;

# BEGIN block.
BEGIN {
    # Try to load sys/ioctl.ph.
    $is_eval = ((eval "require 'sys/ioctl.ph'") ? 1 : 0);
    if ($is_eval ne 1) {
        # Print message into the terminal window.
        print "sys/ioctl.ph is missing\n";
        # Assign winsize to winsize_stty.
        *winsize = \&winsize_stty;
    } else {
        # Assign winsize to winsize_ioctl.
        *winsize = \&winsize_ioctl;
    };
    # Define subroutine aliases.
    *reset_terminal = \&reset_screen;
    *clear_terminal = \&clear_screen;
    *reset = \&reset_screen;
    *clear = \&clear_screen;
};

# Set the package version. 
our $VERSION = '0.04';

# Base class of this module.
our @ISA = qw(Exporter);

# Exporting the implemented subroutines.
our @EXPORT = qw(
                 reset_screen
                 clear_screen
                 reset_terminal  
                 clear_terminal  
                 reset
                 clear
                 winsize
                 chars
                 pixels
                 get_cursor_position
                 set_cursor_position
                 echo_on
                 echo_off 
                 cursor_on
                 cursor_off
);

# Set the global variables.
our($ESC, $CSI);

# Set the Control Sequence Introducer (CSI).
$CSI = "\033[";
$ESC = "\033";

#------------------------------------------------------------------------------# 
# Subroutine clear_screen                                                      #
#                                                                              #
# Description:                                                                 #
# Clear the terminal window using escape sequences.                            #
#------------------------------------------------------------------------------# 
sub clear_screen {
    # Clear screen.
    my $escseq = "${CSI}2J${CSI}1;1H";
    # Get length of the escape sequence.
    my $buflen = length($escseq);
    # Write escape sequence to STDOUT.
    syswrite(STDOUT, $escseq, $buflen, 0);
};

#------------------------------------------------------------------------------# 
# Subroutine reset_screen                                                      #
#                                                                              #
# Description:                                                                 #
# Reset the terminal window using escape sequences.                            #
#------------------------------------------------------------------------------# 
sub reset_screen {
    # Reset screen. 
    my $escseq = "${ESC}c";
    # Get length of the escape sequence.
    my $buflen = length($escseq);
    # Write escape sequence to STDOUT.
    syswrite(STDOUT, $escseq, $buflen, 0);
};

#------------------------------------------------------------------------------# 
# Subroutine cursor_on                                                         #
#                                                                              #
# Description:                                                                 # 
# Shows the cursor in the terminal window. Perform a system call on stty. Use  #
# stty for reading from tty and writing to tty. Redirect stderr to stdout.     #
#------------------------------------------------------------------------------# 
sub cursor_on {
    # Show the cursor.
    print "${CSI}?25h";
};

#------------------------------------------------------------------------------# 
# Subroutine cursor_off                                                        #
#                                                                              #
# Description:                                                                 # 
# Hides the cursor in the terminal window. Perform a system call on stty. Use  #
# stty for reading from tty and writing to tty. Redirect stderr to stdout.     #
#------------------------------------------------------------------------------# 
sub cursor_off {
    # Hides the cursor.
    print "${CSI}?25l";
};

#------------------------------------------------------------------------------# 
# Subroutine echo_on                                                           #
#                                                                              #
# Description:                                                                 # 
# Shows user input in the terminal window. Perform a system call on stty. Use  #
# stty for reading from tty and writing to tty. Redirect stderr to stdout.     #
#------------------------------------------------------------------------------# 
sub echo_on {
    # Turn echo on.
    system("stty echo </dev/tty >/dev/tty 2>&1");
};

#------------------------------------------------------------------------------# 
# Subroutine echo_off                                                          #
#                                                                              #
# Description:                                                                 # 
# Hides user input in the terminal window. Perform a system call on stty. Use  #
# stty for reading from tty and writing to tty. Redirect stderr to stdout.     #
#------------------------------------------------------------------------------# 
sub echo_off {
    # Turn echo off.
    system("stty -echo </dev/tty >/dev/tty 2>&1");
};

#------------------------------------------------------------------------------# 
# Subroutine get_cursor_position                                               #
#                                                                              #
# Description:                                                                 #
# Get the position of the cursor in the terminal window.                       #
#------------------------------------------------------------------------------# 
sub get_cursor_position {
    # Initialise the local variables.
    my $seq = '';
    my $chr = '';
    # Change the settings of the terminal window.
    system "stty cbreak -echo </dev/tty >/dev/tty 2>&1";
    # Print escape sequence.
    print STDOUT "${CSI}6n";
    # Read chars von STDIN.
    while (($chr = getc(STDIN)) ne "R") {
        $seq .= $chr;
    };
    # Restore the settings of the terminal window.
    system "stty -cbreak echo </dev/tty >/dev/tty 2>&1";
    # Get rows and cols.
    my ($y, $x) = $seq =~ m/(\d+)\;(\d+)/;
    # Return rows and cols.
    return ($y, $x)
};

#------------------------------------------------------------------------------# 
# Subroutine set_cursor_position                                               #
#                                                                              #
# Description:                                                                 #
# Set the position of the cursor in the terminal window. Moves the cursor to   #
# row n and column m. The top left corner is row 1 and column 1.               #
#------------------------------------------------------------------------------# 
sub set_cursor_position {
    # Assign the subroutine arguments to the local variables.
    my ($n, $m) = @_;
    # Set the new cursor position.
    print "${CSI}${n};${m}H";
};

#------------------------------------------------------------------------------# 
# Subroutine winsize                                                           #
#                                                                              #
# Description:                                                                 #
# Get winsize using system ioctl call.                                         #
#------------------------------------------------------------------------------# 
sub winsize_ioctl {
    # Initialise the variable $winsize. 
    my $winsize = "";
    # Check the ioctl call of TIOCGWINSZ.
    my ($rows, $cols, $xpix, $ypix) = ((ioctl(STDOUT, TIOCGWINSZ(), $winsize)) ?
                                       (unpack 'S4', $winsize) :
                                       (map {$_ * 0} (1..4)));
    # Return rows, cols and xpix, ypix.
    return ($rows, $cols, $xpix, $ypix);
};

#------------------------------------------------------------------------------# 
# Subroutine winsize                                                           #
#                                                                              #
# Description:                                                                 #
# Get winsize using system stty.                                               #
#------------------------------------------------------------------------------# 
sub winsize_stty {
    # Initialise the local variable.
    my $winsize = "";
    # Get winsize from stty.
    $winsize = `stty size`;
    my ($x, $y) = $winsize =~ m/(\d+) (\d+)/s;
    # Create list with rows, cols, xpix and ypix. 
    my ($rows, $cols, $xpix, $ypix) = ($x, $y, -1, -1);
    # Return rows, cols and xpix, ypix.
    return ($rows, $cols, $xpix, $ypix);
};

#------------------------------------------------------------------------------# 
# Subroutine chars                                                             #
#                                                                              #
# Description:                                                                 #
# Get rows and columns using system ioctl call.                                #
#------------------------------------------------------------------------------# 
sub chars {
    # Declare rows and columns.
    my ($rows, $cols) = (undef, undef);
    # Get a list from winsize.
    my @list = winsize();
    # Extract rows and columns.
    ($rows, $cols) = ($list[0], $list[1]);
    # Return chars.
    return ($rows, $cols);
};

#------------------------------------------------------------------------------# 
# Subroutine pixels                                                            #
#                                                                              #
# Description:                                                                 #
# Get pixels using system ioctl call.                                          #
#------------------------------------------------------------------------------# 
sub pixels {
    # Declare xpix and ypix.
    my ($xpix, $ypix) = (undef, undef);
    # Get a list from winsize.
    my @list = winsize();
    # Extract xpix and ypix.
    ($xpix, $ypix) = ($list[2], $list[3]);
    # Return pixels.
    return ($xpix, $ypix);
};

1;

__END__
# Below is the package documentation.

=head1 NAME

Terminal::Control - Perl extension for terminal control

=head1 SYNOPSIS

  use Terminal::Control;

  # Clear screen.
  clear_screen();

  # Reset screen.
  reset_screen();

  # Get terminal size and print to screen.
  my ($rows, $cols, $xpix, $ypix) = winsize();
  printf ("%s\n%s\n%s\n%s\n", $rows, $cols, $xpix, $ypix);

  # Get chars and print to screen.
  ($rows, $cols) = chars();
  printf ("%s\n%s\n", $rows, $cols);

  # Get pixels and print to screen. 
  ($xpix, $ypix) = pixels();
  printf ("%s\n%s\n", $xpix, $ypix);

  # Get cursor position.
  my ($y, $x) = get_cursor_position();
  printf ("%s\n%s\n", $y, $x);

  # Set cursor position.
  my $rows = 20; 
  my $cols = 80; 
  set_cursor_position(20, 80);

=head1 Aliases

  reset_terminal <= reset_screen;
  clear_terminal <= clear_screen;
  reset          <= reset_screen;
  clear          <= clear_screen;

=head1 Requirement

The Perl header 'sys/ioctl.ph' is required for ioctl and TIOCGWINSZ.

=head1 DESCRIPTION

=head2 Implemented Methods

The following methods have been implemented so far:

=over 4 

=item * clear_screen()

=item * reset_screen()

=item * get_cursor_position()

=item * set_cursor_position()

=item * winsize()

=item * chars()

=item * pixels()

=item * echo_on()

=item * echo_off()

=item * cursor_on()

=item * cursor_off()

=back

=head2 Method description

The method clear_screen is clearing the terminal. This is similar to the system call system('clear').
The method reset_screen is reseting the terminal. This is similar to the system call system('reset').

The method winsize gets the dimensions in x-direction and y-direction of the terminal. The methods chars
and pixels extract chars (rows and cols) and pixels (xpix and ypix.)

The method get_cursor_position() gets the current cursor position in the terminal window. The method
set_cursor_position() sets the cursor position in the terminal window.
 

=head1 Programmable background

The methods clear_screen and reset_screen are using escape sequences. Doing this
no other Perl modules are needed to clear and reset a screen. Both are in principle
one liners.

The method winsize is using the C/C++ header for the system ioctl call and there
the command TIOCGWINSZ. The call return winsize in rows and cols and xpix and ypix.

=head1 SEE ALSO

ASCII escape sequences

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
