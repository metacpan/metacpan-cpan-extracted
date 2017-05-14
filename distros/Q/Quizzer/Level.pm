#!/usr/bin/perl -w

=head1 NAME

Quizzer::Level - level module

=cut

=head1 DESCRIPTION

This is a simple perl module, not an object. It is used to deal with
the levels of Questions.

=cut

=head1 METHODS

=cut

package Quizzer::Level;
use strict;
use Quizzer::Config;

my $VERSION='0.01';

=head1

Currently known levels are low, medium, high, and critical.

=cut

my %levels=(
	'low' => 0,
	'medium' => 1,
	'high' => 2,
	'critical' => 3,
);

=head1 METHODS

=cut

=head1 high_enough

Returns true iff the passed value is greater than or equal to
the current level level.

=cut

sub high_enough {
	my $level=shift;

	die "Unknown level $level" unless exists $levels{$level};

	return $levels{$level} >= $levels{Quizzer::Config::level()};
}

=head1 AUTHOR

Joey Hess <joey@kitenet.net>

=cut

1
