package Terminal::Identify;

# Load the basic Perl pragmas.
use 5.010100;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Export the implemented subroutines and the global variable.
our @EXPORT = qw(
    whichterminalami
    whichtermami
    which_terminal
    identify_terminal
    terminal_identify
    $OutputFormat
);

# Base class of this module.
our @ISA = qw(Exporter);

# Set the package version.
our $VERSION = '0.29';

# Load the Perl modules.
use POSIX qw(ttyname);

# Set the global output format.
our $OutputFormat = "";

# Set the global term hash variable.
our %termhash = ();

# Define the Perl BEGIN block.
BEGIN {
    # Set the subroutine aliases.
    *whichtermami = \&whichterminalami;
    *which_terminal = \&whichterminalami;
    *identify_terminal = \&whichterminalami;
    *terminal_identify = \&whichterminalami;
};

# ++++++++++++++++++++++++++++++++
# Perform some preliminary checks.
# ++++++++++++++++++++++++++++++++

# Check if the operating system is Windows.
if ($^O eq "MSWin32") {
    # Print a message into the terminal window.
    print "This module works not on Windows. Bye.\n";
    # Exit the script with error code 1.
    exit 1;
};

# Check if the Linux command 'which' exists.
my $exitcode = system("which which > /dev/null 2>&1");
if ($exitcode != 0) {
    # Print a message into the terminal window.
    print "The Linux command 'which' does not exist. Bye.\n";
    # Exit the script with error code 2.
    exit 1;
};

# Check if the Linux command 'grep' exists.
if (!defined `which grep 2>/dev/null` || `which grep 2>/dev/null` eq "") {
    # Print a message into the terminal window.
    print "The Linux command 'grep' does not exist. Bye.\n";
    # Exit the script with error code 3.
    exit 3;
};

# Check if the Linux command 'users' exists.
if (!defined `which users 2>/dev/null` || `which users 2>/dev/null` eq "") {
    # Print a message into the terminal window.
    print "The Linux command 'grep' does not exist. Bye.\n";
    # Exit the script with error code 4.
    exit 4;
};

# Check if the Linux command 'ps' exists.
if (!defined `which ps 2>/dev/null` || `which ps 2>/dev/null` eq "") {
    # Print a message into the terminal window.
    print "The Linux command 'ps' does not exist. Bye.\n";
    # Exit the script with error code 5.
    exit 5;
};

# Set some variables.
our $FN_PASSWD = "/etc/passwd";
our $FN_SHELLS = "/etc/shells";

# Check if passwd exists.
if (! -e $FN_PASSWD) {
    die "$!, $FN_PASSWD not exists.\n";
};

# Check if shells exists.
if (! -e $FN_SHELLS) {
    die "$!, $FN_SHELLS not exists.\n";
};

# ++++++++++++++++++++++++++++++++++++++++++
# Create a dictionary from __DATA__ section.
# ++++++++++++++++++++++++++++++++++++++++++

# Initialise some variables. 
my $line = "";
my $key = "";
my $value = "";

# Read data from __DATA__ section.
while (<DATA>) {
    # Read data only between the two given boundaries.
    if (/# Begin terminals/../# End terminals/) {
        next if /# Begin terminals/ || /# End terminals/;
        $line = $_;
        my @parts = split /=>/, $line, 2;
        $key = $parts[0];
        $key =~ s/^\s+|\s+$//g;
        $value = $parts[1];
        $value =~ s/^\s+|\s+$//g;
        $termhash{$key} = $value;
    };
};

# ============================================================================ #
# Subroutine trim                                                              #
#                                                                              #
# Description:                                                                 #
# The subroutine removes white spaces from both ends of a string. This is done #
# by a logical or operation and using \s from regular expressions. Anchors are #
# begin ^ of string and end $ of string.                                       #
#                                                                              #
# @argument: $_[0] => $string  String to trim  (scalar)                        #
# @return:   $string           Trimmed string  (scalar)                        #
# ============================================================================ #
sub trim {
    # Assign the function argument to the local string variable $str.
    my $string = ((defined $_[0] && $_[0] ne "") ? $_[0] : "");
    # Trim the string from the left side and the right side.
    $string =~ s/^\s+|\s+$//g;
    # Return the trimmed string.
    return $string;
};

