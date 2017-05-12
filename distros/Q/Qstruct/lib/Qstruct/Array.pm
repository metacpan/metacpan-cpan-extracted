package Qstruct::Array;

use strict;
use Carp;

use Tie::Array;
our @ISA = ('Tie::Array');


sub TIEARRAY {
  my $class = shift;
  my $obj = shift;
  return bless $obj, $class;
}

sub FETCH {
  my $self = shift;
  my $index = shift;
  return $self->{a}->($index);
}

sub FETCHSIZE {
  my $self = shift;
  return $self->{n};
}

sub STORE {
  croak "unable to modify a read-only Qstruct array";
}


package Qstruct::ArrayRef;

use strict;

use overload
  ## Make this behave like an array ref
  '@{}' => sub { $_[0]->{arr} },

  ## This method is used by Test::More is_deeply()
  ## FIXME: if it doesn't match is_deeply() prints dumb 'Operation """": no method found' error
  'eq' => sub {
            my ($self, $compare) = @_;
            my $arr = $self->{arr};
            return '' if @$arr != @$compare;
            for my $i (0 .. (@$compare - 1)) {
              return '' if $arr->[$i] ne $compare->[$i];
            }
            return 1;
          },
  ;


sub new {
  my ($class, $elems, $elem_accessor, $raw_accessor) = @_;

  my @arr;
  tie @arr, 'Qstruct::Array', {
                                n => $elems,
                                a => $elem_accessor,
                              };

  return bless { n => $elems, arr => \@arr, a => $elem_accessor, raw => $raw_accessor, }, $class; 
}


sub raw {
  my $self = shift;

  die "array type doesn't support raw access"
    if !$self->{raw};

  $self->{raw}->(exists $_[0] ? $_[0] : my $o);
  return $o if !exists $_[0];
}


sub foreach {
  my $self = shift;

  for my $i (0 .. ($self->{n} - 1)) {
    $self->{a}->($i, my $o);
    $_[0]->($o);
  }
}


sub len {
  return $_[0]->{n};
}


sub get {
  my $self = shift;
  $self->{a}->($_[0], exists $_[1] ? $_[1] : my $o);
  return $o if !exists $_[1];
}


1;
