use Mojo::Base -strict;
use Test::More;
use Test::Mojo;

use lib::relative 'lib';

our $TEST = __FILE__;
$TEST =~ s/(?>t\/)?(.+)\.t/$1/;

# Test suite variables
my $t;
my $tid = 0;
my $tc  = 0;

# trusted_sources as a string
$t = Test::Mojo->new('TestApp', {trustedproxy => {
  trusted_sources => '1.1.1.1',
}});

$tid++;
$tc++;
is $t->app->config->{trustedproxy}->{trusted_sources}->[0], '1.1.1.1';

# trusted_sources as an array
$t = Test::Mojo->new('TestApp', {trustedproxy => {
  trusted_sources => ['2.2.2.2'],
}});

$tid++;
$tc++;
is $t->app->config->{trustedproxy}->{trusted_sources}->[0], '2.2.2.2';

done_testing($tc);
