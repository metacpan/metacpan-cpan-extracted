#!perl

use strict;
use warnings;
use Test::More tests => 3;
use Test::Trap qw/ :on_fail(diag_all) /;

use Monit::HTTP ':constants';

#my $hd = new Monit::HTTP(
#    hostname => 'localhost',
#    port => 'port',
#    username => 'admin',
#    password => 'monit',
#    use_auth => 1);

my $hd = Monit::HTTP->new(hostname=>'nonexistenthost');
{
my @r = trap { $hd->get_services() };
like( $trap->die, qr{Error while connecting to}, 'Die on none-existent host' );
}

$hd->set_hostname('localhost');
{
my @r = trap { $hd->get_services() };
like( $trap->die, qr{Error while connecting to}, 'Die on localhost' );
}

$hd->set_port(14566);
{
my @r = trap { $hd->get_services() };
like( $trap->die, qr{Error while connecting to}, 'Die on localhost with alt port' );
}
