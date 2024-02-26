package Net::DNS::Resolver::Recurse;

use strict;
use warnings;
our $VERSION = (qw$Id: Recurse.pm 1965 2024-02-14 09:19:32Z willem $)[2];


=head1 NAME

Net::DNS::Resolver::Recurse - DNS recursive resolver


=head1 SYNOPSIS

    use Net::DNS::Resolver::Recurse;

    my $resolver = new Net::DNS::Resolver::Recurse();

    $resolver->hints('198.41.0.4');	# A.ROOT-SERVER.NET.

    my $packet = $resolver->send( 'www.rob.com.au.', 'A' );


=head1 DESCRIPTION

This module is a subclass of Net::DNS::Resolver.

=cut


use base qw(Net::DNS::Resolver);


=head1 METHODS

This module inherits almost all the methods from Net::DNS::Resolver.
Additional module-specific methods are described below.


=head2 hints

This method specifies a list of the IP addresses of nameservers to
be used to discover the addresses of the root nameservers.

    $resolver->hints(@ip);

If no hints are passed, the priming query is directed to nameservers
drawn from a built-in list of IP addresses.

=cut

my @hints;
my $root;

sub hints {
	my ( undef, @argument ) = @_;
	return @hints unless scalar @argument;
	undef $root;
	return @hints = @argument;
}


=head2 query, search, send

The query(), search() and send() methods produce the same result
as their counterparts in Net::DNS::Resolver.

    $packet = $resolver->send( 'www.example.com.', 'A' );

Server-side recursion is suppressed by clearing the recurse flag in
query packets and recursive name resolution is performed explicitly.

The query() and search() methods are inherited from Net::DNS::Resolver
and invoke send() indirectly.

=cut

sub send {
	my ( $self, @q ) = @_;
	my @conf = ( recurse => 0, udppacketsize => 1232 );
	return bless( {persistent => {'.' => $root}, %$self, @conf}, ref($self) )->_send(@q);
}


sub query_dorecursion {			## historical
	my ($self) = @_;					# uncoverable pod
	$self->_deprecate('prefer  $resolver->send(...)');
	return &send;
}


sub _send {
	my ( $self, @q ) = @_;
	my $query = $self->_make_query_packet(@q);

	unless ($root) {
		$self->_diag('resolver priming query');
		$self->nameservers( scalar(@hints) ? @hints : $self->_hints );
		$self->_referral( $self->SUPER::send(qw(. NS)) );
		$root = $self->{persistent}->{'.'};
	}

	return $self->_recurse( $query, '.' );
}


sub _recurse {
	my ( $self, $query, $apex ) = @_;
	$self->_diag("using cached nameservers for $apex");
	my $cache  = $self->{persistent}->{$apex};
	my @nslist = keys %$cache;
	my @glue   = grep { $$cache{$_} } @nslist;
	my @noglue = grep { !$$cache{$_} } @nslist;
	my $reply;
	foreach my $ns ( @glue, @noglue ) {
		if ( my $iplist = $$cache{$ns} ) {
			$self->nameservers(@$iplist);
		} else {
			$self->_diag("recover missing glue for $ns");
			next if substr( lc($ns), -length($apex) ) eq $apex;
			my @ip = $self->nameservers($ns);
			$$cache{$ns} = \@ip;
		}
		$query->header->id(undef);
		last if $reply = $self->SUPER::send($query);
		$$cache{$ns} = undef;				# park non-responder
	}
	$self->_callback($reply);
	return unless $reply;
	my $zone = $self->_referral($reply) || return $reply;
	die '_recurse exceeded depth limit' if $self->{recurse_depth}++ > 50;
	my $qname  = lc( ( $query->question )[0]->qname );
	my $suffix = substr( $qname, -length($zone) );
	return $zone eq $suffix ? $self->_recurse( $query, $zone ) : undef;
}


sub _referral {
	my ( $self, $packet ) = @_;
	return unless $packet;
	my @ans	 = $packet->answer;
	my @auth = grep { $_->type eq 'NS' } $packet->authority, @ans;
	return unless scalar(@auth);
	my $owner = lc( $auth[0]->owner );
	my $cache = $self->{persistent}->{$owner};
	return scalar(@ans) ? undef : $owner if $cache;

	$self->_diag("caching nameservers for $owner");
	my %addr;
	my @addr = grep { $_->can('address') } $packet->additional;
	push @{$addr{lc $_->owner}}, $_->address foreach @addr;

	my %cache;
	foreach my $ns ( map { lc( $_->nsdname ) } @auth ) {
		$cache{$ns} = $addr{$ns};
	}

	$self->{persistent}->{$owner} = \%cache;
	return scalar(@ans) ? undef : $owner;
}


=head2 callback

This method specifies a code reference to a subroutine,
which is then invoked at each stage of the recursive lookup.

For example to emulate dig's C<+trace> function:

    my $coderef = sub {
	my $packet = shift;

	printf ";; Received %d bytes from %s\n\n",
		$packet->answersize, $packet->answerfrom;
    };

    $resolver->callback($coderef);

The callback subroutine is not called
for queries for missing glue records.

=cut

sub callback {
	my ( $self, @argument ) = @_;
	for ( grep { ref($_) eq 'CODE' } @argument ) {
		$self->{callback} = $_;
	}
	return;
}

sub _callback {
	my ( $self, @argument ) = @_;
	my $callback = $self->{callback};
	$callback->(@argument) if $callback;
	return;
}

sub recursion_callback {		## historical
	my ($self) = @_;					# uncoverable pod
	$self->_deprecate('prefer  $resolver->callback(...)');
	&callback;
	return;
}


1;

__END__


=head1 ACKNOWLEDGEMENT

This package is an improved and compatible reimplementation of the
Net::DNS::Resolver::Recurse.pm created by Rob Brown in 2002,
whose contribution is gratefully acknowledged.


=head1 COPYRIGHT

Copyright (c)2014,2019 Dick Franks.

Portions Copyright (c)2002 Rob Brown.

All rights reserved.


=head1 LICENSE

Permission to use, copy, modify, and distribute this software and its
documentation for any purpose and without fee is hereby granted, provided
that the original copyright notices appear in all copies and that both
copyright notice and this permission notice appear in supporting
documentation, and that the name of the author not be used in advertising
or publicity pertaining to distribution of the software without specific
prior written permission.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.


=head1 SEE ALSO

L<Net::DNS::Resolver>

=cut

