#!/bin/false
# ABSTRACT: Subscriber ID option (code 38) -- opaque subscriber identification
# PODNAME: Net::DHCPv6::Option::SubscriberId
use strictures 2;

package Net::DHCPv6::Option::SubscriberId;
$Net::DHCPv6::Option::SubscriberId::VERSION = '0.003';
use Net::DHCPv6::OptionList ();
use Net::DHCPv6::Constants  qw(
    $OPTION_SUBSCRIBER_ID
);
use parent 'Net::DHCPv6::Option';
use namespace::clean;
my $EMPTY = q();

sub new {
    my ( $class, %args ) = @_;
    my $subscriber_id = $args{subscriber_id} // $EMPTY;
    $args{code} = $OPTION_SUBSCRIBER_ID;
    $args{data} = $subscriber_id;
    my $self = $class->SUPER::new( %args );
    $self->{subscriber_id} = $subscriber_id;
    return bless $self, $class;
}

sub subscriber_id { return shift->{subscriber_id} }

sub from_bytes_inner {
    my ( $class, $code, $payload ) = @_;
    return $class->new( subscriber_id => $payload );
}

$Net::DHCPv6::OptionList::OPTION_CLASS{$OPTION_SUBSCRIBER_ID} = __PACKAGE__;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Option::SubscriberId - Subscriber ID option (code 38) -- opaque subscriber identification

=head1 VERSION

version 0.003

=head1 SYNOPSIS

  use Net::DHCPv6::Option::SubscriberId;
  my $opt = Net::DHCPv6::Option::SubscriberId->new(
      subscriber_id => "\x00\x01\x02",
  );

=head1 DESCRIPTION

Carries an opaque subscriber identifier set by a relay agent.
See RFC 4580.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 METHODS

=head2 new

Constructor.  Optional C<subscriber_id> (opaque bytes, defaults to empty).

=head2 subscriber_id

Returns the opaque subscriber identifier.

=head1 SEE ALSO

L<Net::DHCPv6::Option>, L<Net::DHCPv6::OptionList>

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
