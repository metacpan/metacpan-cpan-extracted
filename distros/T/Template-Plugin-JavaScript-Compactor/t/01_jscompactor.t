use strict;
use Test::More tests => 2;
use Template;

my $tt = Template->new;
my $js =<<EOF;
document.writeln('Hello, World!');
function foobar () {
  alert('hoge');
}
EOF

$tt->process(\<<EOF, {}, \my $out) or die $tt->error;
[% USE JavaScript::Compactor -%]
[% FILTER jscompactor -%]
$js
[%- END %]
EOF

like $out, qr/^document.writeln\('Hello, World!'\);function foobar\(\){alert\('hoge'\);}$/, $out;
ok(length $out < length $js);
