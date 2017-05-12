use 5.008;
use strict;
use warnings;

package Term::Shell::Enhanced;
BEGIN {
  $Term::Shell::Enhanced::VERSION = '1.101420';
}

# ABSTRACT: More functionality for Term::Shell
use Sys::Hostname;
use Getopt::Long;
use Cwd;
use parent qw(
  Data::Inherited
  Term::Shell
  Class::Accessor::Complex
);
__PACKAGE__->mk_hash_accessors(qw(opt))->mk_accessors(
    qw(
      num hostname log name longname prompt_spec history_filename
      )
);

# These aren't the constructor()'s DEFAULTS()!  Because new() comes from
# Term::Shell, we don't have the convenience of the the 'constructor'
# MethodMaker-generated constructor. Therefore, Term::Shell::Enhanced defines
# its own mechanism.
sub DEFAULTS {
    my $self = shift;
    (   num         => 0,
        name        => 'mysh',
        longname    => 'My Custom Shell',
        prompt_spec => ': \n:\#; ',
        hostname    => ((split(/\./, hostname))[0]),
    );
}

sub get_history_filename {
    my $self     = shift;
    my $filename = $self->history_filename;
    return $filename if defined $filename;

    # Per default, the history file name is derived from the shell name, with
    # non-word characters suitably changed to make a sane filename.
    (my $name = $self->name) =~ s/\W/_/g;
    "$ENV{HOME}/.$name\_history";
}

sub init {
    my $self = shift;
    $self->SUPER::init(@_);
    my %args = @{ $self->{API}{args} };
    $self->log($args{log}) unless defined $self->log;
    $self->opt($args{opt}) unless defined $self->opt;
    my %defaults = $self->every_hash('DEFAULTS');
    while (my ($key, $value) = each %defaults) {
        $self->$key($value) unless defined $self->$key;
    }

    # Only now can we try to read the history file, because the
    # 'history_filename' might have been defined in the DEFAULTS().
    if ($self->{term}->Features->{setHistory}) {
        my $filename = $self->get_history_filename;
        if (-r $filename) {
            open(my $fh, '<', $filename)
              or die "can't open history file $filename: $!\n";
            chomp(my @history = <$fh>);
            $self->{term}->SetHistory(@history);
            close $fh or die "can't close history file $filename: $!\n";
        }
    }
}

sub print_greeting {
    my $self = shift;
    printf <<EOINTRO, $self->name, $self->longname, our $VERSION;

%s -- %s (v%s)

Type 'help' for help, 'help <command>' for more detailed help on a command.

EOINTRO
}

sub precmd {
    my ($self, $args) = @_[0,3];
    @$args = $self->expand(@$args);
}

sub expand {
    my $self = shift;
    for (@_) {

        # it's easier to do this here instead of in cmd() because the input
        # will already have been split into words, so we can use '^' in
        # regexes to do what we mean.
        s[^~][$ENV{HOME}];
        s[\$([_A-Za-z0-9]+)][$ENV{$1} || '']eg;
    }
    @_;
}

sub cmd {
    my $self = shift;
    my $line = shift;
    if ($line =~ /^(\w+)/) {
        my $word = $1;
        if (exists $self->{SHELL}{alias}{$word}) {
            $line =~ s/^$word/ $self->{SHELL}{alias}{$word} /g;
        }
    }
    $self->SUPER::cmd($line);
}

sub PROMPT_VARS {
    my $self = shift;
    (   h    => $self->hostname,
        n    => $self->name,
        '#'  => $self->num,
        '\\' => '\\',
    );
}

# Can't use every_hash, because that caches and we might need dynamic values,
# such as the prompt number ($self->num)
sub prompt_str {
    my $self = shift;
    $self->num($self->num + 1);
    my %prompt_vars = $self->every_hash('PROMPT_VARS', 1);    # no caching
    (my $prompt = $self->prompt_spec) =~ s/\\(.)/$prompt_vars{$1} || ''/ge;
    $prompt;
}

# The empty command; this sub needs to be there or the shell would exit
sub run_ {
    my $self = shift;

    # don't let the empty command count
    $self->num($self->num - 1);
}

sub postloop {
    my $self = shift;
    print "\n";
    if ($self->{term}->Features->{getHistory}) {
        my $filename = $self->get_history_filename;
        open(my $fh, '>', $filename)
          or die "can't open history file $filename for writing: $!\n";
        print $fh "$_\n" for grep { length } $self->{term}->GetHistory;
        close $fh or die "can't close history file $filename: $!\n";
    }
}

