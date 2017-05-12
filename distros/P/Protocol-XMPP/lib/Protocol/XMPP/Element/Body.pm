package Protocol::XMPP::Element::Body;
$Protocol::XMPP::Element::Body::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

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
	return unless $self->parent->isa('Protocol::XMPP::Element::Message');

	$self->parent->{body} = $self->{data};
	$self->debug("Body was " . $self->{data});
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
