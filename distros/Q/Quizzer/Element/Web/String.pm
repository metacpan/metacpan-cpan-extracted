#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Web::String - A text input field on a form

=cut

=head1 DESCRIPTION

This element handles a text input field on a web form.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Web::String;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

=head2 show

Generates and returns html representing the text box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b><input name=\"$id\" value=\"$default\">\n";

	return $_;
}

1
