package Miril::Store::File::Post;

use strict;
use warnings;
use autodie;

use Try::Tiny;
use Miril::Exception;
use Miril::Filter::Markdown;
use File::Slurp;

use base 'Miril::Post';

use Object::Tiny qw(in_path);

sub body {
	my $self = shift;

	if ($self->{body}) {
		return $self->{body};
	} else {
		$self->_populate;
		return $self->{body};
	}
}

sub teaser {
	my $self = shift;

	if ($self->{teaser}) {
		return $self->{teaser};
	} else {
		$self->_populate;
		return $self->{teaser};
	}
}

sub status {
	my $self = shift;
	my $status = $self->published ? 'published' : 'draft';
	return $status;
}

sub _populate {
	my $self = shift;

	my $post_file;
	try {
		$post_file = File::Slurp::read_file($self->in_path);
	} catch {
		Miril::Exception->throw(
			message => "Cannot load data file",
			errorvar => $_,
		);
	};

	my ($meta, $source) = split( /\n\n/, $post_file, 2);
	my ($teaser) = split( '<!-- BREAK -->', $source, 2);

	# temporary until we introduce multiple filters
	my $filter = Miril::Filter::Markdown->new;

	$self->{body}   = $filter->to_xhtml($source);
	$self->{teaser} = $filter->to_xhtml($teaser);
	$self->{source} = $source;
}

1;
