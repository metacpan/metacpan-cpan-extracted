use strict; use warnings;
package Sub::Composable;
use Sub::Name;

# use Sub::Compose qw( chain ); # doesn't fucking work, due to scalar/list context shenanigans

sub compose {
    my ($l, $r, $swap) = @_;

    if ($swap) { ($l, $r) = ($r, $l); }
    my $sub = subname composition => sub {
        $l->($r->(@_));
        };
    bless $sub, __PACKAGE__;
}

sub backcompose {
    my ($l, $r, $swap) = @_;

    compose($l, $r, !$swap);
}

sub applyto {
  my ($self, $other, $swap)=@_;

  if ($swap) {
    # $other | $self
    $self->($other);
  } else {
    # $self | $other
    overload::Method($other, '|')->($other, $self, 1);
  }
}

use overload '<<' => \&compose,
             '>>' => \&backcompose,
             '|'  => \&applyto;

1;
