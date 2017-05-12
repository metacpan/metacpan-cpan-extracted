use Test::More tests => 2;

use Template::Provider::Encode;
use Template;
my $tt = Template->new(
    LOAD_TEMPLATES => [Template::Provider::Encode->new({ie=>'shift_jis',oe=>'utf-8'})]
);
my $out;
my $author = "\xe3\x81\x9b\xe3\x81\x8d\xe3\x82\x80\xe3\x82\x89";
my $ok = $tt->process('t/tmpl/SJIS.tt2', {author => $author}, \$out);

diag $tt->error unless $ok;
ok($ok);
is($out, "ががせきむらがが\n");