# ============================================================================ #
# Subroutine search_brackets                                                   #
#                                                                              #
# Description:                                                                 #
# The subroutine adds the square brackets [ and ] to the searchstring for      #
# use with grep. E.g. shell becomes [s]hell. Therefor the string must have     #
# a minumum length of 1.                                                       #
#                                                                              #
# @argument: $_[0] => $str  Searchstring                       (scalar)        #
# @return:   $str           Searchstring with square brackets  (scalar)        #
# ============================================================================ #
sub search_brackets {
    # Initialise the local variable $searchstring.
    my $searchstring = "";
    # Check if $searchstring is defined and is not empty.
    if ((defined $_[0]) && (length($_[0]) > 0)) {
        # Assign the subroutine argument to the local variable.
        $searchstring = $_[0];
    } else {
        # Return string of length 0.
        return "";
    }
    # Add square brackets [ and ] to the given string.
    substr($searchstring, 0, 0) = '[';
    substr($searchstring, 2, 0) = ']';
    # Return the modified string.
    return $searchstring;
};

# ============================================================================ #
# Subroutine read_file                                                         #
#                                                                              #
# Description:                                                                 #
# Read the complete content of a file in one chunk. The retrieved content is   #
# stored in a string variable.                                                 #
#                                                                              #
# @argument: $_[0] => $file  Text filename  (scalar)                           #
# @return:   $content        File content   (scalar)                           #
# ============================================================================ #
sub read_file {
    # Assign the function argument to the local variable.
    my $file = $_[0];
    # Initialise the return variable.
    my $content = "";
    # If file not exists, return an empty string.
    if (-f $file) {
        # Open a file handler for reading the file.
        open(my $fh, "<", $file);
        # Read the complete content from the file.
        $content = do {local $/; <$fh>};
        # Close the file handler.
        close($fh);
    };
    # Return the file content.
    return $content;
};

# ============================================================================ #
# Subroutine login_users                                                       #
#                                                                              #
# Description:                                                                 #
# Split the logged-in users by sperator space and store them to an array.      #
#                                                                              #
# @argument: None                                                              #
# @return:   $user_arr  Array with the logged-in users  (array)                #
# ============================================================================ #
sub login_users {
    # Initialise the return array.
    my @user_array = (); 
    # Get the logged-in users from the Linux command users.
    my $user = `users`;
    # Check if the variable $user is defined and not empty.
    if (defined $user && $user ne "") {
        # Split the logged-in users and store them to the array.
        @user_array = split ' ', $user;
    };
    # Return the array with the logged-in users.
    return @user_array;
};

# ============================================================================ #
# Subroutine login_shells                                                      #
#                                                                              #
# Description:                                                                 #
# Read the content of the file /etc/shells and store the content in a string   #
# variable. Then the content is splited up into lines. In a loop the lines     #
# are used where a valid login shell is given. Then the path is removed from   #
# the line with the login shell. The login shell is added to an array. In a    #
# last step douple entries are removed from the array.                         #
#                                                                              #
# @argument: None                                                              #
# @return:   @login_shells  Array with valid login shells  (array)             #
# ============================================================================ #
sub login_shells {
    # Declare the login shells array.
    my @login_shells;
    # Set the file for reading.
    my $file = $FN_SHELLS;
    # Read the content from the file.
    my $content = read_file($file);
    # Loop over the lines of the file content.
    foreach (split '\n', $content) {
        # Trim the new line.
        my $line = trim($_);
        # Use only a line with a valid login shell.
        if ($line =~ /^\/.*\/(.*)$/) {
            # Remove the path from the line with the login shell.
            my ($shell) = $line =~ /^\/.*\/(.*)$/;
            # Add the login shell to the array.
            push(@login_shells, $shell);
        };
    };
    # Remove the double entries from the array.
    my %login_hash = map({$_, 1} @login_shells);
    @login_shells = keys %login_hash;
    # Return the array with the unique login shells.
    return @login_shells;
};

# ============================================================================ #
# Subroutine get_ppid                                                          #
#                                                                              #
# Description:                                                                 #
# Determine the PPID of the calling Perl script using the Linux command ps.    #
#                                                                              #
# @argument: $_[0] => $pid  PID   (scalar)                                     #
# @return:   $ppid          PPID  (scalar)                                     #
# ============================================================================ #
sub get_ppid {
    # Assign the subroutine argument to the local variable $pid.
    my $pid = $_[0];
    # Store the output of the Linux command ps in the local variable $ppid.
    my $ppid = `ps --no-headers -o ppid:1 -p $pid --sort lstart 2>/dev/null`;
    # Split a multiline Perl scalar with the PPID's in parts.
    my @parts = split /\s+/, $ppid;
    # If there is more than one PPID, use the first PPID.
    $ppid = $parts[0];
    # Trim the Perl scalar with the PPID.
    $ppid = trim($ppid);
    # Return the PPID.
    return $ppid;
};

