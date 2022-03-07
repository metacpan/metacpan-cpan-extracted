package Slovo::Model::Products;
use Mojo::Base 'Slovo::Model', -signatures;
use Slovo::Model::Celini;

my $table = 'products';
has table => $table;
my $ctable = Slovo::Model::Celini->table;

sub add ($m, $row) {
  $row->{tstamp}     //= time - 1;
  $row->{created_at} //= $row->{tstamp};
  $m->c->debug($row);
  return $m->next::method($row);
}

# select "books" with the same celina.pid except the book with the current
# celina.id
sub others ($m, $celina) {
  return $m->all({
    table   => [$ctable, $table],
    columns => "$ctable.language,$table.title,$table.properties,$table.alias",
    where   => {
      "$ctable.id"   => {'!=' => $celina->{id}},
      language       => {'='  => $celina->{language}},
      pid            => $celina->{pid},
      p_type         => $celina->{data_type},
      published      => {'>'   => 1},
      "$table.alias" => {'='   => \"$ctable.alias"},
      properties     => {-like => '%"images"%'}        #only variants which have images
    },
    limit => 35
  })->each(sub {
    $_->{properties} = Mojo::JSON::from_json($_->{properties});
  });

}

1;
