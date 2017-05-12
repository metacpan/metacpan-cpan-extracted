package Tap;

use Pipeline::Segment;
use Pipeline::Production;
use Water;
use base qw (Pipeline::Segment);

sub init {
  my $self = shift;
  my %params = @_;
  $self->{type} = ($params{type} || 'in');
}

sub dispatch {
  my($self, $pipe) = @_;

  if ($self->{type} eq 'in') {
    my $water = Water->new();
    return $water;
  } elsif ($self->{type} eq 'out') {
    my $water = $pipe->store->get('Water');
    my $production = Pipeline::Production->new();
    $production->contents($water);
    return $production;
  } else {
    warn "unknown tap type $self->{type}\n";
  }
}

1;

__END__

=head1 NAME

Tap - represent a tap in a pipeline

=head1 SYNOPSIS

  use Pipeline;
  use Tap;
  my $pipeline = Pipeline->new();
  $pipeline->add_segment(
    Tap->new(type => 'in'  ),
    # ...
    Tap->new(type => 'out' ),
  );

=head1 DESCRIPTION

C<Tap> is a module used by the C<Pipeline> tests and is a
C<Pipeline::Segment>. It represents a Tap, which can have one of two
states. If it is an 'in' tap, then the tap flows water into the
pipeline. If it is an 'out' tap, then the tap fetches water from the
pipeline and returns it as a production.

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

=cut
