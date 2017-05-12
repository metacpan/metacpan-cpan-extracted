package Net::DNS::Method::Hash;

require 5.005_62;
use strict;
use warnings;

use Carp;
use Net::DNS;
use Net::DNS::Method;
use vars qw($VERSION @ISA $AUTOLOAD);

@ISA = qw(Net::DNS::Method);

$VERSION = '2.00';

				# Default responses
our $DEF_ZONE	= 'some.com';

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Net::DNS::Method::Hash";

    my $ref = shift;

    croak "Argument to new() must be a reference to a hash\n"
	if (ref $ref ne 'HASH');

    my $self = 
    {
	zone => (defined($ref) && defined($ref->{BaseDomain}) ? 
		 lc $ref->{BaseDomain} : $DEF_ZONE),
	hash => (defined($ref) && defined($ref->{Hash}) ? 
		 $ref->{Hash} : {}),
	};
    
    return bless $self, $class;
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

    if (_match($q->qname, $self->{zone})) {

#	warn "match ", $q->qname, "\n";

	my $ip = lc substr($q->qname, 0, index($q->qname, $self->{zone}) - 1);

#	warn "lookup of <$ip>\n";

	my $name = $q->qname;
	$name =~ s/\.+$//;

	if (exists  $self->{hash}->{$ip}
	    or exists $self->{hash}->{$name}
	    or exists $self->{hash}->{$name . "."}) 
	{

#	    warn "found ", $q->qname, "\n";

				# In this case, we should try to answer
				# this question...

	    my $answers = 0;

#	    warn "question ", $q->qname, " resolves to $ip\n";
#	    warn "class ", $q->qclass, "\n";
#	    warn "type ", $q->qtype, "\n";

	    my $set = $self->{hash}->{$ip} 
	    || $self->{hash}->{$name} 
	    || $self->{hash}->{$name . "."};

	    if (!ref $set) {
		$set = [ $set ];
	    }
	    
	    for my $data (@{$set}) {
		my $rr = new Net::DNS::RR $q->qname . " " . $data;
		
#		warn "Check against rr type=", $rr->type, " class=", 
#		$rr->class, "\n";
		
		if (($q->qtype eq 'ANY' or $rr->type eq $q->qtype) 
		    and $rr->class eq $q->qclass) 
		{
		    $ans->push('answer', $rr);
		    ++ $answers;
		}
	    }
	
	    if ($answers) {	# If we have something to say, we
				# return success...

		$ans->header->rcode('NOERROR');
		return NS_OK | NS_STOP;
	    }
	}
    }

#    warn "NS_FAIL\n";
    return NS_FAIL;
}

sub AUTOLOAD {
    my $sub = $AUTOLOAD;
    $sub =~ s/.*:://;

				# Insure that the called method has an all
				# uppercase name. This avoids any clash with
				# future extensions for these handlers, which
				# will use mixed case or lowercase.

    return undef if $sub eq 'DESTROY';
    return NS_FAIL unless $sub eq uc $sub;

    *$sub = sub { ANY @_; };
    goto &$sub;
}

1;
__END__

=head1 NAME

Net::DNS::Method::Hash - Perl extension to provide static mapping of RRs to IP addresses

=head1 SYNOPSIS

  use Net::DNS::Method::Hash;

  my $Hash = new Net::DNS::Method::Hash { BaseDomain => 'hashdomain.com',
					  Hash => $ref_to_hash,
					  };


=head1 DESCRIPTION

This class supports the specification of large amounts of RRs under
the zone specified as the C<BaseDomain> option. The RRs have the
generic form

    <key>.<BaseDomain> <RR DATA>
    <key> <RR DATA>

for example,

    key-to-the-hash.hashdomain.com 30 IN TXT "Some weird host"

would be produced by a hash such as

    { 'key-to-the-hash' => '30 IN TXT "Some weird host"', }

The RRs are specified using a reference to a hash whose left-hand side
is the name of the RR and its right-hand side is either the RR data to
be fed to Net::DNS::RR or a reference to a list of RR data strings.

Only RRs of matching type will be returned to a DNS query, with the
exception of an 'ANY' query, for which all available RRs will be
returned.

=head2 EXPORT

None by default.


=head1 HISTORY

$Id: Hash.pm,v 1.2 2002/10/23 04:43:58 lem Exp $

=over

=item 1.00

Original version; created by h2xs 1.20 with options

  -ACOXfn
	Net::DNS::Method::Hash
	-v
	1.00

=item 1.01

Modified the match, to make it lookup the name with or without the domain.

=item 2.00

=over

=item * 

Merging for first public distribution.

=item *

Used C<AUTOLOAD> to automatically support all the RRs that L<Net::DNS>
supports.

=back

=back

=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), Net::DNS::Method(3).

=cut
