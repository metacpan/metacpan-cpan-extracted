#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 2;

use SMS::API::QuickTelecom;

can_ok ( 'SMS::API::QuickTelecom', qw(balance) );

my $i = SMS::API::QuickTelecom->new( user => 'usertest', pass => 'userpass', test => 1 ) or die "Failed to create new object"; # unless defined $i;

my $b = $i->balance();

like ($b, '/Ошибка авторизации usertest/', 'got balance');

