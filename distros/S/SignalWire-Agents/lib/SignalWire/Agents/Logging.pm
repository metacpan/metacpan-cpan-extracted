package SignalWire::Agents::Logging;
use strict;
use warnings;
use Moo;

# Log levels in ascending severity
my %LEVELS = (
    debug => 0,
    info  => 1,
    warn  => 2,
    error => 3,
);

has 'name' => (
    is      => 'ro',
    default => sub { 'signalwire' },
);

has 'level' => (
    is      => 'rw',
    default => sub {
        my $env = $ENV{SIGNALWIRE_LOG_LEVEL} // 'info';
        return lc($env);
    },
);

has 'suppressed' => (
    is      => 'rw',
    default => sub {
        my $mode = $ENV{SIGNALWIRE_LOG_MODE} // '';
        return lc($mode) eq 'off' ? 1 : 0;
    },
);

sub _should_log {
    my ($self, $msg_level) = @_;
    return 0 if $self->suppressed;
    my $current = $LEVELS{ $self->level } // 1;
    my $target  = $LEVELS{ $msg_level }   // 1;
    return $target >= $current;
}

sub _log {
    my ($self, $level, @msgs) = @_;
    return unless $self->_should_log($level);
    my $tag = uc($level);
    my $name = $self->name;
    my $msg = join(' ', @msgs);
    my $ts = _timestamp();
    print STDERR "[$ts] [$tag] [$name] $msg\n";
}

sub debug { shift->_log('debug', @_) }
sub info  { shift->_log('info',  @_) }
sub warn  { shift->_log('warn',  @_) }
sub error { shift->_log('error', @_) }

sub _timestamp {
    my @t = localtime;
    return sprintf('%04d-%02d-%02d %02d:%02d:%02d',
        $t[5]+1900, $t[4]+1, $t[3], $t[2], $t[1], $t[0]);
}

# Singleton-ish factory
my %loggers;

sub get_logger {
    my ($class, $name) = @_;
    $name //= 'signalwire';
    $loggers{$name} //= SignalWire::Agents::Logging->new(name => $name);
    return $loggers{$name};
}

1;
