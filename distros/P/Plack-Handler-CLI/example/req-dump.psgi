#!perl -w

use strict;

sub main {
    my($env) = @_;
    return [
        200,
        [ 'Content-Type' => 'text/plain'],
        [ $env->{REQUEST_URI}, "\n" ],
    ];
}

if(caller) {
    return \&main;
}
else {
    require Plack::Handler::CLI;
    my $handler = Plack::Handler::CLI->new();
    $handler->run(\&main, \@ARGV);
}