# ============================================================================ #
# Subroutine get_termpath                                                      #
# ============================================================================ #
sub get_termpath {
    # Initialise the local variables.
    my $fileno = fileno(STDIN);
    my $term_path = "";
    # Get the terminal path.
    # $term_path = TermPath();
    $term_path = ttyname($fileno);
    # Check the terminal path
    $term_path = (defined $term_path ? $term_path : "");
    # Return the terminal path.
    return $term_path;
};

# ============================================================================ #
# Subroutine get_user_name                                                     #
# ============================================================================ #
sub get_username {
    # Initialise the username.
    my $username = "";
    # Define the methods for getting the username.
    my $method1 = getlogin();
    my $method2 = (getpwuid($<))[0];
    my $method3 = $ENV{LOGNAME};
    my $method4 = $ENV{USER};
    # Extract the username.
    $username = ($method1 || $method2 || $method3 || $method4);
    # Return the username.
    return $username;
};

# ============================================================================ #
# Subroutine term_user_shell                                                   #
#                                                                              #
# Description:                                                                 #
# Create a multi dimensional array with term, user and shell.                  #
#                                                                              #
# @arguments: $_[0] => $passwd_content  Content of passwd      (scalar)        #
#             @{$_[1]} => @user_array   User array             (array)         #
#             @{$_[2]} => @shell_array  Shell array            (array)         #
# @return:    @result_array             Array with the result  (array)         #
# ============================================================================ #
sub term_user_shell {
    # Assign the subroutine arguments to the local variables.
    my $passwd_content = $_[0];
    my @user_array = @{$_[1]};
    my @shell_array = @{$_[2]};
    # Initialise variable $term.
    my $term = "";
    # Get the username related to the terminal.
    my $username = get_username();
    # Declare the return array.
    my @result_array = ();
    # Get the terminal path.
    my $term_path = get_termpath();
    # If $term_path is not defined or empty set $term to ?.
    if (!defined $term_path || $term_path eq "") {
        # Set variable $term_path.
        $term = "?";
    } else {
        # Check on pts and tty.
        if ($term_path =~ /^.*\/dev\/(pts\/\d+)$/) {
            # Extract the pseudo terminal slave.
            ($term) = $term_path =~ /^.*\/dev\/(pts\/\d+)$/;
        } elsif ($term_path =~ /^.*\/dev\/(tty\d+)$/) {
            # Extract the terminal TeleTYpewriter.
            ($term) = $term_path =~ /^.*\/dev\/(tty\d+)$/;
        } else {
            $term = "?";
        };
    };
    # Loop over the array with the lines of $passwd_content.
    foreach (split '\n', $passwd_content) {
        # Get user and shell from each line of the content.
        my ($user) = $_ =~ /^(.*?):.*/;
        my ($shell) = $_ =~ /^.*\/(.*)$/;
        if ($shell ne "nologin" && $shell ne "sync" && $shell ne "false") {
            # Check user and shell against the given arrays.
            if (grep(/^$user$/, @user_array) &&
                grep(/^$shell$/, @shell_array)) {
                # Assemble a new list.
                my @tmp = ($term, $user, $shell);
                # Add data to array.
                push(@result_array, \@tmp);
            } elsif ($user eq $username) {
                # Assemble a new list.
                my @tmp = ($term, $user, $shell);
                # Add data to array.
                push(@result_array, \@tmp);
            };
        };
    };
    # Return the array.
    return @result_array;
};

