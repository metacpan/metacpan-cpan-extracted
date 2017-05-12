#! /usr/bin/perl
#
#
# $Id: Simple.pm 75 2009-08-12 22:08:28Z lem $

package Net::Radius::Server::Set::Simple;

use 5.008;
use strict;
use warnings;

our $VERSION = do { sprintf "%0.3f", 1+(q$Revision: 75 $ =~ /\d+/g)[0]/1000 };

use Net::Radius::Server::Base qw/:set/;
use base qw/Net::Radius::Server::Set/;
__PACKAGE__->mk_accessors(qw/auto attr code result vsattr/);

sub set_auto
{
    my $self = shift;
    my $r_data = shift;
    return unless $self->auto;

    my $req = $r_data->{request};
    my $rep = $r_data->{response};

    $self->log(4, "Copy autheticator and id");

    $rep->set_authenticator($req->authenticator);
    $rep->set_identifier($req->identifier);
}

sub set_attr
{
    my $self = shift;
    my $r_data = shift;

    my $rep = $r_data->{response};
    foreach (@{$self->attr})
    {
	$self->log(4, "set_attr " . join(' ', @$_));
	$rep->set_attr(@$_);
    }
}

sub set_code
{
    my $self = shift;
    my $r_data = shift;

    my $rep = $r_data->{response};
    my $code = $self->code;
    $self->log(4, "set_code $code");
    $rep->set_code($code);
}

sub set_vsattr
{
    my $self = shift;
    my $r_data = shift;

    my $rep = $r_data->{response};
    foreach (@{$self->vsattr})
    {
	$self->log(4, "set_vsattr " . join(' ', @$_));
	$rep->set_vsattr(@$_);
    }
}

42;

__END__

=head1 NAME

Net::Radius::Server::Set::Simple - Simple set methods for RADIUS requests

=head1 SYNOPSIS

  use Net::Radius::Server::Set::Simple;
  use Net::Radius::Server::Base qw/:set/;


  my $set = Net::Radius::Server::Set::Simple->new
    ({
      code => 'Access-Accept',
      auto => 1,
      result => NRS_SET_RESPOND,
      vsattr => [
        [ 'Cisco' => 'cisco-avpair' => 'foo=bar' ],
        [ 'Cisco' => 'cisco-avpair' => 'baz=bad' ],
      ],
      attr => [
        [ 'Framed-IP-Address' => '127.0.0.1' ],
        [ 'Reply-Message' => "Welcome home!!!\r\n\r\n" ],
      ]});
  my $set_sub = $set->mk;

=head1 DESCRIPTION

C<Net::Radius::Server::Set::Simple> implements simple but effective
packet set method factories for use in C<Net::Radius::Server> rules.

See C<Net::Radius::Server::Set> for general usage guidelines. The
relevant attributes that control the matching of RADIUS requests are:

=over

=item C<auto>

When set to a true value, cause the identifier and authenticator from
the RADIUS request to be copied into the response.

=item C<attr>

Takes a list-ref containing list-refs where the first item is the
RADIUS attribute to set and the second item is the value to set in the
attribute. This translates to calls to C<-E<gt>set_attr()> in
C<Net::Radius::Packet>.

=item C<code>

Sets the RADIUS packet code of the response to the given value. See
Net::Radius::Packet(3) for more information on atribute and type
representation.

This is a thin wrapper around C<Net::Radius::Packet-E<gt>set_code()>.

=item C<result>

The result of the invocation of this set method. See
C<Net::Radius::Server::Set> for more information. The example shown in
the synopsis would cause an inmediate return of the packet. Other set
methods after the current one won't be called at all.

=item C<vsattr>

Just as C<attr>, but dealing with
C<Net::Radius::Packet-E<gt>set_vsattr()> instead.

=back

=head2 EXPORT

None by default.


=head1 HISTORY

  $Log$
  Revision 1.4  2006/12/14 16:33:17  lem
  Rules and methods will only report failures in log level 3 and
  above. Level 4 report success and failure, for deeper debugging

  Revision 1.3  2006/12/14 15:52:25  lem
  Fix CVS tags


=head1 SEE ALSO

Perl(1), Net::Radius::Server(3), Net::Radius::Server::Set(3),
Net::Radius::Packet(3).

=head1 AUTHOR

Luis E. Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Luis E. Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl 5.8.6 itself.

=cut


