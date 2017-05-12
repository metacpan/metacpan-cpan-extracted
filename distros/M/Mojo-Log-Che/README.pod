package Mojo::Log::Che;
use Mojo::Base 'Mojo::Log';

use Carp 'croak';
use Fcntl ':flock';
use Mojo::File;
#~ use Debug::LTrace qw/Mojo::Log::_log/;;
#~ use Carp::Trace;
#~ use Encode qw(decode_utf8);
#~ binmode STDERR, ":utf8";

has paths => sub { {} };
has handlers => sub { {} };
has trace => 4;

# Standard log levels
my %LEVEL = (debug => 1, info => 2, warn => 3, error => 4, fatal => 5);

sub new {
  my $self = shift->SUPER::new(format => \&_format, @_);
  $self->unsubscribe('message')->on(message => \&_message);
  return $self;
}

sub handler {
  my ($self, $level) = @_;
  
  my $handler = $self->handlers->{$level};
  return $handler
    if $handler;
  
  my $path = shift->path;
  my $path_level = $self->paths->{$level};
  my $is_dir = -d -w $path
    if $path;
  
  my $file;
  if ($is_dir) {# DIR
    # relative path for level
    chop($path)
      if $path =~ /\/$/;
    
    $file = sprintf "%s/%s", $path, $path_level ||"$level.log";
  }
  elsif ($path_level) {# absolute FILE for level
    $file = $path_level;
  }
  else {
    #~ croak "Cant create log handler for level=[$level] and path=[$path] (also check filesystem permissions)";
    return; # Parent way to handle
  }
  
  $handler = Mojo::File->new($file)->open('>>:encoding(UTF-8)')
    or croak "Cant create log handler for [$file]";
  
  $self->handlers->{$level} = $handler;
  
  return $handler;
};

sub append {
  my ($self, $msg, $handle) = @_;

  return unless $handle ||= $self->handle;
  flock $handle, LOCK_EX;
  $handle->print( $msg)
    or croak "Can't write to log: $!";
  flock $handle, LOCK_UN;
}

my @mon = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
my @wday = qw(Sn Mn Ts Wn Th Fr St);
sub _format {
  my ($time, $level) = (shift, shift);
  $level = '['.($LEVEL{$level} ? ($level =~ /^(\w)/)[0] : $level) . '] ' #"[$level] "
    if $level //= '';
  
  my ($sec,$min,$hour,$mday,$mon,$year,$wday) = localtime($time);
  $time = sprintf "%s %s %s %s:%s:%s", $wday[$wday], $mday, map(length == 1 ? "0$_" : $_, $mon[$mon], $hour, $min, $sec);
  
  #~ my $trace =  '['. join(" ", @{_trace()}[1..2]) .']';
  
  return "$time $level" . join "\n", @_, '';
}

sub _trace {
  my $start = shift // 1;
  my @call = caller($start);
  return \@call
    if @call;
  #~ my @frames;
  $start = 1;
  #~ while (my @trace = caller($start++)) { push @call, \@trace }
  #~ return pop @call;
  while (@call = caller($start++)) { 1; }
  #~ return $frames[4];
  return \@call;
}


sub _message {
  my ($self, $level) = (shift, shift);

  return unless !$LEVEL{$level} || $self->is_level($level);

  my $max     = $self->max_history_size;
  my $history = $self->history;
  my $time = time;
  my $trace = _trace($self->trace)
    if $self->trace;
  unshift @_, join(":", @$trace[$$trace[0] eq 'main' ? (1,2) : (0,2)]). ' ' . shift
    if $trace && @$trace;
  push @$history, my $msg = [$time, $level, @_];
  shift @$history while @$history > $max;
  
  if (my $handle = $self->handler($level)) {
    return $self->append($self->format->($time, '', @_), $handle);
  }

  # as parent
  return $self->append($self->format->(@$msg));
  
}

sub AUTOLOAD {
  my $self = shift;

  my ($package, $method) = our $AUTOLOAD =~ /^(.+)::(.+)$/;
  Carp::croak "Undefined log level(subroutine) &${package}::$method called"
    unless Scalar::Util::blessed $self && $self->isa(__PACKAGE__);

  return $self->_log( $method => @_ );
  
}

our $VERSION = '0.06';

=encoding utf8

Доброго всем

=head1 Mojo::Log::Che

I<¡ ¡ ¡ ALL GLORY TO GLORIA ! ! !>

=head1 VERSION

0.06

=head1 NAME

Mojo::Log::Che - Little child of great parent Mojo::Log.

=head1 SYNOPSIS

  use Mojo::Log::Che;
  
  # Parent Mojo::Log behavior just works
  my $log = Mojo::Log::Log->new(path => '/var/log/mojo.log', level => 'warn');
  $log->debug(...);

