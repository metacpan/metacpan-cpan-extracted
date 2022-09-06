package Terminal::Control;

# Load the basic Perl pragmas.
use 5.030000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use Exporter;

# Load the neccessary Perl modules.
use bytes;
use Try::Catch;

# Set the package version. 
our $VERSION = '0.12';

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
    winsize_pixels
    screen_size_pixels
    screen_size_chars
    window_size_chars
    window_size_pixels
    ctlseqs_request
    on_echo
    off_echo
    winsize_ic
);

# Set the global variables.
our($ESC, $CSI, $OSC);

# Set some constants.
$ESC = "\033";  # Escape
$CSI = "\033["; # Control Sequence Introducer
$OSC = "\033]"; # Operating System Command

# Declare the global variables.
my $is_sysph;
my $is_alarm;
my $mod_alarm;
my $timeout;

# BEGIN block.
BEGIN {
    # Try to use Inline C program code.
    eval {use Inline 'C'; 1};
    # Try to load Time::HiRes
    eval {require Time::HiRes;
         Time::HiRes->import ( qw(ualarm) );
         1;
    };
    if ($@) {
        # On error use alarm.
        $mod_alarm = 'alarm';
        # Timeout is in seconds.
        $timeout = 1;
        # Set flag.
        $is_alarm = 1;
    } else {
        # On success use ualarm.
        $mod_alarm = 'ualarm';
        # Timeout is in microseconds.
        $timeout = 1000000;
        # Set flag.
        $is_alarm = 0; 
    };
    # Try to load sys/ioctl.ph.
    $is_sysph = ((eval "require 'sys/ioctl.ph'") ? 1 : 0);
    if ($is_sysph ne 1) {
        # Print message into the terminal window.
        print "sys/ioctl.ph is missing\n";
        # Assign winsize to winsize_stty.
        *winsize = \&winsize_stty;
    } else {
        # Assign winsize to winsize_ioctl.
        *winsize = \&winsize_ioctl;
    };
    # Define some subroutine aliases.
    *reset_terminal = \&reset_screen;
    *clear_terminal = \&clear_screen;
    *reset = \&reset_screen;
    *clear = \&clear_screen;
};

#------------------------------------------------------------------------------# 
# Subroutine clear_screen                                                      #
#                                                                              #
# Description:                                                                 #
# Clear the terminal window using escape sequences.                            #
#------------------------------------------------------------------------------# 
sub clear_screen {
    # Set command sequences for clear and home.
    my $clear = "2J";
    my $home = "1;1H";
    # Clear screen.
    my $escseq = "${CSI}${clear}${CSI}${home}";
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
    # Set the control sequence.
    my $ctl_seq = "?25h";
    # Show the cursor. Send command to the terminal.
    print "${CSI}${ctl_seq}";
};

#------------------------------------------------------------------------------# 
# Subroutine cursor_off                                                        #
#                                                                              #
# Description:                                                                 # 
# Hides the cursor in the terminal window. Perform a system call on stty. Use  #
# stty for reading from tty and writing to tty. Redirect stderr to stdout.     #
#------------------------------------------------------------------------------# 
sub cursor_off {
    # Set the control sequence.
    my $ctl_seq = "?25l";
    # Hide the cursor. Send command to the terminal.
    print "${CSI}${ctl_seq}";
};

