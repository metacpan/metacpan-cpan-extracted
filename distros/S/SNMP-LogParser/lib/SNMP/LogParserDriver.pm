#
# $Id: LogParserDriver.pm,v 1.3 2006/09/25 06:28:44 nito Exp $
#
# Simple class that counts he number of lines of a file
#
# Nito@Qindel.ES -- 7/9/2006
package SNMP::LogParserDriver;

use warnings;
use strict;
use Log::Log4perl qw(:easy);;
use Data::Dumper;

=head1 NAME

SNMP:LogParserDriver

=head1 SYNOPSIS

This is base class for the usage of the logparser
parsing. Usually you will implement a subclass of
this class implementing the following methods:

=over 8

=item * new


You can define whatever new parameters you want
in this method, but usually only the object variable
B<pattern> (the regular expression to match in the file)
is needed

=item * evalBegin


This is an extract of code which initializes all the variables
that you might need during the run of logparser

=item * evalIterate


This method will be invoked for each line of the log file.

=item * evalEnd


This method usually records in the B<properties> hash reference
the key, value pairs that you want ot record in the output.

=back

=head1 DESCRIPTION

For a more detailed description on how to use this class
please check B<logparser>.

This document is a detailed reference of the different
methods provided in this class

=head1 METHODS

=head2 new

Receives (at the moment) no arguments. It creates an object
of SNMP::LogParserDriver

=cut

# Class constructor
sub new {
  my $class = shift;
  my $self = {};
  $self = {
	   name => undef,
	   logfile => undef,
	   pattern => undef,
	   savespace => undef,
	   workspace => undef,
	   properties => undef,
	   logger => undef
	  };
  bless ($self, $class);
  $self->name($class);
  $self->pattern('^.*$');
  if(!(Log::Log4perl->initialized())) {
    Log::Log4perl->easy_init($ERROR);
  }
  $self->logger(Log::Log4perl->get_logger("logparser.$class"));
  $self->{logger}->info("Created object of class $class");
  return $self;
}

=head2 name

Permits to retrieve or set the name of the object as in

 print "name: ".$self->name;

or

 $self->name("myname");

=cut

# The name of this object
sub name {
  my $self = shift;
  $self->{name} = shift if (@_);
  return $self->{name};
}

=head2 logfile

Permits to retrieve or set the logfile of the object as in

 print "logfile: ".$self->logfile;

or

 $self->logfile("/var/log/logfile");

=cut

# The log file that should be parsed
sub logfile {
  my $self = shift;
  $self->{logfile} = shift if (@_);
  return $self->{logfile};
}

=head2 pattern

Permits to retrieve or set the regular expression pattern of the object as in

 print "pattern: ".$self->pattern;

or

 $self->pattern("^myregex$");

=cut

# The regular expression that should be matched
sub pattern {
  my $self = shift;
  $self->{pattern} = shift if (@_);
  return $self->{pattern};
}

=head2 savespace

Permits to retrieve or set the savespace of the object as in

 print "savespace: ".Dumper($self->savespace);

or

 $self->savespace(\%mysavespace);

The savespace is usually a reference to a hash file. The
value of the savespace variable will be restored in the beginning
of each invocation of B<logparser> and saved at the end of the
invocation. Tipically things like counters are saved in each
invocation of the savespace.

=cut

# The savespace that should be saved across sessions
sub savespace {
  my $self = shift;
  $self->{savespace} = shift if (@_);
  return $self->{savespace};
}

=head2 workspace

Permits to retrieve or set a variable that will be maintained across iterative parsings
of the log, but will not be maintained across logparser invocations

 print "workspace: ".Dumper($self->workspace);

or

 $self->workspace(\%workspace);

The workpace is usually a reference to a hash file. The
value of the workspace variable will only last for each invocation
of B<logparser>. Tipically things like local variable are saved in
in the workspace.

=cut

# A variable that will be maintained across iterative parsings
# of the log, but will not be maintained across logparser invocations
sub workspace {
  my $self = shift;
  $self->{workspace} = shift if (@_);
  return $self->{workspace};
}

=head2 properties

Permits to retrieve or set the properties of the object as in

 print "properties: ".$self->properties;

or

 $self->properties(\%myproperties);

The properties of an object are the key/value pairs that will
be stored in the B<propertiesFile> of the B<logparser.conf>
file.

=cut

# The properties that should be set in the output file
sub properties {
  my $self = shift;
  $self->{properties} = shift if (@_);
  return $self->{properties};
}

=head2 logger

Permits to retrieve or set the logger of the object as in

 print $self->logger->debug("debug message");

or

 $logger = Log::Log4perl->get_logger(LOG_TAG);
 $self->logger($logger);

=cut

# Sets the logger object to allow for logging
sub logger {
  my $self = shift;
  $self->{logger} = shift if (@_);
  return $self->{logger};
}


=head2 evalBegin

This method is usually overriden in the child class.
This method will be invoked before any line of the
file is parsed.

Typically counters will be initialised here if they
have not been initialised before:

  $self->{savespace}{counter} = 0 if (!exists($self->{savespace}{counter}));

=cut

# This will be invoked before the first parsing of the log
sub evalBegin {
  my $self = shift;
  $self->{savespace}{counter} = 0 if (!exists($self->{savespace}{counter}));
}

=head2 evalIterate

This method is usually overriden in the child class.
This method will be invoked for each line of the 
log that should be parsed.

It receives as an argument the line of the log to be parsed.

One typical implementation could be:

 sub evalIterate {
  my $self = shift;
  my ($line) = @_;
  my $pattern = $self->{pattern};
  if ($line =~ /$pattern/) {
    $self->{savespace}{counter} ++;
  }
 }


=cut

# This will be invoked whenever the pattern matches
# the log line parsed
# Input:
# - The line to be parsed
# Output:
# - 1 if the line has matched the regular expression and 0 otherwise
sub evalIterate {
  my $self = shift;
  my ($line) = @_;
  my $pattern = $self->{pattern};
  if ($line =~ /$pattern/) {
    $self->{savespace}{counter} ++;
  }
}

=head2 evalEnd

This method is usually overriden in the child class.
This method will be invoked after all the lines
have been parsed.

Typically the properties elements will be initialised here

=cut

# This will be invoked after the last log line has been parsed
sub evalEnd {
  my $self = shift;
  $self->properties($self->savespace());
}

1;


=head1 REQUIREMENTS AND LIMITATIONS

=head1 BUGS

=head1 TODO

=over 8

=item * document logger.

=back

=head1 SEE ALSO

=head1 AUTHOR

Nito at Qindel dot ES -- 7/9/2006

=head1 COPYRIGHT & LICENSE

Copyright 2007 by Qindel Formacion y Servicios SL, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
