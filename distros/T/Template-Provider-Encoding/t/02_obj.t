use strict;
use Test::More;

eval { require DateTime; 1 };
if ($@) {
    plan skip_all => 'require DateTime';
}

use Template;
use Template::Stash::ForceUTF8;

if ($Template::Config::STASH ne 'Template::Stash::XS') {
    plan skip_all => 'require Template::Stash::XS';
}

plan tests => 1;

my $tt = Template->new({
    STASH => Template::Stash::ForceUTF8->new,
});

my $dt = DateTime->new(year => 2005, month => 9, day => 12);
$tt->process(\<<EOF, { dt => $dt }, \my $out) or die $tt->error;
[% dt.ymd %]
EOF

like $out, qr/2005-09-12/;

