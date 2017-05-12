use 5.006;
use strict;
use warnings;

package Set::Associate::Role::RefillItems;

# ABSTRACT: A data provider for Set::Associate

our $VERSION = '0.004001';

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use MooseX::Role::Parameterized qw( parameter role requires );

parameter can_get_next => (
  isa     => Bool =>,
  is      => rw   =>,
  default => sub  { undef },
);

parameter can_get_all => (
  isa     => Bool =>,
  is      => rw   =>,
  default => sub  { undef },
);

parameter can_get_nth => (
  isa => Bool =>,
  ,
  is      => rw  =>,
  default => sub { undef },
);

role {
  my $p = shift;

  requires name =>;

  if ( $p->can_get_next ) {
    requires get_next =>;
  }
  if ( $p->can_get_all ) {
    requires get_all =>;
  }
  if ( $p->can_get_nth ) {
    requires get_nth =>;
  }

};

no MooseX::Role::Parameterized;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Set::Associate::Role::RefillItems - A data provider for Set::Associate

=head1 VERSION

version 0.004001

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
