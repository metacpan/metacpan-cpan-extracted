print "1..60\n";

use Statistics::Frequency;

my $t = 1;

sub ok ($$) {
  print +(defined $_[0] ? $_[0] == $_[1] : not defined $_[1]) ?
	"ok $t\n" : "not ok $t\n";
  $t++;
}

sub test {
  my $f = shift;

  ok($f->elements, 3);

  ok($f->frequency(1), 3);
  ok($f->frequency(2), 2);
  ok($f->frequency(3), 1);
  ok($f->frequency(4), undef);

  ok($f->frequencies_sum, 6);
  ok($f->frequencies_min, 1);
  ok($f->frequencies_max, 3);

  my %freq = $f->frequencies;

  ok($freq{1}, 3);
  ok($freq{2}, 2);
  ok($freq{3}, 1);
  ok($freq{4}, undef);

  ok($f->proportional_frequency(1), 3/6);
  ok($f->proportional_frequency(2), 2/6);
  ok($f->proportional_frequency(3), 1/6);
  ok($f->proportional_frequency(4), undef);

  my %prop = $f->proportional_frequencies;

  ok($prop{1}, 3/6);
  ok($prop{2}, 2/6);
  ok($prop{3}, 1/6);
  ok($prop{4}, undef);
}

test( Statistics::Frequency->new(   1, 1, 1, 2, 2, 3, 4 )->remove_data(4) );
test( Statistics::Frequency->new( [ 1, 1, 1, 2, 2, 3, 4 ] )->remove_data(4) );
test( Statistics::Frequency->new( { 1 => 3, 2 => 2, 3 => 1, 4 => 1 } )->remove_data(4) );

