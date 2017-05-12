#!perl
use warnings;
use strict;
use Test::More;
use Data::Dumper;

use lib qw(t/lib);
use Mock::LWP::UserAgent;
use Net::Topsy;

plan tests => 2;
{
    my $nt   = Net::Topsy->new( key => 'foo' );
    my $r    = $nt->trending();
    isa_ok($r,'Net::Topsy::Result');

    my $iter = $r->iter;

    while ($iter->has_next) {
        my $item = $iter->next;
        ok($item,'got an item from the iterator');
    }
}
