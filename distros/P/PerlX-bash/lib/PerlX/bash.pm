package PerlX::bash;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = ('bash');
our @EXPORT_OK = (@EXPORT, qw< shq pwd head tail >);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.05'; # VERSION


use Carp;
use Contextual::Return;
use List::Util 1.33 qw< min max any >;
use Scalar::Util qw< blessed >;
use IPC::System::Simple qw< run capture EXIT_ANY $EXITVAL >;

# see e.g. https://mywiki.wooledge.org/BashGuide/SpecialCharacters
my $BASH_SPECIAL_CHARS = qr/[\s\$'"\\#\[\]!<>|;{}()~&]/;
my $BASH_REDIRECTION   = qr/^\d[<>].+/;



my @AUTOQUOTE =
(
	sub {	ref shift eq 'Regexp'						},
	sub {	blessed $_[0] and $_[0]->can('basename')	},
);

sub _should_quote ()
{
	my $arg = $_;
	local $_;
	return 1 if any { $_->($arg) } @AUTOQUOTE;
	return 0 if $arg =~ /^$BASH_SPECIAL_CHARS/;
	return 0 if $arg =~ $BASH_REDIRECTION;
	return 1 if $arg =~ $BASH_SPECIAL_CHARS;
	return 0;
}

sub _process_bash_arg ()
{
	# incoming arg is in $_
	my $arg = $_;				# make a copy
	croak("Use of uninitialized argument to bash") unless defined $arg;
	$arg = shq($arg) if _should_quote;
	return $arg;
}



sub bash (@)
{
	my (@opts, $capture);
	my $exit_codes = [0..125];

	my $dash_c_cmd;
	while ( $_[0] and ($_[0] =~ /^-/ or ref $_[0]) )
	{
		my $arg = shift;
		if (ref $arg)
		{
			croak("bash: multiple capture specifications") if $capture;
			$capture = $$arg;
		}
		elsif ($arg eq '-c')
		{
			$dash_c_cmd = shift;
			croak("Missing argument for bash -c") unless length($dash_c_cmd);
		}
		elsif ($arg eq '-e')
		{
			$exit_codes = [0];
		}
		else
		{
			push @opts, $arg;
		}
	}
	if (defined $dash_c_cmd)
	{
		croak("Too many arguments for bash -c") if @_;
	}
	else
	{
		croak("Not enough arguments for bash") unless @_;
		$dash_c_cmd = shift if @_ == 1 and $_[0] and $_[0] =~ /\s/;
	}

	my $filter;
	$filter = pop if ref $_[-1] eq 'CODE';
	croak("bash: multiple output redirects") if $capture and $filter;

	my @cmd = 'bash';
	push @cmd, @opts;
	push @cmd, '-c';

	my $bash_cmd = $dash_c_cmd ? $dash_c_cmd : join(' ', map { _process_bash_arg } @_);
	push @cmd, $bash_cmd;

	if ($capture)
	{
		my $IFS = $ENV{IFS};
		$IFS = " \t\n" unless defined $IFS;

		my $output = capture $exit_codes, qw< bash -c >, $bash_cmd;
		if ($capture eq 'string')
		{
			chomp $output;
			return $output;
		}
		elsif ($capture eq 'lines')
		{
			my @lines = split("\n", $output);
			return wantarray ? @lines : $lines[0];
		}
		elsif ($capture eq 'words')
		{
			my @words = split(/[$IFS]+/, $output);
			return wantarray ? @words : $words[0];
		}
		else
		{
			die("bash: unrecognized capture specification [$capture]");
		}
	}
	elsif ($filter)
	{
		$cmd[-1] =~ s/\s*(?<!\|)\|(&)?\s*$// or croak("bash: cannot filter without redirect");
		$cmd[-1] .= ' 2>&1' if $1;

		# This is pretty much straight out of `man perlipc`.
		local *CHILD;
		my $pid = open(CHILD, "-|");
		defined($pid) or die("bash: can't fork [$!]");

		if ($pid)				# parent
		{
			local $_;
			while (<CHILD>)
			{
				chomp;
				$filter->($_);
			}
			unless (close(CHILD))
			{
				# You know how IPC::System::Simple says that `_process_child_error` is not intended
				# to be called directly?  Yeah, well, the alternatives are worse ...
				IPC::System::Simple::_process_child_error($?, 'bash', $exit_codes);
			}
		}
		else					# child
		{
			exec(@cmd) or die("bash: can't exec program [$!]");
		}
	}
	else
	{
		run $exit_codes, @cmd;
		return
			BOOL	{	$EXITVAL == 0	}
			SCALAR	{	$EXITVAL		}
		;
	}
}


sub shq
{
	local $_ = shift;
	#$_ = "$_";					# stringify
	s/'/'\\''/g;				# handle internal single quotes
	"'$_'";						# quote with single quotes
}



use Cwd ();
*pwd = \&Cwd::cwd;



sub head
{
	my $num = shift;
	$num = $num < 0 ? @_ + $num : min($num, scalar @_);
	@_[0..$num-1];
}

sub tail
{
	my $num = shift;
	return () unless $num;
	$num = $num < 0 ? max(@_ + $num, 0) : $num - 1 ;
	@_[$num..$#_];
}


1;

# ABSTRACT: tighter integration between Perl and bash
# COPYRIGHT
#
# This module is similar to the solution presented here:
# http://stackoverflow.com/questions/571368/how-can-i-use-bash-syntax-in-perls-system

__END__

=pod

=head1 NAME

PerlX::bash - tighter integration between Perl and bash

=head1 VERSION

This document describes version 0.05 of PerlX::bash.

=head1 SYNOPSIS

    # put all instances of Firefox to sleep
    foreach (bash \lines => pgrep => 'firefox')
    {
        bash kill => -STOP => $_ or die("can't spawn `kill`!");
    }

    # count lines in $file
    my $num_lines;
    local $@;
    eval { $num_lines = bash \string => -e => wc => -l => $file };
    die("can't spawn `wc`!") if $@;

    # can capture actual exit status
    my $pattern = qr/.../;
    my $status = bash grep => -e => $pattern => $file, ">$tmpfile";
    die("`grep` had an error!") if $status == 2;

=head1 DESCRIPTION

There is one primary function, which is always exported: C<bash>.  This takes several arguments and
passes them to your system's C<bash> command (therefore, if your system has no C<bash>--e.g.
Windows--this module is useless to you).  Since C<bash> is a shell, it will run its arguments as a
command, meaning that C<bash> is functionally very similar to C<system>.  The primary advantages of
C<bash> over C<system> are:

=over

=item *

B<Actual bash syntax.>  The C<system> command runs C<sh>, and, even if C<sh> on your system is just
a symlink to C<bash>, it will I<not> respect the full bash syntax.  For instance, this

    system("diff <(sort $file1) <(sort $file2)");

will B<not> work on your system (unless your system is super-special in some magical way), because
this type of advanced bash syntax is backwards-incompatible with old Bourne shell syntax.  However,
I<this>

    bash diff => "<(sort $file1)", "<(sort $file2)";

works just fine.

=item *

B<Better return context.>  The return value of C<system> is "backwards" because it returns the exit
code of the command it ran, which is 0 if there were no errors, which is false, thus leading to
confusing code like so:

    if (not system($cmd))
    {
        say "It worked!";
    }

But C<bash> returns true if the command succeeded, and false if it didn't ... in a boolean context.
In other scalar contexts, it returns the numeric value of the exit code.  If anything goes wrong, an
exception is thrown, which can be handy if you're using the return value for something else (like
capturing).