# ============================================================================ #
# Subroutine terminal_process                                                  #
#                                                                              #
# Description:                                                                 #
# Get the process related to term, user and shell.                             #
#                                                                              #
# @argument: @{$_[0]} => @data  Array with term, user and shell  (array)       #
# @return:   @result            Array with matching processes    (array)       #
# ============================================================================ #
sub terminal_process {
    # Assign the subroutine argument to the local variable.
    my @data = @{$_[0]};
    # Initialise the return array.
    my @match = ();
    # Set command.
    my $ps_cmd = "ps aux --sort lstart 2>/dev/null";
    # Loop over the elements of the array.
    foreach my $item (@data) {
        # Get term, user and shell from the array.
        my $term = $item->[0];
        my $user = $item->[1];
        my $shell = $item->[2];
        $term = search_brackets($term);
        $user = search_brackets($user);
        $shell = search_brackets($shell);
        # Search for processes which is matching shell, user and terminal.
        my $grep_shell = "grep $shell 2>/dev/null";
        my $grep_user = "grep $user 2>/dev/null";
        my $grep_term = "grep $term 2>/dev/null";
        my $process = `${ps_cmd} | ${grep_shell} | ${grep_user} | ${grep_term}`;
        # Check if the result is not empty.
        if ($process ne "") {
            # Add the process to the return array.
            push(@match, $process);
        };
    };
    # If array @match is empty, it is not a local process.
    if (@match == 0) {
        # Loop over the elements of the array.
        foreach my $item (@data) {
            # Get term and user from the array.
            my $term = $item->[0];
            my $user = $item->[1];
            # Add square brackets to searchstrings.
            $term = search_brackets($term);
            $user = search_brackets($user);
            # Search for processes which is matching shell and terminal.
            my $grep_term = "grep $term 2>/dev/null";
            my $grep_user = "grep $user 2>/dev/null";
            my $process = `${ps_cmd} | ${grep_user} | ${grep_term} | grep "?" | grep "sshd"`;
            # Check if the result is not empty.
            if ($process ne "") {
                # Add the process to the return array.
                push(@match, $process);
            };
        };
    };
    # Return the array.
    return @match;
};

# ============================================================================ #
# Subroutine terminal_command_line                                             #
#                                                                              #
# Description:                                                                 #
# Use the Linux command ps to get the command line of the process which is     #
# related to the terminal in use.                                              #
#                                                                              #
# @argument  $_[0] => $ppid  PPID                   (scalar)                   #
# @return    $termproc       Terminal command line  (scalar)                   #
# ============================================================================ #
sub terminal_command_line {
    # Assign the subroutine argument to the local variable $ppid.
    my $ppid = $_[0];
    # Get the command column from the ps output.
    my $termproc = `ps --no-headers -o cmd:1 -p $ppid --sort lstart 2>/dev/null`;
    # Trim the command line output string.
    $termproc = trim($termproc);
    # Return the process related to the terminal in use.
    return $termproc
};

# ============================================================================ #
# Subroutine terminal_identifier                                               #
#                                                                              #
# Description:                                                                 #
# Identify the process command line of the terminal in use.                    #
#                                                                              #
# @argument: None                                                              #
# @return:   $terminal_command  Process command line  (scalar)                 #
# ============================================================================ #
sub terminal_identifier {
    # Declare the return variable $terminal_command.
    my $terminal_command;
    # Set the filename.
    my $filename = $FN_PASSWD;
    # Get the logged-in users.
    my @user_arr = login_users();
    # Get the available login shells.
    my @shell_arr = login_shells();
    # Read the file /etc/passwd in and store it in the variable $content.
    my $content = read_file($filename);
    # Create the array with user and shell.
    my @result = term_user_shell($content, \@user_arr, \@shell_arr);
    # check if @result is empty.
    if (@result == 0) {
        # Set terminal command.
        $terminal_command = "";
        # Return an empty string.
        return $terminal_command;
    };
    # Create the array with user and term.
    my @match = terminal_process(\@result);
    # Check if array is empty.
    if (@match > 0) {
        # Split up the process by lines and white spaces.
        my @columns = split /\s+/, $match[0];
        # Extract the PID from the array.
        my $pid = $columns[1];
        # Get the PPID from the command ps.
        my $ppid = get_ppid($pid);
        # Get the terminal in use from the command ps.
        $terminal_command = terminal_command_line($ppid);
    } else {
        # Set terminal command.
        $terminal_command = "";
    };
    # Return the terminal process command.
    return $terminal_command;
};

# ============================================================================ #
# Subroutine get_terminal_path                                                 #
# ============================================================================ #
sub get_terminal_path {
    # Assign the subroutine argument to the local variable.
    my $terminal_command = $_[0];
    # Initialise the return variable.
    my $terminal_path = "";
    # Define the regular expression for white spaces.
    my $re_ws = qr/\s+/;
    # Define the regular expression for command line arguments.
    my $re_args = qr/(?<= )(-.*?)(?= |$)/;
    # Check terminal command on white spaces.
    if ($terminal_command =~ /$re_ws/) {
        # Initialise the progs array.
        my @progs = ();
        # Assign terminal command to raw string.
        my $raw_string = $terminal_command;
        # Remove all terminal command line arguments.
        $raw_string =~ s/$re_args//g;
        # Split the terminal command line by white spaces.
        my @parts = split /$re_ws/, $raw_string;
        # Loop over the elements of the array.
        foreach (@parts) {
            # Check if the element is an executable.
            if (`which $_` ne "") {
                # Add executable to new array.
                push(@progs, $_);
            };
        };
        # Check number of executables.
        if (@progs == 0) {
            # Assign first element to path.
            $terminal_path = $parts[0];
        } else {
            if (@progs > 1) {
                # Assign first element to path.
                $terminal_path = $progs[1];
            } else {
                # Assign second element to path.
                $terminal_path = $progs[0];
            };
        };
    } else {
        # Set variable $terminal_path.
        $terminal_path = $terminal_command;
    };
    # Return the terminal name.
    return $terminal_path;
};

