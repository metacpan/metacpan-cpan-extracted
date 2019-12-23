#!perl

use Test::More;
use lib '.', 't/';
use TestNvim;
use Neovim::Ext::Plugin::Host;

my $tester = TestNvim->new;
my $vim = $tester->start();

my $host = Neovim::Ext::Plugin::Host->new ($vim);

is scalar (keys %{$host->request_handlers}), 2;

is $vim->api->get_chan_info ($vim->channel_id)->{client}{type}, 'remote';
$host->_load();
is $vim->api->get_chan_info ($vim->channel_id)->{client}{type}, 'host';

done_testing();

