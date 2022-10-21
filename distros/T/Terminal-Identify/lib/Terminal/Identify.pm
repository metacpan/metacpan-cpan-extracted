package Terminal::Identify;
# ------------------------------------------------------------------------------
# This package is inspired by a method using a shell like BASH to identify the
# terminal emulator which is in use by the logged-in user.
#
# The Linux command ps can be used to do this: 
# ps -o 'cmd=' -p $(ps -o 'ppid=' -p $$
# ------------------------------------------------------------------------------

# Load the basic Perl pragmas.
use 5.030000;
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
    $OutputFormat
);

# Base class of this module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.08';

# Load the Perl modules.
use POSIX qw(ttyname);

# Use inline C code.
#use Inline 'C';

# Define the Perl BEGIN block.
BEGIN {
    # Set the subroutine aliases.
    *whichtermami = \&whichterminalami;
    *which_terminal = \&whichterminalami;
    *identify_terminal = \&whichterminalami;
};

# Set the global output format.
our $OutputFormat = ""; 

# Assign terminal process name to known terminal name.
my %termhash = (
    "alacritty"              => "Alacritty",               # successful tested 
    "altyo"                  => "AltYo",                   # known, but not tested 
    "aterm"                  => "aterm",                   # successful tested
    "cool-retro-term"        => "Cool Retro Term",         # successful tested
    "deepin-terminal"        => "Deepin Terminal",         # successful tested
    "domterm"                => "DomTerm",                 # know, but not tested
    "Eterm"                  => "Eterm",                   # successful tested
    "extraterm"              => "Extraterm",               # know, but not tested 
    "fbpad"                  => "Fbpad",                   # know, but not tested
    "fbterm"                 => "Fbterm",                  # know, but not tested
    "finalterm"              => "Final Term",              # know, but not tested  
    "flexterm"               => "FlexTerm",                # know, but not tested
    "foot"                   => "foot",                    # know, but not tested
    "gnome-terminal-server"  => "Gnome Terminal",          # successful tested
    "guake"                  => "Guake Terminal",          # successful tested
    "hterm"                  => "HTerm",                   # know, but not tested
    "hyper"                  => "Hyper",                   # know, but not tested
    "kitty"                  => "kitty",                   # successful tested
    "konsole"                => "Konsole",                 # successful tested
    "lilyterm"               => "LilyTerm",                # successful tested
    "lxterminal"             => "LXTerminal",              # successful tested
    "mate-terminal"          => "MATE-Terminal",           # successful tested
    "mlterm"                 => "mlterm",                  # successful tested
    "mlterm-tiny"            => "mlterm-tiny",             # know, but not tested
    "pantheon-terminal"      => "Pantheon Terminal",       # know, but not tested 
    "pterm"                  => "pterm",                   # successful tested
    "qterminal"              => "QTerminal",               # successful tested
    "roxterm"                => "ROXTerm",                 # successful tested
    "rxvt"                   => "rxvt",                    # successful tested
    "rxvt-unicode"           => "rxvt-unicode",            # successful tested
    "rxvt-unicode-truecolor" => "rxvt-unicode-truecolor",  # know, but not tested
    "sakura"                 => "Sakura",                  # successful tested
    "stterm"                 => "stterm",                  # successful tested
    "tabby"                  => "Tabby",                   # know, but not tested
    "terminal"               => "Terminal",                # know, but not tested
    "terminator"             => "Terminator",              # successful tested
    "terminology"            => "Terminology",             # successful tested
    "termit"                 => "Termit",                  # successful tested
    "termite"                => "Termite",                 # know, but not tested
    "tilda"                  => "Tilda",                   # successful tested
    "tilix"                  => "Tilix",                   # know, but not tested
    "urxvt"                  => "urxvt",                   # successful tested
    "uxterm"                 => "UXTerm",                  # successful tested
    "wezterm"                => "WezTerm",                 # know, but not tested
    "xfce4-terminal"         => "Xfce4-Terminal-Emulator", # successful tested
    "xiterm+thai"            => "xiterm+thai",             # successful tested
    "xterm"                  => "XTerm",                   # successful tested
    "xvt"                    => "xvt",                     # know, but not tested
    "yakuake"                => "Yakuake"                  # successful tested
);