# ========================================================================
# External commands
# ========================================================================
sub smry_eval { "how to evaluate Perl code" }

sub help_eval {
    <<'END' }
You can evaluate snippets of Perl code just by putting them on a line
beginning with !:

  psh:~> ! print "$_\n" for keys %ENV

END
{
    my $eval_num = "000001";

    sub catch_run {
        my ($o, $command, @args) = @_;

        # Evaluate perl code if it's a ! line.
        if ($command =~ s/^!//) {
            (my $code = $o->line) =~ s/^!//;
            my $really_long_string = <<END;
package Term::Shell::Enhanced::namespace_$eval_num;
{
    no strict;
    eval "no warnings";
    local \$^W = 0;
    $code;
}
END
            {
                local *_;
                my ($eval_num, $o, $command, @args, $code);
                eval $really_long_string;
            }
            print "$@\n" if $@;
            $eval_num++;
        } elsif ($command =~ s/^@//) {

            # Real external commands.
            system($command, @args);
        } elsif ($command =~ s/^://) {

            # The noop; ignore it
        } else {
            print "unknown command\n";
        }
    }
}

# ========================================================================
# set
# ========================================================================
sub smry_set { 'set environment variables' }

sub help_set {
    <<'END' }
set: set [ name[=value] ... ]
    set lets you manipulate environment variables. You can view environment
    variables using 'set'. To view specific variables, use 'set name'. To set
    environment variables, use 'set foo=bar'.

END

sub run_set {
    shift;
    if (@_) {
        for my $arg (@_) {
            my ($key, $val) = split /=/, $arg;
            if (defined $val) {
                $ENV{$key} = $val;
            } else {
                $val = $ENV{$key} || '';
                print "$key=$val\n";
            }
        }
    } else {
        my ($key, $val);
        while (($key, $val) = each %ENV) {
            print "$key=$val\n";
        }
    }
}

# ========================================================================
# cd
# ========================================================================
sub smry_cd { 'change working directory' }

sub help_cd {
    <<'END' }
cd: cd [dir]
    Change the current directory to the given directory. If no directory is
    given, the current value of $HOME is used.

END

sub run_cd {
    my $dir = $_[1];
    $dir = $ENV{HOME} unless defined $dir;
    chdir $dir or do {
        print "$0: $dir: $!\n";
        return;
    };
    $ENV{PWD} = $dir;
}

# ========================================================================
# pwd
# ========================================================================
sub smry_pwd { 'print working directory' }

sub help_pwd {
    <<'END' }
pwd: cwd
    Prints the current working directory.

END

sub run_pwd {
    print getcwd;
}

# ========================================================================
# alias
# ========================================================================
sub smry_alias { 'view or set command aliases' }

sub help_alias {
    <<'END' }
alias: [ name[=value] ... ]
    'alias' with no arguments prints the list of aliases in the form
    NAME=VALUE on standard output. An alias is defined for each NAME whose
    VALUE is given.

END

sub run_alias {
    my $o = shift;
    if (@_) {
        for my $a (@_) {
            my ($key, $val) = split /=/, $a;
            if (defined $val) {
                $o->{SHELL}{alias}{$key} = $val;
            } else {
                $val = $o->{SHELL}{alias}{$key};
                print "alias $key=$val\n" if defined $val;
                print "alias: '$key' not found\n" if not defined $val;
            }
        }
    } else {
        my %alias = %{ $o->{SHELL}{alias} || {} };
        for my $alias (sort keys %alias) {
            printf "alias %s=%s\n", $alias, $alias{$alias};
        }
    }
}

# ========================================================================
# echo
# ========================================================================
sub smry_echo { 'output the args' }

sub help_echo {
    <<END }
echo [arg ...]
  Output the args.

END

sub run_echo {
    my ($self, @args) = @_;
    my @exp = $self->expand(@args);
    defined $_ or $_ = '' for @exp;
    print "@exp\n" if @exp;
}

# ========================================================================
# quit
# ========================================================================
sub smry_quit { 'exits the program' }

sub help_quit {
    <<END }
quit
  Exits the program.

END

sub run_quit {
    my $self = shift;
    $self->run_exit;
}

