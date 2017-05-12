#! /usr/bin/perl
#
#
# $Id: Simple.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Match::Simple;

use 5.008;
use strict;
use warnings;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

use NetAddr::IP 4;
use Net::Radius::Server::Base qw/:match/;
use base qw/Net::Radius::Server::Match/;
__PACKAGE__->mk_accessors(qw/addr attr code peer_addr peer_port port/);

sub _match_addr
{
    my $self = shift;
    my $peer = shift;
    my $mpeer = shift;

    if (ref($mpeer) eq 'Regexp')
    {
	if ($peer =~ m/$mpeer/)
	{
	    $self->log(4, "_match_addr ok: $mpeer matches $peer");
	    return NRS_MATCH_OK;
	}
    }
    elsif (ref($mpeer) eq 'NetAddr::IP')
    {
	my $pip = NetAddr::IP->new($peer);
	if (!$pip)
	{
	    $self->log
		(4, 
		 "_match_addr fails: Cannot convert $peer to a NetAddr::IP");
	    return NRS_MATCH_FAIL;
	}

	if ($mpeer->contains($pip))
	{
	    $self->log(4, "_match_addr ok: $mpeer contains $pip");
	    return NRS_MATCH_OK;
	}
    }
    elsif ($peer eq $mpeer)
    {
	$self->log(4, "_match_addr ok: $mpeer eq $peer");
	return NRS_MATCH_OK;
    }

    $self->log(3, "_match_addr fails: Don't know how to handle '$mpeer'");
    return NRS_MATCH_FAIL;
}

sub _match_port
{
    my $self = shift;
    my $port = shift;
    my $mport = shift;

    if (ref($mport) eq 'Regexp')
    {
	if ($port =~ m/$mport/)
	{
	    $self->log(4, "_match_port ok: $mport matches $port");
	    return NRS_MATCH_OK;
	}
    }
    else
    {
	if ($port == $mport)
	{
	    $self->log(4, "_match_port ok: $mport == $port");
	    return NRS_MATCH_OK;
	}
    }

    $self->log(3, "_match_port fails: Don't know how to handle '$mport'");
    return NRS_MATCH_FAIL;
}

sub match_peer_addr
{
    my $self = shift;
    my $peer = $_[0]->{peer_addr};
    my $mpeer = $self->peer_addr;

    $self->log(4, "Invoked match_peer_addr");
    return $self->_match_addr($peer, $mpeer);
}

sub match_addr
{
    my $self = shift;
    my $peer = $_[0]->{addr};
    my $mpeer = $self->addr;

    $self->log(4, "Invoked match_addr");
    return $self->_match_addr($peer, $mpeer);
}

sub match_port
{
    my $self = shift;
    my $port = $_[0]->{port};
    my $mport = $self->port;

    $self->log(4, "Invoked match_port");
    return $self->_match_port($port, $mport);
}

sub match_peer_port
{
    my $self = shift;
    my $port = $_[0]->{peer_port};
    my $mport = $self->peer_port;

    $self->log(4, "Invoked match_peer_port");
    return $self->_match_port($port, $mport);
}

sub match_attr
{
    my $self = shift;
    my $req = $_[0]->{request};

    my %conds = @{$self->attr};

    while (my ($a, $v) = each %conds)
    {
	my $V = $req->attr($a);
	$self->log(4, "match_attr: ($a, $v, " . ($V || 'undef value') . ")");
	if (defined $V)
	{
	    if (ref($v) eq 'Regexp')
	    {
		if ($V =~ m/$v/)
		{
		    $self->log(4, "match_attr: Regexp $v matches $V ($a)");
		    next;
		}
	    }
	    elsif (ref($v) eq 'NetAddr::IP')
	    {
		my $ip = NetAddr::IP->new($V);
		if ($ip and $v->contains($ip))
		{
		    $self->log(4, "match_attr: $v contains $ip ($a)");
		    next;
		}
	    }
	    else
	    {
		if ($V eq $v)
		{
		    $self->log(4, "match_attr: $V eq $v ($a)");
		    next;
		}
	    }
	}
	$self->log(3, "match_attr: No match - Return FAIL");
	return NRS_MATCH_FAIL;
    }
    $self->log(4, "match_attr: Default - Return OK");
    return NRS_MATCH_OK;
}

