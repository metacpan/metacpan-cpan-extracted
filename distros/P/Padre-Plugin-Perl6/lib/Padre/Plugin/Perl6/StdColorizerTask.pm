package Padre::Plugin::Perl6::StdColorizerTask;
BEGIN {
  $Padre::Plugin::Perl6::StdColorizerTask::VERSION = '0.71';
}

# ABSTRACT: Perl 6 STD.pm Colorizer Task

use strict;
use warnings;
use base 'Padre::Task';
use Scalar::Util    ();
use Padre::Constant ();
use Padre::Logger;
use Padre::Util ();

our $thread_running = 0;

# This is run in the main thread before being handed
# off to a worker (background) thread. The Wx GUI can be
# polled for information here.
# If you don't need it, just inherit this default no-op.
sub prepare {
	my $self = shift;

	# it is not running yet.
	$self->{broken} = 0;

	return if $self->{_editor};
	$self->{_editor} = Scalar::Util::refaddr( Padre::Current->editor );

	# assign a place in the work queue
	if ($thread_running) {

		# single thread instance at a time please. aborting...
		$self->{broken} = 1;
		return "break";
	}
	$thread_running = 1;
	return 1;
}

sub is_broken {
	my $self = shift;
	return $self->{broken};
}

my %colors = (
	'comp_unit'          => Padre::Constant::PADRE_BLUE,
	'scope_declarator'   => Padre::Constant::PADRE_RED,
	'routine_declarator' => Padre::Constant::PADRE_RED,
	'regex_declarator'   => Padre::Constant::PADRE_RED,
	'package_declarator' => Padre::Constant::PADRE_RED,
	'statement_control'  => Padre::Constant::PADRE_RED,
	'block'              => Padre::Constant::PADRE_BLACK,
	'regex_block'        => Padre::Constant::PADRE_BLACK,
	'noun'               => Padre::Constant::PADRE_BLACK,
	'sigil'              => Padre::Constant::PADRE_GREEN,
	'variable'           => Padre::Constant::PADRE_GREEN,
	'assertion'          => Padre::Constant::PADRE_GREEN,
	'quote'              => Padre::Constant::PADRE_MAGENTA,
	'number'             => Padre::Constant::PADRE_ORANGE,
	'infix'              => Padre::Constant::PADRE_DIM_GRAY,
	'methodop'           => Padre::Constant::PADRE_BLACK,
	'pod_comment'        => Padre::Constant::PADRE_GREEN,
	'param_var'          => Padre::Constant::PADRE_CRIMSON,
	'_scalar'            => Padre::Constant::PADRE_RED,
	'_array'             => Padre::Constant::PADRE_BROWN,
	'_hash'              => Padre::Constant::PADRE_ORANGE,
	'_comment'           => Padre::Constant::PADRE_GREEN,
);

# This is run in the main thread after the task is done.
# It can update the GUI and do cleanup.
# You don't have to implement this if you don't need it.
sub finish {
	my $self       = shift;
	my $mainwindow = shift;

	my $editor = Padre::Current->editor;
	my $addr   = delete $self->{_editor};
	if ( not $addr or not $editor or $addr ne Scalar::Util::refaddr($editor) ) {

		# shall we try to locate the editor ?
		$thread_running = 0;
		return 1;
	}

	my $doc = Padre::Current->document;
	if ( not $doc ) {
		$thread_running = 0;
		return 1;
	}

	if ( $self->{tokens} ) {
		$doc->remove_color;
		my @tokens = @{ $self->{tokens} };
		for my $htoken (@tokens) {
			my %token = %{$htoken};
			my $color = $colors{ $token{rule} };
			if ( defined $color ) {
				my $len   = length $token{buffer};
				my $start = $token{last_pos} - $len;
				$editor->StartStyling( $start, $color );
				$editor->SetStyling( $len, $color );
			} elsif ( $token{rule} eq '0' ) {

				# Why are there such cases?
			} else {
				warn "No color found for '$token{rule}'";
			}
		}
		$doc->{tokens} = $self->{tokens};
	} else {
		$doc->{tokens} = [];
	}

	if ( $self->{issues} ) {

		# pass errors/warnings to document...
		$doc->{issues} = $self->{issues};
	} else {
		$doc->{issues} = [];
	}

	# TODO: understand the case when opening Padre, if there
	# is a Perl 6 file this will be called and it won't find the method
	# probably this happens as the current file is different when the finish is called
	# from the one that was called at the beginning (this is at open time with many
	# buffers opening). There is a safeguard at the beginning of this sub but it seems
	# to be failing its job, Maybe the Padre::Task should have a built in suppport to
	# associate a task with a certain buffer
	eval {
		$doc->check_syntax_in_background( force => 1 );
		$doc->get_outline( force => 1 );
	};
	if ($@) {

		#print "$doc\n";
	}

	# finished here
	$thread_running = 0;

	return 1;
}

