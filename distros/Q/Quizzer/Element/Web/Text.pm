#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Web::Text - A paragraph on a form

=cut

=head1 DESCRIPTION

This element handles a paragraph of text on a web form.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Web::Text;
use strict;
use Quizzer::Element;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element);

my $VERSION='0.01';

=head2 show

Generates and returns html for the paragraph of text.

=cut

sub show {
	my $this=shift;

	$_=$this->question->extended_description;
	s/\n/\n<br>\n/g;
	$_.="\n<p>\n";

	return "<b>".$this->question->description."</b>$_<p>";
}

1
