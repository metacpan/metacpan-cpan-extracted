package Slovo::Model::Poruchki;
use Mojo::Base 'Slovo::Model', -signatures;

my $table = 'orders';
has table => $table;

sub add ($m, $row) {
  $row->{tstamp}     //= time - 1;
  $row->{created_at} //= $row->{tstamp};
  $m->c->debug($row);
  return $m->next::method($row);
}
1;
