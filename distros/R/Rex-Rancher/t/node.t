use strict;
use warnings;
use Test::More;

# -----------------------------------------------------------------------------
# Offline tests for prepare_node's NTP, /etc/hosts and locale steps (k42).
#
# 1. NTP: an already NTP-synchronized clock installs nothing; a failed chrony
#    install falls back to systemd-timesyncd and warns loudly, not dies, when
#    that is not active either (k55.2).
# 2. /etc/hosts: a hostname without domain still gets 127.0.1.1, unless a
#    line already names it.
# 3. Locale: on Debian/Ubuntu the locale is enabled in /etc/locale.gen, with
#    the charset spelled as locale.gen spells it, and generated before
#    localectl sets it; a locale that is not locale-shaped dies before any
#    command runs (k55.1).
# 4. Timezone: a zoneinfo-shaped name reaches timedatectl or the symlink
#    single-quoted; anything else dies before any command runs (k60).
# 5. Hostname: a static hostname (/etc/hostname) whose first label is the
#    requested name -- or that is the name -- is left standing, with and
#    without hostnamectl; anything else, or nothing readable, is set (k86).
#
# run, pkg, can_run, is_debian, host_entry, get_host and file are replaced in
# Rex::Rancher::Node, so no remote host is involved. This proves the decision
# logic and the command strings, not a deploy.
# -----------------------------------------------------------------------------

use Rex::Rancher::Node;

