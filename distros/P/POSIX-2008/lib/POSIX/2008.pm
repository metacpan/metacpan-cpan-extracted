package POSIX::2008;

use strict;
use warnings;
use Carp ();
use IO::Dir ();
use IO::File ();

require Exporter;
require 'POSIX/2008/symbols.pl'; # Defines @_constants and @_functions.

our @_constants;
our @_functions;

our $VERSION = '0.27';
our $XS_VERSION = $VERSION;
$VERSION = eval $VERSION; # so "use Module 0.002" won't warn on underscore

our @ISA = qw(Exporter);
our @EXPORT = ();
our @EXPORT_OK = (@_functions, @_constants);

our %EXPORT_TAGS = (
  # at: Older Perls don't have variable length lookbehind, thus two regexen
  # for functions.
  'at'     => [
    grep(/^(?:AT|RENAME|RESOLVE)_/, @_constants),
    grep(/at2?$/ && !/^(?:creat|l?stat)$/, @_functions),
  ],
  'id'     => [grep /^[gs]et.+id$/, @_functions],
  'is'     => [grep /^is/, @_functions],
  'rw'     => [qw(read write readv writev)],
  'prw'    => [qw(pread preadv preadv2 pwrite pwritev pwritev2)],
  'clock'  => [
    grep(/^(?:CLOCK_|TIMER_ABSTIME)/, @_constants),
    grep(/^clock/, @_functions),
  ],
  'errno_h'=> [grep /^E(?!MPTY)[A-Z]+$/, @_constants],
  'fcntl'  => [grep /^(?:[FORWX]|FD|POSIX_FADV|SEEK)_/, @_constants],
  'fenv_h' => [grep(/^FE_/, @_constants), grep (/^fe/, @_functions)],
  'fnm'    => [grep(/^FNM_/, @_constants), 'fnmatch'],
  'poll'   => ['poll', 'ppoll', grep /^(?:POLL|INFTIM)/, @_constants],
  'socket_h' => [
    qw(SCM_RIGHTS SOL_SOCKET SOMAXCONN),
    grep(/^(?:AF|MSG|SHUT|SO|SOCK)_/, @_constants),
  ],
  'stat_h' => [grep /^(?:S_I|UTIME_)/, @_constants],
  'time_h' => [grep /^(?:CLOCK|TIMER)_/, @_constants],
  'timer'  => [grep(/^TIMER_/, @_constants), grep(/^timer_/, @_functions)],
  'utmpx_h'  => [
    grep(/_(?:TIME|PROCESS)$/, @_constants),
    grep(/^(?:ACCOUNTING|EMPTY|RUN_LVL|UT_UNKNOWN)$/, @_constants),
    grep(/utx/, @_functions),
  ],
  'confstr'  => ['confstr', grep /^_CS_/, @_constants],
  'pathconf' => ['pathconf', grep /^_PC_/, @_constants],
  'sysconf'  => ['sysconf', grep /^_SC_/, @_constants],
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

  require XSLoader;
  XSLoader::load('POSIX::2008', $XS_VERSION);

  while (my ($func, $repl) = each %deprecated) {
    my $package_func = __PACKAGE__."::${func}";
    my $package_repl = __PACKAGE__."::${repl}";
    no strict 'refs';
    *{$package_func} = sub {
      Carp::carp(
        "${package_func}() is deprecated, use ${package_repl}() instead"
      ) unless $deprecated_warned{$func}++;
      &{*{$package_repl}};
    }
  }

  __PACKAGE__->export_to_level(1, $this, @_);
}

1;
