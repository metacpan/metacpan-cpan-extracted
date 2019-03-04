package RogersMine::MineField;
use 5.20.0;
use Moo;
use strictures;
use RogersMine::Cell;

has risk => (is => 'ro');
has rows => (is => 'ro');
has cols => (is => 'ro');
has lives => (is => 'rw');
has minefield => (is => 'lazy');

sub _build_minefield {
  my $self = shift;
  my $minefield = [];
  for my $i (0..$self->rows) {
    my $row = [];
    for my $j (0..$self->cols) {
      push @$row, RogersMine::Cell->new(risk => $self->risk);
    }
    push @$minefield, $row;
  }
  $minefield;
}

sub complete {
  my $self = shift;
  return 1 if $self->lives <= 0;
  for my $i (0..$self->rows-1) {
    for my $j (0..$self->cols-1) {
      my $cell = $self->cell($i, $j);
      return 0 unless $cell->clicked || $cell->bomb;
    }
  }
  1;
}

sub safe {
  my ($self, $i, $j) = @_;
  return 0 if $self->cell($i, $j)->bomb;
  my $safety = 9;
  for my $x ($i-1..$i+1) {
    for my $y ($j-1..$j+1) {
      my $cell = $self->cell($x, $y);
      if(!$self->cell($x, $y) || $self->cell($x, $y)->bomb) {
        $safety -= 1;
      }
    }
  }
  $safety;
}

sub click {
  my ($self, $i, $j) = @_;
  my $safety = $self->safe($i, $j);
  if(!$safety && !$self->cell($i, $j)->clicked) {
    $self->lives($self->lives - 1);
  }
  $self->cell($i, $j)->clicked(1);
  return $safety;
}

sub cell {
  my ($self, $i, $j) = @_;
  return undef if $i >= $self->rows || $i < 0 || $j >= $self->cols || $j < 0;
  return $self->minefield->[$i][$j];
}

1;
