#!perl -T
use 5.10.0;
use strict;
use warnings;
use utf8;
use Test::More;

BEGIN {
  use_ok('Net::IPAM::Tree')  || print "Bail out!\n";
  use_ok('Net::IPAM::Block') || print "Bail out!\n";
}

my ( $t, @blocks, $str, $dups );
@blocks = map { Net::IPAM::Block->new($_) } qw(0.0.0.0/0 ::ffff:1.2.3.5 1.2.3.6 1.2.3.7/31 ::/0 fe80::1/10 ::cafe:affe);

ok($t = Net::IPAM::Tree->new(@blocks), "new");

$str = <<EOT;
▼
├─ 0.0.0.0/0
│  ├─ 1.2.3.5/32
│  └─ 1.2.3.6/31
│     └─ 1.2.3.6/32
└─ ::/0
   ├─ ::cafe:affe/128
   └─ fe80::/10
EOT

is( $t->to_string, $str, 'stringify' );
ok( $t->len == 7, 'len' );

### dups

@blocks = map { Net::IPAM::Block->new($_) } qw(::/0 1.2.3.4 ::/0);
ok( ($t, $dups) = Net::IPAM::Tree->new(@blocks) , 'new with dups');

$str = <<EOT;
▼
├─ 1.2.3.4/32
└─ ::/0
EOT

is( $t->to_string, $str, 'stringify with dups' );
is($dups->[0], "::/0", 'found the duplicate block');

### dups with warn
{
    my $msg;
    local $SIG{__WARN__} = sub { $msg = shift };
    $t = Net::IPAM::Tree->new(@blocks);
    like( $msg, qr/duplicate/, 'new with dups, check warnings');
}

done_testing();
