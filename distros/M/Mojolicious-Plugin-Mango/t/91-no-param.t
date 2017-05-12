use Modern::Perl;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Try::Tiny;
try {
  use Mango;
  my $mango = Mango->new;
}
catch {
  plan skip_all => 'Cannot test because connection failed';
}
finally {
  no Mango;
};

plugin 'Mango';

for my $helper (qw/_mango mango/) {
  get "/$helper" => sub {
    my $self = shift;
    $self->render(text => ref $self->app->$helper);
  };
}

get '/getdb' => sub {
  my $self = shift;
  $self->render(text => $self->db->name);
};

my $coll = "aaaa";
my $otherdb = 'xhofadFA';
get '/otherdb' => sub {
  my $self = shift;
  $self->render(text => $self->db($otherdb)->name);
};
get '/db_collection' => sub {
  my $self = shift;
  my $db = $self->db;
  my $collection = $db->collection($coll);
  $self->render(text => $collection->name);
};
get '/coll' => sub {
  my $self = shift;
  $self->render(text => $self->coll($coll)->name);
};

my $t = Test::Mojo->new;
$t->get_ok('/mango')->status_is(200)->content_is('Mango');
$t->get_ok('/_mango')->status_is(200)->content_is('Mango');
$t->get_ok('/getdb')->status_is(200)->content_is('test');
$t->get_ok('/otherdb')->status_is(200)->content_is($otherdb);
$t->get_ok('/db_collection')->status_is(200)->content_is($coll);
$t->get_ok('/coll')->status_is(200)->content_is($coll);

done_testing;

