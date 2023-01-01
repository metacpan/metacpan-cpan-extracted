package Router::Dumb::Match 0.006;
use Moose;
# ABSTRACT: a dumb match against a dumb route

use namespace::autoclean;

#pod =head1 OVERVIEW
#pod
#pod Match objects are dead simple.  They have a C<target> method that returns the
#pod target of the match (from the Route taken), a C<matches> method that returns a
#pod list of pairs of the placeholders matched, and a C<route> method that returns
#pod the L<route object|Router::Dumb::Route> that led to the match.
#pod
#pod =cut

has route => (
  is  => 'ro',
  isa => 'Router::Dumb::Route',
  required => 1,
  handles  => [ qw(target) ],
);

has matches => (
  isa => 'HashRef',
  required => 1,
  traits   => [ 'Hash' ],
  handles  => {
    matches => 'elements',
  },
);

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Router::Dumb::Match - a dumb match against a dumb route

=head1 VERSION

version 0.006

=head1 OVERVIEW

Match objects are dead simple.  They have a C<target> method that returns the
target of the match (from the Route taken), a C<matches> method that returns a
list of pairs of the placeholders matched, and a C<route> method that returns
the L<route object|Router::Dumb::Route> that led to the match.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 AUTHOR

Ricardo Signes <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
