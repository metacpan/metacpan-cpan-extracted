package Purple::Object {
  use Pony::Object;

  sub sum($self, $a, $b = 0) {
    return $a + $b;
  }

  sub sum_it($self, @args) {
    return $self->sum(@args);
  }
}

1;
