use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit tests for the deb822 non-free rewrite (karr #36).
#
# Debian 13 and Debian's cloud images keep their archive in
# /etc/apt/sources.list.d/debian.sources (deb822, "Components:" field), not in
# /etc/apt/sources.list. _deb822_enable_nonfree($content) is pure (string in,
# string out), so the edit install_driver writes back is unit-testable offline.
# Claims asserted:
#   * a Debian archive stanza gets exactly the missing ones of contrib,
#     non-free, non-free-firmware appended to its Components: line;
#   * a second pass changes nothing (idempotent);
#   * every other line -- comments, other fields, third-party stanzas -- is
#     kept byte for byte;
#   * a stanza is only edited when it is a Debian archive: Types has deb,
#     Components has main, Enabled is not no, and either Signed-By names only
#     debian-archive keyrings (any URI -- a company mirror or apt-cacher-ng,
#     karr #41) or there is no Signed-By and every URI is Debian's
#     (*.debian.org, Hetzner's /debian/ mirror, the cloud-image mirror+file
#     list);
#   * a subclass overriding is_debian_archive_uri makes its mirror a Debian
#     archive, and still leaves a stanza with a foreign Signed-By alone.
#
# NOT covered (needs a real Debian 13 host):
#   * that apt accepts the written file and `apt-cache policy nvidia-driver`
#     then shows a candidate;
#   * the `ls`/`cat`/`file` round trip over Rex::LibSSH (the command sequence
#     is pinned in t/golden/driver/debian-13--*.txt, not executed).
# -----------------------------------------------------------------------------

use Rex::GPU::NVIDIA;
use Rex::GPU::NVIDIA::Setup::Debian;

sub rewrite { [ Rex::GPU::NVIDIA::Setup::Debian->_deb822_enable_nonfree($_[0]) ] }

my $KEY = 'Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp';

# What the trixie installer writes (run "cat" chomps the last newline).
my $TRIXIE = <<"SRC";
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main non-free-firmware
$KEY

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main non-free-firmware
$KEY
SRC
chomp(my $trixie_chomped = $TRIXIE);

(my $TRIXIE_WANT = $TRIXIE) =~ s/^Components: main non-free-firmware$/Components: main non-free-firmware contrib non-free/mg;

subtest 'trixie installer debian.sources: both stanzas, security included' => sub {
  my ($new, $matched) = @{ rewrite($trixie_chomped) };
  is($matched, 2, 'two Debian archive stanzas recognised');
  is($new, $TRIXIE_WANT, 'contrib non-free appended, non-free-firmware not repeated, final newline restored');
  is_deeply(rewrite($new), [ undef, 2 ], 'second pass: unchanged, still recognised');
};

subtest 'already fully enabled: no rewrite' => sub {
  my $src = "Types: deb\nURIs: https://deb.debian.org/debian\nSuites: trixie\n"
    . "Components: main contrib non-free non-free-firmware\n$KEY\n";
  is_deeply(rewrite($src), [ undef, 1 ], 'undef, one stanza recognised');
  my $partial = "Types: deb\nURIs: https://deb.debian.org/debian\nSuites: trixie\n"
    . "Components: non-free main\n";
  is(rewrite($partial)->[0],
    "Types: deb\nURIs: https://deb.debian.org/debian\nSuites: trixie\n"
    . "Components: non-free main contrib non-free-firmware\n",
    'only the missing components are added, existing order kept');
};

subtest 'Debian cloud image (mirror+file, deb deb-src, no Signed-By)' => sub {
  my $src = "Types: deb deb-src\nURIs: mirror+file:///etc/apt/mirrors/debian.list\n"
    . "Suites: trixie trixie-updates trixie-backports\nComponents: main\n\n"
    . "Types: deb deb-src\nURIs: mirror+file:///etc/apt/mirrors/debian-security.list\n"
    . "Suites: trixie-security\nComponents: main\n";
  (my $want = $src) =~ s/^Components: main$/Components: main contrib non-free non-free-firmware/mg;
  is_deeply(rewrite($src), [ $want, 2 ], 'both stanzas edited');
};

subtest 'Hetzner mirror and other *.debian.org hosts' => sub {
  for my $uri (qw(
    http://mirror.hetzner.com/debian/packages
    https://mirror.hetzner.de/debian/security
    http://ftp.de.debian.org/debian
    tor+http://deb.debian.org/debian
  )) {
    my $src = "Types: deb\nURIs: $uri\nSuites: trixie\nComponents: main\n";
    is(rewrite($src)->[1], 1, "$uri is a Debian archive");
  }
};

subtest 'comments and multiple stanzas are kept byte for byte' => sub {
  my $src = "# Managed by installimage\n#\n"
    . "Types: deb\n# a comment inside the stanza\nURIs: http://deb.debian.org/debian\n"
    . "Suites: trixie\nComponents: main   \nSigned-By: /usr/share/keyrings/debian-archive-keyring.gpg\n"
    . "\n\n"
    . "# disabled backports\nEnabled: no\nTypes: deb\nURIs: http://deb.debian.org/debian\n"
    . "Suites: trixie-backports\nComponents: main\n";
  my $want = $src;
  $want =~ s/^Components: main   $/Components: main contrib non-free non-free-firmware/m;
  my ($new, $matched) = @{ rewrite($src) };
  is($matched, 1, 'Enabled: no stanza not counted');
  is($new, $want, 'only the enabled stanza\'s Components line changed');
};

subtest 'multi-line Components field: appended to its last line' => sub {
  my $src = "Types: deb\nURIs: http://deb.debian.org/debian\nSuites: trixie\n"
    . "Components: main\n non-free-firmware\n$KEY\n";
  is(rewrite($src)->[0],
    "Types: deb\nURIs: http://deb.debian.org/debian\nSuites: trixie\n"
    . "Components: main\n non-free-firmware contrib non-free\n$KEY\n",
    'continuation line extended');
};

subtest 'third-party and non-matching stanzas are left alone' => sub {
  my %case = (
    'NVIDIA repo, own key' =>
      "Types: deb\nURIs: https://developer.download.nvidia.com/compute/cuda/repos/debian13/x86_64/\n"
      . "Suites: /\nSigned-By: /usr/share/keyrings/cuda-archive-keyring.gpg\n",
    'third party with main, bookworm suite' =>
      "Types: deb\nURIs: https://packages.microsoft.com/debian/12/prod\nSuites: bookworm\n"
      . "Components: main\nSigned-By: /usr/share/keyrings/microsoft.gpg\n",
    'third party with main, no Signed-By' =>
      "Types: deb\nURIs: https://apt.releases.hashicorp.com\nSuites: trixie\nComponents: main\n",
    'Debian URI but foreign key' =>
      "Types: deb\nURIs: http://deb.debian.org/debian\nSuites: trixie\nComponents: main\n"
      . "Signed-By: /etc/apt/keyrings/other.gpg\n",
    'Debian URI, inline key block' =>
      "Types: deb\nURIs: http://deb.debian.org/debian\nSuites: trixie\nComponents: main\n"
      . "Signed-By:\n -----BEGIN PGP PUBLIC KEY BLOCK-----\n .\n -----END PGP PUBLIC KEY BLOCK-----\n",
    'mixed Debian and foreign URIs' =>
      "Types: deb\nURIs: http://deb.debian.org/debian https://example.com/debian\n"
      . "Suites: trixie\nComponents: main\n",
    'Hetzner host outside /debian/' =>
      "Types: deb\nURIs: http://mirror.hetzner.com/ubuntu/packages\nSuites: noble\nComponents: main\n",
    'lookalike host' =>
      "Types: deb\nURIs: http://deb.debian.org.example.com/debian\nSuites: trixie\nComponents: main\n",
    'Docker (Debian path, no main)' =>
      "Types: deb\nURIs: https://download.docker.com/linux/debian\nSuites: trixie\nComponents: stable\n",
    'deb-src only' =>
      "Types: deb-src\nURIs: http://deb.debian.org/debian\nSuites: trixie\nComponents: main\n",
    'no URIs' =>
      "Types: deb\nSuites: trixie\nComponents: main\n"
  );
  for my $name (sort keys %case) {
    is_deeply(rewrite($case{$name}), [ undef, 0 ], $name);
  }

  my $mixed = $TRIXIE . "\n" . $case{'third party with main, bookworm suite'};
  my ($new, $matched) = @{ rewrite($mixed) };
  is($matched, 2, 'Debian + third party in one file: two recognised');
  is($new, $TRIXIE_WANT . "\n" . $case{'third party with main, bookworm suite'},
    'only the Debian stanzas edited');
};

subtest 'empty input' => sub {
  is_deeply(rewrite(''), [ undef, 0 ], 'empty string');
  is_deeply(rewrite(undef), [ undef, 0 ], 'undef');
};

#### karr #41: mirrors of your own ###########################################

subtest 'Signed-By with only Debian archive keyrings: any URI is Debian' => sub {
  for my $uri (qw(
    http://apt-cache.corp.example:3142/debian
    http://mirror.corp.example/debian
    http://ftp.fau.de/debian
  )) {
    my $src = "Types: deb\nURIs: $uri\nSuites: trixie\nComponents: main\n$KEY\n";
    is_deeply(rewrite($src), [
      "Types: deb\nURIs: $uri\nSuites: trixie\nComponents: main contrib non-free non-free-firmware\n$KEY\n", 1
    ], "$uri with the Debian keyring");
  }
};

my %OWN = (
  'apt-cacher-ng, no Signed-By' =>
    "Types: deb\nURIs: http://apt-cache.corp.example:3142/debian\nSuites: trixie\nComponents: main\n",
  'company mirror, no Signed-By' =>
    "Types: deb\nURIs: http://mirror.corp.example/debian\nSuites: trixie\nComponents: main\n",
  'company mirror, own keyring' =>
    "Types: deb\nURIs: http://apt-cache.corp.example:3142/debian\nSuites: trixie\nComponents: main\n"
    . "Signed-By: /etc/apt/keyrings/corp.gpg\n",
  'company mirror, Debian and own keyring' =>
    "Types: deb\nURIs: http://apt-cache.corp.example:3142/debian\nSuites: trixie\nComponents: main\n"
    . "Signed-By: /usr/share/keyrings/debian-archive-keyring.pgp /etc/apt/keyrings/corp.gpg\n",
  'company mirror, inline key' =>
    "Types: deb\nURIs: http://apt-cache.corp.example:3142/debian\nSuites: trixie\nComponents: main\n"
    . "Signed-By:\n -----BEGIN PGP PUBLIC KEY BLOCK-----\n .\n -----END PGP PUBLIC KEY BLOCK-----\n"
);

subtest 'unknown mirror without Debian Signed-By is left alone' => sub {
  for my $name (sort keys %OWN) {
    is_deeply(rewrite($OWN{$name}), [ undef, 0 ], $name);
  }
};

{
  package Test::Deb822Mirror;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Debian';
  sub is_debian_archive_uri {
    my ( $self, $uri ) = @_;
    return 1 if $uri =~ m{^http://apt-cache\.corp\.example:3142/debian/?$};
    return $self->SUPER::is_debian_archive_uri($uri);
  }
}

subtest 'override is_debian_archive_uri' => sub {
  my $as = sub { [ Test::Deb822Mirror->_deb822_enable_nonfree($_[0]) ] };
  (my $want = $OWN{'apt-cacher-ng, no Signed-By'})
    =~ s/^Components: main$/Components: main contrib non-free non-free-firmware/m;
  is_deeply($as->($OWN{'apt-cacher-ng, no Signed-By'}), [ $want, 1 ], 'apt-cacher-ng recognised and edited');
  for my $name ('company mirror, own keyring', 'company mirror, Debian and own keyring', 'company mirror, inline key') {
    is_deeply($as->($OWN{$name}), [ undef, 0 ], "$name: a foreign Signed-By still wins");
  }
  is_deeply($as->("Types: deb\nURIs: https://apt.releases.hashicorp.com\nSuites: trixie\nComponents: main\n"),
    [ undef, 0 ], 'third party elsewhere still untouched');
  is_deeply($as->($trixie_chomped)->[1], 2, 'built-in list kept via SUPER');
};

done_testing;