my ( @cmds, @pkgs, @hosts, @warn, @info, %answer, %have, $debian, $pkg_fails, @existing );
{
  no warnings 'redefine';
  *Rex::Rancher::Node::run = sub {
    my ( $cmd ) = @_;
    push @cmds, $cmd;
    for my $re ( keys %answer ) {
      next unless $cmd =~ $re;
      my ( $out, $rc ) = @{ $answer{$re} };
      $? = $rc << 8;
      return $out;
    }
    $? = 0;
    return '';
  };
  *Rex::Rancher::Node::pkg = sub {
    push @pkgs, $_[0][0];
    die "Error installing $_[0][0]\n" if $pkg_fails;
  };
  *Rex::Rancher::Node::can_run    = sub { $have{ $_[0] } };
  *Rex::Rancher::Node::is_debian  = sub { $debian };
  *Rex::Rancher::Node::host_entry = sub { my ( $name, %o ) = @_; push @hosts, [ $name, \%o ] };
  *Rex::Rancher::Node::get_host   = sub { @existing };
  *Rex::Rancher::Node::file       = sub { push @cmds, 'file '.$_[0] };
  *Rex::Logger::info              = sub {
    push @info, $_[0];
    push @warn, $_[0] if ( $_[1] // '' ) eq 'warn';
  };
}

sub reset_fakes {
  @cmds = @pkgs = @hosts = @existing = @warn = @info = ();
  %answer    = ();
  %have      = ();
  $debian    = 0;
  $pkg_fails = 0;
}

# --- NTP ---------------------------------------------------------------------

subtest 'ntp: already synchronized installs nothing' => sub {
  reset_fakes();
  $answer{qr/NTPSynchronized/} = [ "yes\n", 0 ];
  Rex::Rancher::Node::_setup_ntp();
  is_deeply( \@pkgs, [], 'no chrony install' );
  is( scalar @cmds, 1, 'only the timedatectl query ran' );
};

subtest 'ntp: not synchronized installs chrony' => sub {
  reset_fakes();
  $answer{qr/NTPSynchronized/} = [ "no\n", 0 ];
  Rex::Rancher::Node::_setup_ntp();
  is_deeply( \@pkgs, ['chrony'], 'chrony installed' );
  ok( grep( /systemctl start chronyd/, @cmds ), 'chrony started' );
  ok( !grep( /timesyncd/, @cmds ), 'timesyncd not touched' );
};

subtest 'ntp: no timedatectl counts as not synchronized' => sub {
  reset_fakes();
  $answer{qr/NTPSynchronized/} = [ '', 127 ];
  Rex::Rancher::Node::_setup_ntp();
  is_deeply( \@pkgs, ['chrony'], 'chrony installed' );
};

subtest 'ntp: chrony fails, timesyncd active' => sub {
  reset_fakes();
  $answer{qr/NTPSynchronized/}  = [ "no\n", 0 ];
  $answer{qr/is-active systemd-timesyncd/} = [ "active\n", 0 ];
  $pkg_fails = 1;
  ok( eval { Rex::Rancher::Node::_setup_ntp(); 1 }, 'does not die' ) or diag $@;
  ok( grep( /^systemctl enable --now systemd-timesyncd/, @cmds ), 'timesyncd enabled and started' );
  ok( !grep( /chronyd/, @cmds ), 'chrony service not touched' );
};

subtest 'ntp: chrony fails, no timesyncd (RHEL family) warns, does not die (k55.2)' => sub {
  reset_fakes();
  $answer{qr/NTPSynchronized/}  = [ "no\n", 0 ];
  $answer{qr/is-active systemd-timesyncd/} = [ "inactive\n", 3 ];
  $pkg_fails = 1;
  ok( eval { Rex::Rancher::Node::_setup_ntp(); 1 }, 'does not die, as k42 specifies' ) or diag $@;
  is( scalar @warn, 2, 'the chrony fallback, then the outcome' );
  like( $warn[1] // '', qr/^NO TIME SYNCHRONIZATION IS ACTIVE on this node: chrony install failed \(Error installing chrony\) and systemd-timesyncd is not active/,
    'says plainly that nothing syncs the clock, and why' );
};

# --- /etc/hosts --------------------------------------------------------------

subtest 'hosts: with domain writes FQDN plus short name' => sub {
  reset_fakes();
  Rex::Rancher::Node::_set_hosts_entry( 'worker-01', 'worker-01.k8s.local' );
  is_deeply( \@hosts,
    [ [ 'worker-01.k8s.local', { ensure => 'present', ip => '127.0.1.1', aliases => ['worker-01'] } ] ],
    'unchanged FQDN entry' );
};

subtest 'hosts: without domain writes the short name' => sub {
  reset_fakes();
  Rex::Rancher::Node::_set_hosts_entry( 'worker-01', undef );
  is_deeply( \@hosts, [ [ 'worker-01', { ensure => 'present', ip => '127.0.1.1' } ] ],
    '127.0.1.1 worker-01' );
};

subtest 'hosts: without domain leaves an existing line alone' => sub {
  reset_fakes();
  @existing = ( { ip => '203.0.113.7', host => 'worker-01', aliases => [] } );
  Rex::Rancher::Node::_set_hosts_entry( 'worker-01', undef );
  is_deeply( \@hosts, [], 'no host_entry, the provider line survives' );
};

subtest 'prepare_node: hostname without domain reaches /etc/hosts' => sub {
  reset_fakes();
  my @hosts_calls;
  no warnings 'redefine';
  local *Rex::Rancher::Node::_install_base_packages = sub { };
  local *Rex::Rancher::Node::_set_hostname          = sub { };
  local *Rex::Rancher::Node::_set_hosts_entry       = sub { push @hosts_calls, [@_] };
  local *Rex::Rancher::Node::_set_timezone          = sub { };
  local *Rex::Rancher::Node::_set_locale            = sub { };
  local *Rex::Rancher::Node::_setup_ntp             = sub { };
  local *Rex::Rancher::Node::_disable_swap          = sub { };
  local *Rex::Rancher::Node::_load_kernel_modules   = sub { };
  local *Rex::Rancher::Node::_configure_sysctl      = sub { };
  use warnings 'redefine';
  Rex::Rancher::Node::prepare_node( hostname => 'worker-01' );
  is_deeply( \@hosts_calls, [ [ 'worker-01', undef ] ], 'hosts step runs without domain' );
};

# --- Hostname (k86) ------------------------------------------------------------

my $READ_STATIC = 'cat /etc/hostname 2>/dev/null';

# The two ways _set_hostname sets a name: [ label, can_run, commands when set ].
my @BRANCHES = (
  [ 'hostnamectl',    { hostnamectl => 1 }, [ $READ_STATIC, 'hostnamectl set-hostname otho-lab' ] ],
  [ 'no hostnamectl', {},                   [ $READ_STATIC, 'file /etc/hostname', 'hostname otho-lab' ] ]
);

subtest 'hostname: a static FQDN whose first label is the name stays' => sub {
  for my $branch (@BRANCHES) {
    my ( $label, $have ) = @$branch;
    for my $fqdn ( undef, 'otho-lab.k8s.local' ) {
      my $with = $fqdn ? 'domain k8s.local' : 'no domain';
      reset_fakes();
      %have = %$have;
      $answer{qr{^cat /etc/hostname}} = [ "otho-lab.ai.citilan.de\n", 0 ];
      Rex::Rancher::Node::_set_hostname( 'otho-lab', $fqdn );
      is_deeply( \@cmds, [$READ_STATIC], "$label, $with: only read, not set" );
      is_deeply( \@info,
        ['Static hostname is already otho-lab.ai.citilan.de, leaving it (first label matches otho-lab)'],
        "$label, $with: the log names both" );
    }
  }
};

subtest 'hostname: the same name does nothing' => sub {
  for my $branch (@BRANCHES) {
    my ( $label, $have ) = @$branch;
    reset_fakes();
    %have = %$have;
    $answer{qr{^cat /etc/hostname}} = [ "otho-lab\n", 0 ];
    Rex::Rancher::Node::_set_hostname( 'otho-lab', undef );
    is_deeply( \@cmds, [$READ_STATIC], "$label: only read, not set" );
    is_deeply( \@info, ['Static hostname is already otho-lab, leaving it'], "$label: says so" );
  }
};

subtest 'hostname: case is ignored, the file is read the way systemd reads it' => sub {
  for my $static ( "Otho-Lab.AI.citilan.de\n", "OTHO-LAB\n", "# installimage\n\n  otho-lab.ai.citilan.de  \n" ) {
    reset_fakes();
    %have = ( hostnamectl => 1 );
    $answer{qr{^cat /etc/hostname}} = [ $static, 0 ];
    Rex::Rancher::Node::_set_hostname( 'otho-lab', undef );
    ( my $shown = $static ) =~ s/\n/\\n/g;
    is_deeply( \@cmds, [$READ_STATIC], "'$shown': left standing" );
  }
};

subtest 'hostname: another name is set as before' => sub {
  for my $branch (@BRANCHES) {
    my ( $label, $have, $set ) = @$branch;
    for my $static ( 'other.ai.citilan.de', 'otho-lab2.ai.citilan.de', 'otho-lab-2', 'otho.ai.citilan.de',
      'lab.otho-lab.de', 'localhost.localdomain' ) {
      reset_fakes();
      %have = %$have;
      $answer{qr{^cat /etc/hostname}} = [ "$static\n", 0 ];
      Rex::Rancher::Node::_set_hostname( 'otho-lab', undef );
      is_deeply( \@cmds, $set, "$label, '$static': set to otho-lab" );
      is_deeply( \@info, ['Setting hostname to otho-lab'], "$label, '$static': logged as before" );
    }
  }
};

subtest 'hostname: nothing readable is set as before' => sub {
  for my $branch (@BRANCHES) {
    my ( $label, $have, $set ) = @$branch;
    for my $case (
      [ 'missing file',   '',              1 ],
      [ 'empty file',     '',              0 ],
      [ 'blank lines',    "\n  \n",        0 ],
      [ 'only a comment', "# otho-lab\n",  0 ]
    ) {
      my ( $what, $out, $rc ) = @$case;
      reset_fakes();
      %have = %$have;
      $answer{qr{^cat /etc/hostname}} = [ $out, $rc ];
      Rex::Rancher::Node::_set_hostname( 'otho-lab', undef );
      is_deeply( \@cmds, $set, "$label, $what: set to otho-lab" );
    }
  }
};

# --- Locale ------------------------------------------------------------------

subtest 'locale: debian enables, generates, then sets' => sub {
  reset_fakes();
  $debian = 1;
  %have = ( 'locale-gen' => 1, localectl => 1 );
  Rex::Rancher::Node::_set_locale('en_US.UTF-8');
  is( scalar @cmds, 3, 'three commands' );
  like( $cmds[0], qr{^if \[ -f /etc/locale\.gen \]; then sed -i -E 's/\^#\\s\*\(en_US\\\.UTF-8 UTF-8\)\\s\*\$/\\1/' /etc/locale\.gen; },
    'uncomments the locale.gen line' );
  like( $cmds[0], qr{\|\| echo 'en_US\.UTF-8 UTF-8' >> /etc/locale\.gen; fi$}, 'appends it when absent' );
  is( $cmds[1], 'locale-gen en_US.UTF-8', 'generates the locale' );
  is( $cmds[2], 'localectl set-locale LANG=en_US.UTF-8', 'sets it last' );
};

subtest 'locale: redhat does not run locale-gen' => sub {
  reset_fakes();
  %have = ( 'locale-gen' => 1, localectl => 1 );
  Rex::Rancher::Node::_set_locale('en_US.UTF-8');
  is_deeply( \@cmds, ['localectl set-locale LANG=en_US.UTF-8'], 'only localectl' );
};

subtest 'locale: debian without locale-gen only sets' => sub {
  reset_fakes();
  $debian = 1;
  %have = ( localectl => 1 );
  Rex::Rancher::Node::_set_locale('de_DE.UTF-8');
  is_deeply( \@cmds, ['localectl set-locale LANG=de_DE.UTF-8'], 'no generation attempted' );
};

subtest 'locale: the charset is spelled as locale.gen spells it (k55.1)' => sub {
  for my $case (
    [ 'de_DE.utf8',        'de_DE.UTF-8 UTF-8',                'de_DE.UTF-8' ],
    [ 'de_DE.UTF8',        'de_DE.UTF-8 UTF-8',                'de_DE.UTF-8' ],
    [ 'en_GB.utf-8',       'en_GB.UTF-8 UTF-8',                'en_GB.UTF-8' ],
    [ 'de_DE.iso88591',    'de_DE.ISO-8859-1 ISO-8859-1',      'de_DE.ISO-8859-1' ],
    [ 'en_US.ISO-8859-15', 'en_US.ISO-8859-15 ISO-8859-15',    'en_US.ISO-8859-15' ],
  ) {
    my ( $locale, $line, $name ) = @$case;
    reset_fakes();
    $debian = 1;
    %have = ( 'locale-gen' => 1, localectl => 1 );
    Rex::Rancher::Node::_set_locale($locale);
    ( my $re = $line ) =~ s/\./\\./g;
    ok( index( $cmds[0], q{sed -i -E 's/^#\s*(}.$re.q{)\s*$/\1/'} ) >= 0, "$locale: uncomments '$line'" )
      or diag $cmds[0];
    like( $cmds[0], qr{\|\| echo '\Q$line\E' >> /etc/locale\.gen; fi$}, "$locale: appends '$line'" );
    is( $cmds[1], "locale-gen $name", "$locale: generates $name" );
    is( $cmds[2], "localectl set-locale LANG=$locale", "$locale: sets it as given" );
  }
};

subtest 'locale: anything not locale-shaped dies before the host (k55.1)' => sub {
  for my $bad ( q{en_US.UTF-8'; rm -rf /; '}, 'en_US.UTF-8 UTF-8', 'de_DE.(utf8)', '$(id)', '' ) {
    reset_fakes();
    $debian = 1;
    %have = ( 'locale-gen' => 1, localectl => 1 );
    ok( !eval { Rex::Rancher::Node::prepare_node( locale => $bad, ntp => 0 ); 1 }, "'$bad': dies" );
    like( $@, qr/^locale must look like en_US\.UTF-8 .*got '\Q$bad\E'\n\z/s, "'$bad': names it" );
    is_deeply( [ @cmds, @pkgs ], [], "'$bad': nothing ran" );
  }
};

# --- Timezone (k60) ------------------------------------------------------------

subtest 'timezone: zoneinfo names pass, quoted in both commands' => sub {
  for my $tz ( 'UTC', 'Europe/Berlin', 'America/Argentina/Buenos_Aires', 'America/Port-au-Prince',
    'Etc/GMT+5', 'Etc/GMT-14', 'EST5EDT' ) {
    reset_fakes();
    %have = ( timedatectl => 1 );
    Rex::Rancher::Node::_set_timezone($tz);
    is_deeply( \@cmds, ["timedatectl set-timezone '$tz'"], "$tz: timedatectl, quoted" );

    reset_fakes();
    Rex::Rancher::Node::_set_timezone($tz);
    is_deeply( \@cmds, [ "ln -sf '/usr/share/zoneinfo/$tz' /etc/localtime", 'file /etc/timezone' ],
      "$tz: symlink fallback, quoted" );
  }

  reset_fakes();
  my @tz;
  no warnings 'redefine';
  local *Rex::Rancher::Node::_install_base_packages = sub { };
  local *Rex::Rancher::Node::_set_timezone          = sub { push @tz, $_[0] };
  local *Rex::Rancher::Node::_set_locale            = sub { };
  local *Rex::Rancher::Node::_disable_swap          = sub { };
  local *Rex::Rancher::Node::_load_kernel_modules   = sub { };
  local *Rex::Rancher::Node::_configure_sysctl      = sub { };
  use warnings 'redefine';
  Rex::Rancher::Node::prepare_node( ntp => 0 );
  Rex::Rancher::Node::prepare_node( timezone => 'Etc/GMT+5', ntp => 0 );
  is_deeply( \@tz, [ 'UTC', 'Etc/GMT+5' ], 'prepare_node: default UTC and Etc/GMT+N get through' );
};

subtest 'timezone: anything not zoneinfo-shaped dies before the host' => sub {
  for my $bad ( q{UTC'; rm -rf /; '}, 'Europe/Berlin; reboot', '$(id)', '../../../etc/shadow',
    'Europe/../../etc/passwd', '/etc/shadow', 'Europe/', 'Europe Berlin', '' ) {
    reset_fakes();
    %have = ( timedatectl => 1 );
    ok( !eval { Rex::Rancher::Node::prepare_node( timezone => $bad, ntp => 0 ); 1 }, "'$bad': dies" );
    like( $@, qr/^timezone must look like Europe\/Berlin, UTC or Etc\/GMT\+5 .*got '\Q$bad\E'\n\z/s, "'$bad': names it" );
    is_deeply( [ @cmds, @pkgs ], [], "'$bad': nothing ran" );
  }
};

subtest 'locale: C.UTF-8 is built in' => sub {
  reset_fakes();
  $debian = 1;
  %have = ( 'locale-gen' => 1, localectl => 1 );
  Rex::Rancher::Node::_set_locale('C.UTF-8');
  is_deeply( \@cmds, ['localectl set-locale LANG=C.UTF-8'], 'no locale.gen edit, no locale-gen' );
};

done_testing;
