package Poker::Card;
use strict;
use warnings FATAL => 'all';
use Moo;

=head1 NAME

Poker::Card - Simple class to represent a poker card. 

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';


=head1 SYNOPSIS

This class is used internally by Poker::Deck.  You probably don't want to use it directly. Attributes include rank, suit, up_flag, and wild_flag.

=cut;

has 'suit' => (
  is => 'rw',
);

has 'rank' => (
  is => 'rw',
);

has 'id' => (
  is => 'rw',
);

has 'up_flag' => (
  is => 'rw',
);

has 'wild_flag' => (
  is => 'rw',
  clearer => 1,
  predicate => 'is_wild',
);

sub clone {
  my $self = shift;
  bless { %$self, @_ }, ref $self;
}

=head1 AUTHOR

Nathaniel Graham, C<< <ngraham at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2016 Nathaniel Graham.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
