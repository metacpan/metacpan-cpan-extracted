package POSIX::2008;

use strict;
use warnings;

use Carp ();
use IO::Dir ();
use IO::File ();
use XSLoader ();

BEGIN {
  our $VERSION = '0.30';
  our $XS_VERSION = $VERSION;
  $VERSION = eval $VERSION; # so "use Module 0.002" won't warn on underscore
  XSLoader::load('POSIX::2008', $XS_VERSION);
}

require Exporter;
require 'POSIX/2008/symbols.pl'; # Get @_constants and @_functions.

our @_constants;
our @_functions;

our @ISA = 'Exporter';
our @EXPORT = ();
our @EXPORT_OK = (@_functions, @_constants);

our %EXPORT_TAGS = (
  # at: Older Perls lack variable length lookbehind, thus two regexen
  # for functions.
  'at'     => [
    grep(/^(?:AT|RENAME|RESOLVE)_/, @_constants),
    grep(/at2?$/ && !/^(?:creat|lstat|stat)$/, @_functions),
  ],
  'id'     => [grep /^[gs]et.+id$/, @_functions],
  'is'     => [grep /^is/, @_functions],
  'rw'     => [grep /^(?:read|write)v?$/, @_functions],
  'prw'    => [grep /^(?:pread|pwrite)(?:v2?)?$/, @_functions],
  'clock'  => [
    grep(/^(?:CLOCK_|TIMER_ABSTIME)/, @_constants),
    grep(/^clock/, @_functions),
  ],
  'errno_h'=> [grep /^E(?!MPTY)[A-Z]+$/, @_constants],
  'fcntl'  => [grep /^(?:[ORWX]|F|FD|POSIX_FADV|SEEK)_/, @_constants],
  'fenv_h' => [grep(/^FE_/, @_constants), grep (/^fe/, @_functions)],
  'fnm'    => [grep(/^FNM_/, @_constants), grep(/^fnmatch$/, @_functions)],
  'poll'   => [
    grep(/^(?:POLL|INFTIM)/, @_constants),
    grep(/^(?:poll|ppoll)$/, @_functions),
  ],
  'socket_h' => [
    grep(/^(?:AF|MSG|SCM|SHUT|SO|SOCK|SOL)_/ || /^SOMAXCONN$/, @_constants),
  ],
  'stat_h' => [grep /^(?:S_I|UTIME_)/, @_constants],
  'time_h' => [grep /^(?:CLOCK|TIMER)_/, @_constants],
  'timer'  => [grep(/^TIMER_/, @_constants), grep(/^timer_/, @_functions)],
  'utmpx_h'  => [
    grep(/_(?:TIME|PROCESS)$/, @_constants),
    grep(/^(?:ACCOUNTING|EMPTY|RUN_LVL|UT_UNKNOWN)$/, @_constants),
    grep(/utx/, @_functions),
  ],
  'confstr'  => [grep(/^confstr$/, @_functions), grep(/^_CS_/, @_constants)],
  'pathconf' => [grep(/^pathconf$/, @_functions), grep(/^_PC_/, @_constants)],
  'sysconf'  => [grep(/^sysconf$/, @_functions), grep(/^_SC_/, @_constants)],
);

my %deprecated = (
  atol => 'atoi',
  atoll => 'atoi',
  ldiv => 'div',
  lldiv => 'div',
  fchdir => 'chdir',
  fchmod => 'chmod',
  fchown => 'chown',
  ftruncate => 'truncate',
);
my %deprecated_warned;

push @EXPORT_OK, keys %deprecated;

our $AUTOLOAD;
sub AUTOLOAD {
  my ($func) = ($AUTOLOAD =~ /.*::(.*)/);
  die "POSIX::2008.xs has failed to load\n" if $func eq 'constant';
  constant($func);
}

sub import {
  my $this = shift;

  while (my ($func, $repl) = each %deprecated) {
    my $pkg_func = __PACKAGE__."::${func}";
    my $pkg_repl = __PACKAGE__."::${repl}";
    no strict 'refs';
    *{$pkg_func} = sub {
      Carp::carp(
        "${pkg_func}() is deprecated, use ${pkg_repl}() instead"
      ) unless $deprecated_warned{$func}++;
      &{$pkg_repl};
    }
  }

  __PACKAGE__->export_to_level(1, $this, @_);
}

1;
