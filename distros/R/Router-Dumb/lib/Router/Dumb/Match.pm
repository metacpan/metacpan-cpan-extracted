package Router::Dumb::Match;
{
  $Router::Dumb::Match::VERSION = '0.005';
}
use Moose;
# ABSTRACT: a dumb match against a dumb route

use namespace::autoclean;


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
    _matches_href => 'shallow_clone',
  },
);

1;

__END__

=pod

=head1 NAME

Router::Dumb::Match - a dumb match against a dumb route

=head1 VERSION

version 0.005

=head1 OVERVIEW

Match objects are dead simple.  They have a C<target> method that returns the
target of the match (from the Route taken), a C<matches> method that returns a
list of pairs of the placeholders matched, and a C<route> method that returns
the L<route object|Router::Dumb::Route> that led to the match.

=head1 AUTHOR

Ricardo Signes <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Ricardo Signes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
