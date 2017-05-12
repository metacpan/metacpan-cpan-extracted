use Mojolicious::Lite;

get '/' => sub {
  my $c = shift;
  use MojoX::Log::Any;
  $c->render(text => (ref app->log));
};

get '/stderr/adapter' => sub {
  my $c = shift;
  use Log::Any::Adapter;
  Log::Any::Adapter->set('Stderr');
  use MojoX::Log::Any;
  $c->render(text => (ref app->log->adapter));
};