# ============================================================================ #
# Subroutine get_terminal_name                                                 #
# ============================================================================ #
sub get_terminal_name {
    # Assign the subroutine argument to the local variable.
    my $terminal_path = $_[0];
    # Initialise the return variable.
    my $terminal_name = "";
    # Define the regular expression for program pathes.
    my $re_pp = qr/^\/.*\//;
    # Check the variable $terminal_path on the existence of a path.
    if ($terminal_path =~ /$re_pp/) {
        # Remove the path from variable $terminal_path.
        $terminal_name = $terminal_path =~ s/$re_pp//r;
    } else {
        # Assign variable $terminal_path to variable $terminal_name.
        $terminal_name = $terminal_path;
    };
    # Return the terminal name.
    return $terminal_name;
};

# ============================================================================ #
# Subroutine get_terminal_ftn                                                  #
# ============================================================================ #
sub get_terminal_ftn {
    # Assign the subroutine argument to the local variable.
    my $terminal_name = $_[0];
    # Initialise the return variable.
    my $terminal_ftn = "";
    # Convert terminal name to lower case.
    $terminal_name = lc($terminal_name);
    # Check terminal name.
    if (defined $termhash{$terminal_name}) {
        # Get the friendly terminal name.
        $terminal_ftn = $termhash{$terminal_name};
    } else {
        # Set the friendly terminal name.
        $terminal_ftn = $terminal_name;
    };
    # Return the friendly terminal name.
    return $terminal_ftn;
};

# ============================================================================ #
# Subroutine whichterminalami                                                  #
#                                                                              #
# Description:                                                                 #
# Identify the terminal emulator.                                              #
#                                                                              #
# @argument: $_[0] => $flag  Output format flag  (scalar)                      #
# @return:   $terminal       Terminal name       (scalar)                      #
# ============================================================================ #
sub whichterminalami {
    # Initialise the output format flag variable.
    my $flag = "";
    # Set the output format flag.
    if ($OutputFormat ne "") {
        # Set the output format flag variable based on the global variable.
        $flag = $OutputFormat;
    } else {
        # Get the output format flag variable from the subroutine argument.
        $flag = (defined $_[0] ? $_[0] : '');
    };
    # Initialise the terminal variables.
    my $terminal = "";
    my $terminal_ftn = "";
    my $terminal_name = "";
    my $terminal_path = "";
    # Identify the terminal process command line.
    my $terminal_command = terminal_identifier();
    # If terminal process command line is an empty string it is an unknown terminal.
    if ($terminal_command eq "") {
        # Return unknown terminal.
        return "Unknown Terminal";
    };
    # Get the terminal path.
    $terminal_path = get_terminal_path($terminal_command);
    # Get the terminal name.
    $terminal_name = get_terminal_name($terminal_path);
    # Get the friendly terminal name.
    $terminal_ftn = get_terminal_ftn($terminal_name);
    # Return remote console or system console based on sshd or login.
    if (($terminal_name) =~ /^sshd.*/) {
        return "Remote Console";
    } elsif (($terminal_name) =~ /^login.*/) {
        return "System Console";
    };
    # Return the terminal string based on the flag setting.
    if ($flag eq "") {
        $terminal = $terminal_name;
    } elsif ($flag eq "FTN") {
        $terminal = $terminal_ftn;
    } elsif ($flag eq "PATH") {
        $terminal = $terminal_path;
    } elsif ($flag eq "PROC") {
        $terminal = $terminal_command;
    };
    # Return the found terminal string.
    return $terminal;
};

1;

__DATA__

# Some of the terminal emulators listed below were tested with the package in
# the test environment, or are generally known as terminal emulators, or come
# from other sources. Care was taken to ensure that the executable and the
# publicly used name match. Without further tests, the latter statement is to
# be seen relatively. The list cannot claim to be complete.

