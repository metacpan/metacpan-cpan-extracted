use t::App;
use Test::More;

plan skip_all => 'TEST_ONLINE=1 need to be set' unless $ENV{TEST_ONLINE};

$ENV{IX_ID} ||= 'hgz';

$t->get_ok("/embed?url=http://ix.io/$ENV{IX_ID}")->element_exists(qq(div.link-embedder.text-paste pre))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta a[href="http://ix.io"]))
  ->element_exists(qq(div.link-embedder.text-paste div.paste-meta a[href="http://ix.io/$ENV{IX_ID}"]));

my $pre = $t->tx->res->dom->at('pre')->to_string;

$pre =~ s!</?pre>!!g;
like $pre,   qr{&lt;}, 'escaped tags';
unlike $pre, qr{<\w},  'no tags';

done_testing;
