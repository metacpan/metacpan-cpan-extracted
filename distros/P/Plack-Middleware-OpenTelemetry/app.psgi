#!/usr/bin/env perl
use strict;
use warnings;
use lib '/Users/ask/src/ntppool/lib';
use NP::Tracing;

use Plack::Builder;

my $body = join '', <DATA>;

my $app = sub {
    my $self = shift;
    warn "REQ: $self->{REQUEST_URI}";
    if ( $self->{REQUEST_URI} eq "/slow") { sleep 10 }
    return [200, ['Content-Type' => 'text/html'], [ $body ]];
};

builder {
    # Precious debug info. Right on your page!
    enable 'Debug';

    # Make Plack middleware render some static for you
    enable "Static",
      path => qr{\.(?:js|css|jpe?g|gif|ico|png|html?|swf|txt)$},
      root => './htdocs';

    # Let Plack care about length header
    enable "ContentLength";

    $app;
}

__DATA__
<!doctype html>
<html>

<head>
 <title>Few words about Plack and PSGI</title>
</head>

<body>
 <h1>Hello World!</h1>
</body>

</html>