# Begin terminals
ajaxterm                => AjaxTerm
alacritty               => Alacritty
altyo                   => AltYo
aminal                  => Aminal
anyterm                 => anyterm
aterm                   => aterm
blackbox                => Black Box
black-screen            => Black Screen
blinkshell              => Blink Shell
boxi                    => Boxi
cicslterm               => cicslterm
cathode                 => Cathode
commander               => Commander One
conemu                  => ConEmu
contour                 => Contour Terminal
coolterm                => CoolTerm
cool-retro-term         => Cool Retro Term
cutecom                 => CuteCom
deepin-terminal         => Deepin Terminal
domterm                 => DomTerm
dterm                   => dterm
dtterm                  => dtterm
edex-ui                 => eDEX-UI
eterm                   => Eterm
extraterm               => Extraterm
fbpad                   => Fbpad
fbterm                  => Fbterm
finalterm               => Final Term
flexterm                => Flex Term
foot                    => foot
gnome-terminal-server   => GNOME Terminal
gtkterm                 => GtkTerm
guake                   => Guake Terminal
havoc                   => Havoc
hterm                   => hterm
hyper                   => Hyper
iterm                   => iTerm
iterm2                  => iTerm2
kitty                   => kitty
konsole                 => Konsole
kterm                   => kterm
libiterm                => libiterm
lilyterm                => LilyTerm
lterm                   => lterm
lxterminal              => LXTerminal
macterm                 => MacTerm
macwise                 => MacWise
mate-terminal           => MATE-Terminal
minicom                 => Minicom
mlterm                  => mlterm
mlterm-tiny             => mlterm-tiny
mrxvt                   => mrxvt
netterm                 => NetTerm
noter                   => NoTer
okidk                   => OkiDK
pantheon-terminal       => Pantheon Terminal
picocom                 => PicoCom
pterm                   => pterm
powershell              => PowerShell
powerterm               => PowerTerm
putty                   => PuTTY
qtterm                  => QtTerm
qterminal               => QTerminal
realterm                => RealTerm
rocket                  => Rocket
roxterm                 => ROXTerm
rxvt                    => rxvt
rxvt-unicode            => rxvt-unicode
rxvt-unicode-truecolor  => rxvt-unicode-truecolor
sakura                  => Sakura
screen                  => SCREEN
shellcraft              => ShellCraft
stjerm                  => stjerm
stterm                  => stterm
tabby                   => Tabby
terminal                => Terminal
terminalpp              => terminalpp
terminator              => Terminator
terminix                => Terminix
terminology             => Terminology
terminus                => Terminus
termite                 => Termite
termit                  => Termit
teraterm                => Tera Term
tilda                   => Tilda
tilix                   => Tilix
tinyterm                => TinyTERM
tmux                    => tmux
treeterm                => TreeTerm
tterm                   => TTerm
tym                     => tym
upterm                  => Upterm
urxvt                   => urxvt
uxterm                  => UXTerm
warp                    => Warp
wazaterm                => Wazaterm
wezterm                 => WezTerm
windterm                => WindTerm
wterm                   => Wterm
xfce4-terminal          => Xfce4 Terminal
xiki                    => Xiki
xiterm                  => xiterm
xiterm+thai             => xiterm+thai
xterm                   => XTerm
xvt                     => Xvt
yakuake                 => Yakuake
yat                     => YAT
zoc                     => ZOC
zterm                   => ZTerm
# End terminals

# The shells listed below are known or come from an internet search. The list
# does not claim to be complete.

# Begin shells
ash
bash
csh
dash
dtksh
es
esh
fish
jsh
ksh
ksh88
ksh93
mksh
nash
oksh
pdksh
pfbash
pfcsh
pfexec
pfksh
pftcsh
pfsh
pfzsh
psh
psh2
rbash
rc
sash
screen
scsh
sh
tcsh
tmux
zsh
# End shells

__END__

# ---------------------------------------------------------------------------- #
# The package documentation in POD format starts here.                         #
# ---------------------------------------------------------------------------- #

=head1 NAME

Terminal::Identify - Perl extension for identifying the terminal emulator

=head1 SYNOPSIS

Methods call using a subroutine argument:

  use Terminal::Identify;                      # Imports all methods
  use Terminal::Identify qw(whichterminalami); # Imports method whichterminalami()

  # Identify the terminal emulator.
  whichterminalami(["PROC"|"PATH"|"FTN"]);                     # Standard methods invocation
  Terminal::Identify::whichterminalami(["PROC"|"PATH"|"FTN"]); # Alternate methods invocation

