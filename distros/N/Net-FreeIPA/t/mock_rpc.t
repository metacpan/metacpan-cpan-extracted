use strict;
use warnings;

use File::Basename;
use Test::More;

BEGIN {
    push(@INC, dirname(__FILE__));
}

use Test::MockModule;

use Net::FreeIPA;
use mock_rpc qw(example);

=head2 import

=cut

is(scalar keys %mock_rpc::cmds, 8, "imported example data");

=head2 Test the mock_rpc test module

=cut

my $f = Net::FreeIPA->new("hostname.domain");
isa_ok($f->{rc}, 'REST::Client', 'rc is a mocked REST::Client');
is($f->{rc}->{opts}->{host}, 'https://hostname.domain',
   'REST::Client host arg in opts attribute');
is($f->{rc}->{opts}->{ca}, '/etc/ipa/ca.crt',
   'REST::Client ca arg in opts attribute');
isa_ok($f->{rc}->{opts}->{useragent}, 'LWP::UserAgent',
       'REST::Client useragent arg in opts attribute');

$f->{id} = 0;
is($f->get_api_version(), '0.1.2', 'mocked env api_version found with id=0');

my @hist = find_POST_history(''); # empty string matches everything
diag "whole history ", explain \@hist;
is_deeply(\@hist, [
    '0 NOMETHOD  ', # login
    '0 env api_version version=2.230',
], "POST history: one non-method call from login, one call to get the api_version");

ok(POST_history_ok(['NOMETHOD', 'env api_version']), "call history ok");
# Tests the order
ok(! POST_history_ok(['env api_version', 'NOMETHOD']), "login/NOMETHOD not called after env");

# Test not_commands
ok(! POST_history_ok(['env api_version'], ['NOMETHOD']), "NOMETHOD not_command found");


reset_POST_history;

$f->{id} = 1;
is($f->get_api_version(), '1.1.2', 'mocked env api_version found with id=1');

@hist = find_POST_history('');
diag "whole after reset history ", explain \@hist;
is_deeply(\@hist, [
    '1 env api_version version=2.230',
], "POST history after reset: one call to get the api_version with id=1 (no new login)");

$f->{id} = 2;
is($f->get_api_version(), '2.1.3', 'mocked env api_version found with id=2, specified params precedes');

$f->{id} = 3;
is($f->get_api_version(), '3.1.3', 'mocked env api_version found with id=3, specified params precedes and is regex');

$f->{id} = 4;
is($f->get_api_version(), '4.1.3', 'mocked env api_version found with id=4, specified options precedes and is regex');

done_testing();
