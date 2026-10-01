use strict;
use warnings;
use Test::More;
use File::Temp qw( tempdir );
use YAML::PP;

use Rex::Rancher::Server;

# patch_kubeconfig_server is pure; fetch_kubeconfig reads through
# get_kubeconfig (a fake here) and writes on this machine. Offline.

my $kc = <<'KC';
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tQ0EtLS0=
    server: https://127.0.0.1:6443
  name: default
contexts:
- context:
    cluster: default
    user: default
  name: default
current-context: default
kind: Config
preferences: {}
users:
- name: default
  user:
    client-certificate-data: LS0tQ0VSVC0tLQ==
    client-key-data: LS0tS0VZLS0t
KC

my $server_line = sub { $_[0] =~ /^\s*server: (\S+)$/m ? $1 : undef };

#### patch_kubeconfig_server

my $patched = patch_kubeconfig_server($kc, 'cp.example.com');
is($patched, $kc =~ s{https://127\.0\.0\.1:6443}{https://cp.example.com:6443}r,
  'host name: the server URL changes, nothing else');
like($patched, qr/^    certificate-authority-data: LS0tQ0EtLS0=$/m, 'the CA stays');
like($patched, qr/^    client-key-data: LS0tS0VZLS0t$/m, 'the client key stays');

is($server_line->(patch_kubeconfig_server($kc, '203.0.113.10')),
  'https://203.0.113.10:6443', 'IPv4 address');
is($server_line->(patch_kubeconfig_server($kc =~ s/:6443/:6444/r, 'cp')),
  'https://cp:6444', 'the port is kept');

is($server_line->(patch_kubeconfig_server($kc, '2001:db8::10')),
  'https://[2001:db8::10]:6443', 'IPv6 address: put in brackets');
is($server_line->(patch_kubeconfig_server($kc, '[2001:db8::10]')),
  'https://[2001:db8::10]:6443', 'IPv6 address already in brackets: taken as it is');
is($server_line->(patch_kubeconfig_server($kc, '::ffff:192.0.2.1')),
  'https://[::ffff:192.0.2.1]:6443', 'IPv4-mapped IPv6 address: in brackets');

# k3s/rke2 write [::1] when the (first) service CIDR is IPv6.
my $kc6 = $kc =~ s{127\.0\.0\.1}{[::1]}r;
is($server_line->(patch_kubeconfig_server($kc6, 'cp.example.com')),
  'https://cp.example.com:6443', 'IPv6 loopback [::1] is patched too');
is($server_line->(patch_kubeconfig_server($kc6, 'fd00::1')),
  'https://[fd00::1]:6443', 'IPv6 loopback to an IPv6 address');

for my $url (qw( https://10.0.0.5:6443 https://127.0.0.10:6443 https://localhost:6443 )) {
  my $other = $kc =~ s{https://127\.0\.0\.1:6443}{$url}r;
  is(patch_kubeconfig_server($other, 'cp'), $other, 'left alone: '.$url);
}

{
  package My::Server;
  use overload '""' => sub { $_[0]->{name} }, fallback => 1;
}
is($server_line->(patch_kubeconfig_server($kc, bless { name => 'node1.example.com' }, 'My::Server')),
  'https://node1.example.com:6443', 'a server object is taken by its string');

ok(!eval { patch_kubeconfig_server($kc); 1 }, 'no server: dies');
like($@, qr/^patch_kubeconfig_server: no server address given/, 'no server: says so');
ok(!eval { patch_kubeconfig_server($kc, ''); 1 }, 'empty server: dies');
ok(!eval { patch_kubeconfig_server(undef, 'cp'); 1 }, 'no kubeconfig: dies');
like($@, qr/^patch_kubeconfig_server: no kubeconfig given/, 'no kubeconfig: says so');

#### fetch_kubeconfig

my $dir = tempdir( CLEANUP => 1 );
our $remote_kc = $kc;
my ( @fetched, @log );
no warnings 'redefine';
local *Rex::Rancher::Server::get_kubeconfig = sub {
  push @fetched, $_[0];
  die "cat: /etc/rancher/k3s/k3s.yaml: No such file or directory\n" unless defined $remote_kc;
  $remote_kc;
};
local *Rex::Logger::info = sub { push @log, [ $_[1] // 'info', $_[0] ] };
use warnings 'redefine';

my $slurp = sub { open(my $fh, '<', $_[0]) or die $!; local $/; <$fh> };
my $mode  = sub { ( stat $_[0] )[2] & 07777 };

@fetched = ();
is(fetch_kubeconfig(server => 'cp.example.com'), $patched, 'returns the patched kubeconfig');
is_deeply(\@fetched, ['rke2'], 'rke2 by default');
@fetched = ();
fetch_kubeconfig(distribution => 'k3s', server => 'cp');
is_deeply(\@fetched, ['k3s'], 'k3s when asked');

is(fetch_kubeconfig(), $kc, 'no server: as the node wrote it');
is(fetch_kubeconfig(server => undef), $kc, 'server undef: as the node wrote it');
is(fetch_kubeconfig(server => ''), $kc, 'server empty: as the node wrote it');

@log = ();
fetch_kubeconfig(server => 'cp');
is_deeply([ grep { $_->[1] =~ /saved/ } @log ], [], 'no file: nothing written, nothing said');

# file: 0600 whatever the umask, also over an existing 0644 file.
for my $umask ( 022, 0 ) {
  my $file = $dir.'/umask-'.$umask.'.yaml';
  my $old = umask $umask;
  @log = ();
  my $got = fetch_kubeconfig(server => 'cp.example.com', file => $file);
  umask $old;
  is($mode->($file), 0600, sprintf('file: 0600 under umask %03o', $umask));
  is($slurp->($file), $got, 'file: holds what is returned');
  is_deeply(\@log, [ [ info => 'Kubeconfig saved to '.$file ] ], 'file: says where it went');
}
{
  my $file = $dir.'/existing.yaml';
  open(my $fh, '>', $file) or die $!;
  print $fh "old content that is longer than nothing\n" x 100;
  close $fh;
  chmod 0644, $file;
  fetch_kubeconfig(server => 'cp.example.com', file => $file);
  is($mode->($file), 0600, 'existing 0644 file: now 0600');
  is($slurp->($file), $patched, 'existing file: replaced, no old tail left');
}
SKIP: {
  my $target = $dir.'/target.yaml';
  my $link   = $dir.'/link.yaml';
  skip 'no symlinks here', 3 unless eval { symlink $target, $link };
  fetch_kubeconfig(server => 'cp', file => $link);
  ok(-l $link, 'symlinked file: the link stays a link');
  is($slurp->($target), $slurp->($link), 'symlinked file: the target is written');
  is($mode->($target), 0600, 'symlinked file: the target is 0600');
}

# filter: the caller's policy, applied between patch and write. This is the
# filter from fetch_kubeconfig's POD (CA out, insecure-skip-tls-verify in).
{
  my @seen;
  my $file = $dir.'/policy.yaml';
  my $got = fetch_kubeconfig(
    distribution => 'k3s',
    server       => '203.0.113.10',
    file         => $file,
    filter       => sub {
      my ( $kc ) = @_;
      push @seen, $kc;
      $kc =~ s/^[ \t]*certificate-authority-data:.*\n//mg;
      $kc =~ s/^([ \t]*)(server: https:\/\/\S+)\n/$1$2\n$1insecure-skip-tls-verify: true\n/mg;
      return $kc;
    },
  );
  is_deeply(\@seen, [ patch_kubeconfig_server($kc, '203.0.113.10') ],
    'filter: gets the patched kubeconfig, once');
  is($slurp->($file), $got, 'filter: its result is what is written');
  is($mode->($file), 0600, 'filter: still 0600');
  unlike($got, qr/certificate-authority-data/, 'filter: the CA is gone');
  my $doc = YAML::PP->new(boolean => 'JSON::PP')->load_string($got);
  my $cluster = $doc->{clusters}[0]{cluster};
  is_deeply([ sort keys %$cluster ], [ 'insecure-skip-tls-verify', 'server' ],
    'filter: valid YAML, insecure-skip-tls-verify next to the server');
  is($cluster->{server}, 'https://203.0.113.10:6443', 'filter: the patched server');
  ok(ref $cluster->{'insecure-skip-tls-verify'} eq 'JSON::PP::Boolean'
      && $cluster->{'insecure-skip-tls-verify'},
    'filter: insecure-skip-tls-verify is a YAML true');
  is($doc->{users}[0]{user}{'client-key-data'}, 'LS0tS0VZLS0t', 'filter: the client key stays');
}

for my $empty ( undef, '' ) {
  my $file = $dir.'/never.yaml';
  ok(!eval { fetch_kubeconfig(server => 'cp', file => $file, filter => sub { $empty }); 1 },
    'filter returns nothing: dies');
  like($@, qr/^fetch_kubeconfig: filter returned no kubeconfig, nothing was written\n\z/,
    'filter returns nothing: says so');
  ok(!-e $file, 'filter returns nothing: no file');
}

@fetched = ();
ok(!eval { fetch_kubeconfig(server => 'cp', filter => 'drop the CA'); 1 },
  'filter not code: dies');
like($@, qr/^fetch_kubeconfig: filter must be a code reference\n\z/, 'filter not code: says so');
is_deeply(\@fetched, [], 'filter not code: the host is not read');

ok(!eval { fetch_kubeconfig(distribution => 'k8s', server => 'cp'); 1 },
  'unknown distribution: dies');
like($@, qr/^Unknown distribution: k8s \(expected 'rke2' or 'k3s'\)/,
  'unknown distribution: the distribution message');
is_deeply(\@fetched, [], 'unknown distribution: the host is not read');

{
  local $remote_kc;
  ok(!eval { fetch_kubeconfig(distribution => 'k3s', server => 'cp'); 1 }, 'fetch fails: dies');
  is($@, "Could not fetch the kubeconfig from the k3s server "
    . "(cat: /etc/rancher/k3s/k3s.yaml: No such file or directory)\n",
    'fetch fails: names the distribution and the error');
}
{
  local $remote_kc = '';
  ok(!eval { fetch_kubeconfig(server => 'cp'); 1 }, 'empty kubeconfig: dies');
  is($@, "Could not fetch the kubeconfig from the rke2 server (empty file)\n",
    'empty kubeconfig: says so');
}
{
  my $bad = $dir.'/missing/dir/kc.yaml';
  ok(!eval { fetch_kubeconfig(server => 'cp', file => $bad); 1 }, 'write fails: dies');
  like($@, qr/^Could not write the kubeconfig to \Q$bad\E: \S.*\n\z/,
    'write fails: names the file and the error');
}

done_testing;
