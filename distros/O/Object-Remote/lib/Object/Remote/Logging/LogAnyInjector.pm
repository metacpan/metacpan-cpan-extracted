package Object::Remote::Logging::LogAnyInjector;

#Experimental object that can be used to receive Log::Any
#generated log messages and inject them into the log router

use Moo;
use Object::Remote::Logging qw( router );
use Carp qw(croak);

BEGIN {
  our %LEVEL_NAME_MAP = (
    #key is Log::Any log level name or alias and value is Object::Remote::Logging
    #log level name
    trace => 'trace', debug => 'debug', info => 'info', notice => 'verbose',
    warning => 'warn', error => 'error', fatal => 'fatal',
    critical => 'error', alert => 'error', 'emergency' => 'error',
    inform => 'info', warn => 'warn', err => 'error', crit => 'error',
  );
}

sub AUTOLOAD {
  my ($self, @content) = @_;
  (my $log_level) = (our $AUTOLOAD =~ /([^:]+)$/);
  my $generator;
  my $log_contextual_level;
  our %LEVEL_NAME_MAP;

  #just a proof of concept - support for the is_ methods can
  #be done but requires modifications to the router
  return 1 if $log_level =~ m/^is_/;
  #skip DESTROY and friends
  return if $log_level =~ m/^[A-Z]+$/;

  if ($log_contextual_level = $LEVEL_NAME_MAP{$log_level}) {
    $generator = sub { @content };
  } elsif(($log_level =~ s/f$//) && ($log_contextual_level = $LEVEL_NAME_MAP{$log_level})) {
    my $format = shift(@content);
    $generator = sub { sprintf($format, @content) };
  } else {
   croak "invalid log level: $log_level";
  }

  router->handle_log_request({
    controller => 'Log::Any',
    package => scalar(caller),
    caller_level => 1,
    level => $log_contextual_level,
  }, $generator);

  return;
}

1;
