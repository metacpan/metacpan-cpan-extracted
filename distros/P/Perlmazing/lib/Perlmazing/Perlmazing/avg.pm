use List::Util qw(sum);

sub main {
  no warnings qw(numeric uninitialized);
  sum(@_) / @_;
}

1;