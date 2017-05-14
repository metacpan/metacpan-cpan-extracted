package Padre::Swarm::Message::Diff;

use strict;
use warnings;
use Padre::Swarm::Message ();

our $VERSION = '0.11';
our @ISA     = 'Padre::Swarm::Message';

sub new {
	my $class = shift;
        my $self  = bless { @_ }, $class;
	return $self;
}

sub file {
	my $self = shift;
	$self->{file} = shift if @_;
	$self->{file};
}

sub project {
	my $self = shift;
	$self->{project} = shift if @_;
	$self->{project};
}

sub project_dir {
	my $self = shift;
	$self->{project_dir} = shift if @_;
	$self->{project_dir};
}

sub diff {
	my $self = shift;
	$self->{diff} = shift if @_;
	$self->{diff};
}

sub comment {
	my $self = shift;
	$self->{comment} = shift if @_;
	$self->{comment};
}

1;
