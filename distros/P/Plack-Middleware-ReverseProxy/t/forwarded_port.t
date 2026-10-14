use strict;
use warnings;
use Test::More;
use Plack::Middleware::ReverseProxy;

my $env;
my $app = Plack::Middleware::ReverseProxy->wrap(sub { $env = shift; [ 200, [], [] ] });

sub run_with_port {
    my $port = shift;
    $app->({
        'psgi.url_scheme'      => 'http',
        HTTP_HOST              => '127.0.0.1:5000',
        SERVER_PORT            => 5000,
        HTTP_X_FORWARDED_HOST  => 'example.com',
        HTTP_X_FORWARDED_PORT  => $port,
    });
}

run_with_port('8080');
is $env->{SERVER_PORT}, 8080, 'numeric X-Forwarded-Port is used';
is $env->{HTTP_HOST}, 'example.com:8080';

for my $port ('(', '.*.*.*1', '80abc', "80\n", '80; rm', 'example.com',
              "\x{0663}", "\x{FF18}\x{FF10}") { # non-ASCII digits
    run_with_port($port);
    (my $name = $port) =~ s/([^\x20-\x7e])/sprintf '\\x{%X}', ord $1/ge;
    is $env->{SERVER_PORT}, 80, "non-numeric X-Forwarded-Port '$name' is ignored";
    is $env->{HTTP_HOST}, 'example.com', "non-numeric X-Forwarded-Port '$name' is not added to Host";
}

# non-ASCII digits in the port part of Host headers are not a port
for my $header (qw(HTTP_HOST HTTP_X_FORWARDED_HOST)) {
    $app->({
        'psgi.url_scheme' => 'http',
        HTTP_HOST         => '127.0.0.1',
        SERVER_PORT       => 5000,
        $header           => "example.com:\x{0663}",
    });
    is $env->{SERVER_PORT}, 80, "non-ASCII digits in $header port are ignored";
}

done_testing;
