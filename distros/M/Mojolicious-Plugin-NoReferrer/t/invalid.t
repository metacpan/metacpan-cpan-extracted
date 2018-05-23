use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

my $error;
eval {
    plugin 'NoReferrer' => { content => 'no-referrer-test' };
} or $error = $@;

like $error, qr/invalid value: no-referrer-test/;


done_testing();

