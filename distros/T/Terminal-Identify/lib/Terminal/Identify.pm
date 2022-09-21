package Terminal::Identify;

# Load the basic Perl pragmas.
use 5.030000;
use strict;
use warnings;

# Load the Perl pragma Exporter.
use vars qw(@ISA @EXPORT @EXPORT_OK);
use Exporter 'import';

# Exporting the implemented subroutines.
our @EXPORT = qw(
    whichterminalami
    whichtermami
    which_terminal
    identify_terminal
);

# Base class of this module.
our @ISA = qw(Exporter);

# Set the package version. 
our $VERSION = '0.03';

# Use Inline C code.
use Inline 'C' => <<'END_OF_C_CODE';

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

END_OF_C_CODE

# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
# Define the BEGIN block                                                       #
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++ #
BEGIN {
    *whichtermami = \&whichterminalami;
    *which_terminal = \&whichterminalami;
    *identify_terminal = \&whichterminalami;
};

# Assign terminal process to terminal name.
my %termhash = (
    "alacritty"             => "Alacritty",
    "aterm"                 => "aterm",
    "cool-retro-term"       => "Cool Retro Term",
    "deepin-terminal"       => "Deepin Terminal",
    "Eterm"                 => "Eterm",
    "gnome-terminal-server" => "Gnome Terminal",
    "guake"                 => "Guake Terminal",
    "kitty"                 => "kitty",
    "konsole"               => "Konsole",
    "lilyterm"              => "LilyTerm",
    "lxterminal"            => "LXTerminal",
    "mate-terminal"         => "MATE-Terminal",
    "mlterm"                => "mlterm",
    "mlterm-tiny"           => "mlterm-tiny",
    "pterm"                 => "pterm", 
    "qterminal"             => "QTerminal", 
    "roxterm"               => "ROXTerm",
    "rxvt"                  => "rxvt",
    "rxvt-unicode"          => "rxvt-unicode",
    "sakura"                => "Sakura",
    "stterm"                => "stterm",
    "terminal"              => "Terminal",
    "terminator"            => "Terminator",
    "terminology"           => "Terminology",
    "termit"                => "Termit",
    "tilda"                 => "Tilda",
    "tilix"                 => "Tilix",
    "urxvt"                 => "urxvt",
    "uxterm"                => "UXTerm",
    "xfce4-terminal"        => "Xfce Terminal-Emulator",
    "xiterm+thai"           => "xiterm+thai",
    "xterm"                 => "Xterm",
    "yakuake"               => "Yakuake"
);

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
# Subroutine search_brackets                                                   #
# Adds [ and ] to searchstring for grep                                        # 
#------------------------------------------------------------------------------# 
sub search_brackets {
    my $str = $_[0];
    substr($str, 0, 0) = '[';
    substr($str, 2, 0) = ']';
    return $str;
};

#------------------------------------------------------------------------------# 
# Subroutine read_file                                                         #
#------------------------------------------------------------------------------# 
sub read_file {
    my $file = $_[0];
    open(my $fh, "<", $file);
    my $content = do { local $/; <$fh> };
    close $fh;
    return $content;
};

#------------------------------------------------------------------------------# 
# Subroutine login_users                                                       #
#------------------------------------------------------------------------------# 
sub login_users {
    my $user = `users`;
    my @user_arr = split ' ', $user;
    return @user_arr;
}

#------------------------------------------------------------------------------# 
# Subroutine login_shells                                                       #
#------------------------------------------------------------------------------# 
sub login_shells {
    my @login_arr;
    my $content = read_file("/etc/shells");
    foreach (split '\n', $content) {
        my $line = trim($_);
        if ($line =~ /^\/.*\/(.*)$/) {
            my ($shell) = $line =~ /^\/.*\/(.*)$/;
            push(@login_arr, $shell);
        };
    };
    my %hash = map { $_, 1 } @login_arr;
    @login_arr = keys %hash;
    return @login_arr;
};

sub get_ppid {
    my $pid = $_[0]; 
    # Get the PPID from the command ps.
    my $ppid = `ps -o 'ppid=' -p $pid`;
    # Trim the PPID.  
    $ppid = trim($ppid);
    return $ppid;
};

sub get_terminal {
    my $ppid = $_[0];
    my $terminal = `ps -o 'cmd=' -p $ppid`;
    # Trim the terminal variable.  
    $terminal = trim($terminal);
    return $terminal
};

sub user_shell {
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
    return @match;
};

