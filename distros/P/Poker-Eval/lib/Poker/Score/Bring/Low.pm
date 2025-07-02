package Poker::Score::Bring::Low;
use Moo;
use Algorithm::Combinatorics qw(combinations);
use List::Util qw(max);

=head1 NAME

Poker::Score::Bring::Low - Scoring system used in lowball Stud to decide which player starts the action.

=head1 VERSION

Version 0.09

=cut

our $VERSION = '0.09';

=head1 SYNOPSIS

See Poker::Score for code example.

=cut


extends 'Poker::Score::Bring::High';

after _build_hands => sub {
  my $self = shift;
  $self->hands( [ reverse @{ $self->hands } ] );
};

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
