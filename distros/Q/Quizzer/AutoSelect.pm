#!/usr/bin/perl -w

=head1 NAME

Quizzer::AutoSelect -- automatic FrontEnd selection library.

=cut

=head1 DESCRIPTION

This library makes it easy to create FrontEnd and ConfModule objects. It starts
with the desired type of object, and tries to make it. If that fails, it
progressivly falls back to other types.

=cut

package Quizzer::AutoSelect;
use strict;
use Quizzer::Config;
use Quizzer::Log ':all';

my $VERSION='0.01';

my %fallback=(
	# preferred frontend		# fall back to
	'Web'			=>	'Gtk',
	'Dialog'		=>	'Text',
	'Gtk'			=>	'Dialog',
	'Text'			=>	'Dialog',
);

my $frontend;
my $type;

=head1 METHODS

=cut

=head2 frontend

Creates and returns a FrontEnd object.

=cut

sub frontend {
	my $script=shift;

	$type=Quizzer::Config::frontend() unless $type;

	my %seen;
	while ($type ne '') {
		debug 1, "trying frontend $type" ;
		$frontend=eval qq{
			use Quizzer::FrontEnd::$type;
			Quizzer::FrontEnd::$type->new();
		};
		last if defined $frontend;
		
		warn "failed to initialize $type frontend";
		debug 1, "(Error: $@)";

		# Only try each type once to prevent loops.
		$seen{$type}=1;
		$type=$fallback{$type};
		last if $seen{$type};

		warn "falling back to $type frontend" if $type ne '';
	}
	
	if (! defined $frontend) {
		# Fallback to noninteractive as a last resort.
		$frontend=eval qq{
			use Quizzer::FrontEnd::Noninteractive;
			Quizzer::FrontEnd::Noninteractive->new();
		};
		die "Unable to start a frontend: $@" unless defined $frontend;
	}

	return $frontend;
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
