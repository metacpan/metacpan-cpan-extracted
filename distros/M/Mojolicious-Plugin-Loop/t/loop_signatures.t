use Test::More;
use Test::Mojo;
eval "use experimental 'signatures';";
plan skip_all => "signatures not supported" if $@;

use Mojolicious::Lite;
plugin 'loop';
get '/array' => {v => [qw(24 25 26)]}, 'index';

my $t = Test::Mojo->new;

$t->get_ok('/array')->content_is(<<'HERE');
key/val: 0/24
key/val: 1/25
key/val: 2/26
HERE

done_testing;

__DATA__
@@ index.html.ep
% use experimental 'signatures';
% loop $v, sub($v, $i) {
key/val: <%= $i %>/<%= $v %>
% }