sub user_term {
    my @match = @{$_[0]};
    #print @match;
    my @result;
    # Get the terminal path.
    my $term_path = TermPath();
    my ($term) = $term_path =~ /^.*\/dev\/(pts\/\d+)$/;
    $term = search_brackets($term);
    # Loop over the matches.
    foreach (@match) {
        my ($user) = $_ =~ /^(.*?):.*/;
        my ($shell) = $_ =~ /^.*\/(.*)$/;
        $user = search_brackets($user);
        $shell = search_brackets($shell);
        my $process = `ps aux | grep $shell | grep $user | grep $term`;
        if ($process ne '') {
            push(@result, $process);
        };
    };
    return @result;
};

#------------------------------------------------------------------------------# 
# Subroutine which_terminal                                                    # 
# Terminal identification using bash:                                          #
# ps -o 'cmd=' -p $(ps -o 'ppid=' -p $$)                                       #
# my $tshell = LoginShell();                                                   # 
# ($shell) = $tshell =~ /^.*\/(.*)$/;                                          #
# cat /etc/shells                                                              #
#------------------------------------------------------------------------------# 
sub whichterminalami {
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
    # Split up the process by lines and white spaces.
    my @columns = split /\s+/, $match[0];
    # Extract the PID from the array.
    my $pid = $columns[1];
    # Get the PPID from the command ps.
    my $ppid = get_ppid($pid);
    # Get the terminal in use from the command ps.
    my $terminal = get_terminal($ppid);
    # Split the terminal string by white spaces.
    my @parts = split /\s+/, $terminal;
    # If it has 2 elements, it is command and argument.
    if (@parts == 2) {
        # Terminal is part 1.
        $terminal = $parts[1];
    };
    # Remove the path.
    $terminal =~ s{^.*/}{};
    # Lookup terminal in hash.
    if (defined $termhash{$terminal}) {
        # Get the friendly terminal name.
        $terminal = $termhash{$terminal};
    };
    # Return the terminal name.
    return $terminal
};

1;

__END__
# Below is the package documentation.

=head1 NAME

Terminal::Control - Perl extension for identifying the terminal window in use

=head1 SYNOPSIS

  use Terminal::Identify;

  # Get informations about the terminal.

  whichterminalami();

Variables in square brackets in the method call are optional. They are in the
related method predefined.

In general every method is still accessible from outside the module using the
syntax I<Terminal::Control::method_name>.

=head1 DESCRIPTION

=head2 Preface

The main goal of this module is offering a methods which is able to identify
the terminal emulator, which a user uses.

=head2 Methods summary

The terminal emulator in use can be identified by the command itself and the 
aliases.

=head2 List of methods

B<Standard methods>

=over 4 

=item * whichterminalami()

=back

=head1 METHODS

B<whichterminalami()>

Get the name of the terminal emulator, which is in use by the user. First
the method tries to fetch the login shell. Next the path to the terminal
is determined. Based on this informations the related process to login shell
and terminal path is identified. Evaluation of the PPID results in the parents
process ID. The command related to this PID is the name of the terminal in use.   

Variables in square brackets in the method call are optional. They are in the
related method predefined.

=head1 ERROR CODES

No error codes yet

=head1 EXAMPLES

  my $terminal = whichterminalami();
  print $term . "\n";

=head1 VARIABLES EXPLANATION

No variables yet

=head1 NOTES

No notes yet

=head1 SYSTEM COMPATIBILITY

The module should work on B<Linux> as well as B<Unix> or B<Unix-like>
operating systems in general until something else was shown.

=head1 FUNCTIONALITY REQUIREMENT

=over 4 

=item * ps

=item * users

=item * shells

=item * passwd

=back

=head1 PORTABILITY

The module should work on B<Linux> as well as B<Unix> or B<Unix-like>
operating systems in general until something else was shown.

=head1 METHOD ALIASES

  whichtermami       <=  whichterminalami
  which_terminal     <=  whichterminalami
  identify_terminal  <=  whichterminalami

=head1 TERMINALS TESTED

As described above, terminal emulators or the system console are used to
interact with the operating system.

Terminals tested so far with the module:

=over 4

=item * Aterm

=item * Eterm

=item * Guake Terminal

=item * kitty

=item * LXTerminal

=item * MATE-Terminal

=item * ROXTerm

=item * Terminology

=item * Tilix

=item * Xterm

=back

=head1 LIMITATIONS

Not known yet

=head1 OPEN ISSUES

None so far

=head1 KNOWN BUGS

Not known yet

=head1 ABSTRACT

The module identifies the terminal which the logged in user is using currently.
For this purpose, the login shell and the logged-in users are determined. The 
Perl script runs in a pseudo terminal shell with its own identification number.
This pseudo terminal shell is also identified. Based on this data, the terminal
emulator used can be determined.

=head1 SEE ALSO

users(1) - Linux manual page

shells(5) - Linux manual page

passwd(5) - Linux manual page

ps(1) - Linux manual page

=head1 AUTHOR

Dr. Peter Netz, E<lt>ztenretep@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Dr. Peter Netz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.30.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
