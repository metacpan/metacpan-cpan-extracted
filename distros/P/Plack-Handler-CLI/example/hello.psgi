#!perl -w

use 5.010_000;
use strict;
use Plack::Request;

sub main {
    my $req = Plack::Request->new(@_);

    my $name = $req->param('name') // 'world';
    return [
        200,
        [ 'Content-Type' => 'text/plain'],
        [ "Hello, $name!\n" ],
    ];
}

if(caller) {
    return \&main;
}
else {
    require Plack::Handler::CLI;
    my $handler = Plack::Handler::CLI->new(need_headers => 0);
    $handler->run(\&main, \@ARGV);
}
