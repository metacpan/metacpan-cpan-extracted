package Net::AIM::Event;

#
# $Revision: 1.11 $
# $Author: aryeh $
# $Date: 2001/06/04 17:03:08 $
#

use strict;
my %_names;
=pod

=head1 NAME

Net::AIM::Event - Object to hold event data

=head1 SYNOPSIS

=head1 DESCRIPTION

This module holds data about an event which is any instruction we get from the server.

=head1 METHODS

=over 4

=cut

# Constructor method for Net::AIM::Event objects.
# Takes at least 4 args:  the type of event
#                         the person or server that initiated the event
#                         the recipient(s) of the event, as arrayref or scalar
#                         the name of the format string for the event
#            (optional)   any number of arguments provided by the event
=pod

=item Net::AIM::Event->new($type, $from, $to, @args)

Net::AIM::Event constructor.  Takes 4 args
   * The type of event
   * The originator (screenname or server)
   * To/Destination (us - remnants from IRC module days...)
   * @ARGS

=cut
sub new {
   my $class = shift;

   my $self = { 'type'   =>  $_[0],
	 'from'   =>  $_[1],
	 'to'     =>  $_[2],
	 'args'   =>  [ @_[3..$#_] ],
   };
    
   bless $self, $class;
    
   # Take your encapsulation and shove it!
   if ($self->{'type'} !~ /\D/) {
      $self->{'type'} = $self->trans($self->{'type'});
   } else {
      $self->{'type'} = lc $self->{'type'};
   }

   $self->args(@{$self->{'args'}});  # strips colons from args
    
   return $self;
}

=pod

=item $aim_event->dump()

Print the event to STDERR good for debugging

=cut
sub dump {
   my ($self, $arg, $counter) = (shift, undef, 0);   # heh heh!

   printf STDERR "TYPE: %-30s    FORMAT: %-30s\n",
      $self->{'type'}, $self->{'format'};
   print STDERR "FROM: ", $self->{'from'}, "\n";
   print STDERR "TO: ", join(", ", @{$self->{'to'}}), "\n";
   print STDERR "Args:\n";
   foreach $arg (@{$self->{'args'}}) {
      print STDERR "\t", $counter++, ": ", $arg, "\n";
   }
   print STDERR "\n";
}


# Sets or returns the format string for this event.
# Takes 1 optional arg:  the new value for this event's "format" field.
sub format {
    my $self = shift;

    $self->{'format'} = $_[0] if @_;
    return $self->{'format'};
}

=pod

=item $aim_event->args(@args)

Sets the event's argument list to @args if it is provided.
Otherwise it returns the event's argument list.

=cut
sub args {
   my $self = shift;

   if (@_) {
      $self->{'args'} =  [@_];
   }

   return $self->{'args'};
}

=pod

=item $aim_event->from($from)

Sets the originator of this event if $from is provided. 
Otherwise it returns the event's originator.  Usually either a ScreenName|Server

=cut
sub from {
    my $self = shift;
    $self->{'from'} = $_[0] if @_;

    return $self->{'from'};
}

=pod

=item $aim_event->to(@to)

Sets the recipients of this event if @to is provided. 
Otherwise it returns the event's recipient list.

=cut
sub to {
    my $self = shift;
    
    $self->{'to'} = [ @_ ] if @_;
    return $self->{'to'};
}

=pod

=item $aim_event->trans($error_code)

This method takes a numeric $error_code and returns a string representing the definition of the error code, or undef if the $error_code is unknown.

=cut

sub trans {
    shift if (ref($_[0]) || $_[0]) =~ /^Net::AIM/;
    my $ev = shift;
    
    return (exists $_names{$ev} ? $_names{$ev} : undef);
}

=pod

=item $aim_event-E<gt>type($type)

Sets the type of this event if $type is provided. 
Otherwise it returns the event's type.

=cut

sub type {
    my $self = shift;
    
    $self->{'type'} = $_[0] if @_;
    return $self->{'type'};
}

%_names = (
# AIM ERRORS
   901   => '$0 not currently available',
   902   => 'Warning of $0 not currently available',
   903   => 'A message has been dropped, you are exceeding the server speed limit',
#   * Chat Errors  *',
   950   => 'Chat in $0 is unavailable.',

#   * IM & Info Errors *',
   960   => 'You are sending message too fast to $0',
   961   => 'You missed an im from $0 because it was too big.',
   962   => 'You missed an im from $0 because it was sent too fast.',

#   * Dir Errors *',
   970   => 'Failure',
   971   => 'Too many matches',
   972   => 'Need more qualifiers',
   973   => 'Dir service temporarily unavailable',
   974   => 'Email lookup restricted',
   975   => 'Keyword Ignored',
   976   => 'No Keywords',
   977   => 'Language not supported',
   978   => 'Country not supported',
   979   => 'Failure unknown $0',

#  * Auth errors *',
   980   => 'Incorrect nickname or password.',
   981   => 'The service is temporarily unavailable.',
   982   => 'Your warning level is currently too high to sign on.',
   983   => 'You have been connecting and disconnecting too frequently.  Wait 10 minutes and try again.  If you continue to try, you will need to wait even longer.',
   989   => 'An unknown signon error has occurred $0'
);

"Aryeh Goldsmith";
__END__

=pod

=head1 AUTHOR

Aryeh Goldsmith E<lt>perlaim@aryeh.netE<gt>.

=head1 URL

The Net::AIM project:
http://www.aryeh.net/Net-AIM/


The Net::AIM bot list:
http://www.nodoubtyo.com/aimbots/

=head1 SEE ALSO

perl(1)

=cut