Methods call using the global variable:

  use Terminal::Identify;                      # Imports all methods
  use Terminal::Identify qw(whichterminalami); # Imports method whichterminalami()

  # Set the global output format flag.
  $OutputFormat = ["PROC"|"PATH"|"FTN"];
  $Terminal::Identify::OutputFormat = ["PROC"|"PATH"|"FTN"];

  # Identify the terminal emulator.
  whichterminalami();                     # Standard methods invocation
  Terminal::Identify::whichterminalami(); # Alternate methods invocation

=head1 OPTIONS

=head2 Output control

The string arguments C<PROC>, C<PATH> and C<FTN> in square brackets in the
method call are optional.

  ["PROC"|"PATH"|"FTN"]

The valid method arguments are separated by a logical or. The string arguments
are controlling the format of the output of the identified terminal. Without a
subroutine argument, the process name of the terminal emulator is printed to
the terminal window.

In addition to the usage of the valid method arguments, there is a global
variable which can be used to control the format of the output of the identified
terminal.

  $OutputFormat

If the global variable is set, the method arguments are ignored if existing in
the method call. Unset the process name of the terminal emulator is printed to
the terminal window.

=head2 Output format

As described above the output format of the identified terminal can be influenced
by the options C<"PROC">, C<"PATH"> and C<"FTN">.

The output format is as follows:

=over 4

  PROC => Full process command line of the terminal emulator

  PATH => Path to the location of the executable of the terminal emulator

  FTN =>  Friendly terminal name of the terminal emulator

=back

=head1 DESCRIPTION

The main objective of this package is to provide a method which is capable of
identifying the terminal emulator a logged-in user is actual using. In addition
to the terminal emulator, the system console and a remote console are also
recognised.

The logged-in user is related to a valid login shell directly. The login shell
of the logged-in user as well as the logged-in user is determined. Next the
terminal path to the pseudo terminal slave (pts) is identified. Based on the
previously informations the related process of the logged-in user, the login
shell and the terminal path is determined. The evaluation of the PID of the
process of the current running Perl script results in the PPID. The command
related to this PPID is the name of the terminal emulator in use. The package
works together with different terminal emulators. When terminal emulators are
spawned from an initial invoked terminal emulator, each terminal emulator is
correctly recognised. If the logged-in user changes during the session, this
is recognised. Also using the sudo command does not affect the recognition of
the terminal emulator.

The terminal emulator in use by the logged-in user can be identified by the
main command C<whichterminalami()> or the other defined aliases.

=head1 EXAMPLES

=head2 Example 1

  # Load the Perl module.
  use Terminal::Identify;

  # Declare the terminal variable.
  my $terminal;

  # Method call without an argument.
  $terminal = whichterminalami();
  print $terminal . "\n";

  # Method call with argument "PROC".
  $terminal = whichterminalami("PROC");
  print $terminal . "\n";

  # Method call with argument "PATH".
  $terminal = whichterminalami("PATH");
  print $terminal . "\n";

  # Method call with argument "FTN".
  $terminal = whichterminalami("FTN");
  print $terminal . "\n";

=head2 Example 2

  # Load the Perl module.
  use Terminal::Identify;

  # Declare the terminal variable.
  my $terminal;

  # Reset the global output format flag.
  $OutputFormat = "";

  # Method call without an argument.
  $terminal = whichterminalami();
  print $terminal . "\n";

  # Set the global output format flag.
  $OutputFormat = "PROC";

  # Method call without an argument.
  $terminal = whichterminalami();
  print $terminal . "\n";

  # Set the global output format flag.
  $OutputFormat = "PATH";

  # Method call without an argument.
  $terminal = whichterminalami();
  print $terminal . "\n";

  # Set the global output format flag.
  $OutputFormat = "FTN";

  # Method call without an argument.
  $terminal = whichterminalami();
  print $terminal . "\n";

=head1 SYSTEM COMPATIBILITY

The module will work on B<Linux> and on B<Unix> or B<Unix-like>
operating systems in general until something else was shown.

=head1 FUNCTIONALITY REQUIREMENT

The following Linux commands must be available for package functionality:

=over 4

=item * ps

=item * users

=item * which

=item * grep

=back

The subsequent system files must be exist for package functionality:

=over 4

=item * /etc/shells

=item * /etc/passwd

=back

=head1 METHOD ALIASES

