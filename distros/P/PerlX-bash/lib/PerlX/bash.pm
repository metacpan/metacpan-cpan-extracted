package PerlX::bash;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT = ('bash');
our @EXPORT_OK = (@EXPORT, qw< pwd head tail >);
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.03'; # VERSION


use Contextual::Return;
use Scalar::Util qw< blessed >;
use IPC::System::Simple qw< run capture EXIT_ANY $EXITVAL >;


sub _process_bash_arg ()
{
	# incoming arg is in $_
	my $arg = $_;				# make a copy
	if (blessed $arg and $arg->can('basename'))
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

	while ( $_[0] =~ /^-/ or ref $_[0] )
	{
		my $arg = shift;
		if (ref $arg)
		{
			die("bash: multiple capture specifications") if $capture;
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

	my @cmd = 'bash';
	push @cmd, @opts;
	push @cmd, '-c';

	my $bash_cmd = join(' ', map { _process_bash_arg } @_);
	push @cmd, $bash_cmd;

	if ($capture)
	{
		my $IFS = $ENV{IFS};
		$IFS = " \t\n" unless defined $IFS;

		my $output = capture [0..125], qw< bash -c >, $bash_cmd;
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

This document describes version 0.03 of PerlX::bash.

=head1 SYNOPSIS

	# put all instances of Firefox to sleep
	foreach (bash \lines => "pgrep firefox")
	{
		bash "kill -STOP $_" or die("can't spawn `kill`!");
	}

	# count lines in $file
	local $@;
	eval { bash \string => -e => "wc -l $file" };
	die("can't spawn `wc`!") if $@;

	# can capture actual exit status
	my $status = bash "grep -e $pattern $file >$tmpfile";
	die("`grep` had an error!") if $status == 2;

=head1 STATUS

This module is an experiment.  It's fun to play around with, and I welcome suggestions and
contributions.  However, don't rely on this in production code (yet).

Further documentation will be forthcoming, hopefully soon.

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

This software is Copyright (c) 2015-2017 by Buddy Burden.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
