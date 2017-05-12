use Mojo::Base -strict;

use Test::More tests => 5;
use Test::Mojo;
use Mojo::URL;

use Mojolicious::Lite;

BEGIN { use_ok('Mojolicious::Plugin::Crypto') };

plugin 'crypto', { 
       mac => 1
};

my $t = Test::Mojo->new(app);
my $key = "BIGSecret";

my $hmac = "";
$hmac = $t->app->hmac_hex('SHA256',$key,"Marco2");
ok($hmac eq "67b2afdecffa341fd773373615d53bf700b094611e390539aeb9fdd5a037be07", "Ok $hmac");
$hmac = $t->app->hmac_hex('SHA256',$key,"Marco2","Marco3");
ok($hmac eq "cc4de0c167552705f5c986b840717ca917833078d4b45acc57ef34501ca6e002", "Ok $hmac");
$hmac = $t->app->hmac_hex('SHA256',$key,"Marco2","Marco3","Marco4");
ok($hmac eq "73f2131918b46b1e6a098d01411558ee614993ee2456d80bfe1fc2b829316a59", "Ok $hmac");
$hmac = $t->app->hmac_b64('SHA256',$key,"Marco2","Marco3","Marco4");
ok($hmac eq "c/ITGRi0ax5qCY0BQRVY7mFJk+4kVtgL/h/CuCkxalk=", "Ok $hmac");
done_testing(5);


