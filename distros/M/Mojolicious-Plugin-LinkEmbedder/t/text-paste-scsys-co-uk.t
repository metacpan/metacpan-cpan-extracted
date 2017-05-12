use t::App;
use Test::More;

plan skip_all => 'PASTE_SCSYS_ID=470943 need to be set' unless $ENV{PASTE_SCSYS_ID};

$t->get_ok("/embed?url=http://paste.scsys.co.uk/$ENV{PASTE_SCSYS_ID}")
  ->element_exists(qq(div.link-embedder.text-paste pre))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta a[href="http://paste.scsys.co.uk"]))
  ->element_exists(
  qq(div.link-embedder.text-paste div.paste-meta a[href="http://paste.scsys.co.uk/$ENV{PASTE_SCSYS_ID}?tx=on"]))
  ->element_exists_not('script')->text_like('pre', qr{asdasd});

my $pre = $t->tx->res->dom->at('pre')->to_string;

$pre =~ s!</?pre>!!g;
like $pre,   qr{&lt;}, 'escaped tags';
unlike $pre, qr{<\w},  'no tags';

done_testing;
