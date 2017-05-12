package Reaction::ClassExporter;

use strict;
use warnings;
use Reaction::Class ();

sub import {
  my $self = shift;
  my $pkg = caller;
  &strict::import;
  &warnings::import;
  {
    no strict 'refs';
    @{"${pkg}::ISA"} = ('Reaction::Class');
    *{"${pkg}::import"} = \&Reaction::Class::import;
  }
  goto &Moose::import;
}

1;

=head1 NAME

Reaction::ClassExporter

=head1 DESCRIPTION

=head1 SEE ALSO

L<Reaction::Class>

=head1 AUTHORS

See L<Reaction::Class> for authors.

=head1 LICENSE

See L<Reaction::Class> for the license.

=cut
