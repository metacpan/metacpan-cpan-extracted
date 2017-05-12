# File:     $Source: /Users/clajac/cvsroot//Scripting/Scripting/Event.pm,v $
# Author:   $Author: clajac $
# Date:     $Date: 2003/07/21 10:10:05 $
# Revision: $Revision: 1.5 $

package Scripting::Event;
use strict;

use constant GLOBAL_NAMESPACE => "_Global";

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT = qw();
our @EXPORT_OK = qw(GLOBAL_NAMESPACE);
our %EXPORT_TAGS = (
		    constants => [qw(GLOBAL_NAMESPACE)],
		   );

my %Events;

sub new {
  my $pkg = shift;
  $pkg = ref $pkg || $pkg;
  my %args = (
	      namespace => GLOBAL_NAMESPACE,
	      @_,
	     );
    
  my $self = bless {
		   }, $pkg;

  return $self;
}

sub has_event {
  my ($pkg, $ns, $event) = @_;

  return exists $Events{"$ns/$event"};
}

sub remove_event {
  my ($pkg, $ns, $event) = @_;

  delete $Events{"$ns/$event"};
}

sub add_event {
  my ($pkg, $ns, $event, $cb) = @_;

  $Events{"$ns/$event"} = $cb;
}

sub invoke {
  my $self = shift;

  my ($ns, $event);
  if(@_ == 1) {
    $ns = GLOBAL_NAMESPACE;
    $event = shift;
  } elsif(@_ == 2) {
    ($ns, $event) = @_;
  } else {
    die "Bad number of arguments\n";
  }

  return unless $self->has_event($ns, $event);
  $Events{"$ns/$event"}->()
}

1;
