use Mojo::Base -strict;

use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Net::Prometheus;

my $prometheus = Net::Prometheus->new(disable_process_collector => 1, disable_perl_collector => 1);
$prometheus->new_counter(
	name   => "dummy",
	help   => "Dummy counter for testing purposes",
	labels => []
);
plugin Prometheus => { prometheus => $prometheus };

my $has_dummy = grep { /^dummy$/ } map { $_->fullname } app->prometheus->{registry}->collectors;
ok $has_dummy, 'custom prometheus instance used';

done_testing();
