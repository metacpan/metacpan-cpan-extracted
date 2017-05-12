# Rex::IO::Client

A api client for rex-io-server.

## EXAMPLE

```perl
my $cl = Rex::IO::Client->create(
  protocol => 1,
  endpoint => "http://"
    . $self->session('user') . ":"
    . $self->session('password') . '@'
    . $app->config->{server}->{url}
);

my $ret = $cl->call("GET", "1.0", "user", user => undef)->{data};

my $ret = $cl->call(
  "POST", "1.0", "user",
  user => undef,
  ref  => $self->req->json->{data},
);

my $ret = $cl->call( "DELETE", "1.0", "user", user => $self->param("user_id") );

```

The Syntax of the `call` method is:

```
$cl->call( $HTTP_METHOD, $api_version, $plugin, $resource => $value, [ ref => $data ] );
```

If you don't need a `$value` to access the resource you have to use `undef`.
If you need to send json data via `POST` or `PUT` you can use the `ref` parameter.

