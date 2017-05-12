package Protocol::IMAP::Envelope;
{
  $Protocol::IMAP::Envelope::VERSION = '0.004';
}
use strict;
use warnings;

=head1 NAME

Protocol::IMAP::Envelope - represents the message envelope

=head1 VERSION

version 0.004

=cut

use Protocol::IMAP::Address;

sub new {
	my $class = shift;
	my %args = @_;
	$args{$_} = [ map Protocol::IMAP::Address->new(%$_), @{$args{$_}} ] for qw(from to cc bcc reply_to);
	my $self = bless \%args, $class;
	$self
}

sub date { shift->{date} }
sub from { @{shift->{from}} }
sub to { @{shift->{to}} }
sub cc { @{shift->{cc}} }
sub bcc { @{shift->{bcc}} }
sub subject { shift->{subject} }
sub message_id { shift->{message_id} }

1;
