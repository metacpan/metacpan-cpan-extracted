package Nagios::Plugin::LDAP;

use strict;
use warnings;

use base qw(Nagios::Plugin);

use Net::LDAP;
use Net::LDAP::Util;
use Nagios::Plugin;
use Time::HiRes qw(time);
use DateTime;

our $VERSION = '0.04';
our $TIMEOUT = 4;


sub new {
  my $class = shift;

  my $usage = <<'USAGE';
Usage: check_ldap -H <host> -b <base_dn> [-p <port>] [-a <attr>] [-D <binddn>]
       [-P <password>] [-w <warn_time>] [-c <crit_time>] [-t timeout]
       [-2|-3] [-4|-6]
USAGE

  my $self = $class->SUPER::new(
    shortname => 'LDAP',
    usage     => $usage,
    version   => $VERSION,
    url       => 'http://search.cpan.org/dist/Nagios-Plugin-LDAP/bin/check_ldap_repl',
    license   =>
      qq|This library is free software, you can redistribute it and/or modify\nit under the same terms as Perl itself.|,
  );

  $self->_add_ldap_options;

  return $self;
}


sub _add_ldap_options {
  my ($self) = @_;

  my @args = (
    { spec => 'master|M=s',
      help =>
        qq|-M, --master=ADDRESS\n  Host name or IP Address of master LDAP server to check replication|,
      required => 1,
    },
    { spec => 'hostname|H=s',
      help =>
        qq|-H, --hostname=ADDRESS\n  Host name, IP Address, or unix socket (must be an absolute path)|,
      required => 1,
    },
    { spec => 'port|p=i',
      help => qq|-p, --port=INTEGER\n  Port number (default: 389)|,
    },
    { spec => 'use-ipv4|4!',
      help => qq|-4, --use-ipv4\n  Use IPv4 connection|,
    },
    { spec => 'use-ipv6|6!',
      help => qq|-6, --use-ipv6\n  Use IPv6 connection|,
    },
    { spec => 'attr|a=s',
      help => qq|-a [--attr]\n  ldap attribute to search (default: "(objectclass=*)")|,
    },
    { spec => 'base|b=s',
      help => qq|-b [--base]\n  ldap base (eg. ou=my unit, o=my org, c=at)|,
    },
    { spec => 'bind|D=s',
      help => qq|-D [--bind]\n  ldap bind DN (if required)|,
    },
    { spec => 'pass|P=s',
      help => qq|-P [--pass]\n  ldap password (if required)|,
    },
    { spec => 'starttls|T!',
      help => qq|-T [--starttls]\n  use starttls mechanism introduced in protocol version 3|,
    },
    { spec => 'ssl|S!',
      help =>
        qq|-S [--ssl]\n  use ldaps (ldap v2 ssl method). this also sets the default port to %s|,
    },
    { spec => 'ver2|2!',
      help => qq|-2 [--ver2]\n  use ldap protocol version 2|,
    },
    { spec => 'ver3|3!',
      help => qq|-3 [--ver3]\n  use ldap protocol version 3\n  (default protocol version: 2)|,
    },
    { spec => 'repl-warning=i',
      help =>
        qq|--repl-warning=INTEGER\n  Replication time delta to result in warning status (seconds)|,
    },
    { spec => 'repl-critical=i',
      help =>
        qq|-c, --critical=DOUBLE\n  Replication time delta to result in critical status (seconds)|,
    },
    { spec => 'warning|w=f',
      help => qq|-w, --warning=DOUBLE\n  Response time to result in warning status (seconds)|,
    },
    { spec => 'critical|c=f',
      help => qq|-c, --critical=DOUBLE\n  Response time to result in critical status (seconds)|,
    },
  );

  $self->add_arg(%$_) for (@args);
}


sub run {
  my ($self) = @_;

  $self->getopts;

  my $opts = $self->opts;

  my $hostname = $opts->get('hostname') || 'localhost';

  if (my $ldap = $self->_ldap_connect($hostname)) {
    if ($self->_ldap_bind($ldap)) {
      $self->_ldap_search($ldap);
    }
    $self->_ldap_check_repl($ldap);
  }

  $self->nagios_exit($self->check_messages(join => ", "));
  return;
}