sub match_code
{
    my $self = shift;
    my $req = $_[0]->{request};

    if (ref($self->code) eq 'Regexp')
    {
	my $re = $self->code;
	if ($req->code =~ m/$re/)
	{
	    $self->log(4, "match_code: match: $re did not match " 
		       . $req->code);
	    return NRS_MATCH_OK;
	}
    }
    else
    {
	if ($req->code eq $self->code)
	{
	    $self->log(4, "match_code: match: " 
		       . $self->code . " eq " 
		       . $req->code);
	    return NRS_MATCH_OK;
	}
    }
    $self->log(3, "match_code: fail by default");
    return NRS_MATCH_FAIL;
}

# Preloaded methods go here.

42;
__END__

=head1 NAME

Net::Radius::Server::Match::Simple - Simple match methods for RADIUS requests

=head1 SYNOPSIS

  use Net::Radius::Server::Match::Simple;

  my $match = Net::Radius::Server::Match::Simple->new
    ({
      code => 'Access-Request',
      attr => [ 
        'User-Name' => qr/(?i)\@my\.domain\.?$/,
        'NAS-IP-Address' => NetAddr::IP->new('127.0.0.0/24'),
        'Framed-Protocol' => 'PPP',
      ],
    });
  my $match_sub = $match->mk;

=head1 DESCRIPTION

C<Net::Radius::Server::Match::Simple> implements simple but effective
packet matcher method factories for use in C<Net::Radius::Server>
rules.

See C<Net::Radius::Server::Match> for general usage guidelines. The
relevant attributes that control the matching of RADIUS requests are:

=over

=item C<attr>

Controls matching of a given attribute in the request packet. Must be
called with a listref where even elements represent the name of a
RADIUS attribute to match. The odd elements can be any of the
following:

=over

=item *

A scalar, in which case an exact match with the attribute contents
must occur for this method to return C<NRS_MATCH_OK>.

=item *

A regexp, in which case the attribute's content must match the regexp
for this method to return C<NRS_MATCH_OK>.

=item *

A C<NetAddr::IP> subnet, in which case the attribute matches if its
value can be converted to a C<NetAddr::IP> object and it is contained
in the given subnet. This is very useful to perform sanity check on
your RADIUS requests.

=back

All the conditions specified in this way must match in order for the
method to return C<NRS_MATCH_OK>. Otherwise, C<NRS_MATCH_FAIL> will be
returned.

This would match if the User-Name attribute in the RADIUS request
contains a (case insensitive) "@foo.domain" realm AND the
NAS-IP-Address attribute contains '127.0.0.1'.

=item C<code>

Matches the RADIUS packet code. The following types of attributes can
be specified:

=over

=item *

A scalar, in which case an exact match with the code must occur for
this method to return C<NRS_MATCH_OK>.

=item *

A regexp, in which case the code's name must match the regexp for this
method to return C<NRS_MATCH_OK>.

=back

See Net::Radius::Packet(3) for more information on atribute and type
representation.

=item C<peer_addr> and C<addr>

Match the address of either the peer or the local socket used to
receive the request. The following specifications can be used for the
match:

=over

=item *

A scalar, in which case an exact match with the address must occur for
this method to return C<NRS_MATCH_OK>.

=item *

A regexp, in which case the address must match the regexp
for this method to return C<NRS_MATCH_OK>.

=item *

A C<NetAddr::IP> subnet, in which case the address matches if its
value can be converted to a C<NetAddr::IP> object and it is contained
in the given subnet.

=back

=item C<peer_port> and C<port>

Match the port of either the peer or the local socket used to
receive the request. The following specifications can be used for the
match:

=over

=item *

A scalar, in which case an exact match with the port must occur for
this method to return C<NRS_MATCH_OK>.

=item *

A regexp, in which case the port must match the regexp for this method
to return C<NRS_MATCH_OK>.

=back

Note that ports are usually numeric (ie, 1812 instead of "radacct").

=back

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.3  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), NetAddr::IP(3), Net::Radius::Server(3),
Net::Radius::Server::Match(3), Net::Radius::Packet(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut


