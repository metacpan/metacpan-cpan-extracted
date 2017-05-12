package Net::SolarWinds::Log;

=pod

=head1 NAME

Net::SolarWinds::Log - Simple file logging module

=head1 SYNOPSIS

  use Net::SolarWinds::Log;
  
  my $log=new Net::SolarWinds::Log('/some/log/file.log');
  
  $log->log_info("This will not be logged");
  $log->log_error("This will be logged");
  
  $log->set_loglevel(Net::SolarWinds::Log->LOG_INFO);
  
  $log->log_info("This will now be logged");
  $log->log_error("This will still be logged");
  
  

=head1 DESCRIPTION

This package provides a very simple somewhat standardized logging interface.  The module itself extends Net::SolarWinds::FileRotationBase and inherits all of its features.

=cut

use strict;
use warnings;
use base qw(Net::SolarWinds::FileRotationBase);
use File::Basename qw(basename);
use Scalar::Util qw(looks_like_number);
use Sys::Hostname;
use Carp qw(croak);
require Exporter;

our @EXPORT_OK = (qw(LOG_NONE LOG_ERROR LOG_WARN LOG_INFO LOG_DEBUG));

use constant LOOK_BACK_DEPTH => 4;

=head1 Exports

The following constants can be exported using the standard exporter syntax

  use Net::SolarWinds::Log (qw(LOG_NONE LOG_ERROR LOG_WARN LOG_INFO LOG_DEBUG));

=cut

use constant LOG_NONE   => -1;
use constant LOG_ALWAYS => 0;
use constant LOG_ERROR  => 1;
use constant LOG_WARN   => 2;
use constant LOG_INFO   => 3;
use constant LOG_DEBUG  => 4;

=head2 Default Log level

The default log level is LOG_ERROR or 1.  In the default state only errors are logged.

=cut

use constant DEFAULT_LOG_LEVEL => 1;

=head1 OO Methods

=over 3

=item * Object constructor

The object constructor takes key=>'value' argument pairs example:

  my $log=new Net::SolarWinds::Log(
      filename=>'/full/path/to/file.log',
      loglevel=>4,
      
      # optional, if not set the system hostname will be used
      hostname=>'somehost'
      
      # ignored when filename is set
      basefilename=>'myapp',
      folder=>'/var/myappfolder',

  );
  
When the constructor is called with a single argument it is assumed to be the fully quallified name of the log file to manage and rotate.

  my $log=new Net::SolarWinds::Log('/some/log/file.log');

=cut

sub new {
    my ( $class, @args ) = @_;

    unshift @args, 'filename' if ( $#args == 0 );

    my $self = $class->SUPER::new(
        loglevel     => $class->DEFAULT_LOG_LEVEL,
        basefilename => 'changeme',
        hostname     => hostname,
        @args
    );
}

=item * my $hash=$self->lookback(stack_level);

This method returns a hash that provides information about who called this function relative to the stack_level argument.  The class default value is 4.

Example result

  {
  	# the fully qualified package that this method ran under
  	package=>'main',
  	
  	# the package and subrouteen this was called under
  	sub=>'main::some_method',
  	
  	# the source file ( may be eval or undef )
  	filename=>'/path/to/my/Script',
  	
  	# the line in wich the function was called
  	# if the internals are unsure the value is undef
  	line=>11
  }

=cut

sub lookback {
    my ( $self, $level ) = @_;

    my $hash = {};
    @{$hash}{qw(package filename line sub)} = caller($level);

    # Look up the stack until we find something that explains who and what called us
  LOOK_BACK_LOOP: while ( defined( $hash->{sub} ) and $hash->{sub} =~ /eval/ ) {

        my $copy = {%$hash};
        @{$hash}{qw(package filename line sub)} = caller( ++$level );

        # give up when we have a dead package name
        unless ( defined( $hash->{package} ) ) {

            $hash = $copy;
            $hash->{eval} = 1;

            last LOOK_BACK_LOOP;

        }

    }

    # if we don't know where we were called from, we can assume main.
    @{$hash}{qw(sub filename package line)} = ( 'main::', $0, 'main', 'undef' )
      unless defined( $hash->{package} );

    return $hash;
}

=item * my $string=$log->format_log('LEVEL=ERROR|WARN|INFO|DEBUG',"some log");

Formats your log entry as:

  HOSTNAME PID TIMESTAMP LEVEL STACK_TRACE DATA \n

Special notes: any undef value will be converted to a string value of 'undef'.

=cut

sub format_log {
    my ( $self, $level, @info ) = @_;

    foreach my $string (@info) {

        unless ( defined($string) ) {
            $string = 'undef';
        }

    }

    my $lb = $self->lookback( $self->LOOK_BACK_DEPTH );

    my $string = join ' ', $self->{hostname}, $$, scalar(localtime), $level, $lb->{sub}, @info;
    return $string . "\n";
}

=item * $log->log_info("message");

Logs to a file if the log level is LOG_INFO or greater.

=cut

sub log_info {
    my ( $self, @args ) = @_;

    return unless $self->{loglevel} >= $self->LOG_INFO;

    $self->write_to_log( 'INFO', @args );
}

=item * $log->log_error("message");

Logs to a file if the log level is LOG_error or greater.

=cut

sub log_error {
    my ( $self, @args ) = @_;

    return unless $self->{loglevel} >= $self->LOG_ERROR;

    $self->write_to_log( 'ERROR', @args );
}

=item * $log->log_die("Some message");

Logs the message then dies.

=cut

sub log_die {
  my ($self,@args)=@_;
  my $string=$self->format_log('DIE',@args);

  die $string unless $self->{loglevel} >= $self->LOG_ALWAYS;

  $self->write_to_log( 'DIE', @args );
  die $string;
}

=item * $log->log_warn("message");

Logs to a file if the log level is LOG_WARN or greater.

=cut

sub log_warn {
    my ( $self, @args ) = @_;

    return unless $self->{loglevel} >= $self->LOG_WARN;

    $self->write_to_log( 'WARN', @args );
}

=item * $log->log_always("message");

Logs to a file if the log level is LOG_ALWAYS or greater.

=cut

sub log_always {
    my ( $self, @args ) = @_;

    return unless $self->{loglevel} >= $self->LOG_ALWAYS;

    $self->write_to_log( 'ALWAYS', @args );
}

=item * $log->log_debug("message");

Logs to a file if the log level is LOG_DEBUG or greater.

=cut

sub log_debug {
    my ( $self, @args ) = @_;

    return unless $self->{loglevel} >= $self->LOG_DEBUG;

    $self->write_to_log( 'DEBUG', @args );
}

=item * $log->write_to_log('LEVEL=ERROR|WARN|INFO|DEBUG','message');

Writes 'message' to the log file with formatting representing 2 levels aboive itself in the stack.

=cut

sub write_to_log {
    my ( $self, @info ) = @_;

    my $string = $self->format_log(@info);

    $self->write_to_file($string);
}

=item * my $loglevel=$log->get_loglevel;

Returns the current runtime loglevel.

=cut

sub get_loglevel {
    $_[0]->{loglevel};
}

=item * $log->set_loglevel(level);

Used to set the current loglevel to the level.

=cut

sub set_loglevel {
    my ( $self, $level ) = @_;
    $self->{loglevel} = $level;
}

# overload default functions, but make them work.. sort of
sub get_log { $_[0] }
sub set_log { croak "Cannot set log object within itself!" }

=back

=head1 Author

Michael Shipper

=cut

1;
