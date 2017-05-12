use Modern::Perl;
use Test::More;
use Module::Find;

my $module = 'Mojolicious::Plugin::Mango';
use_ok($_) foreach findallmod $module;
use_ok($module);
done_testing;