=head2 EXTENDED THINGS of this module

  # Set "path" to folder + have default "paths" for levels (be sure that mkdir /var/log/mojo)
  my $log = Mojo::Log::Log->new(path => '/var/log/mojo'); 
  $log->warn(...);# log to  /var/log/mojo/warn.log
  $log->error(...); # log to  /var/log/mojo/error.log
  $log->foo(...);# log to  /var/log/mojo/foo.log
  
  # set "path" to folder + set custom relative "paths" (be sure that mkdir /var/log/mojo)
  my $log = Mojo::Log::Log->new(path => '/var/log/mojo', paths=>{debug=>'dbg.log', foo=>'myfoo.log'});
  $log->debug(...); # log to  /var/log/mojo/dbg.log
  $log->warn(...);# log to /var/log/mojo/warn.log
  $log->foo(...);# log to  /var/log/mojo/myfoo.log
  
  # set "path" to file + have default "paths" for levels
  # this is standard Mojo::Log behavior + custom level/method also
  my $log = Mojo::Log::Log->new(path => '/var/log/mojo.log');
  $log->debug(...); # log to  /var/log/mojo.log
  $log->warn(...);# log to  /var/log/mojo.log
  $log->foo(...);# log to /var/log/mojo.log
  
  # set "path" to file + set custom absolute "paths"
  my $log = Mojo::Log::Log->new(path => '/var/log/mojo.log', paths => {error=>'/var/log/mojo.error.log'});
  $log->debug(...); # log to  /var/log/mojo.log
  $log->foo(...);# log to /var/log/mojo.log
  $log->error(...);  # log to /var/log/mojo.error.log
  
  # Log to STDERR + set custom absolute "paths"
  $log->path(undef); # none path
  $log->level('info');
  $log->paths->{'error'} = '/var/log/error.log'; # absolute file only for error level
  $log->error(...);  # log to /var/log/error.log
  $log->info(...); # log to STDERR
  $log->debug(...); # no log
  $log->foo(...); # anyway log to STDERR
  

=head1 DESCRIPTION

This B<Mojo::Log::Che> is a extended logger module for L<Mojo> projects.

=head1 EVENTS

B<Mojo::Log::Che> inherits all events from L<Mojo::Log> and override following ones.

=head2 message

See also parent L<Mojo::Log/"message">. Extends parent module logics for switching handlers.

=head1 ATTRIBUTES

B<Mojo::Log::Che> inherits all attributes from L<Mojo::Log and implements the following new ones.

=head2 handlers

Hashref of created file handlers for standard and custom levels. For standard parent L<Mojo::Log> logic none handlers but L<Mojo::Log/"handle"> will be in the scene.

  $log->handlers->{'foo'} = IO::Handle->new();

=head2 path

See parent L<Mojo::Log/"path">. Can set to folder and file path.

=head2 paths

Hashref map level names to absolute or relative to L</"path">

  $log->path('/var/log'); # folder relative
  $log->paths->{'error'} = 'err.log';
  $log->error(...);#  /var/log/err.log
  $log->info(...); # log to filename as level name /var/log/info.log
  
  $log->path(undef); # none 
  $log->paths->{'error'} = '/var/log/error.log'; # absolute path only error level
  $log->error(...); # log to /var/log/error.log
  $log->info(...); # log to STDERR

=head2 trace

An trace level, defaults to C<4>, C<0> value will disable trace log. This value pass to C<caller()>.

=head1 METHODS

B<Mojo::Log::Che> inherits all methods from L<Mojo::Log> and implements the
following new ones.

=head2 handler($level)

Return undef when L</"path"> undefined or L</"path"> is file or has not defined L</"paths"> for $level. In this case L<Mojo::Log/"handle"> will return default handler.

Return file handler overwise.

=head1 AUTOLOAD

Autoloads nonstandard/custom levels excepts already defined keywords of this and parent modules L<Mojo::Log>, L<Mojo::EventEmitter>, L<Mojo::Base>:

  qw(message _message format _format handle handler handlers
  history level max_history_size  path paths append debug  error fatal info
  is_level  new warn  catch emit  has_subscribers on  once subscribers unsubscribe
  has  attr tap _monkey_patch import)

and maybe anymore!


  $log->foo('bar here');

That custom levels log always without reducing log output outside of level.

=head1 SEE ALSO

L<Mojo::Log>, L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=head1 AUTHOR

Михаил Че (Mikhail Che), C<< <mche[-at-]cpan.org> >>

=head1 BUGS / CONTRIBUTING

Please report any bugs or feature requests at L<https://github.com/mche/Mojo-Log-Che/issues>. Pull requests also welcome.

=head1 COPYRIGHT

Copyright 2017 Mikhail Che.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
