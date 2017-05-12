package Protocol::XMPP::Element::Mechanism;
$Protocol::XMPP::Element::Mechanism::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::TextElement);

=head1 NAME

Protocol::XMPP::Mechanism - information on available auth mechanisms

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut


=head2 on_text_complete

Set L<type> based on the text data.

=cut

sub on_text_complete {
	my $self = shift;
	my $data = shift;
	$self->{type} = $data;
	return $self;
}
	
=head2 type

Mechanism type.

=cut

sub type { shift->{type} }

=head2 end_element

=cut

sub end_element {
	my $self = shift;
	$self->SUPER::end_element(@_);

	$self->parent->add_mechanism($self);
	$self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
