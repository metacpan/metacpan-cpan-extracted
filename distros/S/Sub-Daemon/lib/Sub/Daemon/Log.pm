package Sub::Daemon::Log;

use Fcntl qw(:flock);
use Carp;

use constant LEVEL => {debug => 1, info => 2, warn => 3, error => 4, fatal => 5};

sub new {
	my $class = shift;
	my %opts = (
		path 	=> undef,
		level 	=> 'debug',
		@_,
	);
	
	my $self = bless \%opts, $class;
}

sub debug {
	$self = shift;
	$self->log('debug', @_);
}

sub info {
	$self = shift;
	$self->log('info', @_);
}

sub warn {
	$self = shift;
	$self->log('warn', @_);
}

sub error {
	$self = shift;
	$self->log('error', @_);
}

sub fatal {
	$self = shift;
	$self->log('fatal', @_);
}

sub _default {
	my $self = shift;
  my ($time, $level) = (shift, shift);
  my ($s, $m, $h, $day, $month, $year) = localtime $time;
  $time = sprintf '%04d-%02d-%02d %02d:%02d:%08.5f', $year + 1900, $month + 1,
    $day, $h, $m, "$s." . ((split /\./, $time)[1] // 0);
  return "[$time] [$$] [$level] " . join "\n", @_, '';
}

sub log {
	my ($self, $level) = (shift, shift);
	return if LEVEL()->{$self->{level}}  > LEVEL()->{$level};
	my $str = $self->_default(time(),$level,@_);
	my $handle = $self->handle;
	
	flock $handle, LOCK_EX;
	print $handle $str;
	flock $handle, LOCK_UN;
	#$self->append($str);
}

sub handle {
	my $self = shift;
	my $path = $self->{path} or return \*STDERR;
	open my $fi, '>>' . $path;
	return $fi;
}

sub append {
  my ($self, $msg) = @_;
  return unless my $handle = $self->handle;
  flock $handle, LOCK_EX;
  print($handle encode('UTF-8', $msg)) or croak "Can't write to log: $!";
  flock $handle, LOCK_UN;
}

1;