=item *

B<More capturing options.>  To capture the output of C<system>, you would normally use backquotes,
which returns everything as a string.  With PerlX::bash, you can capture output as a string, as an
array of lines, or as an array of words.  See L</"Run Modes">.

=item *

B<Better quoting.>  With C<system>, you either pass your arguments as separate arguments, in which
case the shell is bypassed, or you pass them as one big string.  This can make quoting challenging.
With PerlX::bash, you never want to bypass C<bash> (if you do, you should be using C<system>
instead).  Thus, you can specify arguments separately and have things automatically quoted properly
(hopefully) without you having to think about it too hard.  See L</Arguments>.  Of course, if you'd
I<rather> pass the whole command as one big string, you can do that too (see L</Switches>).

=item *

B<Access to (certain) bash switches.>  Some options to C<bash> come in handy.  The most important
one is probably C<-e>.  With C<system>, you can either C<use autodie ':all'>, or not.  If you do,
then all your commands throw an exception if they don't return success; if you don't, then none of
them do.  With PerlX::bash, you can just provide C<-e> (or not) to individual commands to achieve
the same effect on a more granular level.  Other important switches include C<-c> and C<-x>.

=back

=head2 Run Modes

You can specify what you want done with the output of C<bash> via several features collectively
called "run modes."  If you don't specify any run mode at all (which I sometimes call "just run it!"
mode), then output goes wherever it would normally go: probably to your terminal, unless you've
redirected it in the C<bash> command itself.

