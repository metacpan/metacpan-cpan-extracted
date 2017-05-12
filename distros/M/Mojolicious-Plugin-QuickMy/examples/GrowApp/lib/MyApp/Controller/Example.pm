package MyApp::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

sub index {
  my $c = shift;
  my $sort = $c->param('order') || 'desc';
  my $order = ($sort eq 'desc') ? 'asc' : ($sort eq 'asc') ? 'desc' : 'desc';
  # simple select: ($table) = $c->qselect('table_name');
  my ($table) = $c->qselect('models',
                          {},
                          {
                            order_by  => { $sort => 'id' },
                            limit     => 10,
                            # select custom columns
                            # columns   => [qw(id name foto)],
                          }
                          );
  
  #my $custom = $c->qcustom('SELECT * FROM models WHERE name LIKE ?','New%');
  #say $c->dumper($custom->hashes->to_array);
  $c->stash(
            table => $table,
            count => $c->qcount('models'),
            order => $order,
            );
  $c->render;
}

sub edit {
  my $c = shift;
  my $id = $c->param('id');
  $c->qupdate('models', {id => $id}, { name => 'New York',
                                      foto => 'https://www.flickr.com/search/?text=New%20York'
                                      } );
  $c->redirect_to('/');
}

sub insert {
  my $c = shift;
  my $id = $c->qinsert('models', { name => 'Moscow', foto => 'https://www.flickr.com/search/?text=Moscow' } );
  $c->app->log->info($id);
  $c->redirect_to('/');
}

sub delete {
  my $c = shift;
  my $id = $c->param('id');
  $c->qdelete('models', {id => $id});
  $c->redirect_to('/');
}

1;
