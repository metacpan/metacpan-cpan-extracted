#  $Id: Event.pm 424 2008-08-19 16:27:43Z duncan $

## @file
# Define the Event class
#

## @class Event

package OpenGL::QEng::Event;

use strict;
use warnings;

#
## Example:
#
#Say you want to watch for the event 'doorbell' and handle it with the
#subroutine 'answer_door' in the package/module 'Butler':
#
#in the file that contains 'answer_door', register the 'answer_door' sub
#as a callback to handle the 'doorbell' event (typically in 'new')
#
#package Butler;
#<pre>
# @fn $ new
#sub new {
#  my ($class) = @_;
#  my $self = { event => Event->new,
#               ...
#             };
#
#  ...
#  bless($self, $class);
#
#  $self->{event}->callback($self,'doorbell',\&answer_door,@anystuff);
#  return $self;
#}
#
#
#sub answer_door \{
#  my ($self,  # me, duh
#      $stash, # [@anystuff] -- mostly unused
#      $obj,   # who sent the event
#      $ev,    # the event, most likely 'doorbell'
#      @arg    # anything else the event sender sent
#              # ("Domino's",'1 Large',12.95)
#     ) = @_;
#
#  #well, answer it!
#}
#
#--------------------------------------------------------
#some other code:
#
#...
#$self->send_event('doorbell',"Domino's",'1 Large',12.95);
#</pre>
#

#------------- Package Lexical Variables -------------------------------
my %existing_loops;

#-------------   Class Methods    -------------------------------

## @cmethod Event new()
# Create a new Event
sub new {
  my ($class, $loop_name) = @_;
  $loop_name ||= $class;

  return $existing_loops{$loop_name} if (defined $existing_loops{$loop_name});

  my $self = {name     => $loop_name,
	      notify   => {},
	      callback => {},
	      cwho     => {},
	     };
  $existing_loops{$loop_name} = bless($self,$class);
}

#-------------  instance methods  ----------------------------

## @method $  callback($self, $obj, $trigger_ev, $coderef, @args)
# register a "permanent" callback
sub callback {
  my ($self,$obj,$trigger_ev,$coderef,@rest) = @_;

  #check to see if we already registered this callback
  if (exists $self->{callback}{$trigger_ev}) {
    for my $cb (@{$self->{callback}{$trigger_ev}}) {
      return 1 if ($cb->[0] eq $obj && $cb->[1] == $coderef);
    }
  }

  # ok, go ahead and register it
  $self->{callback}{$trigger_ev} = []
    unless defined ($self->{callback}{$trigger_ev});
  unshift(@{$self->{callback}{$trigger_ev}},[$obj,$coderef,@rest]);

  $self->{cwho}{$obj} = [] unless defined ($self->{cwho}{$obj});
  push(@{$self->{cwho}{$obj}},$trigger_ev);
  1;
}

## @method $ notify($self, $obj, $trigger_ev, $coderef, @rest)
# register a "one-shot" callback
sub notify {
  my ($self,$obj,           $trigger_ev,$coderef,@rest) = @_;

  $self->{notify}{$trigger_ev} = []
    unless defined ($self->{notify}{$trigger_ev});
  push(@{$self->{notify}{$trigger_ev}},     [$obj,$coderef,@rest]);
}

#------------------------------------------------------------
# take out any callbacks I registered
#
sub remove_events_for {
  my ($self,$obj) = @_;

  for my $trigger_ev (@{$self->{cwho}{$obj}}) {
    my $cb = [];
    while (my $ocb = shift @{$self->{callback}{$trigger_ev}}) {
      if ($ocb->[0] eq $obj) {
	# throw it away
      } else {
	push(@$cb,$ocb);
      }
    }
    $self->{callback}{$trigger_ev} = $cb;
  }
}

#--------------------------
## @method $ yell([$self,$obj,$ev,@args])
#
#Instance Method to Send an event
#Normally invoked by a local method of the form:
#sub send_event { $_[0]->{event}->yell(@_) }
#
sub yell {			# caller is sending an event
  my ($self,$obj,$ev,@arg) = @_;

  #do these once, and toss 'em
  # FIFO
  my $notified;

  if (defined $self->{notify}{$ev}) {
    $notified = 1;
    while (my $stash = shift @{$self->{notify}{$ev}}) {
      my $orgself = shift @{$stash};
      my $coderef = shift @{$stash};
      $coderef->($orgself,$stash,$obj,$ev,@arg);
    }
  }
  #do these every time
  # LIFO
#warn $ev;
  if (defined $self->{callback}{$ev}) {
    for my $stash (@{$self->{callback}{$ev}}) {
      my @stash = @{$stash}; #must make a copy
      my $self    = shift @stash;
      my $coderef = shift @stash;
	# leftover??? if ($ev ne 'msg' && $ev ne 'step');
      $coderef->($self,\@stash,$obj,$ev,@arg);
    }
  } else {
    my @caller = caller();
    my $called =join('::',@caller);
    warn "Unhandled event '$ev' on $obj @arg from $called"
      if !$notified  && $ENV{WIZARD};
  }
  $notified || defined($self->{callback}{$ev});
}
#------------------------------------------------------------------------------

###############################################################################
1;

__END__

=head1 NAME

Event -- publish/subscribe style event mechanism

=head1 AUTHORS

John D. Overmars E<lt>F<overmars@jdovermarsa.com>E<gt>,
and Rob Duncan E<lt>F<duncan@jdovermarsa.com>E<gt>

=head1 COPYRIGHT

Copyright 2008 John D. Overmars and Rob Duncan, All rights reserved.

=head1 LICENSE

This is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

