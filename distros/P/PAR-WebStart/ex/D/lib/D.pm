package D;
our $VERSION = 0.1;
sub new {
  my $class = shift;
  bless {}, $class;
}

sub print_d {
  print "Hello from D\n";
}

1;