# ========================================================================
# apropos
# ========================================================================
sub smry_apropos { 'like "help", but limited to a topic' }

sub help_apropos {
    <<END }
apropos <word>
  Like the "help" command, but limits the information to commands that contain
  the given word in the command name or the summary.

END

# The implementation is taken directly from the run_help() method.
sub run_apropos {
    my $self = shift;
    my $word = shift;
    $word = '' unless defined $word;
    print "Type 'help command' for more detailed help on a command.\n";
    my (%cmds, %docs);
    for my $h (keys %{ $self->{handlers} }) {
        next unless length($h);
        next
          unless grep { defined $self->{handlers}{$h}{$_} } qw(run smry help);
        my $dest = exists $self->{handlers}{$h}{run} ? \%cmds : \%docs;
        my $smry =
          exists $self->{handlers}{$h}{smry}
          ? $self->summary($h)
          : "undocumented";
        my $help =
          exists $self->{handlers}{$h}{help}
          ? (
            exists $self->{handlers}{$h}{smry}
            ? ""
            : " - but help available"
          )
          : " - no help available";
        $dest->{"    $h"} = "$smry$help";
    }
    my (%apropos_cmds, %apropos_docs);

    # retain only matching commands and docs descriptions
    for my $cmd (keys %cmds) {
        next if index("$cmd$cmds{$cmd}", $word) == -1;
        $apropos_cmds{$cmd} = $cmds{$cmd};
    }
    for my $doc (keys %docs) {
        next if index("$doc$docs{$doc}", $word) == -1;
        $apropos_docs{$doc} = $docs{$doc};
    }
    print "  Commands:\n" if %apropos_cmds;
    $self->print_pairs(
        [ sort keys %apropos_cmds ],
        [ map { $apropos_cmds{$_} } sort keys %apropos_cmds ],
        ' - ', 1
    );
    print "  Extra Help Topics: (not commands)\n" if %apropos_docs;
    $self->print_pairs(
        [ sort keys %apropos_docs ],
        [ map { $apropos_docs{$_} } sort keys %apropos_docs ],
        ' - ', 1
    );
}
1;


__END__
=pod

=for stopwords cmd fini getopt postloop precmd

=head1 NAME

Term::Shell::Enhanced - More functionality for Term::Shell

=head1 VERSION

version 1.101420

=head1 SYNOPSIS

    package MyShell;
    use parent qw(Term::Shell::Enhanced);
    sub run_date { print scalar localtime, "\n" }
    sub smry_date { 'prints the current date and time' }

    sub help_date {
        'This command prints the current date and time as returned
         by the localtime() function.'
    }

    package main;
    my $shell = MyShell->new;
    $shell->print_greeting;
    $shell->cmdloop;

=head1 DESCRIPTION

This class subclasses L<Term::Shell> and adds some functionality.

=head1 METHODS

=head2 DEFAULTS

This method returns a hash of default attribute mappings. Among these, the
shell's name is set to C<mysh>; the prompt is set and the hostname is set per
L<Sys::Hostname>. You can override these attributes when subclassing this
class or when instantiating the shell.

=head2 PROMPT_VARS

Defines variables that can be used in prompt strings. See L</"FEATURES"> for
details.

=head2 catch_run

This is a fallback handler used by L<Term::Shell> when the C<run> command is
invoked on an unimplemented command. It checks whether the command line
entered starts with a C<!> and if so, evaluates it as a perl command. If the
command line starts with a C<@>, it is executed as a C<system()> command. If
the command line starts with a C<:>, it is ignored.

=head2 cmd

Extends L<Term::Shell>'s C<cmd()> by adding aliases. See L</"FEATURES"> for
details.

=head2 expand

When the command line has been split into words, this method is called. It
performs tilde and environment variable expansion.

=head2 get_history_filename

Returns the name of the file in which the shell's command line history is
being stored. If the C<history_filename> attribute is defined, that value will
be returned. Otherwise C<%s_history> where C<%s> is replaced by the shell's
name.

=head2 help_alias

Returns a help string for the C<alias> command.

=head2 help_apropos

Returns a help string for the C<apropos> command.

=head2 help_cd

Returns a help string for the C<cd> command.

=head2 help_echo

Returns a help string for the C<cd> command.

=head2 help_eval

Returns a help string for the C<eval> command.

=head2 help_pwd

