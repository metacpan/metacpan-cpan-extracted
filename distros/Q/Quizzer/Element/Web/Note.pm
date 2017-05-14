#!/usr/bin/perl -w

=head1 NAME

Quizzer::Element::Web::Note - A paragraph on a form

=cut

=head1 DESCRIPTION

This element handles a paragraph of text on a web form. It is identical to
Quizzer::Element::Web::Text.

=cut

=head1 METHODS

=cut

package Quizzer::Element::Web::Note;
use strict;
use Quizzer::Element::Web::Text;
use vars qw(@ISA);
@ISA=qw(Quizzer::Element::Web::Text);

my $VERSION='0.01';

1
