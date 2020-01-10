package PerlX::bash;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = ('bash');
our @EXPORT_OK = (@EXPORT, qw< pwd head tail >);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.04'; # VERSION


use Carp;
use Contextual::Return;
use List::Util 1.33 qw< any >;
use Scalar::Util qw< blessed >;
use IPC::System::Simple qw< run capture EXIT_ANY $EXITVAL >;


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
	return 0;
}

sub _process_bash_arg ()
{
	# incoming arg is in $_
	my $arg = $_;				# make a copy
	croak("Use of uninitialized argument to bash") unless defined $arg;
	if (_should_quote)
	{
		$arg = "$arg";			# stringify
		$arg =~ s/'/'\\''/g;	# handle internal single quotes
		$arg = "'$arg'";		# quote with single quotes
	}
	return $arg;
}


sub bash (@)
{
	my (@opts, $capture);
	my $exit_codes = [0..125];

	while ( $_[0] and ($_[0] =~ /^-/ or ref $_[0]) )
	{
		my $arg = shift;
		if (ref $arg)
		{
			croak("bash: multiple capture specifications") if $capture;
			$capture = $$arg;
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
	croak("Not enough arguments for bash") unless @_;

	my $filter;
	$filter = pop if ref $_[-1] eq 'CODE';
	croak("bash: multiple output redirects") if $capture and $filter;

	my @cmd = 'bash';
	push @cmd, @opts;
	push @cmd, '-c';

	my $bash_cmd = join(' ', map { _process_bash_arg } @_);
	push @cmd, $bash_cmd;

	if ($capture)
	{
		my $IFS = $ENV{IFS};
		$IFS = " \t\n" unless defined $IFS;

		my $output = capture $exit_codes, qw< bash -c >, $bash_cmd;
		if ($capture eq 'string')
		{
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


use Cwd ();
*pwd = \&Cwd::cwd;


sub head
{
	my $num = shift;
	$num = @_ + $num if $num < 0;
#warn("# num is $num");
	@_[0..$num-1];
}

sub tail
{
	my $num = shift;
	return () unless $num;
	$num = $num < 0 ? @_ + $num : $num - 1 ;
#warn("# num is $num");
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

This document describes version 0.04 of PerlX::bash.

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

	if (!system($cmd))
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

Capture modes take the ouptut of the B<bash> command and return it for storage into a Perl variable.
There are 3 basic capture modes, all of which are indicated by a backslashed argument.

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

Not yet documented.

=head2 Arguments

No matter how many arguments you pass to C<bash>, they will be turned into a single command string
and run via C<bash -c>.  However, PerlX::bash tries to make intelligent guesses as to which of your
arguments are meant to be treated as a single argument in the command line (and therefore might
require quoting), and which aren't.  Understanding what the rules behind these guesses can help
avoid surprises.

Basically, there are 3 rules:

=over

=item *

Some things are I<always> quoted.  See L</Autoquoting>.

=item *

Some things are I<never> quoted.  Any argument that I<begins> with a special character (see
L</"Special Characters">) is never quoted.

=item *

Some things are I<sometimes> quoted.  Any argument that I<contains> a special character (see
L</"Special Characters">) is quoted.

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

	system(q| bash -c 'echo foo >bar' |);

whereas:

	bash echo => "foo", "ba>r";

is the equivalent of:

	system(q| bash -c 'echo foo "ba>r"' |);

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

	[ \$'"\\#\[\]!<>|;{}()~]

Note that space is a special character, as are both types of quotes and all four types of brackets,
and backslash.

=head3 Quoting Details

If an argument is quoted, it is run through L</shq>, which means it is surrounded with single
quotes, and any internal single quotes are appropriately escaped.  This is similar to how `bash -x`
does it when it prints command lines.

If an argument is not quoted but you wish it were, you can simply call C<shq> yourself (feature not
yet implemented):

	bash echo => shq(">bar");	# to print ">bar"

If an argument I<is> quoted but you wish it weren't, you need to fall back to passing the entire
command as one big string.  For this, use the C<-c> switch:

	bash -c => "echo foo;echo bar";
	# or just, you know, make the semi-colon a separate arg:
	bash echo => "foo", ';', echo => "bar";

=head2 Switches

Most single character switches are passed through to the spawned B<bash> command, but some are
handled by PerlX::bash directly.

=head3 -c

Just as with system B<bash>, the C<-c> switch means that the entire command will be sent as one big
string.  This completely disables all argument quoting (see L</Arguments>).

=head3 -e

Without the use of C<-e>, any exit value from the command is considered acceptable.  (Exceptions are
still raised if the command fails to launch or is killed by a signal.)  By using C<-e>, exit values
other than 0 cause exceptions.

	bash       diff => $file1, $file2; # just print diffs, if any
	bash -e => diff => $file1, $file2; # if there are diffs, print them, then throw exception

This mimics the C<bash -e> behavior of the system C<bash>.

=head1 STATUS

This module is still an experiment, but I am currently using it daily for small tasks.  The basic
functionality is very useful; however, I still cannot yet promise I won't make sweeping changes to
the interface.  I still welcome suggestions and contributions, and continue to recommend that you do
I<not>  rely on this in production code (yet).

Documentation is much improved, but still not complete.

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc PerlX::bash

=head2 Bugs / Feature Requests

This module is on GitHub.  Feel free to fork and submit patches.  Please note that I develop
via TDD (Test-Driven Development), so a patch that includes a failing test is much more
likely to get accepted (or at least likely to get accepted more quickly).

If you just want to report a problem or suggest a feature, that's okay too.  You can create
an issue on GitHub here: L<http://github.com/barefootcoder/perlx-bash/issues>.

=head2 Source Code

none
L<https://github.com/barefootcoder/perlx-bash>

  git clone https://github.com/barefootcoder/perlx-bash.git

=head1 AUTHOR

Buddy Burden <barefootcoder@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015-2019 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
