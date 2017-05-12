package Perl::Dist::Inno::System;

# Object that represents [Run] or [UninstallRun] system call entries.

use 5.006;
use strict;
use warnings;
use Carp         qw{ croak               };
use Params::Util qw{ _IDENTIFIER _STRING };

use vars qw{$VERSION};
BEGIN {
	$VERSION = '1.16';
}

use Object::Tiny qw{
	section
	filename
	description
	parameters
	working_dir
	status_msg
	run_once_id
	verbs
	flags
};





#####################################################################
# Constructors

sub new {
	my $class = shift;

	# Create the object
	my $self = bless { @_ }, $class;

	# Check params
	unless (
		defined $self->section
		and
		$self->section =~ /^(?:Run|UninstallRun)$/
	) {
		croak("Missing or invalid 'section' param");
	}
	if (
		defined $self->description
		and
		$self->section eq 'Run'
	) {
		croak("A Description is only valid in a [Run] block");
	}
	if (
		defined $self->status_msg
		and
		$self->section eq 'Run'
	) {
		croak("A StatusMsg is only valid in a [Run] block");
	}
	if (
		defined $self->run_once_id
		and
		$self->section eq 'UninstallRun'
	) {
		croak("A RunOnceId is only valid in an [UninstallRun] block");
	}

	return $self;
}

sub run {
	shift->new(
		section => 'Run',
		@_,
	);
}

sub uninstallrun {
	shift->new(
		section => 'UninstallRun',
		@_,
	);
}





#####################################################################
# Main Methods

sub as_string {
	my $self  = shift;
	my @flags = ();
	# push @flags, 'flag_name' if $self->flag_name;
	return join( '; ',
		(defined $self->filename)
			? ("Filename: \"" . $self->filename . "\"")
			: (),
		(defined $self->description)
			? ("Description: \"" . $self->description . "\"")
			: (),
		(defined $self->parameters)
			? ("Parameters: \"" . $self->parameters . "\"")
			: (),
		(defined $self->working_dir)
			? ("WorkingDir: \"" . $self->working_dir . "\"")
			: (),
		(defined $self->status_msg)
			? ("StatusMsg: \"" . $self->status_msg . "\"")
			: (),
		(defined $self->run_once_id)
			? ("RunOnceId: \"" . $self->run_once_id . "\"")
			: (),
		(defined $self->verbs)
			? ("Verbs: \"" . $self->verbs . "\"")
			: (),
		(scalar @flags)
			? ("Flags: " . join(' ', @flags))
			: (),
	);
}

1;
