#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Web::Container - A group of releated questions

=cut

=head1 DESCRIPTION

This element handles a group of related questions on a web form.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Web::Container;
use strict;
use Quizzer::Element::Container;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Container);

my $VERSION='0.01';

=head2 show

Calls all elements inside it and collects the text they return.

=cut

sub show {
	my $this=shift;
	my @contained=@{$this->contained};
	my $ret='';

	foreach my $elt (@contained) {
		$ret.=$elt->show;
	}
	
	return $ret;
}

=head2 process

This gets called once the user has entered a value, to process it before        
it is stored.

=cut

sub process {
	my $this=shift;

	# TODO: need to process values of all elements contained within. Ugh.
}

1
