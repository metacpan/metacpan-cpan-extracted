use Mojo::Base -strict;
use Test::More;

my $package = 'Mojolicious::Plugin::Log::Access';
use_ok $package;
my $version = "$Mojolicious::Plugin::Log::Access::VERSION";
diag "Testing $package $version, Perl $], $^X";

done_testing();