#------------------------------------------------------------------------------# 
# Subroutine echo_on                                                           #
#                                                                              #
# Description:                                                                 # 
# Shows user input in the terminal window. Perform a system call on stty. Use  #
# stty for reading from tty and writing to tty. Redirect stderr to stdout.     #
#------------------------------------------------------------------------------# 
sub echo_on {
    # Turn echo on. Make use of system call of stty.
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
    # Turn echo off. Make use of system call of stty.
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
    my ($y, $x) = $seq =~ /(\d+)\;(\d+)/;
    # Return rows and cols.
    return ($y, $x);
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
# Subroutine ctlseqs_request                                                   #
#                                                                              #
# Description:                                                                 #
# Get the response from escape sequence.                                       #
#------------------------------------------------------------------------------# 
sub ctlseqs_request {
    # Assign the subroutine arguments to the local variables.
    my ($Ps, $user_timeout) = @_;
    # Get id from request.
    my $id = substr($Ps, 1);
    # Change the timeout if neccessary.
    $timeout = (defined $user_timeout) ? $user_timeout : $timeout;
    if ($is_alarm eq 1) {
        $timeout = int($timeout / 1000000);
    };
    $timeout = ($timeout <= 0) ? 1 : $timeout; 
    # Initialise the local variables.
    my ($width, $height) = undef;
    my $buf = '';
    my $chr = '';
    # Change the settings of the terminal window.
    system "stty cbreak -echo -echonl -echoke -echoe -isig </dev/tty >/dev/tty 2>&1";
    # Print the escape sequence to STDOUT.
    print STDOUT "${CSI}${Ps}t";
    # Non blocking reading from STDIN.
    my $match;
    my @nums;
    eval {
        # Define the alarm handler.
        local $SIG{ALRM} = sub {die "timeout"};
        # Start the alarm.
        eval "$mod_alarm $timeout";
        while (($chr = getc(STDIN)) ne "t") {
            $buf .= $chr;
        };
        # Stop the alarm.
        eval "$mod_alarm 0";
    };
    if ($@) {
         # print "timedout\n";
         try {
             die;
         } catch {
             system "stty -cbreak echo echonl echoke echoe isig </dev/tty >/dev/tty 2>&1";
             return (-3, -3);
         };
    } else {
        if ($buf eq '') {
            # Set width and height.
            ($width, $height) = (-1, -1);
        } else {
            my $re = qr/^.*(\d+\;\d+\;\d+).*$/;
            if ($buf =~ $re) {
                $match = $1;
                @nums = split(";", $match);
            };
            # Get width and height.
            if ($id eq $nums[0]) { 
                ($height, $width) = ($nums[1], $nums[2]);
            } else {
                ($height, $width) = (-2, -2);
            };
    };
    # Restore the settings of the terminal window.
    system "stty -cbreak echo echonl echoke echoe isig </dev/tty >/dev/tty 2>&1";
    # Return width and height.
    return ($height, $width);
    };
};

#------------------------------------------------------------------------------# 
# Subroutine window_size_pixels                                                #
#                                                                              #
# Description:                                                                 #
# Xterm Control Sequences                                                      #
# Request: CSI Ps t                                                            #
# Response: Ps = 14 -> Reports xterm window size in pixels as                  #
#                      CSI 4 ; width ; height t                                #
#------------------------------------------------------------------------------# 
sub window_size_pixels {
    # Set the timeout.
    my $timeout = $_[0];
    # Get width and height.
    my ($width, $height) = ctlseqs_request("14", $timeout);
    # Return height and width.
    return ($height, $width);
};

#------------------------------------------------------------------------------# 
# Subroutine screen_size_pixels                                                #
#                                                                              #
# Description:                                                                 #
# Xterm Control Sequences                                                      #
# Request: CSI Ps t                                                            #
# Response: Ps = 15 -> Reports xterm screen size in pixels as                  #
#                      CSI 5 ; width ; height t                                #
#------------------------------------------------------------------------------# 
sub screen_size_pixels {
    # Set the timeout.
    my $timeout = $_[0];
    # Get width and height.
    my ($width, $height) = ctlseqs_request("15", $timeout);
    # Return height and width.
    return ($height, $width);
};

#------------------------------------------------------------------------------# 
# Subroutine window_size_chars                                                 #
#                                                                              #
# Description:                                                                 #
# Xterm Control Sequences                                                      #
# Request: CSI Ps t                                                            #
# Response: Ps = 18 -> Reports xterm window size in chars as                   #
#                      CSI 8 ; height ; width t                                #
#------------------------------------------------------------------------------# 
sub window_size_chars {
    # Set the timeout.
    my $timeout = $_[0];
    # Get height and width.
    my ($height, $width) = ctlseqs_request("18", $timeout);
    # Return height and width.
    return ($height, $width);
};

#------------------------------------------------------------------------------# 
# Subroutine screen_size_chars                                                 #
#                                                                              #
# Description:                                                                 #
# Xterm Control Sequences                                                      #
# Request: CSI Ps t                                                            #
# Response: Ps = 19 -> Reports xterm window size in chars as                   #
#                      CSI 9 ; height ; width t                                #
#------------------------------------------------------------------------------# 
sub screen_size_chars {
    # Set the timeout.
    my $timeout = $_[0];
    # Get height and width.
    my ($height, $width) = ctlseqs_request("19", $timeout);
    # Return height and width.
    return ($height, $width);
};

#------------------------------------------------------------------------------# 
# Subroutine winsizwe_pixels                                                   #
#                                                                              #
# Description:                                                                 #
# Get winsize in pixels.                                                       #
#------------------------------------------------------------------------------# 
sub winsize_pixels {
    # Initialise the local variables.
    my $seq = '';
    my $chr = '';
    # Change the settings of the terminal window.
    system "stty cbreak -echo </dev/tty >/dev/tty 2>&1";
    # Print escape sequence.
    print STDOUT "${CSI}14t";
    # Read chars von STDIN.
    while (($chr = getc(STDIN)) ne "t") {
        $seq .= $chr;
    };
    # Restore the settings of the terminal window.
    system "stty -cbreak echo </dev/tty >/dev/tty 2>&1";
    # Get rows and cols.
    my ($x, $y) = $seq =~ m/(\d+)\;(\d+)$/;
    # Return rows and cols.
    return ($x, $y)
};

#------------------------------------------------------------------------------# 
# Subroutine winsize                                                           #
#                                                                              #
# Description:                                                                 #
# Get winsize using system ioctl call.                                         #
#------------------------------------------------------------------------------# 
sub winsize_ioctl {
    # Initialise the local variables.
    my ($rows, $cols, $xpix, $ypix) = (undef, undef, undef, undef);
    my $winsize = "";
    # Try to get the winsize.
    try {
        # Check the ioctl call of TIOCGWINSZ.
        ($rows, $cols, $xpix, $ypix) = ((ioctl(STDOUT, TIOCGWINSZ(), $winsize)) 
            ? (unpack 'S4', $winsize) : (map {$_ * 0} (1..4)));
    } catch {
        ($rows, $cols, $xpix, $ypix) = (-1, -1, -1, -1);
    };
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
    $winsize = qx/stty size/;
    my ($y, $x) = $winsize =~ m/(\d+) (\d+)/s;
    # Create list with rows, cols, xpix and ypix. 
    my ($rows, $cols, $xpix, $ypix) = ($y, $x, -1, -1);
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

__DATA__

__C__
#include <sys/ioctl.h>
#include <stdio.h>
#include <termios.h>

/* Ref.: termios(3) — Linux manual page
 *
 * struct termios {
 *       tcflag_t c_iflag;     => input modes
 *       tcflag_t c_oflag;     => output modes
 *       tcflag_t c_cflag;     => control modes
 *       tcflag_t c_lflag;     => local modes
 *       cc_t     c_cc[NCCS];  => special characters
 * }
*/

/* Pointer to the termios structure. */
struct termios term;

/*
 * Function: on_echo()
 * -------------------
 */
int on_echo() {
    /* Read attributes, modify attributes and write attributes back. */
    tcgetattr(fileno(stdin), &term);
    term.c_lflag |= ECHO;
    tcsetattr(fileno(stdin), 0, &term);
    /* Return 1. */
    return 1;
};

/*
 * Function: off_echo()
 * --------------------
 */
int off_echo() {
    /* Read attributes, modify attributes and write attributes back. */
    tcgetattr(fileno(stdin), &term);
    term.c_lflag &= ~ECHO;
    tcsetattr(fileno(stdin), 0, &term);
    /* Return 1. */
    return 1;
};

/* Define the function io_on(). */
/* 
 * Function: io_on()
 * -----------------
 */
int io_on() {
    /* Read attributes, modify attributes and write attributes back. */
    tcgetattr(fileno(stdin), &term);
    term.c_lflag |= (ECHO | ICANON);
    tcsetattr(fileno(stdin), 0, &term);
    /* Return 1. */
    return 1;
}

/* 
 * Function: io_off()
 * ------------------
 */
int io_off() {
    /* Read attributes, modify attributes and write attributes back. */
    tcgetattr(fileno(stdin), &term);
    term.c_lflag &= ~(ECHO | ICANON);
    tcsetattr(fileno(stdin), 0, &term);
    /* Return 1. */
    return 1;
};

/* 
 * Function: int_str()
 * -------------------
 *
 * Cast short integer variables to string variables of type char.
 *
 * Args:
 *     len    int       Length of value
 *     value  uint16_t  Short integer number
 *
 * Returns:  
 *     str    char*     Integer as string
 */
char* int_str(int len, uint16_t value) {
    /* Allocate memory for the string variable. */   
    char* str = malloc(len + 1);
    snprintf(str, len + 1, "%d", value);
    return str;
};

/* 
 * Function: winsize()
 * -------------------
 * 
 * Get the window size of a terminal window.  
 *
 * Ref.: ioctl_tty(2) — Linux manual page
 * struct winsize {
 *     unsigned short (uint16_t) ws_row;
 *     unsigned short (uint16_t) ws_col;
 *     unsigned short (uint16_t) ws_xpixel; 
 *     unsigned short (uint16_t) ws_ypixel;
 * };
 */
int winsize_ic(SV* var1, SV* var2, SV* var3, SV* var4) {
    /* Assign struct to ws. */
    struct winsize ws;
    ioctl(STDIN_FILENO, TIOCGWINSZ, &ws);
    /* Cast short integers to strings. */ 
    int len1 = snprintf(NULL, 0, "%d", ws.ws_row);
    char* str1 = int_str(len1, ws.ws_row);
    int len2 = snprintf(NULL, 0, "%d", ws.ws_col);
    char* str2 = int_str(len2, ws.ws_col);
    int len3 = snprintf(NULL, 0, "%d", ws.ws_xpixel);
    char* str3 = int_str(len3, ws.ws_xpixel);
    int len4 = snprintf(NULL, 0, "%d", ws.ws_ypixel);
    char* str4 = snprintf(NULL, 0, "%d", ws.ws_ypixel);
    /* Set var1 to var4. */
    sv_setpvn(var1, str1, len1);
    sv_setpvn(var2, str2, len2);
    sv_setpvn(var3, str3, len3);
    sv_setpvn(var4, str4, len4);
    /* Return 1. */
    return 1;
};

__END__
# Below is the package documentation.

=head1 NAME

Terminal::Control - Perl extension with methods for the control of the terminal window

=head1 SYNOPSIS

  use Terminal::Control;

  clear_screen();
  reset_screen();

  ($rows, $cols, $xpix, $ypix) = winsize();
  ($rows, $cols) = chars();
  ($xpix, $ypix) = pixels();

  ($row, $col) = get_cursor_position();
  set_cursor_position($row, $col);

  echo_on();
  echo_off();
  
  cursor_on();
  cursor_off();   

  ($rows, $cols) = window_size_chars([$timeout]);  
  ($xpix, $ypix) = windows_size_pixels([$timeout]);
  ($rows, $cols) = screen_size_chars([$timeout]); 
  ($xpix, $ypix) = screen_size_pixels([$timeout]);

Variables in square brackets in the method call are optional. They are in the
related method predefined.

=head1 DESCRIPTION

=head2 Module description

The module contains a collection of methods to control a terminal window. The
basic methods are used to delete and reset a terminal window and to query the
current window size.

=head2 Implemented methods

The following methods have been implemented so far within the module.
The methods below are sorted according to their logical relationship.

=over 4 

=item * clear_screen()

=item * reset_screen()

=back

=over 4 

=item * get_cursor_position()

=item * set_cursor_position($rows, $cols)

=back

=over 4 

=item * winsize()

=item * chars()

=item * pixels()

=back

=over 4 

=item * echo_on()

=item * echo_off()

=back

=over 4 

=item * cursor_on()

=item * cursor_off()

=back

=over 4 

=item * screen_size_chars($timeout) 

=item * screen_size_pixels($timeout)

=item * window_size_chars($timeout)

=item * windows_size_pixels($timeout)

=back

=over 4 

=item * ctlseqs_request($parameter, $timeout)

=back

=head1 METHODS

B<clear_screen()>

Clear the terminal window. The method is using Perls C<syswrite> for printing
ANSI escape sequences to STDOUT. The standard terminal window is STDOUT for
the output of Perl. This command has the same effect like calling the Perl
command C<system("clear")>.

B<reset_screen()> 

Reset the terminal window. The method is using Perls C<syswrite> for printing
ANSI escape sequences to STDOUT. The standard terminal window is STDOUT for
the output of Perl. This command has the same effect like calling the Perl 
command C<system("reset")>.

B<echo_on>

Turn the echo on. The method uses for the moment the Shell command C<stty> for 
turning the echo of (user) input on. 

B<echo_off>

Turn the echo off. The method uses for the moment the Shell command C<stty> for 
turning the echo of (user) input off. 

Turn the echo off.

B<cursor_on>

Turn the cursor on. The cursor is enabled by using ANSI escape sequences
in the method.

B<cursor_off>

Turn the cursor off. The cursor is disabled by using ANSI escape sequences
in the method.

B<get_cursor_position()

Get the cursor position. The method gets the current cursor position in the
terminal window.

B<set_cursor_position($row, $col)> 

Set the cursor position. The method gets the current cursor position in the 
terminal window.

B<window_size_chars([$timeout]);>  

B<windows_size_pixels([$timeout]);>

B<screen_size_chars([$timeout]);> 

B<screen_size_pixels([$timeout]);>

B<winsize()> 

Get the window size. The method gets the dimensions in x-direction and y-direction
of the terminal. The methods chars and pixels extract chars (rows and cols)
and pixels (xpix and ypix) from the winsize data. The method is using the C-header
for the system call C<ioctl> and the call or command C<TIOCGWINSZ>. The call
returns the winsize in rows and cols and xpix and ypix.

Variables in square brackets in the method call are optional. They are in the
related method predefined.

=head1 EXAMPLES

  # Clear the terminal window using ANSI escape sequences.
  clear_screen();

  # Reset the terminal window using ANSI escape sequences.
  reset_screen();

  # Get the window size calling ioctl and output the result on the screen.
  my ($rows, $cols, $xpix, $ypix) = winsize();
  printf ("%s\n%s\n%s\n%s\n", $rows, $cols, $xpix, $ypix);

  # Get the chars from the window size and output the result on the screen.
  ($rows, $cols) = chars();
  printf ("%s\n%s\n", $rows, $cols);

  # Get the pixels from the window size and output the result on the screen.
  ($xpix, $ypix) = pixels();
  printf ("%s\n%s\n", $xpix, $ypix);

  # Get the cursor position in chars (not in pixels) using ANSI escape sequences.
  my ($row, $col) = get_cursor_position();
  printf ("%s\n%s\n", $row, $col);

  # Set the cursor position in chars (not in pixels) using ANSI escape sequences.
  my $row = 20; 
  my $col = 80; 
  # $row and $col are required and must be set by the user.
  set_cursor_position($row, $col);

  # Enable echoing of commands using stty. 
  echo_on();

  # Disable echoing of commands using stty. 
  echo_off();

  # Enable visibility of the cursor using ANSI escape sequences.
  cursor_on();

  # Disable visibility of the cursor using ANSI escape sequences.
  cursor_off();

  # Set the timeout for reading from STDIN in microseconds.
  my $timeout = 1000000;
  # Get the window and the screen size using XTERM control sequences.
  # $timeout is optional. If not set 1000000 microseconds (1 second) are used.
  window_size_chars($timeout);  
  windows_size_pixels($timeout);
  screen_size_chars($timeout); 
  screen_size_pixels($timeout);

=head1 VARIABLES EXPLANATION

The x-direction is corresponding to window width and the y-direction is
corresponding to window height.

  $row     => Row (y-position) of terminal window as char position
  $col     => Column (x-position) of terminal window as char position
  $rows    => Rows (height) of terminal window as chars
  $cols    => Columns (width) of terminal window as chars
  $ypix    => Rows (y-direction or height) of terminal window as pixels
  $xpix    => Coulumns (x-direction or width) of terminal window as pixels
  $timeout => Timeout for reading from STDIN in microseconds

The predefined value of $timeout is 1000000 microseconds (1 second). The
value of the parameter $timeout has to be given in microseconds.  

=head1 NOTES

=head2 Development

The idea for the necessity of the module arises from the fact that especially 
the call of the Perl command system C<system("reset")> of the Shell command
C<reset> is noticeably slow.

By using so-called ANSI escape sequences instead of calling a Shell command a
significant acceleration can be achieved. The logical consequence is the
programming of a Perl command that replaces the call of the Perl command system
to reset the terminal window.

A single method is the best way to realise this for the terminal reset and
several other commands. There is no need to implement a class with a bunch of
methods to achive this.  

=head2 Prove of concept

Exemplary comparison of time of execution:

  system("reset")  =>  1.026892 Seconds = 1026,892 Milliseconds = 1026892 Microseconds
  
  reset_screen()   =>  0.000076 Seconds =    0,076 Milliseconds = 76 Microseconds

Using C<reset> on the command line and the Perl command C<system("reset")> have nearly
the same result in time of execution. Detailed comparison is outstanding. This one example
already shows a significant advantage of the new routine.

=head2 Non-blocking behaviour  

Reading from STDIN is blocking w.r.t. to the request of escape sequences, if no
data are available. To overcome the problem of waiting endless for user input a
timeout is programmed. Unfortunately, the programming implementation also slows
down the processing when data is available in STDIN. If the standard value is not
applicable, reduce the timeout step by step. If the timeout is to short the method
is not able to catch the input from STDIN. A error code -1 is returned.

=head1 SYSTEM COMPATIBILITY

Three things must be fulfilled in order to use the full functionality of the
module.

On operating systems that support ANSI escape sequences, individual
methods will work out of the box. Some methods use the Shell command stty.
The Shell command stty must be available accordingly. One method is using the
system call ioctl, which is optional with respect to the functionality of the
module. The restriction under Perl is explained further below.

The above requirements are fulfilled in principle by all Unix or Unix-like systems. 

=head1 FUNCTIONALITY REQUIREMENT

The Perl header C<sys/ioctl.ph> is required for the C<ioctl> call of the
function C<TIOCGWINSZ> to get the window size. The equivalent C/C++ header
is C<sys/ioctl.h>. The Perl command C<h2ph> converts C<.h> C/C++ header files to
C<.ph> Perl header files.

In contrast to modules in general, the module installation process cannot be told
to create a C<sys/ioctl.ph>. This is necessary manually via the C<h2ph> command.

To prevent tests within CPAN from failing due to a missing C<sys/ioctl.ph>, a
fallback solution based on the Shell command C<stty> is implemented.   

=head1 PORTABILITY

The module should work on B<Linux> as well as B<Unix> or B<Unix-like>
operating systems in general.

=head1 CONTROL SEQUENCES

I<ANSI escape sequences> are widely known. Less well known are the so-called I<XTERM
control sequences>.

=head2 ANSI escape sequences

Escape sequences used by the module:

  CSI n ; m H  =>  CUP      =>  Cursor Position       =>  Moves the cursor to row n, column m 
  CSI 6n       =>  DSR      =>  Device Status Report  =>  Reports the cursor position (CPR)
                                                          by transmitting ESC[n;mR,
                                                          where n is the row and m is the column
  CSI ? 25 h   =>  DECTCEM  =>  Shows the cursor
  CSI ? 25 l   =>  DECTCEM  =>  Hides the cursor 

=head2 XTERM control sequences

Escape sequences used by the module:

  CSI 1 4 t  =>  report window size in pixels
  CSI 1 5 t  =>  report screen size in pixels
  CSI 1 8 t  =>  report window size in chars
  CSI 1 9 t  =>  report screen size in chars

=head1 METHOD ALIASES

clear_screen and reset_screen can also be used with this aliases:

  reset_terminal  <=  reset_screen
  clear_terminal  <=  clear_screen
  reset           <=  reset_screen
  clear           <=  clear_screen

=head1 KNOWN BUGS

It happens that in rare cases the CPAN test of the module gives several errors
during compilation. The first error issued is actually an error. This error
then obviously causes subsequent errors that are not actually errors. It is
still unclear how the first real error can be permanently eliminated. 

=head1 ABSTRACT

The module is intended for B<Linux> as well as B<Unix> or B<Unix-like>
operating systems in general. These operating systems meet the requirements
for using the module and its methods. The module contains, among others, two
methods for clearing and resetting the terminal window. This is a standard
task when scripts has to be executed in the terminal window. The related Shell
commands are slow in comparison to the implemented methods in this module. This
is achieved by using ANSI escape sequences. In addition XTERM control sequences
can be used to query screen and window size. The terminal or window size is in
general available via the system call ioctl.

=head1 SEE ALSO

ANSI escape sequences

XTERM control sequences

stty(1) - Linux manual page 

termios(3) — Linux manual page

ioctl_tty(2) — Linux manual page

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
