#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Web::Select - A select box on a form

=cut

=head1 DESCRIPTION

This element handles a select box on a web form.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Web::Select;
use strict;
use Quizzer::Element::Select;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Select);

my $VERSION='0.01';

=head2 show

Generates and returns html representing the select box.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	my $default='';
	$default=$this->question->value if defined $this->question->value;
	my $id=$this->id;
	$_.="<b>".$this->question->description."</b>\n<select name=\"$id\">\n";
	my $c=0;
	foreach my $x ($this->question->choices_split) {
		if ($x ne $default) {
			$_.="<option value=".$c++.">$x\n";
		}
		else {
			$_.="<option value=".$c++." selected>$x\n";
		}
	}
	$_.="</select>\n";
	
	return $_;
}

=head2 process

This gets called once the user has entered a value. It is passed the
value they entered. It saves the value in the associated Question.

=cut

sub process {
	my $this=shift;
	my $value=shift;

	my @choices=$this->question->choices_split;
	return $choices[$value];
}

1
