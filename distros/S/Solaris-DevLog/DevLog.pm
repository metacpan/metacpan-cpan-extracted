########################################################################
# $Id: DevLog.pm,v 1.1 2002/02/11 21:49:58 bossert Exp $
# Project:  Solaris::DevLog
# File:     DevLog.pm
# Author:   Greg Bossert <bossert@fuaim.com>, <greg@netzwert.ag>
#
# Copyright (c) 2002 Greg Bossert
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
########################################################################

package Solaris::DevLog;

use 5.006;
use strict;
no strict 'refs'; # we want to use symbolic refs
no strict 'subs';

use warnings;

require DynaLoader;
require Exporter;

use IO::Handle;
use Carp;

use vars qw($VERSION $REVISION $AUTOLOAD %Config);

our @ISA = qw(DynaLoader Exporter);

### exports ###
our %EXPORT_TAGS = 
  ( 
   'flags' => [ 
	       qw(
		  SL_FATAL
		  SL_NOTIFY
		  SL_ERROR
		  SL_TRACE
		  SL_CONSOLE
		  SL_WARN
		  SL_NOTE
		 )
	      ] 
  );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'flags'} } );

### set the version number here ###
our $VERSION = '1.00';
sub Version { $VERSION; }

### snarf the RCS revision number ###
$REVISION = sprintf("%02d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
sub Revision { $REVISION; }

bootstrap Solaris::DevLog $VERSION;

########################################################################
# start pod (Perl Online Documentation)
########################################################################

=head1 NAME

Solaris::DevLog - Read from a Solaris Syslog stream

=head1 SYNOPSIS

  use Solaris::DevLog;
  my $devlog = new Solaris::DevLog();

  while (1) (
    # block until a message is available
    $devlog->select(undef);

    # get the message
    my ($status, $ctl, $msg) = $devlog->getmsg();
    print "Message priority $ctl->{pri}: $msg\n"
      unless $status;
  }

=head1 DESCRIPTION

B<Solaris::DevLog> facilitates the reading of syslog messages via
Solaris streams, and supports the syslog door mechanism.

See example.pl for a working example.

=cut

########################################################################
# class (config) data
########################################################################
%Config = 
  (
   ### debugging ###
   Debug => {
	     Trace=>0,
	     Create=>0,
	    },
  );

########################################################################
# constructor
########################################################################

sub new {
  my $this = shift;
  my $class = ref($this) || $this;

  ### copy the config data from the implemented class into the object ###
  my $self = {%{"${class}::Config"}};
  
  bless $self, $class;
  
  ### call hook for class initialization ###
  $self->initialize(@_);

  ### example use of debugging ###
  carp "created a " . ref $self if $self->{Debug}{Create};

  return $self;
}

########################################################################
# initialize
########################################################################

=head1 ATTRIBUTES

The DevLog class has the following attributes.  See the section below
on getting/setting these attributes.

=over 4

=item I<stream_path> the path to log stream (eg. /dev/log)

=item I<door_fd> the path to the door file

=item I<stream_fd> the file descriptor for the log stream

=item I<door_fd> the file descriptor for the door

=back

=head1 CREATING AND INITIALIZING AN INSTANCE

    use DevLog;
    my $path = '/dev/log';
    my $door = '/etc/.syslog_door';
    my $devlog = new DevLog ($path, $door);

The constructor takes the path to the log device and the path the door
file.  If these are omitted, the values shown above are used.

=cut

sub initialize {
  my $self = shift;
  my ($stream_path, $door_name) = @_;
  
  ### set defaults ###
  $stream_path ||= '/dev/log';
  $door_name ||= '/etc/.syslog_door';
  my $stream_fd = -1;
  my $door_fd = -1;

  ### set up member vars ###
  $self->stream_path($stream_path);
  $self->door_name($door_name);
  $self->stream_fd($stream_fd);
  $self->door_fd($door_fd);

  ### set up buffers for getmsg ###
  $self->init_buffers;

  ### set up stream ###
  $stream_fd = $self->open_stream($stream_path);
  die $! unless $stream_fd > 0;
  $self->stream_fd($stream_fd);

  $self->init_stream($stream_fd);

  ### set up door ###
  $door_fd = $self->open_door($door_name);
  die $! unless $door_fd > 0;
  $self->door_fd($door_fd);
}

########################################################################
# destructor
########################################################################
sub DESTROY {
  my $self = shift;

  $self->cleanup(
		 $self->stream_fd, 
		 $self->door_fd
		);

  carp "destroyed a " . ref $self if $self->{Debug}{Create};
}

########################################################################
# PUBLIC METHODS
########################################################################

=head1 METHODS

=cut

########################################################################
# getmsg
########################################################################

=head2 GET A MESSAGE

  my ($status, $ctl, $msg) = $devlog->getmsg();
  print "log message was $msg\n";
  print "priority was $ctl->{pri}\n";

Gets the next available message on the log stream.  Returns:

=over 4

=item *

B<status> integer as returned by the system call L<getmsg>

=item *

B<ctl> hash reference containing the fields of the log_ctl structure:

=over 4

=item -

I<mid> ID number of the module or driver submitting the message

=item -

I<sid> ID number for a particular minor device

=item -

I<level> Tracing level for selective screening

=item -

I<flags> Message disposition.  See L<strlog>

=item -

I<ltime> Time in machine ticks since boot

=item -

I<ttime> Time in seconds since 1970

=item -

I<seq_no> Sequence number

=item -

I<pri> Priority = (facility|level)

=back

=item *

B<msg> string containing the log message

=back

=cut

sub getmsg {
  my $self = shift;

  my $ctlhash = {};
  my ($status, $msg);

  eval {
    ($status, $msg)
      = $self->_getmsg($self->stream_fd, $ctlhash);
  };
  warn "$0: getmsg failed: $@" if $@;

  ($status, $ctlhash, $msg);  
}

########################################################################
# select
########################################################################

=head2 SELECT

  my $timeout = undef;
  my ($nfound) = $devlog->select($timeout);

This method works like the L<select> system call on the log stream.
The timeout argument works as described for L<select>; set it to
C<undef> to block, or give it a timeout in seconds to poll.

=cut

sub select {
  my $self = shift;
  my ($timeout) = @_;

  my ($rin, $rout);  
  $rin = '';
  vec($rin, $self->stream_fd ,1) = 1;
  
  select($rout=$rin, undef, undef, $timeout);
}

########################################################################
# flag constants
########################################################################

=head2 FLAGS

The following flag values from I<stdlog.h> are available, and can be
imported with the 'flags' tag:

  use Solaris::DevLog qw(:flags);

  SL_FATAL        # 0x01    indicates fatal error 
  SL_NOTIFY       # 0x02    logger must notify administrator 
  SL_ERROR        # 0x04    include on the error log 
  SL_TRACE        # 0x08    include on the trace log 
  SL_CONSOLE      # 0x10    include on the console log 
  SL_WARN         # 0x20    warning message 
  SL_NOTE         # 0x40    notice message 

=cut

sub SL_FATAL {0x01;} # indicates fatal error 
sub SL_NOTIFY {0x02;} # logger must notify administrator 
sub SL_ERROR {0x04;} # include on the error log 
sub SL_TRACE {0x08;} # include on the trace log 
sub SL_CONSOLE {0x10;} # include on the console log 
sub SL_WARN {0x20;} # warning message 
sub SL_NOTE {0x40;} # notice message 

########################################################################
# debug
########################################################################

=head2 SET THE DEBUGGING LEVEL
  
    my $flags = {Create->1, Trace->1};
    Solaris::DevLog::debug($flags);
    -or-
    $devlog->debug($flags);

The I<debug> method may be called as a class or instance method;
calling it as a class method will affect all objects created after the
call.  It takes a hash ref which defines the state of debugging flags.
The currently defined debugging flags are:

   Trace: prints warnings when calling methods
   Create: prints warnings when creating/destroying instances

=cut

sub debug {
  my $self = shift;
  my ($flags) = @_;

  my $flag;
  for $flag (%$flags) {
    if (ref($self))  {
      $self->{Debug}{$flag} = $flags->{$flag};
    } else {
      $Config{Debug}{$flag} = $flags->{$flag};
    }
  }
}

########################################################################
# instance variable access routine -- uses autoloading to return any
# instance field...
########################################################################

=head2 GET/SET AN ATTRIBUTE

    $value = $devlog-><attribute_name>();
    -or-
    $newvalue = $devlog-><attribute_name>($newvalue);

Attributes of objects of this class and subclasses can be accessed via
a generic autoloaded accessor method.  To get the value of an
attribute, call the method with the same name.  To set an attribute,
or create a new one, supply the value as an argument.

Note: attributes are stored in a subhash of the object named "Data",
to avoid potential collisions with required and utility methods.

=cut

sub AUTOLOAD {
  my $self = shift;
  my ($data) = @_;

  my $type = ref($self)
    or croak "$self is not an object";
  
  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion

  ### example use of debugging ###
  carp "calling autoloaded $name" if $self->{Debug}{Trace};

  ### set value if supplied ###
  $self->{Data}{$name} = $data if defined $data;

  $self->{Data}{$name};
}

### end of library ###
1;
__END__

########################################################################
# rest of pod (Perl Online Documentation)
########################################################################

=head1 EXAMPLE

  use DevLog;
  my @initial_values = ("some value");
  my $object = new DevLog (@initial_values);
  print $object->attribute_1('a new value');

=head1 AUTHOR

Greg Bossert <bossert@fuaim.com>, <greg@netzwert.ag>

Special thanks to Netzwert AG <http://www.netzwert.ag> for supporting
the development of this module.

=head1 SEE ALSO

L<getmsg> (Solaris).

L<strlog> (Solaris).

=head1 COPYRIGHT AND LICENCE

Copyright (c) 2002 Greg Bossert

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

### end pod ###


########################################################################
# end file DevLog.pm
########################################################################
