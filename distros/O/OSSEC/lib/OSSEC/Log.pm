package OSSEC::Log 0.1;

# ABSTRACT: Module/class for simplifying logging of OSSEC log messages
use strict;
use warnings;
use Moose;
use DateTime;
use File::Basename;



has 'ossecPath' => (is => 'rw', isa => 'Str' , default => "/var/ossec" );

has 'file'      => (is => 'rw', isa => 'Str');


sub error
{
  my $self      = shift;
  my $programm  = shift;
  my $message   = shift;

  $self->log("ERROR",$programm, $message);
}

sub fatal
{
  my $self      = shift;
  my $programm  = shift;
  my $message   = shift;

  $self->log("FATAL",$programm, $message);
  die;
}

sub info
{
  my $self      = shift;
  my $programm  = shift;
  my $message   = shift;

  $self->log("INFO",$programm, $message);
}

sub debug
{
  my $self      = shift;
  my $programm  = shift;
  my $message   = shift;

  $self->log("DEBUG",$programm, $message);
}


sub log
{
  my $self      = shift;
  my $type      = shift;
  my $programm  = shift;
  my $message   = shift;

  # a logfile is required
  die("no logfile selected") unless $self->file();

  # create the full path to the file
  my $file      = $self->ossecPath() . "/" . $self->file();
  my $dir       = dirname($file);

  readpipe("mkdir -p $dir");

  my $dt = DateTime->now;

  # create the full log message
  my $msg = sprintf("%10s %8s - %5s - %20s - %s\n",$dt->ymd(), $dt->hms(), $type, $programm, $message);


  # open the logfile
  open(my $fh, ">>", $file);

  print $fh $msg;

  close $fh;

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

OSSEC::Log - Module/class for simplifying logging of OSSEC log messages

=head1 VERSION

version 0.1

=head1 DESCRIPTION

This Module/Class is part of the OSSEC distribution.
It simplifies logging to files, e.g. for active response. You are able
to use different logging types (info,error,fatal,debug) and select the file to log
to. See the methods below.

=head1 ATTRIBUTES

=head2 ossecPath

base path to the ossec installation B<default> /var/ossec

Type: String

=head2 file

In which file to log the messages. The file should be given as the path relative to the
OSSEC configuration file.

Type: String

=head1 METHODS

=head2 error

log error message

=over

=item B<Param1>=I<program name which is logging>

=item B<Param2>=I<the message to log>

=back

log->error("OSSEC-Jabber","alert not found");

=head2 fatal

log fatal message and die

=over

=item B<Param1>=I<program name which is logging>

=item B<Param2>=I<the message to log>

=back

log->fatal("OSSEC-Jabber","could not connect to mysql server");

=head2 info

log info message

=over

=item B<Param1>=I<program name which is logging>

=item B<Param2>=I<the message to log>

=back

log->info("OSSEC-Jabber","alert send");

=head2 debug

log debug message

=over

=item B<Param1>=I<program name which is logging>

=item B<Param2>=I<the message to log>

=back

log->error("OSSEC-Jabber","found alert in database");

=head2 log

log messages to the logfile

=over

=item B<Param1>=I<Type of log message>

=item B<Param2>=I<program name which is logging>

=item B<Param3>=I<the message to log>

=back

=head1 AUTHOR

Domink Meyer <dmeyer@federationhq.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2019 by Dominik Meyer.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
