use Mojo::Base -strict;
use Test::Mojo;
use Test::More;

use Mojolicious::Lite;
plugin 'loop';
get
  '/array' => {v => [qw(24 25 26)]},
  'index';


get
  '/hash' => {v => {x => 24, y => 25, z => 26}},
  'index';

get '/obj' => 'obj';

my $t = Test::Mojo->new;

$t->get_ok('/array')->status_is(200)->content_is(<<'HERE');

---
key/val: 0/24
count: 0 + 1 = 1 (index + 1)
size: 2 + 1 = 3 (max + 1)
prev: undef (peek -1)
next: 25 (peek +1)
parity: even
odd/even: even
first: yes
last: no

---
key/val: 1/25
count: 1 + 1 = 2 (index + 1)
size: 2 + 1 = 3 (max + 1)
prev: 24 (peek -1)
next: 26 (peek +1)
parity: odd
odd/even: odd
first: no
last: no

---
key/val: 2/26
count: 2 + 1 = 3 (index + 1)
size: 2 + 1 = 3 (max + 1)
prev: 25 (peek -1)
next: undef (peek +1)
parity: even
odd/even: even
first: no
last: yes
HERE

$t->get_ok('/hash')->status_is(200)->content_is(<<'HERE');

---
key/val: x/24
count: 0 + 1 = 1 (index + 1)
size: 2 + 1 = 3 (max + 1)
prev: undef (peek -1)
next: y (peek +1)
parity: even
odd/even: even
first: yes
last: no

---
key/val: y/25
count: 1 + 1 = 2 (index + 1)
size: 2 + 1 = 3 (max + 1)
prev: x (peek -1)
next: z (peek +1)
parity: odd
odd/even: odd
first: no
last: no

---
key/val: z/26
count: 2 + 1 = 3 (index + 1)
size: 2 + 1 = 3 (max + 1)
prev: y (peek -1)
next: undef (peek +1)
parity: even
odd/even: even
first: no
last: yes
HERE

$t->get_ok('/obj')->status_is(200)->content_like(qr{0=5\s*1=7\s*2=9}s);

done_testing;

__DATA__
@@ index.html.ep
%= loop $v, begin
---
key/val: <%= loop->key %>/<%= loop->val %>
count: <%= loop->index %> + 1 = <%= loop->count %> (index + 1)
size: <%= loop->max %> + 1 = <%= loop->size %> (max + 1)
prev: <%= loop->peek(-1) // 'undef' %> (peek -1)
next: <%= loop->peek(1) // 'undef' %> (peek +1)
parity: <%= loop->parity %>
odd/even: <%= loop->odd ? 'odd' : loop->even ? 'even' : 'unknown' %>
first: <%= loop->first ? 'yes' : 'no' %>
last: <%= loop->last ? 'yes' : 'no' %>
% end
@@ obj.html.ep
% my $i = loop [5,7,9];
% while ($i->next) {
%= join "=", $i->index, $i->val
% }
