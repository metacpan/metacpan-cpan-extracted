package Terminal::Control;

# Load the basic Perl pragmas.
use 5.030000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutines.
our @EXPORT = qw(
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
    cursor_up
    cursor_down
    cursor_forward
    cursor_backward
    which_terminal
);

# Import method on demand.
our @EXPORT_OK = qw(
    screen_size_pixels
    screen_size_chars
    window_size_chars
    window_size_pixels
    TermColor
    TermName
    TermPath
    TermType
    reset_screen
    clear_screen
    reset_terminal
    clear_terminal
    WinSize
); 

# Base class of this module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.19';

# Load the neccessary Perl modules.
use bytes;
use Try::Catch;
use Inline 'C' => <<'END_OF_C_CODE';

#include <stdio.h>
#include <termios.h>
#include <sys/ioctl.h>

/*
 * Ref.: 
 *   https://metacpan.org/release/INGY/Inline-0.25/view/lib/Inline/C/Tutorial.pod
 *   https://metacpan.org/dist/Inline-C/view/lib/Inline/C/Cookbook.pod
 *   https://metacpan.org/pod/perlguts
 */

/*
 * Function: LoginShell()
 * ----------------------
 */
char* LoginShell() {
    char *login_shell = getenv("SHELL");
    return login_shell;
};

/*
 * Function: User()
 * ----------------
 */
char* User() {
    char *user = getenv("USER");
    return user;
};

/*
 * Function: Logname()
 * -------------------
 */
char* Logname() {
    char *logname = getenv("LOGNAME");
    return logname;
};

/*
 * Function: TermType()
 * --------------------
 */
char* TermType() {
    char *term_type = getenv("TERM");
    return term_type;
};

/*
 * Function: TermColor()
 * ---------------------
 */
char* TermColor() {
    char *term_color = getenv("COLORTERM");
    return term_color;
};

/*
 * Function: TermName()
 * --------------------
 */
char* TermName() {
   static char term[L_ctermid];
   const char *ptr = ctermid(term);
   char* term_name = (ptr != NULL) ? ptr : NULL; 
   return term_name;
};

/*
 * Function: TermPath()
 * --------------------
 */
char* TermPath() {
  char* tty_name = ttyname(STDIN_FILENO);
  char* term_path = (tty_name != NULL) ? tty_name : NULL;
  return term_path;
};

/* Ref.: termios(3) - Linux manual page
 *
 * struct termios {
 *     tcflag_t c_iflag;     => input modes
 *     tcflag_t c_oflag;     => output modes
 *     tcflag_t c_cflag;     => control modes
 *     tcflag_t c_lflag;     => local modes
 *     cc_t     c_cc[NCCS];  => special characters
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

/*
 * Function: echo_icanon_on()
 * --------------------------
 */
int echo_icanon_on() {
    /* Read attributes, modify attributes and write attributes back. */
    tcgetattr(fileno(stdin), &term);
    term.c_lflag |= (ECHO | ICANON);
    tcsetattr(fileno(stdin), 0, &term);
    /* Return 1. */
    return 1;
}

/*
 * Function: echo_icanon_off()
 * ---------------------------
 */
int echo_icanon_off() {
    /* Read attributes, modify attributes and write attributes back. */
    tcgetattr(fileno(stdin), &term);
    term.c_lflag &= ~(ECHO | ICANON);
    tcsetattr(fileno(stdin), 0, &term);
    /* Return 1. */
    return 1;
};

/*
 * Function: WinSize()
 * -------------------
 *
 * Get the window size of a terminal window.
 *
 * Ref.: ioctl_tty(2) - Linux manual page
 *
 * struct winsize {
 *     unsigned short (uint16_t) ws_row;
 *     unsigned short (uint16_t) ws_col;
 *     unsigned short (uint16_t) ws_xpixel;
 *     unsigned short (uint16_t) ws_ypixel;
 * };
 */
void WinSize() {
    struct winsize ws;
    ioctl(STDIN_FILENO, TIOCGWINSZ, &ws);
    Inline_Stack_Vars;
    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(ws.ws_row)));
    Inline_Stack_Push(sv_2mortal(newSViv(ws.ws_col)));
    Inline_Stack_Push(sv_2mortal(newSViv(ws.ws_xpixel))); 
    Inline_Stack_Push(sv_2mortal(newSViv(ws.ws_ypixel)));
    Inline_Stack_Done;
};

