# Author Chris "BinGOs" Williams
# Cribbed the regexps from Net::Ident by Jan-Pieter Cornet
#
# This module may be used, modified, and distributed under the same
# terms as Perl itself. Please see the license that came with your Perl
# distribution for details.
#

package POE::Filter::Ident;

use strict;
use warnings;
use Carp;
use vars qw($VERSION);

$VERSION = '1.16';

sub new {
  my $class = shift;
  my %args = @_;
  $args{lc $_} = delete $args{$_} for keys %args;
  bless \%args, $class;
}


# Set/clear the 'debug' flag.
sub debug {
  my $self = shift;
  $self->{'debug'} = $_[0] if @_;
  return $self->{'debug'};
}


sub get {
  my ($self, $raw) = @_;
  my $events = [];

  foreach my $line (@$raw) {
    warn "<<< $line\n" if $self->{'debug'};
    next unless $line =~ /\S/;

    my ($port1, $port2, $replytype, $reply) =
      $line =~
       /^\s*(\d+)\s*,\s*(\d+)\s*:\s*(ERROR|USERID)\s*:\s*(.*)$/;

    SWITCH: {
      unless ( defined $reply ) {
        push @$events, { name => 'barf', args => [ 'UKNOWN-ERROR' ] };
        last SWITCH;
      }
      if ( $replytype eq 'ERROR' ) {
	my ($error);
	( $error = $reply ) =~ s/\s+$//;
	push @$events, { name => 'error', args => [ $port1, $port2, $error ] };
        last SWITCH;
      } 
      if ( $replytype eq 'USERID' ) {
	my ($opsys, $userid);
	unless ( ($opsys, $userid) =
		 ($reply =~ /\s*((?:[^\\:]+|\\.)*):(.*)$/) ) {
	    # didn't parse properly, abort.
            push @$events, { name => 'barf', args => [ 'UKNOWN-ERROR' ] };
            last SWITCH;
	}
	# remove trailing whitespace, except backwhacked whitespaces from opsys
	$opsys =~ s/([^\\])\s+$/$1/;
	# un-backwhack opsys.
	$opsys =~ s/\\(.)/$1/g;

	# in all cases is leading whitespace removed from the username, even
	# though rfc1413 mentions that it shouldn't be done, current
	# implementation practice dictates otherwise. What insane OS would
	# use leading whitespace in usernames anyway...
	$userid =~ s/^\s+//;

	# Test if opsys is "special": if it contains a charset definition,
	# or if it is "OTHER". This means that it is rfc1413-like, instead
	# of rfc931-like. (Why can't they make these RFCs non-conflicting??? ;)
	# Note that while rfc1413 (the one that superseded rfc931) indicates
	# that _any_ characters following the final colon are part of the
	# username, current implementation practice inserts a space there,
	# even "modern" identd daemons.
	# Also, rfc931 specifically mentions escaping characters, while
	# rfc1413 does not mention it (it isn't really necessary). Anyway,
	# I'm going to remove trailing whitespace from userids, and I'm
	# going to un-backwhack them, unless the opsys is "special".
	unless ( $opsys =~ /,/ || $opsys eq 'OTHER' ) {
	    # remove trailing whitespace, except backwhacked whitespaces.
	    $userid =~ s/([^\\])\s+$/$1/;
	    # un-backwhack
	    $userid =~ s/\\(.)/$1/g;
	}
	push @$events, { name => 'reply', args => [ $port1, $port2, $opsys, $userid ] };
	last SWITCH;
      }
      # If we fell out here then it is probably an error
      push @$events, { name => 'barf', args => [ 'UKNOWN-ERROR' ] };
    }
  }

  return $events;
}


# This sub is so useless to implement that I won't even bother.
sub put {
  croak "Call to unimplemented subroutine POE::Filter::Ident->put()";
}


1;


__END__

=head1 NAME

POE::Filter::Ident -- A POE-based parser for the Ident protocol.

=head1 SYNOPSIS

    my $filter = POE::Filter::Ident->new();
    my @events = @{$filter->get( [ @lines ] )};

=head1 DESCRIPTION

POE::Filter::Ident takes lines of raw Ident input and turns them into
weird little data structures, suitable for feeding to
POE::Component::Client::Ident::Agent. They look like this:

    { name => 'event name', args => [ some info about the event ] }

=head1 CONSTRUCTOR

=over

=item C<new>

Creates a new POE::Filter::Ident object. Takes no arguments.

=back

=head1 METHODS

=over

=item C<get>

Takes an array reference full of lines of raw Ident text. Returns an
array reference of processed, pasteurized events.

=item C<put>

There is no "put" method. That would be kinda silly for this filter,
don't you think?

=item C<debug>

Pass true/false value to enable/disable debugging information.

=back

=head1 AUTHOR

Dennis "fimmtiu" Taylor, E<lt>dennis@funkplanet.comE<gt>.

Hacked for Ident by Chris "BinGOs" Williams E<lt>chris@Bingosnet.co.ukE<gt>

Code for parsing the the Ident messages from Net::Ident by Jan-Pieter Cornet.

=head1 LICENSE

Copyright E<copy> Chris Williams, Dennis Taylor and Jan-Pieter Cornet.

This module may be used, modified, and distributed under the same terms as Perl itself. Please see the license that came with your Perl distribution for details.

=head1 SEE ALSO

L<Net::Ident>

=cut
