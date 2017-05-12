package Regexp::Storable;

our $VERSION = '0.06';

package Regexp;


sub STORABLE_freeze {
  my $serialized = substr($_[0], rindex($_[0],':')+1, -1);
  return $serialized;
}

sub STORABLE_thaw {
  my ( $original, $cloning, $thaw ) = @_;
  my $final = ($thaw) ? qr/$thaw/ : qr//;
  Regexp::Copy::re_copy($final, $original);
}

1;
