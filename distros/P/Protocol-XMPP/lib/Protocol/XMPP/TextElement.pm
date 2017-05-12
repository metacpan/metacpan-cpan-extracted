package Protocol::XMPP::TextElement;
$Protocol::XMPP::TextElement::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

=head1 NAME

Protocol::XMPP::TextElement - handle a text element

=head1 VERSION

Version 0.006

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{text_data} = '';
	$self
}

=head2 characters

=cut

sub characters {
	my $self = shift;
	my $v = shift;
	$self->{text_data} .= $v;
	$self;
}

=head2 trim

Remove all leading and trailing whitespace.

=cut

sub trim { $_[0] =~ s/(?:^\s*)|(?:\s*$)//g; $_[0] }

=head2 end_element

=cut

sub end_element {
	my $self = shift;
	my $data = trim($self->{text_data});
	$self->on_text_complete($data);
	$self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