Run modes are incompatible with each other, whether they're of the same type (e.g. two different
capture modes) or different types (e.g. one capture mode and one filter mode).  Specifying more than
one run mode is a fatal error.

=head3 Capture Modes

Capture modes take the ouptut of the C<bash> command and returns it for storage into a Perl
variable.  There are 3 basic capture modes, all of which are indicated by a backslashed argument.

=head4 String

To capture the entire output as one scalar string, use C<\string>, like so:

    my $num_lines = bash \string => wc => -l => $file;

This is almost exactly like backquotes, except that the output is chomped for you.

=head4 Lines

To capture the output as a series of lines, use C<\lines> instead:

    my @lines = bash \lines => git => log => qw< --oneline >, $file;

Individual lines are pre-chomped.

=head4 Words

If you'd rather have the output split on whitespace, try C<\words>:

    my @words = bash \words => awk => '$1 == "foo" { print $3, $5 }', $file;

Specifically, the output is split on the equivalent of C</[$ENV{IFS}]+/>; if C<$IFS> is not set in
your environment, a default value of C<" \t\n"> is used.

=head4 Context

C<\string> always returns a scalar.  C<\lines> and C<\words> should generally be called in list
context; in scalar context, they just return the first element of the list.

=head3 Filter Modes

If you write some code that looks like this:

    # print paragraph "1:" through paragraph "10:"
    say foreach grep { (/^(\d+):/ && $1 < 10)../^$/ } bash \lines => 'my-script';

then it's going to do what you think: all the lines of output are filtered through your C<grep> and
you get just the lines you wanted.  However, if C<my-script> takes a long time to produce its
output, this solution may not make you happy, because you get nothing at all until C<my-script> has
completely finished running.  It would be nicer if you could get the output as it was produced,
right?

Try this instead:

    # print paragraph "1:" through paragraph "10:"
    bash \lines => 'my-script |' => sub { say if (/^(\d+):/ && $1 < 10)../^$/ };

You'll be much happier.

Technical details:

=over

=item *

There are two filter modes: C<|> and C<|&>.  The former runs each line of C<STDOUT> through your
filter function.  The latter runs both C<STDOUT> and C<STDERR> through it.

=item *

In order to use a filter mode, your final argument must be a coderef, and your penultimate argument
must either consist of, or end with, one of the two modes.

=item *

From the perspective of your filter sub, the incoming line is both C<$_> and C<$_[0]>; use whichever
you prefer.

=item *

Just as with C<\lines>, each line is pre-chomped for you.

=back

=head2 Arguments

No matter how many arguments you pass to C<bash>, they will be turned into a single command string
and run via C<bash -c>.  However, PerlX::bash tries to make intelligent guesses as to which of your
arguments are meant to be treated as a single argument in the command line (and therefore might
require quoting), and which aren't.  Understanding the rules behind these guesses can help avoid
surprises.

Basically, there are 3 rules:

=over

