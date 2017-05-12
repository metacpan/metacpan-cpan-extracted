package Protocol::XMPP::Element::Message;
$Protocol::XMPP::Element::Message::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

use Protocol::XMPP::Message;

=head1 NAME

Protocol::XMPP::Feature - register ability to deal with a specific feature

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

=head2 end_element

=cut

sub end_element {
	my $self = shift;

	$self->{$_} ||= $self->attributes->{$_} for qw(from to type);
	my $msg = Protocol::XMPP::Message->new(
		stream	=> $self->stream,
		from	=> $self->{from},
		to	=> $self->{to},
		type	=> $self->{type},
		subject	=> $self->{subject},
		body	=> $self->{body},
		(exists $self->{nick})
		? (nick	=> $self->{nick})
		: ()
	);
	$self->debug("Had message from " . $msg->from . ($msg->subject ? (" subject " . $msg->subject) : '') . " body " . $msg->body);
	$self->stream->dispatch_event('message', $msg);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
