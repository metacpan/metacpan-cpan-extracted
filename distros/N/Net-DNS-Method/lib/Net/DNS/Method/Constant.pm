package Net::DNS::Method::Constant;

use strict;
use warnings;
use Net::DNS;
use Net::DNS::Method;
use vars qw($VERSION @ISA $AUTOLOAD);

@ISA = qw(Net::DNS::Method);

$VERSION = '2.00';

sub new {
    my $type	= shift;
    my $class	= ref($type) || $type || "Net::DNS::Method::Constant";

    my $self = 
    {
	zone	=> lc shift,
	class	=> uc shift,
	type	=> uc shift,
	rr	=> shift
    };

    $self->{zone} =~ s/\.+$//;

    bless $self, $class;
}

sub _match {
    my $q = lc shift;
    my $d = shift;

    $q =~ s/\.+$//;

    my $pos	= index($q, $d);

    return 1 if $q eq $d;
    return 1 if $pos == 0 and (length($q) <= length($d));
    return 1 if substr($q, $pos - 1, 1) eq '.';
    return 0;
}

sub ANY {
    my $self	= shift;
    my $q	= shift;
    my $ans	= shift;

    if ($q->qclass eq $self->{class}
	and ($q->qtype eq $self->{type}
	     or $q->qtype eq 'ANY')
	and _match($q->qname, $self->{zone}))
    {
	my $rr = new Net::DNS::RR $q->qname . ' ' .$self->{rr};
	if ($rr) {
	    $ans->push('answer', $rr);
	    $ans->header->rcode('NOERROR');
	    $ans->header->aa(1);
	    return NS_OK | NS_STOP;
	}

	warn "Net::DNS::Method::Constant failed to produce an RR to answer ",
	$q->qname, "\n";

    }
    return NS_FAIL;
}

sub AUTOLOAD {
    no strict 'refs';
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;

				# Insure that the called method has an all
				# uppercase name. This avoids any clash with
				# future extensions for these handlers, which
				# will use mixed case or lowercase.

    return NS_FAIL unless $sub eq uc $sub;
    return undef if $sub eq 'DESTROY';

    *$sub = sub { ANY @_; };
    goto &$sub;
}

1;
__END__

=head1 NAME

Net::DNS::Method::Constant - Provides constant answers to queries

=head1 SYNOPSIS

  use Net::DNS::Method;
  use Net::DNS::Method::Constant;

  my $c = new Net::DNS::Method::Constant ('domain.com', 'IN', 'A', 
					  'IN A 127.0.0.1');

=head1 DESCRIPTION

For any question matching the domain, class and type supplied, this
module responds with an authoritative answer containing the specified
RR.

The response RR will be built using the partial data passed as the
fourth parameter to C<-E<gt>new()>. The query name will be used to
build a L<Net::DNS::RR> object, which will be put in the answer
section of the response.

=head1 HISTORY

$Id: Constant.pm,v 1.2 2002/10/23 04:43:58 lem Exp $

=over

=item 1.00  Fri May  4 13:54:19 2001

=over

=item *

original version; created by h2xs 1.19

=back

=item 2.00 Tue Oct 22, 13:55:00 2002

=over

=item *

Repackaged for distribution

=item *

Use of C<AUTOLOAD> to support any RR that L<Net::DNS> supports. Note
that only uppercase names are dynamically created, as this is assumed
to be the name of an RR.

=back

=back

=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), L<Net::DNS>, L<Net::DNS::RR>, L<Net::DNS::Method>.

=cut
