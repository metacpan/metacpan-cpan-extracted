package Protocol::XMPP::Contact;
$Protocol::XMPP::Contact::VERSION = '0.006';
use strict;
use warnings;
use parent qw{Protocol::XMPP::Base};

=head1 NAME

Protocol::XMPP::Stream - handle XMPP protocol stream

=head1 VERSION

Version 0.006

=head1 METHODS

=cut

sub jid { shift->{jid} }
sub name { my $self = shift; defined($self->{name}) ? $self->{name} : $self->{jid} }

sub is_me {
	my $self = shift;
	return $self->jid eq $self->stream->jid;
}

=head2 authorise

Authorise a contact by sending a 'subscribed' presence response.

=cut

sub authorise {
	my $self = shift;
	$self->write_xml(['presence', from => $self->stream->jid, to => $self->jid, type => 'subscribed']);
}

=head2 subscribe

Request subscription for a contact by sending a 'subscribe' presence response.

=cut

sub subscribe {
	my $self = shift;
	$self->write_xml(['presence', from => $self->stream->jid, to => $self->jid, type => 'subscribe']);
}

=head2 unsubscribe

Reject or unsubscribe a contact by sending an 'unsubscribed' presence response.

=cut

sub unsubscribe {
	my $self = shift;
	$self->write_xml(['presence', from => $self->stream->jid, to => $self->jid, type => 'unsubscribed']);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
