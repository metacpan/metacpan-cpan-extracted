package Perldoc::Server::View::TT;

use strict;
use parent 'Catalyst::View::TT';
use MRO::Compat;

__PACKAGE__->config(TEMPLATE_EXTENSION => '.tt');

sub process {
  my ($self, $c) = @_;
  $c->stash->{template} = 'default.tt';

  if (my $counter = $c->session->{counter}) {
    if (scalar keys %{$counter} > 0) {
      my @most_viewed = sort {$counter->{$b}{count} <=> $counter->{$a}{count}} keys %{$counter};
      @most_viewed = @most_viewed[0 .. 9] if (@most_viewed > 10);
      @most_viewed = map {
        {
          link => $_,
          name => $c->session->{counter}{$_}{name},
        }
      } @most_viewed;
      $c->stash->{most_viewed} = \@most_viewed;
    }
  }

  return $self->maybe::next::method($c);
}


=head1 NAME

Perldoc::Server::View::TT - TT View for Perldoc::Server

=head1 DESCRIPTION

TT View for Perldoc::Server. 

=head1 AUTHOR

=head1 SEE ALSO

L<Perldoc::Server>

Jon Allen

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
