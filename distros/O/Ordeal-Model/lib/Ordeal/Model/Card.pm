package Ordeal::Model::Card;

# vim: ts=3 sts=3 sw=3 et ai :

use 5.020;
use strict;    # redundant, but still useful to document
use warnings;
{ our $VERSION = '0.004'; }
use English qw< -no_match_vars >;
use Mo qw< default >;

use experimental qw< signatures postderef >;
no warnings qw< experimental::signatures experimental::postderef >;

use overload
  ne => sub { shift->compare_ne(@_) },
  bool => sub { return 1 },
  fallback => 0;    # false but defined, disables Magic Autogeneration

has content_type => (default => undef);
has group        => (default => '');
has id           => (default => undef);
has name         => (default => '');

sub compare_ne ($self, $other, $x) { return $self->id ne $other->id }

sub data ($self, $data = undef) {
   $self->{data} = $data if @_ > 1;
   $self->{data} = $self->{data}->($self) if ref $self->{data};
   return $self->{data};
}

1;
__END__
