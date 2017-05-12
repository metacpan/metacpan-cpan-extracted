package RRD::Daemon::Util;

use strict;
use warnings;
use feature  qw( :5.10 );

=head1 NAME

RRD::Daemon::Util - utilities for RRD::Daemon

=cut

use base  qw( Exporter );
our @EXPORT_OK = qw( ff fdur ftime
                     debug error fatal trace info lwrite warn warning
                     ddump ddumps ddumpc ddumpcs
                     tdump tdumps tdumpc tdumpcs
                     DUMP_SINGLE_LINE DUMP_MULTI_LINE
                     FTIME_INC_EPOCH FTIME_SHORT
                     init_log4perl mlhash
                  );


use Carp                   qw( cluck );
use File::Spec::Functions  qw( rel2abs );
use FindBin                qw( $Script );
use IO::All                qw( io );
use Log::Log4perl          qw( :levels get_logger ); # grr, cannot import levels individually even from ::Level
use Params::Validate       qw( validate_pos
                               HASHREF SCALAR SCALARREF );
use POSIX                  qw( strftime );


# ----------------------------------------------------------------------------

use constant DUMP_SINGLE_LINE => \1; # value is == only to itself - not even == another \1
use constant DUMP_MULTI_LINE  => \2; # value is == only to itself

use constant FTIME_INC_EPOCH  => 1;
use constant FTIME_SHORT      => 2;

BEGIN {
  Log::Log4perl::Layout::PatternLayout::add_global_cspec
    ('D', sub { strftime '%s %a %F %I:%M:%S %p GMT', gmtime });
}

use constant DEFAULT_LOGGING_CONF => <<'LOG4PERL';
log4perl.rootLogger=WARN, SCREEN, LOGFILE
log4perl.category.Placeholder.For.ScreenD.Appender=NONE, SCREEND, LOGFILED

log4perl.appender.SCREEN=Log::Log4perl::Appender::Screen
log4perl.appender.SCREEN.layout=PatternLayout::Multiline
log4perl.appender.SCREEN.layout.ConversionPattern=[%d{EEEdd}Z%d{HH:mm:ss}] %5p> %m%n
log4perl.appender.SCREEN.Threshold=INFO

