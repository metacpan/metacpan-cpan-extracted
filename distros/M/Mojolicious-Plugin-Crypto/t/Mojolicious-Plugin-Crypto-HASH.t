use Mojo::Base -strict;

use Test::More tests => 3;
use Test::Mojo;
use Mojo::URL;

use Mojolicious::Lite;

BEGIN { use_ok('Mojolicious::Plugin::Crypto') };

sub rndStr{ join'', @_[ map{ rand @_ } 1 .. shift ] }

plugin 'crypto', { 
       digest => 1 
};

my $t = Test::Mojo->new(app);

my $hash = "";
$hash = $t->app->sha256_hex("MARCO2");
ok($hash eq "ba2dc2f8d0bb5ab24abdcf35f42b0026aa193dd8d0e52671ebd75063736cf2b3", "Ok $hash");
$hash = $t->app->md5_hex("MARCO2");
ok($hash eq "15be59d85afe10272cf9f32442289524", "Ok $hash");

done_testing(3);


