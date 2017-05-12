#!/usr/bin/env perl
use Mojo::Base;

# turn off requiring explict inclusion because we're using Mojolicious::Lite
## no critic (Modules::RequireExplicitInclusion)

use Test::More tests => 3;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'WithCSRFProtection';

# custom error
post '/example' => ( with_csrf_protection => 1 );

########################################################################

my $t = Test::Mojo->new;

$t->post_ok('/example')->status_is(403)
    ->content_like(qr/custom error message/);

__DATA__

@@ example.html.ep
<html><body>should not get</body></html>

@@ bad_csrf.html.ep
<html><body>custom error message</body></html>
