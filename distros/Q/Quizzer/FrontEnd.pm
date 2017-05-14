#!/usr/bin/perl -w

=head1 NAME

Quizzer::FrontEnd - base FrontEnd

=cut

=head1 DESCRIPTION

This is the base of the FrontEnd class. Each FrontEnd presents a
user interface of some kind to the user, and handles generating and
communicating with Elements to form that FrontEnd.

=cut

=head1 METHODS

=cut

package Quizzer::FrontEnd;
use Quizzer::Level;
use Quizzer::Config;
use Quizzer::Base;
use Quizzer::Log ':all';
use strict;
use vars qw(@ISA);
@ISA=qw(Quizzer::Base);

my $VERSION='0.01';

=head2 new

Creates a new FrontEnd object and returns it.

=cut

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless $proto->SUPER::new(@_), $class;
	$self->{elements}=[];
	$self->{interactive}='';
	$self->{capb}='';
	$self->{title}="";
	return $self
}

=head2 makeelement

This helper function creates an Element. Pass in the type of Frontend the
Element is for, and the Question that will be bound to the Element. It returns
the generated Element, or false if it was unable to make an Element of the given
type.

=cut

sub makeelement {
	my $this=shift;
	my $frontend_type=shift;
	my $question=shift;

	my $type=$frontend_type.'::'.ucfirst($question->template->type);
	debug 2, "Trying to make element of type $type";
	my $element=eval qq{
		use Quizzer::Element::$type;
		Quizzer::Element::$type->new;
	};
	debug 2, "Failed with $@" if $@;
	if (! ref $element) {
		return;
	}
	$element->frontend($this);
	$element->question($question);
	return $element;
}

=head2 add

Add a Question to the list to be displayed to the user. Pass the Question and
text indicating the level of the Question. This creates an Element and adds
it to the array in the elements property. Returns true if the created Element
is visible.

=cut

sub add {
	my $this=shift;
	my $question=shift || die "\$question is undefined";
	my $level=shift;

	# Figure out if the question should be displayed to the user or not.
	my $visible=1;

	# Noninteractive frontends never show anything.
	$visible='' if ! $this->interactive;
	
	# Don't show items that are unimportant.
	$visible='' unless Quizzer::Level::high_enough($level);
	
	# Set showold to ask even default questions.
	$visible='' if Quizzer::Config::showold() eq 'false' &&
		$question->flag_isdefault eq 'false';
	
	my $element;
	if ($visible) {
		# Create an input Element of the type associated with
		# this frontend. This requires some nastiness.
		my ($frontend_type)=ref($this)=~m/Quizzer::FrontEnd::(.*)/;
		$element=$this->makeelement($frontend_type, $question) ||
			 die "Unknown type of element";

		# Ask the Element if it thinks it is visible. If not,
		# fall back below to making a noninteractive element.
		#
		# This last check is useful, because for example, select
		# Elements are not really visible if they have less than two
		# choices.
		$visible=$element->visible;
	}
	if (! $visible) {
		# Create a noninteractive element.
		$element=$this->makeelement('Noninteractive', $question) ||
			return; # no noninteractive element of this type.
	}
	
	push @{$this->{elements}}, $element;
	return $element->visible;
}

=head2 go

Display accumulated Elements to the user. The Elements are in the elements
property, and that property is cleared after the Elements are presented.

After showing each element, checks to see if the object's backup property has
been set; if so, doen't display any of the other pending questions (remove them
from the buffer), and return false. The default is to return true.

The return value of each element's show() method is used to set the value of
the question associated with that element.

=cut

sub go {
	my $this=shift;

	debug 2, "preparing to ask questions";
	foreach my $element (@{$this->elements}) {
		my $value=$element->show;
		if ($this->backup) {
			$this->{elements}=[];
			$this->backup('');
			return;
		}
		$element->question->value($value);
		# Only set isdefault if the element was visible, because we
		# don't want to do it when showing noninteractive select 
		# elements and so on.
		$element->question->flag_isdefault('false')
			if $element->visible;
	}
	$this->clear;
	return 1;
}

=head2 clear

Clear out the accumulated elements.

=cut

sub clear {
	my $this=shift;
	
	$this->{elements}=[];
}

=head2 default_title

This sets the title property to a default. Pass in the name of the
package that is being configured.

=cut

sub default_title {
	my $this=shift;
	
	$this->title(ucfirst(shift));
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
