package Miril::Filter::Markdown;

use strict;
use warnings;
use autodie;

use Text::MultiMarkdown;

sub new {
	my $class = shift;
	my $self = bless {}, $class;

	$self->{mm} = Text::MultiMarkdown->new;
	return $self;
}

sub to_xhtml {
	my $self = shift;
	my $data = shift;

	return $self->mm->markdown($data);
}

sub mm {return shift->{mm};}

1;
