package Net::Async::Beanstalk::Constant;

our $VERSION = '0.001';
$VERSION = eval $VERSION;

use Exporter ();
our @ISA = qw(Exporter);

our @EXPORT_OK   = qw(
  $NL
  %COMMAND
  %RESPONSE
  @GENERAL
  @WITHDATA
  %STATE_CAN
  STATE_FUTURE
  STATE_MOAR
  STATE_COMMAND
  STATE_DATUM
);

our %EXPORT_TAGS = (
    all     => \@EXPORT_OK,
    receive => [qw($NL %RESPONSE @GENERAL @WITHDATA)],
    send    => [qw($NL %COMMAND)],
    state   => [qw(%STATE_CAN STATE_FUTURE STATE_MOAR STATE_COMMAND STATE_DATUM)],
);

our $NL = "\x0d\x0a";

our %COMMAND = (
  bury                 => [qw(BURIED NOT_FOUND)],
  delete               => [qw(DELETED NOT_FOUND)],
  ignore               => [qw(NOT_IGNORED WATCHING)],
 'kick-job'            => [qw(KICKED NOT_FOUND)],
  kick                 => [qw(KICKED)],
 'list-tubes'          => [qw(OK)],
 'list-tubes-watched'  => [qw(OK)],
 'list-tube-used'      => [qw(USING)],
 'pause-tube'          => [qw(NOT_FOUND PAUSED)],
  peek                 => [qw(FOUND NOT_FOUND)],
 'peek-buried'         => [qw(FOUND NOT_FOUND)],
 'peek-delayed'        => [qw(FOUND NOT_FOUND)],
 'peek-ready'          => [qw(FOUND NOT_FOUND)],
  put                  => [qw(BURIED DRAINING EXPECTED_CRLF INSERTED JOB_TOO_BIG)],
  quit                 => [],
  release              => [qw(BURIED NOT_FOUND RELEASED)],
  reserve              => [qw(DEADLINE_SOON RESERVED)],
 'reserve-with-timeout'=> [qw(DEADLINE_SOON RESERVED TIMED_OUT)],
  stats                => [qw(OK)],
 'stats-job'           => [qw(NOT_FOUND OK)],
 'stats-tube'          => [qw(NOT_FOUND OK)],
  touch                => [qw(NOT_FOUND TOUCHED)],
  use                  => [qw(USING)],
  watch                => [qw(WATCHING)],
);

my @GENERAL = qw(
  BAD_FORMAT
  INTERNAL_ERROR
  OUT_OF_MEMORY
  UNKNOWN_COMMAND
);

our %RESPONSE = map {+($_=>1)} @GENERAL, map {@$_} values %COMMAND;

our @WITHDATA = qw(FOUND OK RESERVED);

our %STATE_CAN;
for my $command (keys %COMMAND) {
  $STATE_CAN{$command}{$_} = 1 for @{ $COMMAND{$command} };
}

use constant STATE_FUTURE  => 0;
use constant STATE_MOAR    => 1;
use constant STATE_COMMAND => 2;
use constant STATE_DATUM   => 3;

1;
