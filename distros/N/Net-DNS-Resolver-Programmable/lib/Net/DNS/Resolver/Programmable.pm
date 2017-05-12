#
# Net::DNS::Resolver::Programmable
# A Net::DNS::Resolver descendant class for offline emulation of DNS
#
# (C) 2006-2007 Julian Mehnle <julian@mehnle.net>
# $Id: Programmable.pm 13 2007-05-30 22:12:35Z julian $
#
##############################################################################

package Net::DNS::Resolver::Programmable;

=head1 NAME

Net::DNS::Resolver::Programmable - programmable DNS resolver class for offline
emulation of DNS

=head1 VERSION

0.003

=cut

use version; our $VERSION = qv('0.003');

use warnings;
use strict;

use base 'Net::DNS::Resolver';

use Net::DNS::Packet;

use constant TRUE   => (0 == 0);
use constant FALSE  => not TRUE;

# Interface:
##############################################################################

=head1 SYNOPSIS

    use Net::DNS::Resolver::Programmable;
    use Net::DNS::RR;
    
    my $resolver = Net::DNS::Resolver::Programmable->new(
        records         => {
            'example.com'     => [
                Net::DNS::RR->new('example.com.     NS  ns.example.org.'),
                Net::DNS::RR->new('example.com.     A   192.168.0.1')
            ],
            'ns.example.org'  => [
                Net::DNS::RR->new('ns.example.org.  A   192.168.1.1')
            ]
        },
        
        resolver_code   => sub {
            my ($domain, $rr_type, $class) = @_;
            ...
            return ($result, $aa, @rrs);
        }
    );

=cut

# Implementation:
##############################################################################

=head1 DESCRIPTION

B<Net::DNS::Resolver::Programmable> is a B<Net::DNS::Resolver> descendant
class that allows a virtual DNS to be emulated instead of querying the real
DNS.  A set of static DNS records may be supplied, or arbitrary code may be
specified as a means for retrieving DNS records, or even generating them on the
fly.

=head2 Constructor

The following constructor is provided:

=over

=item B<new(%options)>: returns I<Net::DNS::Resolver::Programmable>

Creates a new programmed DNS resolver object.

%options is a list of key/value pairs representing any of the following
options:

=over

=item B<records>

A reference to a hash of arrays containing a static set of I<Net::DNS::RR>
objects.  The hash entries must be indexed by fully qualified domain names
(lower-case, without any trailing dots), and the entries themselves must be
arrays of the RR objects pertaining to these domain names.  For example:

    records => {
        'example.com'     => [
            Net::DNS::RR->new('example.com.     NS  ns.example.org.'),
            Net::DNS::RR->new('example.com.     A   192.168.0.1')
        ],
        'www.example.com' => [
            Net::DNS::RR->new('www.example.com. A   192.168.0.2')
        ],
        'ns.example.org'  => [
            Net::DNS::RR->new('ns.example.org.  A   192.168.1.1')
        ]
    }

If this option is specified, the resolver retrieves requested RRs from this
data structure.

=item B<resolver_code>

A code reference used as a call-back for dynamically retrieving requested RRs.

The code must take the following query parameters as arguments: the I<domain>,
I<RR type>, and I<class>.

It must return a list composed of: the response's I<RCODE> (by name, as
returned by L<< Net::DNS::Header->rcode|Net::DNS::Header/rcode >>), the
I<< C<aa> (authoritative answer) flag >> (I<boolean>, use B<undef> if you don't
care), and the I<Net::DNS::RR answer objects>.  If an error string is returned
instead of a valid RCODE, a I<Net::DNS::Packet> object is not constructed but
an error condition for the resolver is signaled instead.

For example:

    resolver_code => sub {
        my ($domain, $rr_type, $class) = @_;
        ...
        return ($result, $aa, @rrs);
    }

If both this and the C<records> option are specified, then statically
programmed records are used in addition to any that are returned by the
configured resolver code.

=item B<defnames>

=item B<dnsrch>

=item B<domain>

=item B<searchlist>

