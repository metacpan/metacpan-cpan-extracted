use strict;
use warnings;
use Test::More tests => 5;
use Net::Drizzle;

my $dr = Net::Drizzle->new();
{
    my $con1 = $dr->con_create();
    isa_ok $con1, "Net::Drizzle::Connection";
    my $con2 = $con1->clone();
    isa_ok $con2, "Net::Drizzle::Connection";
}
ok 1, 'finished 1';

{
    my $con = Net::Drizzle::Connection->new;
    $con->set_revents(1);
    isa_ok $con, 'Net::Drizzle::Connection';
}
ok 2, 'finished 2';