#------------------------------------------------------------------------------#
# Subroutine trim                                                              #
#                                                                              #
# Description:                                                                 #
# The subroutine removes white spaces from both ends of a string. This is done #
# by a logical or operation and using \s from regular expressions. Anchors are #
# begin of string and end of of string.                                        #
#                                                                              #
# @argument: $_[0]  string to trim  (scalar)                                   #
# @return:   $str   trimmed string  (scalar)                                   #
#------------------------------------------------------------------------------# 
sub trim {
    # Assign the function argument to the local string variable $str.  
    my $str = $_[0];
    # Trim the string from the left side and the right side.
    $str =~ s/^\s+|\s+$//g;
    # Return the trimmed string.
    return $str;    
};

#------------------------------------------------------------------------------# 
# Subroutine search_brackets                                                   #
#                                                                              #
# Description:                                                                 #
# Adds [ and ] to searchstring for grep.                                       # 
#------------------------------------------------------------------------------# 
sub search_brackets {
    # Assign the function argument to the local variable.  
    my $str = $_[0];
    # Add square brackets to the given string.
    substr($str, 0, 0) = '[';
    substr($str, 2, 0) = ']';
    # Return the modified string.
    return $str;
};

#------------------------------------------------------------------------------# 
# Subroutine read_file                                                         #
#                                                                              #
# Description:                                                                 #
# Read a file in one chunk. The retrieved content is stored in a string        #
# variable.                                                                    #
#                                                                              #
# @argument: $_[0]     filename      (scalar)                                  #
# @return:   $content  file content  (scalar)                                  #
#------------------------------------------------------------------------------# 
sub read_file {
    # Assign the function argument to the local variable.  
    my $file = $_[0];
    # Open a file handler for reading.
    open(my $fh, "<", $file);
    # Read the complete content from the file.
    my $content = do {local $/; <$fh>};
    # Close the file handler.
    close($fh);
    # Return the file content.
    return $content;
};

#------------------------------------------------------------------------------# 
# Subroutine login_users                                                       #
#                                                                              #
# Description:                                                                 #
# Write logged in user to array.                                               #
#------------------------------------------------------------------------------# 
sub login_users {
    # Assign the function argument to the local variable.  
    my $user = `users`;
    # Write logged-in user to array.
    my @user_arr = split ' ', $user;
    # Return the array.
    return @user_arr;
}

#------------------------------------------------------------------------------# 
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
# @return:   @login_shells  array with valid login shells  (array)             #
#------------------------------------------------------------------------------# 
sub login_shells {
    # Declare the login shells array.
    my @login_shells;
    # Set the file for reading.
    my $file = "/etc/shells";
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
    # Return the array with the login shells.
    return @login_shells;
};

#------------------------------------------------------------------------------# 
# Subroutine get_ppid                                                          #
#                                                                              #
# Description:                                                                 #
# Determine the PPID of the calling Perl script using the Linux command ps.    # 
# Argument: PID                                                                # 
# Returns:  PPID                                                               # 
#------------------------------------------------------------------------------# 
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

#------------------------------------------------------------------------------# 
# Subroutine terminal_command_line                                             #
#                                                                              #
# Description:                                                                 #
# Use the Linux command ps to get the command line of the process which is     #
# related to the terminal in use.                                              #
#                                                                              #
# @argument  $_[0]      PPID          (scalar)                                 #
# @return    $termproc  command line  (scalar)                                 #
#------------------------------------------------------------------------------# 
sub terminal_command_line {
    # Assign the subroutine argument to the local variable $ppid.
    my $ppid = $_[0];
    # Get the command column from the ps output.
    my $termproc = `ps --no-headers -o cmd:1 -p $ppid 2>/dev/null`;
    # Trim the command line output string.  
    $termproc = trim($termproc);
    # Return the process related to the terminal in use.
    return $termproc
};

