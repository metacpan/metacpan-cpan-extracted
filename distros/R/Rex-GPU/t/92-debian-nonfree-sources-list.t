use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Unit tests for the classic /etc/apt/sources.list non-free rewrite (karr #40).
#
# The Debian 12 installer writes "deb ... bookworm main non-free-firmware".
# The check this replaces skipped the whole file when it matched /non-free/,
# and non-free-firmware matched, so non-free was never enabled and Debian's
# nvidia-driver had no candidate. _sources_list_enable_nonfree($content) is
# pure (string in, string out), like _deb822_enable_nonfree (t/91).
# Claims asserted:
#   * a Debian archive "deb" line gets exactly the missing ones of contrib,
#     non-free, non-free-firmware appended after its last component;
#   * a second pass changes nothing (idempotent);
#   * every other line -- comments, commented-out deb lines, deb-src,
#     third-party entries -- is kept byte for byte, and an edited line keeps
#     its [options] and trailing # comment;
#   * a line is only edited when it is a Debian archive: components include
#     main, and either signed-by= names only debian-archive keyrings (any
#     URI: a company mirror or apt-cacher-ng signed with Debian's key, karr
#     #41), or there is no signed-by= and the URI is Debian's (same rules as
#     deb822);
#   * is_debian_archive_uri / is_debian_archive_keyring are the override
#     points: the eg/custom-setup class My::GPU::DebianMirror makes its
#     mirror a Debian archive, and an override never turns an entry with a
#     foreign signed-by= into one;
#   * the warning for "nothing recognised" names is_debian_archive_uri and
#     eg/custom-setup;
#   * a line the old sed handled ("deb URL suite main") ends up with the same
#     text the sed produced.
#
# NOT covered (needs a real Debian 12 host):
#   * that apt accepts the written file and `apt-cache policy nvidia-driver`
#     then shows a candidate;
#   * the `cat`/`file` round trip over Rex::LibSSH (the command sequence is
#     pinned in t/golden/driver/debian-12--*.txt, not executed).
# -----------------------------------------------------------------------------

use FindBin qw( $Bin );
use lib "$Bin/../eg/custom-setup/lib";   # My::GPU::DebianMirror

use Rex::GPU::NVIDIA;
use My::GPU::DebianMirror;

sub rewrite { [ Rex::GPU::NVIDIA::_sources_list_enable_nonfree($_[0]) ] }

my $ALL = 'contrib non-free non-free-firmware';

# What the bookworm installer writes (netinst, network mirror), cat-chomped.
my $BOOKWORM = <<'SRC';
#deb cdrom:[Debian GNU/Linux 12.11.0 _Bookworm_ - Official amd64 NETINST with firmware 20250517-09:51]/ bookworm contrib main non-free-firmware

deb http://deb.debian.org/debian/ bookworm main non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm main non-free-firmware

deb http://security.debian.org/debian-security bookworm-security main non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main non-free-firmware

# bookworm-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
deb http://deb.debian.org/debian/ bookworm-updates main non-free-firmware
deb-src http://deb.debian.org/debian/ bookworm-updates main non-free-firmware
SRC
chomp(my $bookworm_chomped = $BOOKWORM);

(my $BOOKWORM_WANT = $BOOKWORM)
  =~ s/^(deb http\S+ \S+ main non-free-firmware)$/$1 contrib non-free/mg;

subtest 'bookworm installer default: non-free-firmware is not non-free' => sub {
  my ($new, $matched) = @{ rewrite($bookworm_chomped) };
  is($matched, 3, 'three deb lines recognised, deb-src and cdrom comment not');
  is($new, $BOOKWORM_WANT,
    'contrib non-free appended to the deb lines only, final newline restored');
  like($new, qr/^deb http:\/\/security\.debian\.org\/debian-security bookworm-security main non-free-firmware contrib non-free$/m,
    'security line edited');
  is_deeply(rewrite($new), [ undef, 3 ], 'second pass: unchanged, still recognised');
};

subtest 'already fully enabled: no rewrite' => sub {
  my $src = "deb http://deb.debian.org/debian bookworm main $ALL\n"
    . "deb http://security.debian.org/debian-security bookworm-security main $ALL";
  is_deeply(rewrite($src), [ undef, 2 ], 'undef, two lines recognised');
  is(rewrite("deb http://deb.debian.org/debian bookworm non-free main\n")->[0],
    "deb http://deb.debian.org/debian bookworm non-free main contrib non-free-firmware\n",
    'only the missing components are added, existing order kept');
};

subtest 'bullseye main only: same text as the old sed' => sub {
  my @lines = (
    'deb http://deb.debian.org/debian bullseye main',
    'deb http://deb.debian.org/debian bullseye-updates main',
    'deb http://security.debian.org/debian-security bullseye-security main'
  );
  my $src = join("\n", @lines)."\n";
  (my $sed = $src) =~ s/^deb (.*) main/deb $1 main contrib non-free non-free-firmware/mg;
  is_deeply(rewrite($src), [ $sed, 3 ], 'identical to s/^deb \(.*\) main/.../');
  is_deeply(rewrite($sed), [ undef, 3 ], 'idempotent');
};

subtest 'partial components: no duplicate' => sub {
  is(rewrite("deb http://deb.debian.org/debian bookworm main contrib\n")->[0],
    "deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware\n",
    'contrib not repeated (the old sed would have produced main contrib non-free non-free-firmware contrib)');
};

subtest 'options in brackets, spacing and trailing comments kept' => sub {
  my %case = (
    'signed-by debian-archive keyring' => [
      'deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] http://deb.debian.org/debian bookworm main',
      'deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg] http://deb.debian.org/debian bookworm main '.$ALL
    ],
    'arch option with spaces inside brackets' => [
      'deb [ arch=amd64,arm64 ] http://deb.debian.org/debian bookworm main non-free-firmware',
      'deb [ arch=amd64,arm64 ] http://deb.debian.org/debian bookworm main non-free-firmware contrib non-free'
    ],
    'tabs and trailing comment' => [
      "deb\thttp://mirror.hetzner.com/debian/packages\tbookworm\tmain   # Hetzner",
      "deb\thttp://mirror.hetzner.com/debian/packages\tbookworm\tmain $ALL   # Hetzner"
    ],
    'CRLF line ending' => [
      "deb http://deb.debian.org/debian bookworm main\r",
      "deb http://deb.debian.org/debian bookworm main $ALL\r"
    ],
    'cloud image mirror+file' => [
      'deb mirror+file:/etc/apt/mirrors/debian.list bookworm main',
      'deb mirror+file:/etc/apt/mirrors/debian.list bookworm main '.$ALL
    ]
  );
  for my $name (sort keys %case) {
    my ($in, $want) = @{ $case{$name} };
    is_deeply(rewrite("$in\n"), [ "$want\n", 1 ], $name);
  }
};

subtest 'third-party, commented, deb-src and non-matching lines are left alone' => sub {
  my %case = (
    'third party with main' =>
      'deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bookworm main',
    'third party with main, no options' =>
      'deb https://packages.microsoft.com/debian/12/prod bookworm main',
    'Docker (Debian path, no main)' =>
      'deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian bookworm stable',
    'NVIDIA flat repo' =>
      'deb [signed-by=/usr/share/keyrings/cuda-archive-keyring.gpg] https://developer.download.nvidia.com/compute/cuda/repos/debian12/x86_64/ /',
    'Debian URI but foreign key' =>
      'deb [signed-by=/etc/apt/keyrings/other.gpg] http://deb.debian.org/debian bookworm main',
    'Debian URI, one of two keys foreign' =>
      'deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg,/etc/apt/keyrings/other.gpg] http://deb.debian.org/debian bookworm main',
    'lookalike host' =>
      'deb http://deb.debian.org.example.com/debian bookworm main',
    'Hetzner host outside /debian/' =>
      'deb http://mirror.hetzner.com/ubuntu/packages noble main',
    'unknown Debian mirror' =>
      'deb http://ftp.fau.de/debian bookworm main',
    'commented out' =>
      '# deb http://deb.debian.org/debian bookworm main',
    'commented out, no space' =>
      '#deb http://deb.debian.org/debian bookworm main',
    'deb-src' =>
      'deb-src http://deb.debian.org/debian bookworm main',
    'cdrom' =>
      'deb cdrom:[Debian GNU/Linux 12.11.0 _Bookworm_]/ bookworm main non-free-firmware',
    'main only in a comment' =>
      'deb http://deb.debian.org/debian bookworm # main'
  );
  for my $name (sort keys %case) {
    is_deeply(rewrite("$case{$name}\n"), [ undef, 0 ], $name);
  }

  my $mixed = $BOOKWORM . $case{'third party with main'} . "\n";
  my ($new, $matched) = @{ rewrite($mixed) };
  is($matched, 3, 'Debian + third party in one file: three recognised');
  is($new, $BOOKWORM_WANT . $case{'third party with main'} . "\n",
    'only the Debian deb lines edited');
};

subtest 'empty and comment-only input' => sub {
  is_deeply(rewrite(''), [ undef, 0 ], 'empty string');
  is_deeply(rewrite(undef), [ undef, 0 ], 'undef');
  is_deeply(rewrite("# See sources.list(5) and debian.sources\n"), [ undef, 0 ],
    'comment-only file (deb822 host)');
};

#### karr #41: mirrors of your own ###########################################

my $DEBKEY = 'signed-by=/usr/share/keyrings/debian-archive-keyring.gpg';

sub rewrite_as {
  my ( $class, $content ) = @_;
  return [ $class->_sources_list_enable_nonfree($content) ];
}

subtest 'signed-by with only Debian archive keyrings: any URI is Debian' => sub {
  my %case = (
    'company mirror' =>
      "deb [$DEBKEY] http://mirror.corp.example/debian bookworm main",
    'apt-cacher-ng' =>
      "deb [$DEBKEY] http://apt-cache.corp.example:3142/debian bookworm main non-free-firmware",
    'unknown national mirror, removed-keys keyring too' =>
      'deb [signed-by=/usr/share/keyrings/debian-archive-keyring.gpg,/usr/share/keyrings/debian-archive-removed-keys.gpg] http://ftp.fau.de/debian bookworm main'
  );
  for my $name (sort keys %case) {
    my $in = $case{$name};
    my ($new, $matched) = @{ rewrite("$in\n") };
    is($matched, 1, "$name: recognised");
    like($new, qr/^\Q$in\E(?: contrib)? non-free(?: non-free-firmware)?\n\z/, "$name: non-free added");
    is_deeply(rewrite($new), [ undef, 1 ], "$name: idempotent");
  }
};

subtest 'without signed-by an unknown mirror stays unrecognised' => sub {
  for my $line (
    'deb http://apt-cache.corp.example:3142/debian bookworm main',
    'deb http://mirror.corp.example/debian bookworm main',
    'deb http://acng.lan:3142/deb.debian.org/debian bookworm main'
  ) {
    is_deeply(rewrite("$line\n"), [ undef, 0 ], $line);
  }
  is(rewrite("deb http://ftp.de.debian.org/debian bookworm main\n")->[0],
    "deb http://ftp.de.debian.org/debian bookworm main $ALL\n",
    'ftp.de.debian.org is *.debian.org: edited without override');
};

subtest 'foreign signed-by stays third party, even on a Debian URI' => sub {
  for my $line (
    'deb [signed-by=/etc/apt/keyrings/corp.gpg] http://mirror.corp.example/debian bookworm main',
    "deb [$DEBKEY,/etc/apt/keyrings/corp.gpg] http://mirror.corp.example/debian bookworm main",
    'deb [signed-by=/usr/share/keyrings/debian-ports-archive-keyring.gpg] http://mirror.corp.example/debian-ports sid main',
    'deb [signed-by=/tmp/debian-archive-keyring.gpg] http://mirror.corp.example/debian bookworm main',
    'deb [signed-by=] http://deb.debian.org/debian bookworm main'
  ) {
    is_deeply(rewrite("$line\n"), [ undef, 0 ], $line);
  }
};

subtest 'override is_debian_archive_uri (eg/custom-setup My::GPU::DebianMirror)' => sub {
  my $C = 'My::GPU::DebianMirror';
  ok($C->is_debian_archive_uri('http://apt-cache.corp.example:3142/debian'), 'the mirror');
  ok($C->is_debian_archive_uri('http://deb.debian.org/debian'), 'built-in list kept via SUPER');
  ok(!$C->is_debian_archive_uri('http://apt-cache.corp.example:3142/ubuntu'), 'not the mirror host\'s other paths');

  my $src = "deb http://apt-cache.corp.example:3142/debian bookworm main\n"
    . "deb http://apt-cache.corp.example:3142/debian-security bookworm-security main\n"
    . "deb https://packages.microsoft.com/debian/12/prod bookworm main\n"
    . "deb [signed-by=/etc/apt/keyrings/corp.gpg] http://apt-cache.corp.example:3142/debian bookworm main\n";
  is_deeply(rewrite_as($C, $src), [
    "deb http://apt-cache.corp.example:3142/debian bookworm main $ALL\n"
    . "deb http://apt-cache.corp.example:3142/debian-security bookworm-security main $ALL\n"
    . "deb https://packages.microsoft.com/debian/12/prod bookworm main\n"
    . "deb [signed-by=/etc/apt/keyrings/corp.gpg] http://apt-cache.corp.example:3142/debian bookworm main\n",
    2
  ], 'mirror lines edited; third party and the foreign-key line on the mirror URI untouched');
  is_deeply(rewrite("deb http://apt-cache.corp.example:3142/debian bookworm main\n"), [ undef, 0 ],
    'the base class is unchanged');
};

{
  package Test::KeyMirror;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Debian';
  sub is_debian_archive_keyring {
    my ( $self, $path ) = @_;
    return 1 if $path eq '/etc/apt/keyrings/corp-mirror.gpg';
    return $self->SUPER::is_debian_archive_keyring($path);
  }
}

subtest 'override is_debian_archive_keyring: a re-signed mirror' => sub {
  my $line = 'deb [signed-by=/etc/apt/keyrings/corp-mirror.gpg] http://aptly.corp.example/debian bookworm main';
  is_deeply(rewrite_as('Test::KeyMirror', "$line\n"), [ "$line $ALL\n", 1 ], 'recognised by its keyring');
  is_deeply(rewrite("$line\n"), [ undef, 0 ], 'not by the base class');
};

{
  package Test::FakeHost;
  use Moo;
  extends 'Rex::GPU::NVIDIA::Setup::Debian';
  has files => ( is => 'ro' );
  has written => ( is => 'ro', default => sub { [] } );
  sub run_cmd {
    my ( $self, $cmd ) = @_;
    if ($cmd =~ m{^cat (\S+)}) {
      my $c = $self->files->{$1};
      $? = defined $c ? 0 : 256;
      return $c // '';
    }
    $? = 0;
    return join "\n", map { m{^/etc/apt/sources\.list\.d/(.+)$} ? $1 : () } sort keys %{ $self->files };
  }
  sub file_cmd { my ( $self, $path ) = @_; push @{ $self->written }, $path }
}

subtest 'enable_nonfree: the warning names the override point' => sub {
  my @log;
  no warnings 'redefine';
  local *Rex::Logger::info = sub { push @log, [ @_ ] };

  my $host = Test::FakeHost->new(files => {
    '/etc/apt/sources.list' => 'deb http://apt-cache.corp.example:3142/debian bookworm main'
  });
  $host->enable_nonfree;
  is_deeply($host->written, [], 'unknown mirror: nothing written');
  my ($warn) = grep { ($_->[1] // '') eq 'warn' } @log;
  ok($warn, 'warned');
  like($warn->[0], qr/is_debian_archive_uri/, 'names is_debian_archive_uri');
  like($warn->[0], qr/Rex::GPU::NVIDIA::Setup::Debian/, 'names the class to subclass');
  like($warn->[0], qr{eg/custom-setup}, 'points at eg/custom-setup');
  like($warn->[0], qr{signed-by=/usr/share/keyrings/debian-archive-keyring\.gpg}, 'names the signed-by way');

  @log = ();
  my $mirror = Test::FakeHost->new(files => {
    '/etc/apt/sources.list' => "deb [$DEBKEY] http://apt-cache.corp.example:3142/debian bookworm main"
  });
  $mirror->enable_nonfree;
  is_deeply($mirror->written, [ '/etc/apt/sources.list' ], 'Debian-signed mirror: sources.list written');
  ok(!(grep { ($_->[1] // '') eq 'warn' } @log), 'no warning');
};

done_testing;
