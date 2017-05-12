use Mojo::Base -strict;
use Test::More;

my $package = 'Mojolicious::Plugin::Log::Timestamp';
use_ok $package;
my $version = "$Mojolicious::Plugin::Log::Timestamp::VERSION";
diag "Testing $package $version, Perl $], $^X";

done_testing();
