use Mojolicious::Lite;

get '/hello' => {text => 'hello'};

app->start;

__END__

mojo daemon --listen http://*:3001 t/webapp/basic.pl
