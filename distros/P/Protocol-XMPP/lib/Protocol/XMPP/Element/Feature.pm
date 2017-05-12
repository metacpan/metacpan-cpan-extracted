package Protocol::XMPP::Element::Feature;
$Protocol::XMPP::Element::Feature::VERSION = '0.006';
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

=head1 new

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	my $feature = $self->attributes->{var};

	$self->debug("Had feature [" . ($feature || 'undef') . "]");
}

=head2 end_element

=cut

sub end_element {
	my $self = shift;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