sub _ldap_connect {
  my ($self, $hostname) = @_;
  my $opts = $self->opts;

  my $timeout  = $opts->get('timeout') || 4;
  my $ssl      = $opts->get('ssl');
  my $port     = $opts->get('port') || ($ssl ? 636 : 389);
  my $starttls = $opts->get('starttls') && !$ssl;
  my $version  = $opts->get('ver3') ? 3 : 2;
  my $ipv6     = $opts->get('use-ipv6');

  my $class = $ssl ? 'Net::LDAPS' : 'Net::LDAP';

  if ($ssl and !eval { require Net::LDAPS }) {
    my $err = $@;
    $self->add_message(WARNING, $err);
    return;
  }

  my $ldap = $class->new(
    $hostname,
    timeout => $timeout,
    version => $version,
    inet6   => $ipv6,
  );

  unless ($ldap) {
    my $err = $@;
    $self->add_message(CRITICAL, "$hostname: " . $err);
    return;
  }

  if ($starttls) {
    my $mesg = $ldap->start_tls;
    if ($mesg->code) {
      $self->add_message(WARNING, "starttls: [$hostname] " . $mesg->error);
      return;
    }
  }

  return $ldap;
}


sub _ldap_bind {
  my ($self, $ldap) = @_;
  my $opts = $self->opts;
  my $bind = $opts->get('bind') or return 1;

  my $pass = $opts->get('pass');
  my @auth = $pass ? (password => $pass) : (noauth => 1);
  my $mesg = $ldap->bind($bind, @auth);

  if ($mesg->code) {
    $self->add_message(WARNING, "bind: " . $mesg->error_desc);
    return 0;
  }

  return 1;
}

sub _ldap_do_search {
  my ($self, $ldap, $filter, @attrs) = @_;
  my $opts = $self->opts;

  my $base = $opts->get('base');
  unless ($base) {
    $self->add_message(WARNING, "No search base");
    return 0;
  }

  my $mesg = $ldap->search(
    scope => (@attrs ? 'base' : 'subtree'),
    base => $base,
    filter => $filter,
    (@attrs ? (attrs => \@attrs) : ()),
  );
  if ($mesg->code) {
    $self->add_message(WARNING, "search: " . $mesg->error_desc);
    return;
  }

  unless ($mesg->count) {
    $self->add_message(WARNING, "search: No entries found @attrs");
    return;
  }

  return $mesg->pop_entry;
}

sub _ldap_search {
  my ($self, $ldap) = @_;
  my $opts = $self->opts;

  my $warning  = $opts->get('warning');
  my $critical = $opts->get('critical');

  return 1 unless $warning or $critical;

  my $attr = $opts->get('attr') || '(objectClass=*)';

  my $start = time;
  $self->_ldap_do_search($ldap, $attr);
  my $delta = time - $start;

  $self->add_message($self->check_threshold($delta), sprintf("%.3f seconds response time", $delta));

  $self->add_perfdata(
    label     => 'time',
    value     => sprintf("%.4f", $delta),
    uom       => 's',
    threshold => $self->threshold
  );

  return 1;
}

