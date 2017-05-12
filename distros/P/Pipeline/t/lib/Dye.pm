package Dye;

use Pipeline::Segment;
use Water;
use base qw (Pipeline::Segment);

sub init {
  my $self = shift;
  my %params = @_;
  $self->{ink} = ($params{ink} || 'green');
}

sub dispatch {
  my($self, $pipe) = @_;
  my $water = $pipe->store->get('Water');
  $water->dye($self->{ink});
  $pipe->store->set($water);

  return 1;
}

1;

__END__

=head1 NAME

Dye - Dye water in a pipeline

=head1 SYNOPSIS

  use Dye;
  use Pipeline;
  use Tap;
  my $pipeline = Pipeline->new();
  $pipeline->add_segment(
    Tap->new(type => 'in'  ),
    Dye->new( ink => 'blue'),
    Tap->new(type => 'out' ),
  );

=head1 DESCRIPTION

C<Dye> is a module used by the C<Pipeline> tests and is a
C<Pipeline::Segment>. It represents a part of a pipeline which
contains a dye, dyeing the water a colour.

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

=cut
