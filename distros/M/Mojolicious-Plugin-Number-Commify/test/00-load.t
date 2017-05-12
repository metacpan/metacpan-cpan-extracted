use Mojo::Base -strict;
use Test::More;

my $package = 'Mojolicious::Plugin::Number::Commify';
use_ok $package;
my $version = "$Mojolicious::Plugin::Number::Commify::VERSION";
diag "Testing $package $version, Perl $], $^X";

done_testing();
