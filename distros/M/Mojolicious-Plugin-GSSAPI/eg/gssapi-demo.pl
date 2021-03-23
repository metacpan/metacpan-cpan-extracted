#!/usr/bin/env perl
use FindBin;
use lib "$FindBin::RealBin/../3rd/lib/perl5";
use lib "$FindBin::RealBin/../lib";
use Mojolicious::Lite -signatures;
plugin 'GSSAPI';

get '/' => sub ($c) {
    my $user = $c->gssapi_auth or return;
    $c->render(text=>'User '.$user.' authenticated. Use ldapsearch for (userprincipal='.$user.') to get more information');
};
app->start;