sub _ldap_check_repl {
  my ($self, $dst_ldap) = @_;
  my $opts = $self->opts;

  my $master = $opts->get('master') or return 1;

  my $warning  = $opts->get('repl-warning');
  my $critical = $opts->get('repl-critical');
  my $verbose  = $opts->get('verbose');

  return 1 unless $warning or $critical;

  my $src_ldap = $self->_ldap_connect($master) or return;

  my $src_entry =
    $self->_ldap_do_search($src_ldap, '(&(objectClass=*)(contextCSN=*))', 'contextCSN')
    or return;
  my $dst_entry =
    $self->_ldap_do_search($dst_ldap, '(&(objectClass=*)(contextCSN=*))', 'contextCSN')
    or return;

  my $src_csn = $src_entry->get_value('contextCSN');
  my $dst_csn = $dst_entry->get_value('contextCSN');

  print "Master CSN = $src_csn\n" if $verbose;
  print "Slave  CSN = $dst_csn\n" if $verbose;

  my ($YYYY, $MM, $DD, $hh, $mm, $ss);
  ($YYYY, $MM, $DD, $hh, $mm, $ss) = $src_csn =~ /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
  my $src_dt = DateTime->new(
    year   => $YYYY,
    month  => $MM,
    day    => $DD,
    hour   => $hh,
    minute => $mm,
    second => $ss
  );
  ($YYYY, $MM, $DD, $hh, $mm, $ss) = $dst_csn =~ /^(\d{4})(\d\d)(\d\d)(\d\d)(\d\d)(\d\d)/;
  my $dst_dt = DateTime->new(
    year   => $YYYY,
    month  => $MM,
    day    => $DD,
    hour   => $hh,
    minute => $mm,
    second => $ss
  );

  my $delta = abs($src_dt->epoch - $dst_dt->epoch);

  $self->add_message(
    $self->check_threshold(check => $delta, warning => $warning, critical => $critical),
    sprintf("%d seconds replication delta", $delta));

  $self->add_perfdata(
    label     => 'repl',
    value     => $delta,
    uom       => 's',
    threshold => $self->threshold
  );

}

__END__

=head1 NAME

Nagios::Plugin::LDAP - Nagios plugin to observe LDAP.

=head1 SYNOPSIS

  use Nagios::Plugin::LDAP;

  my $np = Nagios::Plugin::LDAP->new;
  $np->run;

=head1 DESCRIPTION

Please setup your nagios config.

  ### check response time(msec) for LDAP
  define command {
    command_name    check_ldap_response
    command_line    /usr/bin/check_ldap -H $HOSTADDRESS$ -w 3 -c 5
  }


This plugin can execute with all threshold options together.

=head2 Command Line Options

  Usage: check_ldap -H <host> -b <base_dn> [-p <port>] [-a <attr>] [-D <binddn>]
         [-P <password>] [-w <warn_time>] [-c <crit_time>] [-t timeout]
         [-2|-3] [-4|-6]

  Options:
   -h, --help
      Print detailed help screen
   -V, --version
      Print version information
   -H, --hostname=ADDRESS
      Host name, IP Address, or unix socket (must be an absolute path)
   -M, --master=ADDRESS
      Host name or IP Address of master LDAP server to check replication
   -p, --port=INTEGER
      Port number (default: 389)
   -4, --use-ipv4
      Use IPv4 connection
   -6, --use-ipv6
      Use IPv6 connection
   -a [--attr]
      ldap attribute to search (default: "(objectclass=*)"
   -b [--base]
      ldap base (eg. ou=my unit, o=my org, c=at
   -D [--bind]
      ldap bind DN (if required)
   -P [--pass]
      ldap password (if required)
   -T [--starttls]
      use starttls mechanism introduced in protocol version 3
   -S [--ssl]
      use ldaps (ldap v2 ssl method). this also sets the default port to %s
   -2 [--ver2]
      use ldap protocol version 2
   -3 [--ver3]
      use ldap protocol version 3
      (default protocol version: 2)
   -w, --warning=DOUBLE
      Response time to result in warning status (seconds)
   -c, --critical=DOUBLE
      Response time to result in critical status (seconds)
   --repl-warning=INTEGER
      Replication time delta to result in warning status (seconds)
   --repl-critical=INTEGER
      Replication time delta to result in critical status (seconds)
   -t, --timeout=INTEGER
      Seconds before connection times out (default: 10)
   -v, --verbose
      Show details for command-line debugging (Nagios may truncate output)

=head1 METHODS

=head2 new()

create instance.

=head2 run()

run checks.

=head1 AUTHOR

Graham Barr C<< <gbarr@pobox.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Toru Yamaguchi, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut


