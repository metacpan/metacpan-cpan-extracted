package Nginx::Control;
use Moose;
use MooseX::Types::Path::Class;
use Path::Class;

our $VERSION   = '0.04';
our $AUTHORITY = 'cpan:PERIGRIN';
our $NGINX_BIN = 'nginx';
our @SEARCH_PATH = qw( /usr /usr/local /usr/local/nginx /opt/local /opt/nginx /sw );

has 'config_file' => (
    is     => 'rw',
    isa    => 'Path::Class::File',
    coerce => 1,
);

has 'prefix_path' => (
    is     => 'rw',
    isa    => 'Path::Class::Dir',
    coerce => 1,
);

has 'binary_path' => (
    is      => 'rw',
    isa     => 'Path::Class::File',
    coerce  => 1,
    lazy    => 1,
    builder => '_find_binary_path'
);

has 'pid_file' => (
    is      => 'rw',
    isa     => 'Path::Class::File',
    coerce  => 1,
    lazy    => 1,
    builder => '_find_pid_file',
);

has 'server_pid' => (
    init_arg => undef,
    is       => 'ro',
    isa      => 'Int',
    lazy     => 1,
    builder  => '_find_server_pid',
);

sub log { shift; warn @_, "\n" }

## ---------------------------------
## events

sub pre_startup  { inner() }
sub post_startup { inner() }

sub pre_shutdown  { inner() }
sub post_shutdown { inner() }

sub pre_reload  { inner() }
sub post_reload { inner() }

## ---------------------------------

sub _find_server_pid {
    my $self = shift;
    my $pid = $self->pid_file->slurp( chomp => 1 );
    ($pid)
      || confess "No PID found in pid_file (" . $self->pid_file . ")";
    $pid;
}

sub _find_pid_file {
    my $self = shift;

    my $config_file = $self->config_file;

    ( -f $config_file )
      || confess
"Could not find pid_file because could not find config file ($config_file)";

    # the two possible approaches to
    # find the pid file (that I know of)
    my @approaches = ( sub { $config_file->slurp( chomp => 1 ) }, );

    foreach my $approach (@approaches) {
        my @config = $approach->();
        foreach my $line (@config) {
            if ( $line =~ /^\s*pid\s+(.*);/ ) {
                return Path::Class::File->new($1);
            }
        }
    }

    confess
      "Could not locate the pid-file information, please supply it manually";
}

sub _find_binary_path {
    my $self = shift;

    my $nginx = do {
        my $bin = `which $NGINX_BIN`;
        chomp($bin);
        Path::Class::File->new($bin);
    };

    return $nginx if -x $nginx;

    for my $prefix (@SEARCH_PATH) {
        for my $bindir (qw(bin sbin)) {
            my $nginx = Path::Class::File->new( $prefix, $bindir, $NGINX_BIN );
            return $nginx if -x $nginx;
        }
    }

    confess "can't find nginx anywhere tried => ("
      . ( $nginx || 'nothing' ) . ")";
}

sub _construct_command_line {
    my $self = shift;
    my @opts = @_;
    my $conf = $self->config_file;

    ( -f $conf )
      || confess "Could not locate configuration file ($conf)";

    my @cli = ( $self->binary_path, @opts, '-c', $conf->stringify );
    if ($self->prefix_path) {
        push @cli, ( '-p', $self->prefix_path->stringify . "/" );
    }

    return @cli;
}

## ---------------------------------

sub is_server_running {
    my $self = shift;

    # no pid file, no server running ...
    return 0 unless -s $self->pid_file;

    # has pid file, then check it ...
    kill( 0, $self->server_pid ) ? 1 : 0;
}

sub start {
    my $self = shift;

    $self->log("Starting nginx ...");
    $self->pre_startup;

    # NOTE:
    # do this after startup so that it
    # would be possible to write the
    # config file in the pre_startup
    # hook if we wanted to.
    # - SL
    my @cli = $self->_construct_command_line;
    $self->log( "Command-line: " . join(" ", @cli) );

    unless ( system(@cli) == 0 ) {
        $self->log("Could not start nginx (@cli) exited with status $?");
        return;
    }

    $self->post_startup;
    $self->log("Nginx started.");
}

sub stop {
    my $self     = shift;
    my $pid_file = $self->pid_file;

    if ( -f $pid_file ) {

        if ( !$self->is_server_running ) {
            $self->log(
"Found pid_file($pid_file), but process does not seem to be running."
            );
            return;
        }

        $self->log("Stoping nginx ...");
        $self->pre_shutdown;

        my @cli = $self->_construct_command_line(qw( -s stop ));
        unless ( system(@cli) == 0 ) {
            kill 2, $self->server_pid;
        }

        $self->post_shutdown;
        $self->log("Nginx stopped.");

        return;
    }

    $self->log("... pid_file($pid_file) not found.");
}

sub reload {
    my $self     = shift;
    my $pid_file = $self->pid_file;

    unless ( -f $pid_file ) {
        $self->log("... pid_file($pid_file) not found.");
    }

    unless ( $self->is_server_running ) {
        $self->log(
"Found pid_file($pid_file), but process does not seem to be running."
        );
        return;
    }

    $self->log("Reloading nginx ...");
    $self->pre_reload;

    my @cli = $self->_construct_command_line(qw( -s reload ));
    unless ( system(@cli) == 0 ) {
        $self->log("Failed to reload Nginx.");
    }

    $self->post_reload;
    $self->log("Nginx reloaded.");
}

sub test {
    my $self     = shift;
    my $pid_file = $self->pid_file;

    my @cli = $self->_construct_command_line("-t");

    return ( system(@cli) == 0 );
}

no Moose;
1;

__END__

=pod

=head1 NAME

Nginx::Control - Simple class to manage a Nginx server

=head1 SYNOPSIS

  #!perl
  
  use strict;
  use warnings;
  
  use Nginx::Control;
  
  my ($command) = @ARGV;
  
  my $ctl = Nginx::Control->new(
      config_file => [qw[ conf nginx.conf ]],
      # PID file can also be discovered automatically 
      # from the conf, or if you prefer you can specify
      pid_file    => 'nginx.control.pid',    
  );
  
  if ($ctl->test) {
      $ctl->start if lc($command) eq 'start';
      $ctl->stop  if lc($command) eq 'stop';
  }

=head1 DESCRIPTION

This is a fork of L<Lighttpd::Control> to work with Nginx, it maintains 100%
API compatibility. In fact most of this documentation was stolen too. This is
an early release with only the bare bones functionality needed, future
releases will surely include more functionality. Suggestions and crazy ideas
welcomed, especially in the form of patches with tests.

=head1 ATTRIBUTES

=over 4

=item I<config_file>

This is a L<Path::Class::File> instance for the configuration file.

=item I<prefix_path>

This is an optional L<Path::Class::Dir> instance pointing to the
root prefix path where you would like Nginx to be started from.
This will typically point at a location where logs and other sorts
of files will be stored at start-up time.

=item I<binary_path>

This is a L<Path::Class::File> instance pointing to the Nginx 
binary. This can be autodiscovered or you can specify it via the 
constructor.

=item I<pid_file>

This is a L<Path::Class::File> instance pointing to the Nginx 
pid file. This can be autodiscovered from the config file or you 
can specify it via the constructor.

=item I<server_pid>

This is the PID of the live server.

=back

=head1 METHODS 

=over 4

=item B<start>

Starts the Nginx server that is currently being controlled by this 
instance. It will also run the pre_startup and post_startup hooks.

=item B<stop>

Stops the Nginx server that is currently being controlled by this 
instance. It will also run the pre_shutdown and post_shutdown hooks.

It will attempt to send a signal to the running master Nginx process
to stop cleanly, and if this fails will manually kill the process.

=item B<reload>

Reloads the Nginx server configuration without stopping and starting
the process. This ensures a minimal amount of downtime will occur
while updating to a new configuration.

=item B<test>

Tests the Nginx server config to make sure it can start successfully.

=item B<is_server_running>

Checks to see if the Nginx server that is currently being controlled 
by this instance is running or not (based on the state of the PID file).

=item B<log>

Simple logger that you can use, it just sends the output to STDERR via
the C<warn> function.

=back

=head1 AUGMENTABLE METHODS

These methods can be augmented in a subclass to add extra functionality 
to your control script. Here is an example of how they might be used
to integrate with L<FCGI::Engine::Manager> (For a complete, working 
version of this, take a look at the file F<003_basic_with_fcgi_engine.t> 
in the test suite).

  package My::Nginx::Control;
  use Moose;
  
  extends 'Nginx::Control';
  
  has 'fcgi_manager' => (
      is      => 'ro',
      isa     => 'FCGI::Engine::Manager',   
      default => sub {
          FCGI::Engine::Manager->new(
              conf => 'conf/fcgi.engine.yml'
          )            
      },
  );
  
  augment post_startup => sub {
      my $self = shift;
      $self->log('Starting the FCGI Engine Manager ...');
      $self->fcgi_manager->start;        
  };
  
  augment post_shutdown => sub {
      my $self = shift;
      $self->log('Stopping the FCGI Engine Manager ...');
      $self->fcgi_manager->stop; 
  };    

=over 4

=item B<pre_startup>

=item B<post_startup>

=item B<pre_shutdown>

=item B<post_shutdown>

=item B<pre_reload>

=item B<post_reload>

=back

=head1 BUGS

All complex software has bugs lurking in it, and this module is no 
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 AUTHOR

Chris Prather E<lt>chris@prather.org$<gt>

Based on L<Lighttpd::Control> by Stevan Little E<lt>stevan.little@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2008 Chris Prather

except for those parts that are 

Copyright 2008 Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
