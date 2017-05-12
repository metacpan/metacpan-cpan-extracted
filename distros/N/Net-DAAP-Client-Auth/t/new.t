#!perl
use strict;
use Test::More tests => 1;
use Net::DAAP::Client::Auth;

my $warning;
$SIG{__WARN__} = sub { $warning = shift };
my $client = Net::DAAP::Client::Auth->new( 'localhost' );
#diag $warning;
like $warning,
  qr{^Net::DAAP::Client::Auth->new deprecated in favour of Net::DAAP::Client->new at t/new\.t line},
  "carps about use";