=item B<debug>

These Net::DNS::Resolver options are also meaningful with
Net::DNS::Resolver::Programmable.  See L<Net::DNS::Resolver> for their
descriptions.

=back

=cut

sub new {
    my ($self, %options) = @_;
    
    # Create new object:
    $self = $self->SUPER::new(%options);
    
    $self->{records}       = $options{records};
    $self->{resolver_code} = $options{resolver_code};
    
    return $self;
}

=back

=head2 Instance methods

The following instance methods of I<Net::DNS::Resolver> are also supported by
I<Net::DNS::Resolver::Programmable>:

=over

=item B<search>: returns I<Net::DNS::Packet>

=item B<query>: returns I<Net::DNS::Packet>

=item B<send>: returns I<Net::DNS::Packet>

Performs an offline DNS query, using the statically programmed DNS RRs and/or
the configured dynamic resolver code.  See the L</new> constructor's C<records>
and C<resolver_code> options.  See the descriptions of L<search, query, and
send|Net::DNS::Resolver/search> for details about the calling syntax of these
methods.

=cut

sub send {
    my $self = shift;
    
    my $query_packet = $self->make_query_packet(@_);
    my $question = ($query_packet->question)[0];
    my $domain   = lc($question->qname);
    my $rr_type  = $question->qtype;
    my $class    = $question->qclass;
    
    $self->_reset_errorstring;
    
    my ($result, $aa, @answer_rrs);
    
    if (defined(my $resolver_code = $self->{resolver_code})) {
        ($result, $aa, @answer_rrs) = $resolver_code->($domain, $rr_type, $class);
    }
    
    if (not defined($result) or defined($Net::DNS::rcodesbyname{$result})) {
        # Valid RCODE, return a packet:
        
        $aa     = TRUE      if not defined($aa);
        $result = 'NOERROR' if not defined($result);
        
        if (defined(my $records = $self->{records})) {
            if (ref(my $rrs_for_domain = $records->{$domain}) eq 'ARRAY') {
                foreach my $rr (@$rrs_for_domain) {
                    push(@answer_rrs, $rr)
                        if  $rr->name  eq $domain
                        and $rr->type  eq $rr_type
                        and $rr->class eq $class;
                }
            }
        }
        
        my $packet = Net::DNS::Packet->new($domain, $rr_type, $class);
        $packet->header->qr(TRUE);
        $packet->header->rcode($result);
        $packet->header->aa($aa);
        $packet->push(answer => @answer_rrs);
        
        return $packet;
    }
    else {
        # Invalid RCODE, signal error condition by not returning a packet:
        $self->errorstring($result);
        return undef;
    }
}

=item B<print>

=item B<string>: returns I<string>

=item B<searchlist>: returns I<list> of I<string>

=item B<defnames>: returns I<boolean>

=item B<dnsrch>: returns I<boolean>

=item B<debug>: returns I<boolean>

=item B<errorstring>: returns I<string>

=item B<answerfrom>: returns I<string>

=item B<answersize>: returns I<integer>

See L<Net::DNS::Resolver/METHODS>.

=back

Currently the following methods of I<Net::DNS::Resolver> are B<not> supported:
B<axfr>, B<axfr_start>, B<axfr_next>, B<nameservers>, B<port>, B<srcport>,
B<srcaddr>, B<bgsend>, B<bgread>, B<bgisready>, B<tsig>, B<retrans>, B<retry>,
B<recurse>, B<usevc>, B<tcp_timeout>, B<udp_timeout>, B<persistent_tcp>,
B<persistent_udp>, B<igntc>, B<dnssec>, B<cdflag>, B<udppacketsize>.
The effects of using these on I<Net::DNS::Resolver::Programmable> objects are
undefined.

=head1 SEE ALSO

L<Net::DNS::Resolver>

For availability, support, and license information, see the README file
included with Net::DNS::Resolver::Programmable.

=head1 AUTHORS

Julian Mehnle <julian@mehnle.net>

=cut

TRUE;

# vim:sts=4 sw=4 et
