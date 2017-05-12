package Net::DNS::Method::Status;

require 5.005_62;
use Carp;
use strict;
use warnings;

use Net::DNS;
use Net::DNS::Method;

use vars qw(@ISA $VERSION $AUTOLOAD);

@ISA = qw(Net::DNS::Method);

$VERSION = '2.00';

				# Default responses
our $DEF_ZONE	= 'some.com';
our $DEF_RSET	= 'reset';
our $DEF_SIZE	= 10;

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Net::DNS::Method::Status";

    my $ref = shift;

    my $self = 
    {
	start => time,
	qs => [],
	zone => (defined($ref) && defined($ref->{BaseDomain}) ? 
		 lc $ref->{BaseDomain} : $DEF_ZONE),
	reset => (defined($ref) && defined($ref->{Reset}) ? 
		  lc $ref->{Reset} : $DEF_RSET),
	count => (defined($ref) && defined($ref->{StoreResults}) ? 
		  $ref->{StoreResults} : $DEF_SIZE),
	};
    
    bless $self, $class;

    return $self->_reset;
}

sub _reset {
    my $self = shift;
    $self->{counter} = {};
    $self->{time} = time;
    return $self;
}

sub _any {
    my $self = shift;
    my $q = shift;
    my $ans = shift;
    my $data = shift;

    unshift @{$self->{qs}}, $data->{from}->addr . 
	'->' . $q->qclass . ' ' . $q->qtype . ' ' . 
	    $q->qname;

    pop @{$self->{qs}} if @{$self->{qs}} > $self->{count};

    $self->{counter}->{$q->qtype}++;

    return NS_FAIL;
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

sub TXT {
    my $self = shift;

    $self->_any(@_);		# Account this question...
    
    my $q = shift;
    my $ans = shift;

    if (_match($q->qname, $self->{zone})) {

#	warn "matched ", $q->qname, "\n";

	$self->{counter}->{$q->qtype} --;

	my $total = 0;
	my $age = time - $self->{start} || 1;
	my $time = time - $self->{time} || 1;

	$ans->push('answer', new Net::DNS::RR $q->qname . " 0 IN TXT OK");

	if (index($q->qname, $self->{reset}) == 0) {
	    $self->_reset;
	}
	else {
	    $ans->push('additional', new Net::DNS::RR 'pid.' . $self->{zone}
		       . " 0 IN TXT $$");
	    $ans->push('additional', new Net::DNS::RR 'started.' . 
		       $self->{zone} . " 0 IN TXT " . $age);
	    $ans->push('additional', new Net::DNS::RR 'last.' . $self->{zone}
		       . " 0 IN TXT " . $time);

	    foreach my $qt (sort keys %{$self->{counter}}) {
		$total += $self->{counter}->{$qt};
		$ans->push('additional', new Net::DNS::RR $qt . '.q.' . 
			   $self->{zone} . " 0 IN TXT " . 
			   $self->{counter}->{$qt});
	    }

	    $ans->push('additional', new Net::DNS::RR 'total.q.' . 
		       $self->{zone} . " IN TXT " . $total);
	    
	    $ans->push('additional', new Net::DNS::RR 'qps.q.' . 
		       $self->{zone} . " IN TXT " . 
		       sprintf("%.04f", $total / $time) . " q/sec");

	    my $ord = 0;
	    for my $qs (@{$self->{qs}}) {
		$ans->push('additional', new Net::DNS::RR 'q' . $ord . '.' 
			   . $self->{zone} . " IN TXT " . 
			   $qs);
		++ $ord;
	    }

	}

	$ans->header->rcode('NOERROR');
#	warn "NS_OK | NS_STOP\n";
	return NS_OK | NS_STOP;
    }

#    warn "NS_FAIL\n";
    return NS_FAIL;		# No match or error
}

sub ANY { TXT @_ };

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;

				# Insure that the called method has an all
				# uppercase name. This avoids any clash with
				# future extensions for these handlers, which
				# will use mixed case or lowercase.

    return undef if $sub eq 'DESTROY';
    return NS_FAIL unless $sub eq uc $sub;

    *$sub = sub { _any @_; };
    goto &$sub;
}


1;

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Net::DNS::Method::Status - Perl extension to provide status of the DNS server

=head1 SYNOPSIS

  use Net::DNS::Method::Status;

  my $Status = new Net::DNS::Method::Status { BaseDomain => 'status.x.com',
					      StoreResults => 10,
					      Reset => 'reset'
					  };


=head1 DESCRIPTION

This class adds support for returning a number of variables regarding
the operation of the DNS server. Variables are returned as a number of
IN TXT RRs.

=head2 EXPORT

None by default.


=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.20 with options

  -ACOXfn
	Net::DNS::Method::Status
	-v
	1.00

=item 1.10

Added the storage of the last 'StoreResults' DNS queries. Stats can
now be reset by querying 'Reset' under 'BaseDomain'.

=item 1.11

Minor change for compatibility with NetAddr::IP 3.00.

=item 2.00

=over

=item *

Repackaged for public release

=item *

Use C<AUTOLOAD> to automatically support all RRs supported by L<Net::DNS>.

=back

=back


=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), Net::DNS::Method(3), L<Net::DNS>.

=cut
