use strict;
use warnings;
use Test::More;

use Rex::Rancher;

# _kubeconfig_server_addr is a pure function: it decides which address the
# saved kubeconfig's https://127.0.0.1 is patched to. Offline, connection-free.

is(
  Rex::Rancher::_kubeconfig_server_addr(
    kubeconfig_server => 'cp.example.com',
    tls_san           => 'ignored.example.com',
  ),
  'cp.example.com',
  'kubeconfig_server takes precedence over tls_san'
);

is(
  Rex::Rancher::_kubeconfig_server_addr(
    tls_san => ['first.example.com', 'second.example.com'],
  ),
  'first.example.com',
  'arrayref tls_san: first element wins'
);

is(
  Rex::Rancher::_kubeconfig_server_addr(
    tls_san => 'first.example.com,second.example.com',
  ),
  'first.example.com',
  'comma-separated string tls_san: first element wins'
);

is(
  Rex::Rancher::_kubeconfig_server_addr(
    tls_san => 'only.example.com',
  ),
  'only.example.com',
  'single-string tls_san: the string itself wins'
);

my $none = Rex::Rancher::_kubeconfig_server_addr();
ok(!defined $none || !length $none,
  'neither kubeconfig_server nor tls_san: returns undef/empty');

done_testing;
