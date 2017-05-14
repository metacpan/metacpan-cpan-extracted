#!/usr/bin/perl -w

=head1 NAME

Quizzer::FrontEnd::Noninteractive - non-interactive FrontEnd

=cut

=head1 DESCRIPTION

This FrontEnd is completly non-interactive.

=cut

=head1 METHODS

=cut
   
package Quizzer::FrontEnd::Noninteractive;
use Quizzer::FrontEnd;
use Quizzer::Log ':all';
use strict;
use vars qw(@ISA);
@ISA=qw(Quizzer::FrontEnd);

my $VERSION='0.01';

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
