package Test::Common;

use Test::More;
require './t/MySerializer.pm';

sub test_core {
    my($middleware, $clear_cb, $app_cb, $cmp_cb) = @_;

    my $app = $middleware->wrap( sub {
	my $env = shift;
	$app_cb->($env);
	return [200, ["content-type", "text/plain"], []];
    } );

    my $cookie;
    for(1..4) {
	$clear_cb->();
	my $env = { HTTP_COOKIE => $cookie };
	my $res = $app->($env);
	$cmp_cb->($_);

	undef $cookie;
	for( 0 .. int($#{$res->[1]}/2) ) {
	    if( $res->[1][$_*2] =~ /^Set-Cookie$/i ) {
		$res->[1][$_*2+1] =~ /([^;]*)/;
		$cookie .= "$1;";
	    }
	}
    }
}

sub test_plain_scalar {
    my($prefix, $middleware) = @_;
    my $count;
    test_core(
	$middleware,
	sub { undef $count },
	sub { $count = ++$_[0]{'psgix.session'} },
	sub { is($count, $_[0], "$prefix test_plain $_[0]") },
    );
}

sub test_array_ref {
    my($prefix, $middleware) = @_;
    my $arr;
    test_core(
	$middleware,
	sub { undef $arr },
	sub { $arr = $_[0]{'psgix.session'} ||= [0]; ++$arr->[0] },
	sub { is($arr->[0], $_[0], "$prefix test_array $_[0]") },
    );
}

sub test_hash_ref {
    my($prefix, $middleware) = @_;
    my $hash;
    test_core(
	$middleware,
	sub { undef $hash },
	sub { $hash = $_[0]{'psgix.session'} ||= { data => 0 }; ++$hash->{data} },
	sub { is($hash->{data}, $_[0], "$prefix test_hash $_[0]") },
    );
}


sub test_plain {
    my($serialize, $deserialize, $serializer) = @_;
    $serializer = MySerializer->new($serialize, $deserialize) if !$serializer;
    $serialize = sub { $serializer->serialize(@_) } if !$serialize;
    $deserialize = sub { $serializer->deserialize(@_) } if !$deserialize;
    my $exception = sub { warn @_ };

    test_plain_scalar(
	'serialize deserialize',
	Plack::Middleware::Session::SerializedCookie->new(
	    serialize => $serialize,
	    deserialize => $deserialize,
	    serialize_exception => $exception,
	    deserialize_exception => $exception,
	)
    );

    test_plain_scalar(
	'serializer',
	Plack::Middleware::Session::SerializedCookie->new(
	    serializer => $serializer,
	    serialize_exception => $exception,
	    deserialize_exception => $exception,
	)
    );
}

sub test_complex {
    my($serialize, $deserialize, $serializer) = @_;
    $serializer = MySerializer->new($serialize, $deserialize) if !$serializer;
    $serialize = sub { $serializer->serialize(@_) } if !$serialize;
    $deserialize = sub { $serializer->deserialize(@_) } if !$deserialize;
    my $exception = sub { warn @_ };

    test_array_ref(
	'serialize deserialize',
	Plack::Middleware::Session::SerializedCookie->new(
	    serialize => $serialize,
	    deserialize => $deserialize,
	    serialize_exception => $exception,
	    deserialize_exception => $exception,
	)
    );

    test_array_ref(
	'serializer',
	Plack::Middleware::Session::SerializedCookie->new(
	    serializer => $serializer,
	    serialize_exception => $exception,
	    deserialize_exception => $exception,
	)
    );

    test_hash_ref(
	'serialize deserialize',
	Plack::Middleware::Session::SerializedCookie->new(
	    serialize => $serialize,
	    deserialize => $deserialize,
	    serialize_exception => $exception,
	    deserialize_exception => $exception,
	)
    );

    test_hash_ref(
	'serializer',
	Plack::Middleware::Session::SerializedCookie->new(
	    serializer => $serializer,
	    serialize_exception => $exception,
	    deserialize_exception => $exception,
	)
    );
}

1;
