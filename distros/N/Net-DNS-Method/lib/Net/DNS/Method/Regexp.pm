package Net::DNS::Method::Regexp;

require 5.005_62;

use Carp;
use strict;
use warnings;
use Net::DNS::Method;
use vars qw($VERSION @ISA $AUTOLOAD);

$VERSION = '2.00';
our $DEBUG = 0;

our @ISA = qw(Net::DNS::Method);

sub new {
    my $type = shift;
    my $class = ref($type) || $type || "Net::DNS::Method::Regexp";

    my $ref = shift;

    croak "Missing initialization parameters\n" unless ref($ref) eq 'HASH';

    return bless { ref => $ref }, $class;
}

sub ANY {
    my $self	= shift;
    my $q	= shift;
    my $ans	= shift;

    warn "inside ANY" if $DEBUG;

    return NS_FAIL unless $self and $q and $ans;

    my $qs = $q->qname . ' ' . $q->qclass . ' ' . $q->qtype;

    for my $re (sort { length $b <=> length $a } keys %{$self->{ref}}) {
	if ($qs =~ /$re/ix)
	{

	    warn "match on $re for question $qs" if $DEBUG;

	    my $s = $self->{ref}->{$re};

				# First, push RRs in the corresponding zones

	    for my $z (qw(answer authority additional question)) {
		next unless exists $s->{$z} and defined $s->{$z};
		croak "$re->$z must be undef or an array reference"
		    unless ref($s->{$z}) eq 'ARRAY';
		for my $rr (@{$s->{$z}}) {
		    $ans->safe_push($z, $rr);
		}
	    }

				# Next, set the answer bits to the requested
				# values

	    $ans->header->ra($s->{ra}) 
		if exists $s->{ra} and defined $s->{ra};

	    $ans->header->rd($s->{rd}) 
		if exists $s->{rd} and defined $s->{rd};

	    $ans->header->aa($s->{aa}) 
		if exists $s->{aa} and defined $s->{aa};

	    $ans->header->tc($s->{tc}) 
		if exists $s->{tc} and defined $s->{tc};

				# Next, set the answer's result code

	    if (exists $s->{code} and defined $s->{code}) {
		$ans->header->rcode($s->{code});
	    }
	    else {
		$ans->header->rcode('NOERROR');
	    }

				# Finally, return the requested value or our
				# default

	    if (exists $s->{return} and defined $s->{return}) {
		return $s->{return};
	    }
	    else {
		return NS_OK | NS_STOP;
	    }
	}
    }
    return NS_FAIL;
}

sub AUTOLOAD {			
    return undef if $AUTOLOAD eq 'Net::DNS::Method::Regexp::DESTROY';

    warn "call to $AUTOLOAD" if $DEBUG;

    goto &ANY;
}

1;
__END__

=head1 NAME

Net::DNS::Method::Regexp - Build answers based on regular expressions

=head1 SYNOPSIS

  use Net::DNS::Method::Regexp;

  my $ans = new Net::DNS::Method::Regexp {
      /^www.test.com\.? IN A$/ => {
	  answer => [ Net::DNS::RR->new("www.test.com. 10 IN A 192.168.0.1"),
		      Net::DNS::RR->new("www.test.com. 10 IN A 192.168.0.2") ],
	  authority => [],
	  additional => [],
	  question => [],
	  code => 'NOERROR',
	  ra => 1,
	  rd => 1,
	  aa => 1,
	  tc => 1,
	  return => NS_OK | NS_STOP
      }
  }


=head1 DESCRIPTION

This module provides a simple but powerful DNS answer generator based
in the idea of matching a DNS question with a regular expression and
building the answer using the supplied rules.

Its C<-E<gt>new()> method receives  as its only parameter, a reference
to  a hash  whose keys  are regular  expressions that  must  match the
question section of a DNS packet. The value associated with these keys
is a hash with the following possible pair - value entries:

=over

=item answer, authority, additional and question

The value stored on these keys is a reference to a list of
Net::DNS::RR objects that will be C<safe_push()>ed into the
corresponding sections of the answer. This requires a fairly recent
version of L<Net::DNS>.

=item ra, rd, aa, tc

Specify a value for the corresponding call in the answer packet,
setting the corresponding bit to the specified value. For instance, an
authoritative answer should specify C<aa => 1>.

=item code

Sets  the  answer's  return  code  to the  specified  value.  If  left
unspecified, the fault value of 'NOERROR' will be used.

=item return

Specifies the return value at the Net::DNS::Method level. This can be
used to allow further classes to attempt a match on the packet, abort
the search, skip the answer altogether, etc.

If this is omitted, the default value of C<NS_OK | NS_STOP> will be
returning, causing the answer to be returned immediately.

=back

Note that the  regular expression match will always  be attempted with
extended  syntax  (ie, spaces  are  meaningless)  and case  sensitivity
turned  off. Also,  matches  are attempted  from  the longest  regular
expression  to  the  shortest,   allowing  for  a  trivial  "priority"
mechanism to  be used. You can  simply add whitespace  to your regular
expression to have it execute before a shorter regular expression.

=head1 HISTORY

=over 8

=item 1.00

Original version; created by h2xs 1.20 with options

  -ACOXfn
	Net::DNS::Method::Regexp
	-v
	1.00

=item 2.00

Repackaged for public distribution.

=head1 AUTHOR

Luis E. Munoz <luismunoz@cpan.org>

=head1 SEE ALSO

perl(1), Net::DNS::Method(3), Net::DNS(3), Net::DNS::RR(3).

=cut