=item *

Some things are I<always> quoted.  See L</Autoquoting>.

=item *

Some things are I<never> quoted.  Any argument that I<begins> with a special character (see
L</"Special Characters">) is never quoted.

=item *

Some things are I<sometimes> quoted.  Any argument that I<contains> a special character (see
L</"Special Characters">) is quoted, unless one of the following things is true:

=over

=item *

It is the only argument left after processing capture modes and filters, B<and> it has whitespace in
it.  In other words, this:

    bash "echo foo; echo bar";

is the same as this:

    bash -c => "echo foo; echo bar";

On the grounds that that's most likely what you meant.  (You weren't really trying to generate a
C<echo foo; echo bar: command not found> error, were you?)  Basically, if it looks like it would
make a lovely command line as is, we don't mess with it.

=item *

It looks like a redirection.  While the majority of redirections I<do> begin with a special char,
sometimes they start with a number; all the following strings would qualify as "looking like a
redirection," despite not beginning with a special char:

=over

=item *

C<< 2>something >> (standard redirection with fileno)

=item *

C<< 2>&1 >> (redirection from fileno to fileno)

=item *

C<< 4<<<$SOMEVAR >> (here string)

=back

Note that some redirection syntax may be bash-version-specific, but the decision on whether to quote
or not does I<not> take the C<bash> version into account.

=back

=item *

If an argument falls into multiple categories, the first matching category (according to the order
above) wins.  Thus, a filename object (which is always quoted) that begins with a special character
(meaning it would never be quoted) is quoted.  An argument that both begins with a special character
(never quoted) and contains a special character later in its string (quoted) is not quoted.

=back

The reason that arguments which I<begin> with a special character are treated differently
(oppositely, even) from other arguments containing special characters is to avoid quoting things
such as redirections.  So, for instance:

    bash echo => "foo", ">bar";

is the equivalent of:

    system('bash', '-c', q[echo foo >bar]);

whereas:

    bash echo => "foo", "ba>r";

is the equivalent of:

    system('bash', '-c', q[echo foo 'ba>r']);

Mostly this does what you want.  For when it doesn't, see L</"Quoting Details">.

=head3 Autoquoting

An autoquoting rule is a reference to a C<sub> that takes a single argument and returns true or
false.  Autoquoting rules are tried, one a time, until one of them returns true, at which point the
argument is quoted.  If I<none> of them return true, autoquoting does not apply.

PerlX::bash starts with a short list of autoquoting rules:

=over

=item *

A reference to a regex is stringified and quoted.

=item *

Any blessed object whose class has a C<basename> method is considered to be a filename and quoted.
This covers L<Path::Class>, L<Path::Tiny>, L<Path::Class::Tiny>, and probably many others.

=back

You can also add your own autoquoting rules (feature not yet implemented).

=head3 Special Characters