# Task thread subroutine
sub run {
	my $self = shift;

	# temporary file for the process STDIN
	require File::Temp;
	my $tmp_in = File::Temp->new( SUFFIX => '_p6_in.txt' );
	binmode $tmp_in, ':utf8';
	print $tmp_in $self->{text};
	delete $self->{text};
	close $tmp_in or warn "cannot close $tmp_in\n";

	# temporary file for the process STDOUT
	my $tmp_out = File::Temp->new( SUFFIX => '_p6_out.txt' );
	close $tmp_out or warn "cannot close $tmp_out\n";

	# temporary file for the process STDERR
	my $tmp_err = File::Temp->new( SUFFIX => '_p6_err.txt' );
	close $tmp_err or warn "cannot close $tmp_out\n";

	my $tmp_dir = File::Spec->catfile( Padre::Constant::PLUGIN_DIR,
		'Padre-Plugin-Perl6'
	);
	if ( not -e $tmp_dir ) {
		require File::Path;
		File::Path::mkpath($tmp_dir);
	}
	$tmp_dir .= '/';

	# construct the command
	require Cwd;
	require File::Basename;
	require File::Spec;
	my $cmd =
		  Padre::Perl->perl . " "
		. File::Spec->catfile( Padre::Util::share('Perl6'), 'p6tokens.p5' )
		. qq( "$tmp_in" "$tmp_out" "$tmp_err" "$tmp_dir");

	# all this is needed to prevent win32 platforms from:
	# 1. popping out a command line on each run...
	# 2. STD.pm uses Storable
	# 3. Padre TaskManager does not like tasks that do Storable operations...
	if (Padre::Constant::WIN32) {

		# on win32 platforms, we need to use this to prevent command line popups when using wperl.exe
		require Win32;
		require Win32::Process;

		sub print_error {
			print Win32::FormatMessage( Win32::GetLastError() );
		}

		my $p_obj;
		Win32::Process::Create( $p_obj, Padre::Perl->perl, $cmd, 0, Win32::Process::DETACHED_PROCESS(), '.' )
			or warn &print_error;
		$p_obj->Wait( Win32::Process::INFINITE() );
	} else {

		# On other platforms, we will simply use the perl way of calling a command
		`$cmd`;
	}

	my ( $out, $err );
	{
		local $/ = undef; #enable localized slurp mode

		# slurp the process output...
		open my $CHLD_OUT, '<', $tmp_out or warn "Could not open $tmp_out";
		binmode $CHLD_OUT;
		$out = <$CHLD_OUT>;
		close $CHLD_OUT or warn "Could not close $tmp_out\n";

		open my $CHLD_ERR, '<', $tmp_err or warn "Cannot open $tmp_err\n";
		binmode $CHLD_ERR, ':utf8';
		$err = <$CHLD_ERR>;
		close $CHLD_ERR or warn "Could not close $tmp_err\n";
	}

	if ($err) {

		# remove ANSI color escape sequences...
		$err =~ s/\033\[\d+(?:;\d+(?:;\d+)?)?m//g;
		TRACE(qq{STD.pm warning/error:\n$err\n}) if DEBUG;
		my @messages = split /\n/, $err;
		my ( $lineno, $type );
		my $issues = [];
		my $prefix = '';
		for my $msg (@messages) {
			if ( $msg =~ /^===SORRY!===/i ) {

				# the following lines are errors until we see the warnings section
				$type = 'F';
			} elsif ( $msg =~ /^Potential difficulties/i ) {

				# all rest are warnings...
				$type   = 'W';
				$lineno = undef;
			} elsif ( $msg =~ /^Undeclared routine/i ) {

				# all rest are warnings...
				$prefix = 'Undeclared routine: ';
				$lineno = undef;
				$type   = 'W';
			} elsif ( $msg =~ /^\s+(.+?)\s+used at (\d+)/i ) {

				# record the line number
				$lineno = $2;
			} elsif ( $msg =~ /line (\d+):$/i ) {

				# record the line number
				$lineno = $1;
			}
			if ($lineno) {
				push @{$issues}, { line => $lineno, message => $prefix . $msg, type => $type, };
			}
		}
		$self->{issues} = $issues;
	}

	if ($out) {
		eval {
			require YAML::XS;
			$self->{tokens} = YAML::XS::Load($out);
		};
		if ($@) {
			warn "Exception: $@";
		}
	}

	return 1;
}

1;

__END__
=pod

=head1 NAME

Padre::Plugin::Perl6::StdColorizerTask - Perl 6 STD.pm Colorizer Task

=head1 VERSION

version 0.71

=head1 AUTHORS

=over 4

=item *

Ahmad M. Zawawi <ahmad.zawawi@gmail.com>

=item *

Gabor Szabo L<http://szabgab.com/>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Ahmad M. Zawawi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