Returns a help string for the C<pwd> command.

=head2 help_quit

Returns a help string for the C<quit> command.

=head2 help_set

Returns a help string for the C<set> command.

=head2 init

FIXME

=head2 postloop

FIXME

=head2 precmd

FIXME

=head2 print_greeting

FIXME

=head2 prompt_str

FIXME

=head2 run_

FIXME

=head2 run_alias

Runs the C<alias> command.

=head2 run_apropos

Runs the C<apropos> command.

=head2 run_cd

Runs the C<cd> command.

=head2 run_echo

Runs the C<cd> command.

=head2 run_pwd

Runs the C<pwd> command.

=head2 run_quit

Runs the C<quit> command.

=head2 run_set

Runs the C<set> command.

=head2 smry_alias

Returns a summary string for the C<alias> command.

=head2 smry_apropos

Returns a summary string for the C<apropos> command.

=head2 smry_cd

Returns a summary string for the C<cd> command.

=head2 smry_echo

Returns a summary string for the C<cd> command.

=head2 smry_eval

Returns a summary string for the C<eval> command.

=head2 smry_pwd

Returns a summary string for the C<pwd> command.

=head2 smry_quit

Returns a summary string for the C<quit> command.

=head2 smry_set

Returns a summary string for the C<set> command.

=head1 FEATURES

The following features are added:

=over 4

=item C<history>

When the shell starts up, it tries to read the command history from the
history file. Before quitting, it writes the command history to the history
file - it does not append to it, it overwrites the file.

The default history file name is the shell name - with non-word characters
replaced by underscores -, followed by C<_history>, as a dotfile in
C<$ENV{HOME}>. For example, if you shell's name is C<mysh>, the default
history file name will be C<~/.mysh_history>.

You can override the history file name in the C<DEFAULTS()>, like this:

    use constant DEFAULTS => (
        history_filename => ...,
        ...
    );

=item C<alias replacement>

See the C<alias> command below.

=item C<prompt strings>

When subclassing Term::Shell::Enhanced, you can define how you want your
prompt to look like. Use C<DEFAULTS()> to override this.

    use constant DEFAULTS => (
        prompt_spec => ...,
        ...
    );

You can use the following prompt variables:

    h    the hostname
    n    the shell name
    '#'  the command number (increased after each command)
    \\   a literal backslash

You can extend the list of available prompt variables by defining your own
PROMPT_VARS() - they are cumulative over the class hierarchy.

    use constant PROMPT_VARS => (
        key => value,
        ...
    );

Since more elaborate prompt variables will have some interaction with the
shell object, you might need a more elaborate C<PROMPT_VARS()> definition:

    sub PROMPT_VARS {
        my $self = shift;
        (
            key => $self->some_method,
            ...
        );
    }

The prompt variables are interpolated anew for every prompt.

The default prompt string is:

    ': \n:\#; ',

so if your shell is called C<mysh>, the default prompt looks somewhat like
this:

   : mysh:1; 

=back

=head1 COMMANDS

The following commands are added:

=over 4

=item C<eval>

You can evaluate snippets of Perl code just by putting them on a line
beginning with C<!>:

  psh:~> ! print "$_\n" for keys %ENV

=item C<set [name[=value] ... ]>

C<set> lets you manipulate environment variables. You can view environment
variables using C<set>. To view specific variables, use C<set name>. To set
environment variables, use C<set foo=bar>.

=item C<cd [dir]>

  cd foo/bar/baz

Change the current directory to the given directory. If no directory is given,
the current value of C<$HOME> is used.

=item C<pwd>

Prints the current working directory.

=item C<alias [ name[=value] ... ]>

C<alias> with no arguments prints the list of aliases in the form
C<NAME=VALUE> on standard output. An alias is defined for each C<NAME> whose
C<VALUE> is given.

When you enter any command, it is checked against aliases and replaced if
there is an alias defined for it. Only the command name - that is, the first
word of the input line - undergoes alias replacement.

=item C<echo [arg ...]>

Output the args.

=item C<quit>

Exits the program.

=item C<apropos <word>>

Like the C<help> command, but limits the information to commands that contain
the given word in the command name or the summary.

=back

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Term-Shell-Enhanced>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Term-Shell-Enhanced/>.

The development version lives at
L<http://github.com/hanekomu/Term-Shell-Enhanced/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2005 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

