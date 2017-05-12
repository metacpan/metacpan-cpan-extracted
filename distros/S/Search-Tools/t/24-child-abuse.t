use strict;
use Search::Tools;
use Search::Tools::HiLiter;
use Test::More tests => 8;

use Data::Dump qw( dump );

ok( my $hiliter = Search::Tools::HiLiter->new(
        tag     => 'hilite',
        charset => 'iso-8859-1',
        query   => q("child abuse")
    ),
    "create new hiliter"
);

#dump( $hiliter->query );

my $child_abuse_buf = Search::Tools->slurp('t/docs/little-c-child-abuse.html');
my $Child_abuse_buf = Search::Tools->slurp('t/docs/big-C-Child-abuse.html');

ok( my $hilited_little_c = $hiliter->light($child_abuse_buf),
    "hilite little c" );
ok( my $hilited_big_C = $hiliter->light($Child_abuse_buf), "hilite big C" );

like( $hilited_little_c, qr/<hilite/, "matched little c" );
like( $hilited_big_C,    qr/<hilite/, "matched big C" );

ok( my $regex = $hiliter->query->regex_for(q(child abuse)), "get regex" );

like( $hilited_big_C, $regex->html,  "match HTML regex against big C" );
like( $hilited_big_C, $regex->plain, "match plain regex against big C" );
