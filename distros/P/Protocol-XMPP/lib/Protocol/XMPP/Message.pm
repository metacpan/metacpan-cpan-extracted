package Protocol::XMPP::Message;
$Protocol::XMPP::Message::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::Base);

=head1 NAME

Protocol::XMPP::Feature - register ability to deal with a specific feature

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub from { my $self = shift; $self->{from} // $self->stream->jid }
sub to { shift->{to} || '' }
sub subject { shift->{subject} || '' }
sub body { shift->{body} || '' }
sub type { shift->{type} || 'chat' }
sub nick { my $self = shift; $self->{nick} || $self->{from} }

sub reply {
	my $self = shift;
	my %args = @_;
	$self->write_xml(['message', 'from' => $self->stream->jid, 'to' => $self->from, type => $self->type, _content => [[ 'body', _content => $args{body} ]]]);
}

sub send {
	my $self = shift;
	my %args = @_;
	$self->write_xml([
		'message',
		'to' => $self->to,
		type => $self->type,
		_content => [[
			'body',
			_content => $self->body
		]]
	]);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
