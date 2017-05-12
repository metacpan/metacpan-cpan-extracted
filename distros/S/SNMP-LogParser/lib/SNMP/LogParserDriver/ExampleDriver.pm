#
# $Id: ExampleDriver.pm 14990 2012-04-10 12:57:24Z rporres $
#
# A bit more complicated class
#
# Nito@Qindel.ES -- 7/9/2006
package SNMP::LogParserDriver::ExampleDriver;
use strict;
use warnings;
use parent 'SNMP::LogParserDriver';

=head1 NAME

SNMP::LogParserDriver::ExampleDriver

=head1 SYNOPSIS

This is an example Driver class to check for strings in the log file
of the form "test string". Every time that this string is found
the variable "counter" is incremented.


=head1 DESCRIPTION

Here we show each of the functions

=head2 new

New is just a passthrough to the parent class

 sub new {
   my $class = shift;
   my $self  = $class->SUPER::new();
   bless ($self, $class);
   return $self;
 }

=cut

sub new {
  my $class = shift;
  my $self  = $class->SUPER::new();
  bless ($self, $class);
  return $self;
}


=head2 evalBegin

Here we initialize the "counter" variable. We declare it in the 
"savespace" hash so that it is persistent across run invocations
of logparser

 sub evalBegin {
   my $self = shift;  
   $self->{savespace}{counter} = 0 if (!defined($self->{savespace}{counter}));
   $self->{savespace}{lines} = 0 if (!defined($self->{savespace}{counter}));
 }

=cut

# This will be invoked before the first parsing of the log
sub evalBegin {
  my $self = shift;
  
  $self->{savespace}{counter} = 0 if (!defined($self->{savespace}{counter}));
  $self->{savespace}{lines} = 0 if (!defined($self->{savespace}{lines})); 
}

=head2 evalIterate

Here we parse each line, incrementing the counter value if it matches the
string (we also keep track of lines) 

 sub evalIterate {
   my $self = shift;
   my ($line) = @_;
   $self->{savespace}{lines} ++;
   if ($line =~ /test string/g) {
      $self->{savespace}{counter} ++;
   }
 }

=cut

sub evalIterate {
  my $self = shift;
  my ($line) = @_;
  $self->{savespace}{lines} ++;
  if ($line =~ /test string/g) {
      $self->{savespace}{counter} ++;
  }
}

=head2 evalEnd

Here we tell the system that we want to output on the properties file
all the variables in the save space...

 sub evalEnd {
   my $self = shift;
   $self->properties($self->savespace);
 }

=cut

sub evalEnd {
  my $self = shift;
  $self->properties($self->savespace);
}

1;
=head1 REQUIREMENTS AND LIMITATIONS

=head1 OPTIONS

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