Aliases for C<whichterminalami>, which can be used are:

  whichtermami       <=  whichterminalami
  which_terminal     <=  whichterminalami
  identify_terminal  <=  whichterminalami

=head1 TERMINALS TESTED

Terminal emulators tested so far with the package:

=over 4

=item * Alacritty

=item * Aterm

=item * Black Box

=item * Cool Retro Term

=item * Deepin Terminal

=item * Eterm

=item * Gnome Terminal

=item * Guake Terminal

=item * Hyper

=item * kitty

=item * Konsole

=item * LilyTerm

=item * LXTerminal

=item * MATE-Terminal

=item * mlterm

=item * mlterm-tiny

=item * pterm

=item * QTerminal

=item * ROXTerm

=item * Sakura

=item * screen

=item * Tabby

=item * Terminator

=item * Terminology

=item * Termit

=item * Tilda

=item * Tilix

=item * tmux

=item * UXTerm

=item * Xfce4-Terminal-Emulator

=item * xiterm+thai

=item * Xterm

=item * Yakuake

=back

=head1 TESTING ENVIRONMENT

The package has been installed on various personal computers and laptops. This
was done in the desktop environment using different terminal emulators, logged
into the system console locally and logged in remotely. The Linux OS is based
on Debian.

=head1 LIMITATIONS

The limitations of the package are given by the Linux commands and the Linux
system files which are used by the package. The Linux command C<ps>, the Linux
command C<users>, the Linux command C<which> and the Linux command C<grep> must
be available. The Linux system files C</etc/shells> and C</etc/passwd> must be
exist.

When the Linux command su is used, then the detection results in su as terminal
emulator, which is wrong. This has to be checked and changed.

=head1 OPEN ISSUES

Terminal emulators which are installed using Flatpak are not all the time correct
identified.

=head1 KNOWN BUGS

The system file /etc/shells is not existing on solaris. If /etc/shells not exists,
a backup solution must be integrated. This is a to-do for one of the next versions.

=head1 ERROR CODES

  1 = Windows is recognised as OS.
  2 = Linux command 'which' does not exist.
  3 = Linux command 'grep' does not exist.
  4 = Linux command 'users' does not exist.
  5 = Linux command 'ps' does not exist.

=head1 NOTES

Problems were found with the use of the Inline C module. The problem is caused
by user and root rights. Until this issue is resolved, the POSIX module is used
instead of the C code.

=head1 PROGRAM-TECHNICAL BACKGROUND

The Linux command ps can be used e.g. in Bash to find out, which terminal
emulator is in use by the current user. The command line to do this is quite
easy:

  ps -o 'cmd=' -p $(ps -o 'ppid=' -p $$)

The previous presented one-liner makes use of the fact, that a login shell e.g.
Bash or Zsh is used by the terminal emulator.

This can be verified by following command line:

  ps -o 'cmd=' -p $$

As consequence of this statement the PPID is the PID of the terminal emulator.
The command related to the PPID is the name or process which invoked the terminal
emulator.

If this procedure is done from within a script it fails in recognition of the
terminal emulator. There are a few hurdles to overcome in order to carry out this
procedure from within a script.

A distinction must be made between user and superuser, which invokes a script.
Calling a script using sudo makes a difference for the recognition of the terminal
emulator.

When the user logs in into the desktop, the user is connected to a login shell.
Nevertheless, the user, which executes a script, can be different to the
logged-in user.

Whenever a terminal is opened, this terminal is connected to a pseudo terminal
slave. These pseudo-terminal slaves are numbered consecutively.

It should also be noted that a script can be executed from the command line as
follows, maybe also with command line arguments:

  sudo perl -w testscript.pl

The goal is to find the process that belongs to the executed script. The PPID
is identified via the PID. This PPID is then the PID of the terminal emulator.
Accordingly, the command line in the process output is the process that started
the terminal emulator.

=head1 ABSTRACT

The module identifies the terminal emulator which the logged-in user is using
currently. For this purpose, the login shells and the logged-in users are
determined. The Perl script from which we identify the terminal emulator itself
runs in a pseudo terminal slave (pts) with its own identification number. This
pseudo terminal slave (pts) is identified, too. Based on all the former
informations, the terminal emulator in use can be determined. If the Perl script
runs from within the system console, the output returns the system console. It
is also recognised, when the script runs in a remote console.

=head1 SEE ALSO

ps(1) - Linux manual page

users(1) - Linux manual page

which(1) - Linux manual page

grep(1) - Linux manual page

shells(5) - Linux manual page

passwd(5) - Linux manual page

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
