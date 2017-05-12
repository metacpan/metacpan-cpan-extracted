package Padre::Plugin::Perl6::Document;
BEGIN {
  $Padre::Plugin::Perl6::Document::VERSION = '0.71';
}

# ABSTRACT: Perl 6 Support Document

use 5.010;
use strict;
use warnings;

use Padre::Wx       ();
use Padre::Document ();

our @ISA = 'Padre::Document';

# Task Integration
sub task_functions {

	# There is no actual need to support it
	# We already have outline support
	return;
}

sub task_outline {
	return 'Padre::Plugin::Perl6::Outline';
}

sub task_syntax {
	return 'Padre::Plugin::Perl6::Syntax';
}

# get Perl6 (rakudo) command line for "Run script" F5 Padre menu item
sub get_command {
	my $self = shift;

	my $filename = $self->filename;
	require Padre::Plugin::Perl6::Util;
	my $perl6 = Padre::Plugin::Perl6::Util::perl6_exe();

	if ( not $perl6 ) {
		my $main = Padre->ide->wx->main;
		$main->error(
			"Either perl6 needs to be in the PATH or RAKUDO_DIR must point to the directory of the Rakudo checkout.");
		return;
	}

	return qq{"$perl6" "$filename"};
}

# Checks the syntax of a Perl document.
# Documented in Padre::Document!
# Implemented as a task. See Padre::Plugin::Perl6::Syntax
sub check_syntax {
	shift->_check_syntax_internals(

		# Passing all arguments is ok, but critic complains
		{   @_, ## no critic (ProhibitCommaSeparatedStatements)
			background => 0
		}
	);
}

sub check_syntax_in_background {
	shift->_check_syntax_internals(

		# Passing all arguments is ok, but critic complains
		{   @_, ## no critic (ProhibitCommaSeparatedStatements)
			background => 1
		}
	);
}

sub _check_syntax_internals {
	my $self = shift;
	my $args = shift;

	my $text = $self->text_with_one_nl;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args->{force} ) {
		if ( defined( $self->{last_syncheck_md5} )
			and $self->{last_syncheck_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_syncheck_md5} = $md5;

	require Padre::Plugin::Perl6::Syntax;
	my $task = Padre::Plugin::Perl6::Syntax->new(
		document => $self,
	);

	if ( $args->{background} ) {

		# asynchroneous execution (see on_finish hook)
		$task->schedule;
		return;
	} else {

		# serial execution, returning the result
		$task->prepare or return;
		$task->run;
		$task->finish;
		return $task->{model};
	}
}

# In Perl 6 the best way to comment the current error reliably is
# by putting a hash and a space since #( is an embedded comment in Perl 6!
# see S02:166
sub comment_lines_str {
	return '# ';
}

#
# Returns the Outline tree
#
sub get_outline {
	my $self = shift;
	my %args = @_;

	my $tokens = $self->{tokens};

	if ( not defined $tokens ) {
		return;
	}

	my $text = $self->text_get;
	unless ( defined $text and $text ne '' ) {
		return [];
	}

	# Do we really need an update?
	require Digest::MD5;
	my $md5 = Digest::MD5::md5_hex( Encode::encode_utf8($text) );
	unless ( $args{force} ) {
		if ( defined( $self->{last_outline_md5} )
			and $self->{last_outline_md5} eq $md5 )
		{
			return;
		}
	}
	$self->{last_outline_md5} = $md5;

	require Padre::Plugin::Perl6::Outline;
	my $task = Padre::Plugin::Perl6::Outline->new(
		document => $self,
	);

	# asynchronous execution (see on_finish hook)
	$task->schedule;
	return;
}

#
# Returns the help provider
#
sub get_help_provider {
	require Padre::Plugin::Perl6::Help;
	return Padre::Plugin::Perl6::Help->new;
}

#
# Returns the quick fix provider
#
sub get_quick_fix_provider {
	require Padre::Plugin::Perl6::QuickFix;
	return Padre::Plugin::Perl6::QuickFix->new;
}

1;

__END__
=pod

=head1 NAME

Padre::Plugin::Perl6::Document - Perl 6 Support Document

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

