use strict;
use warnings;
use Test::More;
use Mojo::SNMP;

my $snmp = Mojo::SNMP->new;
my (@response, @error, $timeout, $finish);

plan skip_all => 'Crypt::DES is required'   unless eval 'require Crypt::DES; 1';
plan skip_all => 'Digest::HMAC is required' unless eval 'require Digest::HMAC; 1';
plan skip_all => 'Digest::SHA1 is required' unless eval 'require Digest::SHA1; 1';

$snmp->concurrent(0);    # required to set up the queue
$snmp->defaults({timeout => 1, community => 'public', username => 'foo'});

$snmp->prepare('1.2.3.5', {version => 3}, get => ['1.3.6.1.2.1.1.5.0']);
ok $snmp->{sessions}{'1.2.3.5|v3||foo'}, '1.2.3.5 v3 foo';

$snmp->prepare('*', get_next => '1.2.3');

is $snmp->{_setup},     2, 'prepare was called twice (stupid test)';
is $snmp->{n_requests}, 0, 'and zero requests were prepared';

is_deeply(
  $snmp->{queue},
  {
    '1.2.3.5|v3||foo' => [
      ['1.2.3.5|v3||foo', 'get', ['1.3.6.1.2.1.1.5.0'], {version => 3}, undef],

      # *
      ['1.2.3.5|v3||foo', 'get_next', ['1.2.3'], {}, undef],
    ]
  },
  'queue is set up'
);

done_testing;