log4perl.appender.LOGFILE=Log::Dispatch::FileRotate
log4perl.appender.LOGFILE.DatePattern=yyyy-MM-dd
log4perl.appender.LOGFILE.filename=sub { use FindBin '$Script'; join '/', ($ENV{join '_', $Script, 'LOGDIR'} // join('/', '/tmp', (getpwuid $<)[0], 'logs')), "$Script.log" }
log4perl.appender.LOGFILE.max=10
log4perl.appender.LOGFILE.mode=append
log4perl.appender.LOGFILE.TZ=UTC
log4perl.appender.LOGFILE.layout=PatternLayout::Multiline
log4perl.appender.LOGFILE.layout.ConversionPattern=[%D] %5p> %m%n
log4perl.appender.LOGFILE.Threshold=INFO


log4perl.appender.SCREEND=Log::Log4perl::Appender::Screen
log4perl.appender.SCREEND.layout=PatternLayout::Multiline
log4perl.appender.SCREEND.layout.ConversionPattern=[%d{EEEdd}Z%d{hh:mm:ss}] %5p> %M(%L) - %m%n
# log4perl.appender.SCREEND.Threshold=NONE

log4perl.appender.LOGFILED=Log::Dispatch::FileRotate
log4perl.appender.LOGFILED.DatePattern=yyyy-MM-dd
log4perl.appender.LOGFILED.filename=sub { use FindBin '$Script'; join '/', ($ENV{join '_', $Script, 'LOGDIR'} // join('/', '/tmp', (getpwuid $<)[0], 'logs')), "$Script.log" }
log4perl.appender.LOGFILED.max=10
log4perl.appender.LOGFILED.mode=append
log4perl.appender.LOGFILED.TZ=UTC
log4perl.appender.LOGFILED.layout=PatternLayout::Multiline
log4perl.appender.LOGFILED.layout.ConversionPattern=[%D] %5p> %M(%L) - %m%n
LOG4PERL

# ----------------------------------------------------------------------------

sub ff (@) {
  my @args = @_;

  cluck sprintf "%s called with no args\n", (caller 0)[3]
    if 0 == @args;
  cluck sprintf "undef passed to %s >>%s<<\n",
        (caller 0)[3],
        Data::Dumper->new(\@_)->Maxdepth(3)->Indent(0)->Terse(1)->Dump
    if grep !defined, @args;

  my $text;
  if ( 1 == @args ) {
    if ( UNIVERSAL::isa($args[0], 'HASH') ) {
      my $dd = Data::Dumper->new(\@args);
      $text = $dd->Maxdepth(3)->Indent(wantarray ? 1 : 0)->Terse(1)->Dump;
    } elsif ( UNIVERSAL::isa($args[0], 'ARRAY') ) {
      my $dd = Data::Dumper->new(\@args);
      $text = $dd->Maxdepth(3)->Indent(wantarray ? 1 : 0)->Terse(1)->Dump;
    } else {
      $text = $args[0];
    }
  } else {
    if ( DUMP_SINGLE_LINE eq $args[0] or DUMP_MULTI_LINE eq $args[0]) {
      if ( 'ARRAY' eq ref $args[1] or 2 < @args ) {
        my @a = 2 == @args ? @{$args[1]} : @args[1..$#args];
        $text = join DUMP_SINGLE_LINE eq $args[0] ? ' ' : "\n",
                     map Data::Dumper->new([$a[$_*2+1]],[$a[$_*2]])->Maxdepth(3)->Indent(0)->Terse(0)->Dump,
                         0..$#a/2;
      } elsif ( 'HASH' eq ref $args[1] ) {
        $text = join DUMP_SINGLE_LINE eq $args[0] ? ' ' : "\n",
                     map Data::Dumper->new([$args[1]->{$_}],[$_])->Maxdepth(3)->Indent(0)->Terse(0)->Dump,
                         sort keys %{$args[1]};
      } else {
        $text = join DUMP_SINGLE_LINE eq $args[0] ? ' ' : "\n",
                     Data::Dumper->new([@args[1..$#args]])->Maxdepth(3)->Indent(DUMP_MULTI_LINE eq $args[0])->Terse(1)->Dump;
      }
    } else {
      # beware sprintf's prototype of ($@), which means that sprintf @args
      # would place the first arg in a scalar context - so taking a single arg
      # being the size of the list
      $text = sprintf $args[0], @args[1..$#args];
    }
  }

  return wantarray ? split(/\n/, $text) : $text
}

# -------------------------------------

sub _lwrite ($$@) {
  my ($methname, $level, @msg) = @_;
  local $Log::Log4perl::caller_depth += 2;
  my $i = 1;
  $Log::Log4perl::caller_depth += 1
    while (caller $i++)[0] eq __PACKAGE__;
  my $logger = get_logger;
  return unless $level >= $logger->level;
  $logger->$methname($level, $_)
    for ff @msg;
}

# -------------------------------------

sub lwrite ($@) { unshift @_, 'log'; goto &_lwrite }

sub trace   (@) { lwrite($TRACE, @_) }
sub info    (@) { lwrite($INFO, @_)  }
sub debug   (@) { lwrite($DEBUG, @_) }
sub warn    (@) { lwrite($WARN, @_)  }
sub warning (@) { lwrite($WARN, @_)  }
sub error   (@) { lwrite($ERROR, @_) }
sub fatal   (@) { lwrite($FATAL, @_) }

sub ddump   (@) { lwrite($DEBUG, DUMP_MULTI_LINE, @_) }
sub ddumps  (@) { lwrite($DEBUG, DUMP_SINGLE_LINE, @_) }
sub ddumpc  (&) { return unless $DEBUG >= get_logger->level; ddump  &{$_[0]} }
sub ddumpcs (&) { return unless $DEBUG >= get_logger->level; ddumps &{$_[0]} }

sub tdump   (@) { lwrite($TRACE, DUMP_MULTI_LINE, @_) }
sub tdumps  (@) { lwrite($TRACE, DUMP_SINGLE_LINE, @_) }
sub tdumpc  (&) { return unless $TRACE >= get_logger->level; tdump  &{$_[0]} }
sub tdumpcs (&) { return unless $TRACE >= get_logger->level; tdumps &{$_[0]} }

# -------------------------------------

=head2 mlhash

take a hash (as a ref), and an RE to split on, and return a hash (as a ref)
that is the orig, as a multi-level hash split on the given re.

So,

  %a = ( 'a.b' => 7, 'a.c' => 5 );
  $b = mlhash(\%a, qr/\./); # $b == +{ a => +{ b => 7, c => 5 } };

=cut

sub mlhash {
  my ($h, $qr) = validate_pos(@_, { type => HASHREF }, { type => SCALARREF });

  my %result;
  while ( my($k,$v) = each %$h ) {
    my @k = split $qr, $k;

    # Build out the subhashes, taking a reference to each one as we go to
    # then build / add onto the one below so $kk is always a ref to a hash
    # element (that itself is generally a hash). If we get input like
    # +{ "a" => 1, "a.b" => 2 }, we will blow up atm.  We should probably fix
    # that to make a hashref like +{ a => { '' => 1, 'a.b' => 2 }, once we
    # have a decent test case.  But beware of order-dependency when building -
    # i.e., "a" may appear either before or after "a.b" due to random key
    # ordering; also, this would mean "a" and "a." would be indistinguishable.
    # Not yet sure if that's a problem.
    my $kk = \ $result{$k[0]};
    for (@k[1..$#k-1]) {
      $$kk //= +{};
      my $ll = \ $$kk->{$_};
      $kk = $ll;
    }
    if ( 1 == @k ) {
      $$kk = $v;
    } else {
      $$kk //= +{};
      $$kk->{$k[-1]} = $v;
    }
  }

  return \%result;
}

# -------------------------------------

sub ftime (;$$) {
  my ($time, $opt) = @_;
  $time //= 0;
  $opt //= 0;
# %a%dZT # Thu15Z05:42:12
  my $format = $opt & FTIME_SHORT ? '%g%m%dZ%T' : '%a %F %I:%M:%S %p GMT';
  $format = '%s ' . $format
    if $opt & FTIME_INC_EPOCH;

  return strftime $format, gmtime $time;
}

# --------------------------------------

sub fdur ($) {
  my ($duration) = @_;

  my $string = '';

  my $seconds = $duration % 60;
  $string = sprintf '%2ds', $seconds
    if $seconds;

  $duration /= 60;
  return $string
    unless $duration >= 1;
  my $minutes = $duration % 60;
  $string = sprintf '%2dm%s', $minutes, $string
    if $minutes;

  $duration /= 60;
  return $string
    unless $duration >= 1;
  my $hours = $duration % 24;
  $string = sprintf '%2dh%s', $hours, $string
    if $hours;

  $duration /= 24;
  return $string
    unless $duration >= 1;
  my $days = $duration % 7;
  $string = sprintf '%dd%s', $days, $string
    if $days;

  $duration /= 7;
  return $string
    unless $duration >= 1;
  my $weeks = $duration % 52;
  $string = sprintf '%2dw%s', $weeks, $string
    if $weeks;

  $duration /= 52;
  return $string
    unless $duration >= 1;
  my $years = $duration;
  $string = sprintf '%2dy%s', $years, $string
    if $years;

  return $string;
}

# --------------------------------------

sub init_log4perl {
  my ($default_conf_text, $conf_fn) =
    validate_pos(@_, +{ default => DEFAULT_LOGGING_CONF,
                        type    => SCALAR, },
                     +{ default => exists $ENV{LOG4PERL_CONF}   ?
                                   rel2abs($ENV{LOG4PERL_CONF}) :
                                   rel2abs("$Script.l4p"),
                        type    => SCALAR, },
                );

  state $initialized = 0;
  state $last_good_config;

  Log::Log4perl::Level::add_priority('NONE', 2*$Log::Log4perl::FATAL, undef);

  if ( defined $conf_fn and -e $conf_fn ) {
    CORE::warn "reading logging conf: '$conf_fn'\n";
    eval {
      Log::Log4perl->init($conf_fn);
    }; if ( $@ ) {
      die $@ unless $initialized and defined $last_good_config;
      # revert to old setting for safety
      Log::Log4perl->init(\$last_good_config);
      CORE::warn "failed to load conf '$conf_fn':\n  $@\n";
    } else {
      $last_good_config < io($conf_fn);
    }
    Log::Log4perl->get_logger('')->level(Log::Log4perl::Level::to_priority($ENV{LOG4PERL_LEVEL}))
      if exists $ENV{LOG4PERL_LEVEL};
    $initialized = 1;
  } elsif ( defined $conf_fn and $initialized ) { # && ! -e $conf_fn
    CORE::warn "writing logging conf: '$conf_fn'\n";
    io($conf_fn) < $default_conf_text;
  } elsif ( ! $initialized ) {
    Log::Log4perl->init(\$default_conf_text);
    $last_good_config = $default_conf_text;
    Log::Log4perl->get_logger('')->level(Log::Log4perl::Level::to_priority($ENV{LOG4PERL_LEVEL}))
      if exists $ENV{LOG4PERL_LEVEL};
    $initialized = 1;
  } else { # $initialized and !defined $conf_fn
    CORE::warn "attempt to re-read logging conf with no conf_fn\n";
  }

  $SIG{USR2} = sub { init_log4perl($default_conf_text, $conf_fn) }
    if defined $conf_fn;

}

# -------------------------------------

# turn on debug output; intended to be used from the command line
# categories is expected to be a comma-separated list of Log4perl categories
# to debug for.  Use undef or empty string for the root logger (i.e., all)
sub cmdline_debug {
  my ($callback, $classes) = @_;
  my $name = $callback->name;

  my $sappender = $Log::Log4perl::Logger::APPENDER_BY_NAME{SCREEND};
  my $fappender = $Log::Log4perl::Logger::APPENDER_BY_NAME{LOGFILED};

  if ( ! defined $classes or ! ref $classes ) {
    my $logger = Log::Log4perl->get_logger('');
    $logger->add_appender($_)
      for $sappender, $fappender;

    if ( 'trace' eq lc substr($name, 0, 5) ) {
      if ( $logger->is_trace ) {
        $logger->more_logging;
      } else {
        $logger->level($Log::Log4perl::TRACE);
      }
    } else {
      if ( $logger->is_debug ) {
        $logger->more_logging;
      } else {
        $logger->level($Log::Log4perl::DEBUG);
      }
    }

    # turn off default loggers to avoid everything getting logged twice
    $Log::Log4perl::Logger::APPENDER_BY_NAME{SCREEN}->threshold('NONE');
    $Log::Log4perl::Logger::APPENDER_BY_NAME{LOGFILE}->threshold('NONE');
  } else {
    my @classes = split /,/, $_[1];
    for my $_ (@classes) {
      my $logger = Log::Log4perl->get_logger($_);
      $logger->add_appender($_)
        for $sappender, $fappender;
      if ( $logger->is_debug ) {
        $logger->more_logging;
      } else {
        $logger->level($Log::Log4perl::DEBUG);
      }
    }
  }
}

# ----------------------------------------------------------------------------

1; # keep require happy
