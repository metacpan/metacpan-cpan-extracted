package Water;
use Acme::Colour;

sub new {
  bless { colour => Acme::Colour->new("white") }, shift;
}

sub colour {
  my $self = shift;
  my $colour = shift;
  if (defined $colour) {
    $self->{colour} = Acme::Colour->new($colour);
  } else {
    my $colour = $self->{colour}->colour;
    $colour = "clear" if $colour eq "white";
    return $colour;
  }
}

sub dye {
  my $self = shift;
  my $ink = shift;
  $self->{colour}->mix($ink, 0.5);
}

1;

__END__

=head1 NAME

Water - represent water in a pipeline

=head1 SYNOPSIS

  use Water;
  my $water = Water->new();
  print "Water is: " . $water->colour . "\n"; # clear
  $water->dye("blue");
  print "Water is: " . $water->colour . "\n"; # light slate blue

=head1 DESCRIPTION

C<Water> is a module used by the C<Pipeline> tests. It represents a
small amount of water, which starts off clear and can be dyed by other
colours.

=head1 AUTHOR

Leon Brocard <leon@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

This software is released under the same terms as Perl itself.

=cut


