use t::App;
use Test::More;

plan skip_all => 'PASTIE_ID=10069272 need to be set' unless $ENV{PASTIE_ID};

$t->get_ok("/embed?url=http://pastie.org/$ENV{PASTIE_ID}/")->element_exists(qq(div.link-embedder.text-paste pre))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta a[href="http://pastie.org"]))
  ->element_exists(
  qq(div.link-embedder.text-paste div.paste-meta a[href="http://pastie.org/pastes/$ENV{PASTIE_ID}/text"]));

my $pre = $t->tx->res->dom->at('pre')->to_string;

$pre =~ s!</?pre>!!g;
like $pre,   qr{&lt;}, 'escaped tags';
unlike $pre, qr{<\w},  'no tags';

done_testing;