#------------------------------------------------------------------------------# 
# Subroutine user_shell                                                        #
#                                                                              #
# Description:                                                                 #
# Get user login shell.                                                        #
#------------------------------------------------------------------------------# 
sub user_shell {
    # Assign the subroutine argument to the local variable $content.
    my $content = $_[0];
    my @user_arr = @{$_[1]};
    my @shell_arr = @{$_[2]};
    my @match;
    # Loop over the array with the lines of $content.
    foreach (split '\n', $content) {
        my ($user) = $_ =~ /^(.*?):.*/;
        my ($shell) = $_ =~ /^.*\/(.*)$/;
        if (grep(/^$user$/, @user_arr) && grep(/^$shell$/, @shell_arr)) {
            push(@match, $_);
        };
    };
    # Return the array @match.
    return @match;
};

#------------------------------------------------------------------------------# 
# Subroutine user_term                                                         #
#                                                                              #
# Description:                                                                 #
# Get the pseudo terminal slave, which is related to the executed Perl script. #
#------------------------------------------------------------------------------# 
sub user_term {
    # Assign the subroutine argument to the local variable $content.
    my @match = @{$_[0]};
    # Declare the array @result.
    my @result;
    # Get the terminal path.
    #my $term_path = TermPath();
    my $fileno = fileno(STDIN);
    my $term_path = ttyname($fileno);
    my ($term) = $term_path =~ /^.*\/dev\/(pts\/\d+)$/;
    if (!defined $term) {
        return ();
    };
    $term = search_brackets($term);
    # Loop over the matches.
    foreach (@match) {
        my ($user) = $_ =~ /^(.*?):.*/;
        my ($shell) = $_ =~ /^.*\/(.*)$/;
        $user = search_brackets($user);
        $shell = search_brackets($shell);
        my $process = `ps aux | grep $shell | grep $user | grep $term`;
        if ($process ne '') {
            # Add process to array @result.
            push(@result, $process);
        };
    };
    # Return the array @result.
    return @result;
};

#------------------------------------------------------------------------------# 
# Subroutine process_command_line                                              #
#                                                                              #
# Description:                                                                 #
# Identify the process command of the terminal in use.                         #
#------------------------------------------------------------------------------# 
sub process_command_line {
    # Declare the return variable.
    my $terminal;
    # Get the logged in users.
    my @user_arr = login_users();
    # Get the available login shells.
    my @shell_arr = login_shells();
    # Read the file /etc/passwd in variable $content.
    my $content = read_file("/etc/passwd");
    # Create the array with user and shell.
    my @match = user_shell($content, \@user_arr, \@shell_arr);
    # Create the array with user and term.
    @match = user_term(\@match);
    if (@match > 0) {
        # Split up the process by lines and white spaces.
        my @columns = split /\s+/, $match[0];
        # Extract the PID from the array.
        my $pid = $columns[1];
        # Get the PPID from the command ps.
        my $ppid = get_ppid($pid);
        # Get the terminal in use from the command ps.
        $terminal = terminal_command_line($ppid);
    } else {
        # Set variable $terminal to NONE.
        $terminal = "NONE";
    };
    # Return the terminal process command or NONE.
    return $terminal
};

#------------------------------------------------------------------------------# 
# Subroutine remove_arguments                                                  # 
#------------------------------------------------------------------------------# 
sub remove_arguments {
    # Assign subroutine argument to the local array.
    my @old_parts = @{$_[0]};
    # Declare the new parts array.
    my @new_parts;
    # Remove all arguments from the old array and store them in the new array.
    foreach (@old_parts) {
        if (substr($_, 0, 1) ne "-") {
            if (system("which $_ >/dev/null 2>&1") == 0) { 
                push(@new_parts, $_)
            }; 
        };
    };
    # Return the new parts array.
    return @new_parts;
}

