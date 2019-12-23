#!perl

use lib '.', 't/';
use File::Spec::Functions qw/rel2abs/;
use Test::More;
use TestNvim;
use Neovim::Ext;

my $tester = TestNvim->new;
my $vim = $tester->start();
my $host = Neovim::Ext::Plugin::Host->new ($vim);

is scalar (keys %{$host->request_handlers}), 2;
is scalar (keys %{$host->notification_handlers}), 1;

$host->_load (rel2abs ('t/rplugin/perl/TestPlugin.pm'));
$host->_load (rel2abs ('t/rplugin/perl/BrokenPlugin.pm'));
is scalar (keys %{$host->request_handlers}), 5;
is scalar (keys %{$host->notification_handlers}), 3;

$host->_unload;
is scalar (keys %{$host->request_handlers}), 2;
is scalar (keys %{$host->notification_handlers}), 1;

done_testing();