For purposes of determining whether to quote arguments, the most important characteristic is whether
a string contains any I<special characters>.  Here's the character class of all characters
considered "special" by bash:

    [\s\$'"\\#\[\]!<>|;{}()~&]

Note that space is a special character, as are both types of quotes and all four types of brackets,
and backslash.  Note that the list does B<not> include C<=> or the glob characters (C<*> and C<?>),
because you probably don't want those quoted under most circumstances.

=head3 Quoting Details

If an argument is quoted, it is run through L</shq>, which means it is surrounded with single
quotes, and any internal single quotes are appropriately escaped.  This is similar to how `bash -x`
does it when it prints command lines.

If an argument is not quoted but you wish it were, you can simply call C<shq> yourself (but remember
it is not exported by default):

    use PerlX::bash qw< bash shq >;
    bash echo => shq(">bar");   # to print ">bar"

If an argument I<is> quoted but you wish it weren't, you need to fall back to passing the entire
command as one big string.  (The C<-c> switch is not required, but it may be clearer.)

    # this echoes one line, not two:
    bash echo => "foo;echo bar";
    # this gives you two:
    bash -c => "echo foo;echo bar";
    # or just, you know, make the semi-colon a separate arg:
    bash echo => "foo", ';', echo => "bar";

=head2 Switches

Most single character switches are passed through to the spawned B<bash> command, but some are
handled by PerlX::bash directly.

=head3 -c

Just as with system B<bash>, the C<-c> switch means that the entire command will be sent as one big
string.  This completely disables all argument quoting (see L</Arguments>).

When using C<-c>, it must be immediately followed by exactly one argument, which is neither C<undef>
nor the empty string (but C<"0"> is okay, although not particularly useful).  Otherwise it's a fatal
error.

=head3 -e

Without the use of C<-e>, any exit value from the command is considered acceptable.  (Exceptions are
still raised if the command fails to launch or is killed by a signal.)  By using C<-e>, exit values
other than 0 cause exceptions.

    bash       diff => $file1, $file2; # just print diffs, if any
    bash -e => diff => $file1, $file2; # if there are diffs, print them, then throw exception

This mimics the C<bash -e> behavior of the system C<bash>.

=head1 FUNCTIONS

=head2 bash

Call your system's C<bash>.  See L</DESCRIPTION> for full details.

=head2 shq

Manually quote something for use as a command-line argument to C<bash>.  The following steps are
performed:

=over

=item *

The argument is stringified, in case it is an object.

=item *

Any single quotes in the string are globally replaced with C<'\''>.

=item *

The entire string is then enclosed in single quotes.

=back

This should get the string to I<bash> as you intended it; however, beware of arguments which are
consequently passed on to another shell (e.g. when your C<bash> command is C<ssh>).  In those cases,
extra quoting may be required, and you must provide that before calling C<shq>.

Exported only on request.

=head2 pwd

This is just an alias for L<Cwd/cwd>.  We use the C<pwd> name because that's more comfortable for
regular users of C<bash>.  Exported on request only, so just C<use Cwd> instead if you prefer the
more Perl-ish name.

=head2 head

=head2 tail

Perl functions that work much like the POSIX-standard C<head> and C<tail> utilities, but for array
elements rather than lines of files.  Exported only on request.

    # this code:          is the same as this code:
    head  3 => @list;   # @list[0..2]
    head -3 => @list;   # @list[0..$#list-3]
    tail -3 => @list;   # @list[@list-3..$#list]
    tail +3 => @list;   # @list[2..$#list]

Note that not only is it way easier to type, easier to understand when reading, and possibly saves
you a temporary variable, it also can be safer: when e.g. C<@list> contains only 2 elements, several
of the right-hand constructs will give you unexpected answers.  However, C<head> and C<tail> always
just return as many elements as they can, which is probably closer to what you were expecting:

    my @list = 1..2;
    @list[@list-3..$#list];  # (2, 1, 2) #!!!
    tail -3 => @list;        # (1, 2)

Their use really shines, however, when used in conjunction with C<bash \lines> and some functional
programming:

    my @top_3_numbered_lines = head 3 => grep /^\d/, bash \lines => 'my-script';

=head1 STATUS

This module is no longer experimental, and is currently being used for production tasks.  There will
be no further sweeping changes to the interface, but some tweaking may be necessary as it sees more
and more use.  Documentation should be complete at this point; anything missing should be considered
a bug and reported.  I continue to welcome suggestions and contributions, and now recommend that you
use this for any purpose you like, but perhaps just keep a close eye on it as it continues to
mature.

=for :stopwords cpan testmatrix url bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc PerlX::bash

=head2 Bugs / Feature Requests

This module is on GitHub.  Feel free to fork and submit patches.  Please note that I develop
via TDD (Test-Driven Development), so a patch that includes a failing test is much more
likely to get accepted (or at least likely to get accepted more quickly).

If you just want to report a problem or suggest a feature, that's okay too.  You can create
an issue on GitHub here: L<https://github.com/barefootcoder/perlx-bash/issues>.

=head2 Source Code

none
L<https://github.com/barefootcoder/perlx-bash>

  git clone https://github.com/barefootcoder/perlx-bash.git

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2020 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