#------------------------------------------------------------------------------# 
# Subroutine which_terminal                                                    # 
#                                                                              #
# Description:                                                                 #
# Identify the terminal name.                                                  #
#------------------------------------------------------------------------------# 
sub whichterminalami {
    # Get the output flag from the subroutine argument.
    my $flag = (defined $_[0] ? $_[0] : '');
    # Set the string variable.
    my $str = "Unknown Terminal";
    # Declace the terminal output variables.
    my $terminal;
    my $terminal_ftn;
    # Identify the terminal process command.
    my $terminal_process = process_command_line();
    # If terminal process is set to NONE it is the system console.
    if ($terminal_process eq "NONE") {
        # Return the system console.
        return "System Console";
    };
    # Split the process command line by white spaces.
    my @parts = split /\s+/, $terminal_process;
    # Remove command line arguments (-/--) from the command line.
    if ($terminal_process =~ /( -.*| --.*)/) {
        @parts = remove_arguments(\@parts);
    }
    # Preset variable $terminal_path
    my $terminal_path = $parts[0];
    # Check number of valid progrtam parts of the process line.
    if (@parts == 2) {
        # Check first and second element of array @parts.
        if (-f $parts[0] && -f $parts[1]) {
            # If both are files, second part is the terminal. 
            $terminal_path = $parts[1];
        };
    };
    # Remove the directory from the path.
    my $terminal_name = $terminal_path =~ s{^.*/}{}r;
    # Lookup terminal name in the terminal hash.
    if (defined $termhash{$terminal_name}) {
       # Get the friendly terminal name.
       $terminal_ftn = $termhash{$terminal_name};
    };
    if ($OutputFormat ne "") {
        $flag = $OutputFormat;
    };
    # Return terminal string based on flag setting.
    if ($flag eq "PROC") {
        $terminal = (defined $terminal_process ? $terminal_process : $str);
    } elsif ($flag eq "PATH") {
        $terminal = (defined $terminal_path ? $terminal_path : $str);
    } elsif ($flag eq "FTN") {
        $terminal = (defined $terminal_ftn ? $terminal_ftn : $str);
    } else {
        $terminal = (defined $terminal_name ? $terminal_name : $str);
    };
    # Return the identified terminal string.
    return $terminal;
};

1;

__DATA__
__C__

/*
 * -------------------
 * Function TermPath()
 * -------------------
 */
char* TermPath() {
  char* tty_name = ttyname(STDIN_FILENO);
  char* term_path = (tty_name != NULL) ? tty_name : NULL;
  return term_path;
};

__END__

# ---------------------------------------------------------------------------- #
# The package documentation in POD format starts here                          #
# ---------------------------------------------------------------------------- #

=head1 NAME

Terminal::Identify - Perl extension for identifying the terminal emulator

=head1 SYNOPSIS

Use the package like this

  use Terminal::Identify;                       # Exports all methods
  use Terminal::Identify qw(whichterminalami);  # Exports method whichterminalami()

  # Identify the terminal emulator in use.
  whichterminalami(["PROC"|"PATH"|"FTN"]);                      # Standard method call   
  Terminal::Identify::whichterminalami(["PROC"|"PATH"|"FTN"]);  # Alternate method call

or like this

  use Terminal::Identify;                       # Exports all methods
  use Terminal::Identify qw(whichterminalami);  # Exports method whichterminalami()

  # Set the global output format flag of the package.
  $OutputFormat = ["PROC"|"PATH"|"FTN"];
  $Terminal::Identify::OutputFormat = ["PROC"|"PATH"|"FTN"];

  # Identify the terminal emulator in use.
  whichterminalami();                      # Standard method call
  Terminal::Identify::whichterminalami() ; # Alternate method call