END_OF_C_CODE

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
    # Try to load Time::HiRes
    eval {
        require Time::HiRes;
        Time::HiRes->import ( qw(ualarm) );
        1;
    };
    if ($@) {
        # Print message into the terminal window.
        print "Time::Hires is missing!\n";
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
        print "sys/ioctl.ph is missing!\n";
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
use IO::Handle;
sub ctlseqs_request {
    sub flags_on {
        my $flags = "cbreak -echo -echonl -echoke -echoe -isig";
        my $args = "</dev/tty >/dev/tty 2>&1";
        my $cmd = "stty $flags $args";
        system($cmd);
    };
    sub flags_off {
        my $flags = "-cbreak echo echonl echoke echoe isig";
        my $args = "</dev/tty >/dev/tty 2>&1";
        my $cmd = "stty $flags $args";
        system($cmd);
    };
    # Assign the subroutine arguments to the local variables.
    my ($Ps, $user_timeout) = @_;
    # Get id from request.
    my $id = substr($Ps, 1);
    # Change the timeout if neccessary.
    $timeout = (defined $user_timeout) ? $user_timeout : $timeout;
    if ($is_alarm eq 1) {
        # Divide given timeout by microseconds.
        $timeout = int($timeout / 1000000);
    };
    $timeout = ($timeout <= 0) ? 1 : $timeout; 
    # Initialise the local variables.
    local $/ = \64;
    my ($width, $height) = undef;
    my $buf = '';
    my $chr = '';
    my $match;
    my @nums;
    # Change the settings of the terminal window.
    flags_on();
    # Print the escape sequence to STDOUT.
    print STDOUT "${CSI}${Ps}t";
    # Non blocking reading from STDIN.
    eval {
        # Define the alarm handler.
        local $SIG{ALRM} = sub {die "timeout"};
        # Start the alarm.
        eval "$mod_alarm $timeout";
        # Read chars from STDIN.
        while (($chr = getc(STDIN)) ne "t") {
            $buf .= $chr;
        };
        # Stop the alarm.
        eval "$mod_alarm 0";
    };
    if ($@) {
         # On timeout raise an exception.
         try {
             # On error die.
             die;
         } catch {
             # Clean up settings.  
             flags_off();
             # Set output to error code -3. 
             ($height, $width) = (-3, -3);
         };
    } else {
        if ($buf eq '') {
            # Set output to error code -1. 
            ($width, $height) = (-1, -1);
        } else {
            # Set regular expression.
            my $re = qr/^.*(\d+\;\d+\;\d+).*$/;
            # Grep numbers from response.
            if ($buf =~ $re) {
                $match = $1;
                @nums = split(";", $match);
            };
            # Get width and height.
            if ($id eq $nums[0]) { 
                # Set height and width.
                ($height, $width) = ($nums[1], $nums[2]);
            } else {
                # Set output to error code -2. 
                ($height, $width) = (-2, -2);
            };
    };
    # Restore the settings of the terminal window.
    flags_off();
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
    my ($height, $width) = ctlseqs_request("14", $timeout);
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
    my ($height, $width) = ctlseqs_request("15", $timeout);
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
# Subroutine winsize_ioctl                                                     #
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
# Subroutine winsize_stty                                                      #
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

#------------------------------------------------------------------------------# 
# Subroutine cursor_up                                                         #
#------------------------------------------------------------------------------# 
sub cursor_up {
    # Set the control sequence.
    my $ctl_seq = "1A"; 
    # Move the cursor up.
    print "${CSI}${ctl_seq}";
};

#------------------------------------------------------------------------------# 
# Subroutine cursor_down                                                       #
#------------------------------------------------------------------------------# 
sub cursor_down {
    # Set the control sequence.
    my $ctl_seq = "1B"; 
    # Move the cursor down.
    print "${CSI}${ctl_seq}";
};

#------------------------------------------------------------------------------# 
# Subroutine cursor_forward                                                    #
#------------------------------------------------------------------------------# 
sub cursor_forward {
    # Set the control sequence.
    my $ctl_seq = "1C"; 
    # Move the cursor forward.
    print "${CSI}${ctl_seq}";
};

#------------------------------------------------------------------------------# 
# Subroutine cursor_backward                                                   #
#------------------------------------------------------------------------------# 
sub cursor_backward {
    # Set the control sequence.
    my $ctl_seq = "1D"; 
    # Move the cursor back.
    print "${CSI}${ctl_seq}";
};

#------------------------------------------------------------------------------# 
# Subroutine trim                                                              #
# trim removes white spaces from both ends of a string.                        #
#------------------------------------------------------------------------------# 
sub trim {
    my $str = $_[0];
    $str =~ s/^\s+|\s+$//g;
    return $str;    
};

#------------------------------------------------------------------------------# 
# Subroutine add_filter_chr                                                    #
# Adds [ and ] to searchstring for grep                                        # 
#------------------------------------------------------------------------------# 
sub add_filter_chr {
    my $str = $_[0];
    substr($str, 0, 0) = '[';
    substr($str, 2, 0) = ']';
    return $str;
};

#------------------------------------------------------------------------------# 
# Subroutine login_shell                                                       #
#------------------------------------------------------------------------------# 
sub login_shell {
    my $user = $ENV{USER};
    my $passwd = `cat /etc/passwd |grep -w $user`;
    $passwd =~ s/^\s+|\s+$//g;
    my ($shell) = $passwd =~ /^.*\/(.*)$/;
    return $shell;
};

#------------------------------------------------------------------------------# 
# Subroutine terminal                                                          # 
# Terminal identification using bash:                                          #
# ps -o 'cmd=' -p $(ps -o 'ppid=' -p $$)                                       #
# my $tshell = LoginShell();                                                   # 
# ($shell) = $tshell =~ /^.*\/(.*)$/;                                          #
# cat /etc/shells                                                              #
#------------------------------------------------------------------------------# 
sub which_terminal {
    # Get the terminal path.
    my $termpath = TermPath();
    # Extract the pts fd from the terminal path.
    my ($ptsfd) = $termpath =~ /^.*\/dev\/(pts\/\d+)$/;
    # Extract the login shell from the passwd file.
    my $loginshell = login_shell();
    # Add square brackets for use with grep.
    $ptsfd = add_filter_chr($ptsfd);
    $loginshell = add_filter_chr($loginshell);
    # Filter process by shell and pts.
    my $process = `ps aux |grep $loginshell| grep $ptsfd`;
    # Split up the process by lines and white spaces.
    my @lines = split /\n/, $process;
    my @columns = split /\s+/, $lines[0];
    # Extract the PID from the array.
    my $pid = $columns[1];
    # Get the PPID from the command ps.
    my $ppid = `ps -o 'ppid=' -p $pid`;
    # Trim the string withe the PPID.
    $ppid = trim($ppid);
    # Get the term in use from the command ps.
    my $term = `ps -o 'cmd=' -p $ppid`;
    # Trim the term variable.  
    $term = trim($term);
    # Return the term in use.
    return $term;
};

1;

__END__
# Below is the package documentation.

=head1 NAME

Terminal::Control - Perl extension with methods for the control of the terminal window

=head1 SYNOPSIS

The usage of 

  use Terminal::Control;

or the usage of

  use Terminal::Control qw(:DEFAULT);

allows the import of the standard methods.

  # Clear or reset the terminal window.

  clear_screen();
  reset_screen();

  # Get the terminal window size using Perl header 'sys/ioctl.ph'.

  ($rows, $cols, $xpix, $ypix) = winsize();
  ($rows, $cols) = chars();
  ($xpix, $ypix) = pixels();

  # Get and set the cursor position on the terminal window.

  ($row, $col) = get_cursor_position();
  set_cursor_position($row, $col);

  # Realise cursor movement on the terminal window.

  cursor_up();
  cursor_down(); 
  cursor_forward(); 
  cursor_backward(); 

  # Show or hide the cursor on the terminal window.
  
  cursor_on();
  cursor_off();   

  # Turn the terminal character echo on or off.  

  echo_on();
  echo_off();

  # Get the terminal in use.

  which_terminal();   

C<qw(:DEFAULT)> imports all methods which are declared in C<@EXPORT> in the module.

The usage of

  use Terminal::Control qw(
     :DEFAULT TermColor TermType TermName TermPath WinSize
     window_size_chars window_size_pixels screen_size_chars screen_size_pixels
  );

or the usage of

  use Terminal::Control qw(
     TermColor TermType TermName TermPath WinSize
     window_size_chars window_size_pixels screen_size_chars screen_size_pixels
  );

allows the import of the optional methods which are declared in C<@EXPORT_OK>
in the module and the import of standard methods. Without entry C<:DEFAULT>
only optional methods are imported.

  # Get the terminal window size using Xterm control sequences. 

  ($rows, $cols) = window_size_chars([$timeout]);  
  ($xpix, $ypix) = windows_size_pixels([$timeout]);
  ($rows, $cols) = screen_size_chars([$timeout]); 
  ($xpix, $ypix) = screen_size_pixels([$timeout]);

  # Get the terminal window size using C header 'sys/ioctl.h'.

  ($rows, $cols, $xpix, $ypix) = WinSize();

  # Get informations about the terminal.

  TermColor();
  TermType();  
  TermName();  
  TermPath();

Variables in square brackets in the method call are optional. They are in the
related method predefined.

In general every method is still accessible from outside the module using the
syntax I<Terminal::Control::method_name>.

=head1 DESCRIPTION

=head2 Preface

There are two main areas of application for the methods presented. They
are useful in the terminal or in the console. The terminal is a terminal
emulator installed on current operating systems. The console is the system
console of the operating system itself. It provides basic functions that
may be of general interest.

=head2 Methods summary

The module contains a collection of methods to control a terminal window. The
basic methods are used to delete or reset a terminal window and to query the
current window size. Other methods showed or suppressed the input echo. Showing
or hiding the cursor is achieved by other methods.

=head2 List of methods

The following methods have been implemented so far within the module.
The methods below are sorted according to their logical relationship.

B<Standard methods>

=over 4 

=item * clear_screen()

=item * reset_screen()

=back

=over 4 

=item * winsize()

=item * chars()

=item * pixels()

=back

=over 4 

=item * get_cursor_position()

=item * set_cursor_position($rows, $cols)

=back

=over 4 

=item * cursor_up()

=item * cursor_down()

=item * cursor_forward()

=item * cursor_backward()

=back

=over 4 

=item * cursor_on()

=item * cursor_off()

=back

=over 4 

=item * echo_on()

=item * echo_off()

=back

=over 4 

=item * which_terminal()

=back

B<Optional methods>

=over 4 

=item * WinSize()

=back

=over 4 

=item * screen_size_chars($timeout) 

=item * screen_size_pixels($timeout)

=item * window_size_chars($timeout)

=item * windows_size_pixels($timeout)

=back

=over 4 

=item * TermColor()

=item * TermType()

=item * TermName()

=item * TermPath()

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

B<winsize()> 

Get the window size.  The method is using the Perl-header for the system call
C<ioctl> and the call or command C<TIOCGWINSZ>. The call returns the winsize in
rows and cols and xpix and ypix.

B<chars()>

Get the window size in chars. The method extract chars (rows and cols) from the
former winsize.

B<pixels()>

Get the window size in pixels. The method pixels extract pixels (xpix and ypix)
from the former winsize.

B<window_size_chars([$timeout]);>  
 
Get the window size in chars. The methods gets the window size in chars using
Xterm control sequences.

B<windows_size_pixels([$timeout]);>

Get the window size in pixels. The methods gets the window size in pixels using 
Xterm control sequences.

B<screen_size_chars([$timeout]);>

Get the screen size in chars. The methods gets the screen size in chars using
Xterm control sequences.

B<screen_size_pixels([$timeout]);>

Get the screen size in pixels. The methods gets the screen size in pixels using 
Xterm control sequences.

B<WinSize()>

Get the window size in chars and pixels. The method is using in The Inline C code 
the C-header for the system call C<ioctl> and the call or command C<TIOCGWINSZ>. The
call returns the winsize in rows, cols, xpix and ypix.

B<get_cursor_position()>

Get the cursor position. The method gets the current cursor position in the
terminal window.

B<set_cursor_position($row, $col)> 

Set the cursor position. The method gets the current cursor position in the 
terminal window.

B<cursor_on()>

Turn the cursor on. The cursor is enabled by using ANSI escape sequences
in the method.

B<cursor_off()>

Turn the cursor off. The cursor is disabled by using ANSI escape sequences
in the method.

B<echo_on()>

Turn the echo on. The method uses for the moment the Shell command C<stty> for 
turning the echo of (user) input on. 

B<echo_off()>

Turn the echo off. The method uses for the moment the Shell command C<stty> for 
turning the echo of (user) input off. 

B<cursor_up()>

Moves the cursor 1 char up.

B<cursor_down()>

Moves the Cursor 1 char down.

B<cursor_forward()>

Moves the cursor 1 char forward.

B<cursor_backward()>

Move the cursor 1 char backward.

B<TermColor()>

Get the color capabilities of the terminal, e.g 24bit, truecolor.

B<TermType()>

Get the terminal capabilities in general, e.g. xterm, xterm-color or xterm-256color.

B<TermName()>

Get name of the terminal like '/dev/tty'.

B<TermPath()>

Get the path to the terminal like '/dev/pts/1'.

B<which_terminal()>

Get the name of the terminal emulator, which is in use by the user. First
the method tries to fetch the login shell. Next the path to the terminal
is determined. Based on this informations the related process to login shell
and terminal path is identified. Evaluation of the PPID results in the parents
process ID. The command related to this PID is the name of the terminal in use.   

Variables in square brackets in the method call are optional. They are in the
related method predefined.

=head1 ERROR CODES

The error codes of methods which are related to getting the window or sreen
size are as follows:

  -1  ->  Unspecific common error
  -2  ->  Data from response not valid
  -3  ->  Execution block timed out

=head1 EXAMPLES

=head2 Terminal window clear and reset

  # Clear the terminal window using ANSI escape sequences.
  clear_screen();

  # Reset the terminal window using ANSI escape sequences.
  reset_screen();

=head2 Standard terminal window size

  # Declare the variables.
  my ($rows, $cols, $xpix, $ypix) = undef;

  # Get the window size calling ioctl and output the result on the screen.
  ($rows, $cols, $xpix, $ypix) = winsize();
  printf ("%s\n%s\n%s\n%s\n", $rows, $cols, $xpix, $ypix);

  # Get the chars from the window size and output the result on the screen.
  ($rows, $cols) = chars();
  printf ("%s\n%s\n", $rows, $cols);

  # Get the pixels from the window size and output the result on the screen.
  ($xpix, $ypix) = pixels();
  printf ("%s\n%s\n", $xpix, $ypix);

=head2 Optional terminal window size

  # Load the required module.
  use Terminal::Control qw(
     window_size_chars
     window_size_pixels
     screen_size_chars
     screen_size_pixels
     WinSize
  );

  # Set the timeout for reading from STDIN in microseconds.
  my $timeout = 1000000;

  # Get the window and the screen size using Xterm control sequences.
  # $timeout is optional. If not set 1000000 microseconds (1 second) are used.
  ($rows, $cols) = window_size_chars($timeout);
  ($xpix, $ypix) = windows_size_pixels($timeout);
  ($rows, $cols) = screen_size_chars($timeout);
  ($xpix, $ypix) = screen_size_pixels($timeout);

  # Get the window size using Inline C code.
  ($rows, $cols, $xpix, $ypix) = Terminal::Control::WinSize();
  printf ("%s\n%s\n%s\n%s\n", $rows, $cols, $xpix, $ypix);

=head2 Getter and setter for the cursor position

  # Declare the variables.
  my ($row, $col) = undef;

  # Get the cursor position in chars (not in pixels) using ANSI escape sequences.
  ($row, $col) = get_cursor_position();
  printf ("%s\n%s\n", $row, $col);

  # Set the cursor position in chars (not in pixels) using ANSI escape sequences.
  $row = 20; 
  $col = 80; 
  # $row and $col are required and must be set by the user.
  set_cursor_position($row, $col);

=head2 Cursor on / off

  # Enable visibility of the cursor using ANSI escape sequences.
  cursor_on();

  # Disable visibility of the cursor using ANSI escape sequences.
  cursor_off();

=head2 Echo on / off

  # Enable echoing of commands using stty. 
  echo_on();

  # Disable echoing of commands using stty. 
  echo_off();

=head2 Cursor movement on the terminal window

The script works as follows. The terminal window is reseted. Then the position
of the cursor is set to (20, 40) on the terminal window. Now the user can use
the the arrow keys on the keyboard to move the cursor on the terminal window.
Pressing 'q' quits the loop and set the cursor position to (1, 1) which is be
the home position.

  # Load the required module.
  use Terminal::Control;

  # Initialise variable $chr.
  my $chr = '';

  # Reset the terminal window.
  reset();

  # Set the initial cursor position.
  set_cursor_position(20, 40); 

  # Set some terminal attributes.
  system("stty -echo -icanon -isig");

  # Run loop until 'q' was pressed.
  while ($chr ne "q") {
      $chr = getc(STDIN);
      if (ord($chr) == 65) {
          cursor_up();
      } elsif (ord($chr) == 66) {
          cursor_down();
      } elsif (ord($chr) == 67) {
          cursor_forward();
      } elsif (ord($chr) == 68) {
          cursor_backward();
      };
  };

  # Reset some terminal attributes.
  system("stty echo icanon isig");

  # Reset the cursor to home.
  set_cursor_position(1,1); 

It is planned for the near future to exchange the Perl system command which
calls stty by a C function. The basic knowledge is given, but this takes a 
bit time to do it the right way. Such a method has to be easy to use and
flexible in turning on and off of the attributes the same time. 

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

=head1 SYSTEM COMPATIBILITY

Three things must be fulfilled in order to use the full functionality of the
module.

On operating systems that support ANSI escape sequences, individual methods
will work out of the box. Some methods still use the Shell command C<stty>.
The Shell command C<stty> must be available accordingly. Some methods are
using the system call ioctl, which is somehow optional with respect to the
functionality of the module. The restriction under Perl is explained further
below.

The above requirements are fulfilled in principle by all Unix or Unix-like
systems. 

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
operating systems in general until something else was shown.

=head1 CONTROL SEQUENCES

I<ANSI escape sequences> are widely known. Less well known are the so-called I<Xterm
control sequences>.

=head2 ANSI escape sequences

Escape sequences used by the module:

  CSI n ; m H   =>  Set Cursor Position  =>  Moves the cursor to row n and column m 
  CSI 6n        =>  Get Cursor Position  =>  Cursor position report (CPR) by
                                             sending ESC [ n ; m R, where
                                             n is the row and m is the column

  CSI n A       =>  Cursor Up 
  CSI n B       =>  Cursor Down
  CSI n C       =>  Cursor Forward
  CSI n D       =>  Cursor Backward 

  Moves the cursor n (default is 1) chars in the given direction up, down, forward or backward.
  If the cursor is already at the one edge of the screen, this control sequence has no effect.

  CSI ? 25 h    =>  Shows the cursor
  CSI ? 25 l    =>  Hides the cursor 

  CSI ? 1049 h  =>  Enable the alternative screen buffer
  CSI ? 1049 l 	=>  Disable the alternative screen buffer 

=head2 Xterm control sequences

The xterm program is a terminal emulator for the X Window System. The Xterm
control sequences take their name from the terminal emulator of the same name.
This means that the Xterm control sequences should primarily be able to run
under xterm. However, they also work with other terminal emulators.

Escape sequences used by the module:

  CSI 1 4 t  =>  Report the window size in pixels
  CSI 1 5 t  =>  Report the screen size in pixels
  CSI 1 8 t  =>  Report the window size in chars
  CSI 1 9 t  =>  Report the screen size in chars

=head1 METHOD ALIASES

clear_screen and reset_screen can also be used with this aliases:

  reset_terminal  <=  reset_screen
  clear_terminal  <=  clear_screen
  reset           <=  reset_screen
  clear           <=  clear_screen

=head1 TERMINALS TESTED

As described above, terminal emulators or the system console are used to
interact with the operating system.

Terminals tested so far with the module:

=over 4

=item * LXTerminal

=item * mate-terminal

=item * ROXTerm

=item * xterm

=back

=head1 LIMITATIONS

=head2 Xterm control sequences

The use of Xterm escape sequences is still considered experimental.

Reading the response from STDIN is blocking with respect to the request
of escape sequences, if no data are responded. To overcome the problem of
waiting endless for an user input a timeout is programmed. 

If the timeout is set too short, the response to the request cannot be
evaluated. If information on the size of the window is requested in quick
succession, the data from STDIN will be read in incorrectly. This can be
overcome by deleting STDIN. A method of deleting or resetting STDIN is not 
known yet.

If the standard value is not applicable, reduce the timeout step by step.
If the timeout is to short the method is not able to catch the input from STDIN. 

=head1 OPEN ISSUES

It is not yet clear how an installation of the module for Unix or Unix-like
operating systems only can best be realised.  

A routine is needed that can reliably delete STDIN. Previous attempts to delete
STDIN did not lead to satisfactory results. 

=head1 KNOWN BUGS

Not known yet

=head1 ABSTRACT

The module is intended for B<Linux> as well as B<Unix> or B<Unix-like>
operating systems in general. These operating systems meet the requirements
for using the module and its methods. The module contains, among others, two
methods for clearing and resetting the terminal window. This is a standard
task when scripts has to be executed in the terminal window. The related Shell
commands are slow in comparison to the implemented methods in this module. This
is achieved by using ANSI escape sequences. In addition Xterm control sequences
can be used to query screen and window size. The terminal or window size is in
general available via the system call ioctl.

=head1 SEE ALSO

ANSI escape sequences

Xterm control sequences

stty(1) - Linux manual page 

termios(3) - Linux manual page

ioctl_tty(2) - Linux manual page

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
