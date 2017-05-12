package Parse::Functions;
use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Parse::Functions - list all the functions in source code

=head1 DESCRIPTION

See L<Parse::Functions::Perl>

=cut

sub new {
	my ($class) = @_;
	my $self = bless {}, $class;
	return $self;
}

sub sort_functions {
	my ($self, $functions, $order) = @_;

	return $functions if not $order;

	my @sorted;

	# Sort it appropriately
	if ( $order eq 'alphabetical' ) {

		# Alphabetical (aka 'abc')
		# Ignore case and leading non-word characters
		my @expected = ();
		my @unknown  = ();
		foreach my $function (@$functions) {
			if ( $function =~ /^([^a-zA-Z0-9]*)(.*)$/ ) {
				push @expected, [ $function, $1, lc($2) ];
			} else {
				push @unknown, $function;
			}
		}
		@expected = map { $_->[0] } sort {
			       $a->[2] cmp $b->[2]
				|| length( $a->[1] ) <=> length( $b->[1] )
				|| $a->[1] cmp $b->[1]
				|| $a->[0] cmp $b->[0]
		} @expected;
		@unknown =
			sort { lc($a) cmp lc($b) || $a cmp $b } @unknown;
		@sorted = ( @expected, @unknown );

	} elsif ( $order eq 'alphabetical_private_last' ) {

		# As above, but with private functions last
		my @expected = ();
		my @unknown  = ();
		foreach my $function (@$functions) {
			if ( $function =~ /^([^a-zA-Z0-9]*)(.*)$/ ) {
				push @expected, [ $function, $1, lc($2) ];
			} else {
				push @unknown, $function;
			}
		}
		@expected = map { $_->[0] } sort {
			       length( $a->[1] ) <=> length( $b->[1] )
				|| $a->[1] cmp $b->[1]
				|| $a->[2] cmp $b->[2]
				|| $a->[0] cmp $b->[0]
		} @expected;
		@unknown =
			sort { lc($a) cmp lc($b) || $a cmp $b } @unknown;
		@sorted = ( @expected, @unknown );

	}

	return \@sorted;
}

# recognize newline even if encoding is not the platform default (will not work for MacOS classic)
sub newline { qr{\cM?\cJ} };

sub find {
	my ($self, $text, $sort) = @_;

	# Show an empty function list by default
	return () if not $text;

	my $function_re = $self->function_re;

	my @functions = grep { defined $_ } $text =~ /$function_re/g;

	return @{ $self->sort_functions( \@functions, $sort ) };
}



1;

# Copyright 2008-2014 The Padre development team as listed in Padre.pm.
# LICENSE
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl 5 itself.