=head1 USAGE

The string arguments in the method call in square brackets are optional.
Without a subroutine argument the process name of the terminal is simply
identified. The valid method arguments are separated by a logical or. These
arguments are controlling the format of the output of the identified terminal.

In addition to the method arguments, a global package variable can be used 
to control the format of the output of the identified terminal. If the global
package variable is set, the method arguments are ignored if existing in the 
method call.

=head1 DESCRIPTION

The main objective of this package is to provide a method which is capable of
identifying the terminal emulator a logged-in user is actual using. 

The logged-in user is related to a valid login shell. Knowing this, the
logged-in user as well as the login shell of the logged-in user are determined.
Next the terminal path to the pseudo terminal slave (pts) is identified. Based
on this informations the related process of the logged-in user, the login shell
and the terminal path is determined. The evaluation of the PID of the process of
the running Perl script results in the PPID. The command related to this PPID
is the name of the terminal emulator in use. Not only a terminal emulator can be
identified by this package, it is also able to detect if a system console is being
used by a logged-in user. The package also works if different terminal emulators
are used and when they were spawned from on initial started terminal emulator.

The terminal emulator in use by the logged-in user can be identified by the
main command C<whichterminalami> and the other defined aliases.

=head1 OUTPUT FORMAT

The output format of the identified terminal can be influenced by the subroutine
arguments C<"PROC">, C<"PATH"> and C<"FTN">.

=over 4 

=item * "PROC"

  PROC => Full process of the terminal emulator in use. 

=item * "PATH"

  PATH => Path to the location of the terminal emulator in use.

=item * "FTN"

  FTN => Friendly terminal name of the terminal emulator in use.

=back

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

=head1 ERROR CODES

No error codes yet

=head1 NOTES

No notes yet

=head1 SYSTEM COMPATIBILITY

The module should work on B<Linux> and on B<Unix> or B<Unix-like>
operating systems in general until something else was shown.

=head1 FUNCTIONALITY REQUIREMENT

Following Linux commands should be available for functionality:

=over 4 

=item * ps

=item * users

=item * shells

=item * passwd

=item * which

=item * grep

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

=item * Cool Retro Term

=item * Deepin Terminal

=item * Eterm

=item * Guake Terminal

=item * kitty

=item * Konsole

=item * LilyTerm

=item * LXTerminal

=item * MATE-Terminal

=item * mlterm

=item * pterm

=item * QTerminal

=item * ROXTerm

=item * Sakura

=item * Terminator

=item * Terminology

=item * Termit

=item * Tilda

=item * Tilix

=item * UXTerm

=item * Xfce4-Terminal-Emulator

=item * xiterm+thai

=item * Xterm

=item * Yakuake 

=back

=head1 LIMITATIONS

The limitations of the package are given by the Linux commands and the Linux
system files which are used by the package. The Linux command C<ps>, the Linux
command C<users> and the Linux command C<which> must be available. The Linux
system files C</etc/shells> and C</etc/passwd> must be exist.

=head1 OPEN ISSUES

Problems were found with the use of the Inline C module. The problem is caused
by user and root rights. Until this issue is resolved, the POSIX module is used
instead of the C code.   

=head1 KNOWN BUGS

Not known yet

=head1 ABSTRACT

The module identifies the terminal emulator which the logged-in user is using
currently. For this purpose, the login shells and the logged-in users are
determined. The Perl script from which we identify the terminal emulator itself
runs in a pseudo terminal slave (pts) with its own identification number. This
pseudo terminal slave (pts) is identified, too. Based on all the former
informations, the terminal emulator in use can be determined. If the Perl script
runs from within the system console, the output returns the system console. 

=head1 SEE ALSO

users(1) - Linux manual page

shells(5) - Linux manual page

passwd(5) - Linux manual page

ps(1) - Linux manual page

which(1) - Linux manual page

grep(1) - Linux manual page

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
