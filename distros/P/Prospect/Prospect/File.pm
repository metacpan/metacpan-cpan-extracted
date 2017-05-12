# Prospect::File
# $Id: File.pm,v 1.14 2003/11/07 00:45:28 cavs Exp $
# @@banner@@

=head1 NAME

Prospect::File -- interface to Prospect Files

S<$Id: File.pm,v 1.14 2003/11/07 00:45:28 cavs Exp $>

=head1 SYNOPSIS

 use Prospect::File;

 my $pf = new Prospect::File( $fn );

 while( my $t = $pf->next_thread() ) {
   printf("%s->%s   raw=%d mut=%d pair=%d\n",
      $t->qname(), $t->tname(), $t->raw_score(), 
      $t->mutation_score(), $t->pair_score() );
   print $t->alignment();
 }

=head1 DESCRIPTION

Prospect::File is a subclass of IO::File and is intended
for use for parsing Prospect XML files.  It is used by 
Prospect::LocalClient to return Thread objects from
Prospect output.

=cut


package Prospect::File;

# ISA:
use base IO::File;

use strict;
use warnings;
use Carp;
use Prospect::Thread;
use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.14 $ =~ /(\d+)\.(\d+)/ );



=pod

=head1 METHODS

=cut

#-------------------------------------------------------------------------------
# new()
#-------------------------------------------------------------------------------

=head2 new()

 Name:      new()
 Purpose:   constructor
 Arguments: 
 Returns:   Prospect::File

=cut

sub new {
  my $class = shift;
  my $self = $class->SUPER::new( @_ );
}


#-------------------------------------------------------------------------------
# fdopen()
#-------------------------------------------------------------------------------

=head2 fdopen()

 Name:      fdopen()
 Purpose:   overrides fdopen in IO::File
 Arguments: same as IO::File::fdopen
 Returns:   nothing

=cut

sub fdopen {
  my $self = shift;
  my $rv = $self->SUPER::fdopen( @_ );
  if (not $self->_advance()) {
    throw Prospect::RuntimeError("file doesn't look like a Prospect XML file\n");
  }
  return 1;
}


#-------------------------------------------------------------------------------
# open()
#-------------------------------------------------------------------------------

=head2 open()

 Name:      open()
 Purpose:   overrides open in IO::File
 Arguments: same as IO::File::open
 Returns:   nothing

=cut

sub open {
  my $self = shift;
  my $rv = $self->SUPER::open( @_ );
  if (not $self->_advance()) {
    throw Prospect::RuntimeError("file doesn't look like a Prospect XML file\n");
  }
  return 1;
}




#-------------------------------------------------------------------------------
# next_thread()
#-------------------------------------------------------------------------------

=head2 next_thread()

 Name:      next_thread()
 Purpose:   return next Thread object
 Arguments: none
 Returns:   Prospect::Thread

=cut

sub next_thread {
  my $self = shift;

  my $xml = $self->next_thread_as_xml();
  return unless defined $xml;

  return( new Prospect::Thread( $xml ) );
}


#-------------------------------------------------------------------------------
# next_thread_as_xml()
#-------------------------------------------------------------------------------

=head2 next_thread_as_xml()

 Name:      next_thread_as_xml()
 Purpose:   return next threading xml tag
 Arguments: none
 Returns:   xml string

=cut

sub next_thread_as_xml {
  my $self = shift;
  local $/ = '</threading>';
  my $retval = $self->SUPER::getline();
  if ( !defined $retval or
    $retval !~ m/<threading/ ) {
     return();
  } else {
    return( $retval );
  }
}


#---------------------------------------------
# INTERNAL METHODS
#---------------------------------------------

#-------------------------------------------------------------------------------
# _advance()
#-------------------------------------------------------------------------------

=head2 fdopen()

 Name:      _advance()
 Purpose:   INTERNAL METHOD: check if proper Prospect xml
 Arguments: none
 Returns:   1 - okay, 0 - bad xml

=cut

sub _advance {
  my $self = shift;
  my $firstline = $self->getline();
  return( (defined $firstline) and ($firstline =~ m/^<prospectOutput>/) );
}


1;
