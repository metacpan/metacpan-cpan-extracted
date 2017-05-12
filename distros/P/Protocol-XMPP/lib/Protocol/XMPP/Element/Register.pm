package Protocol::XMPP::Element::Register;
$Protocol::XMPP::Element::Register::VERSION = '0.006';
use strict;
use warnings;
use parent qw(Protocol::XMPP::ElementBase);

=head1 NAME

=head1 SYNOPSIS

=head1 VERSION

Version 0.006

=head1 DESCRIPTION

=head1 METHODS

=cut

use Data::Dumper;

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->debug($self->{element}->{NamespaceURI});
	$self;
}

sub end_element {
	my $self = shift;
	$self->debug("Register request received, data was: " . $self->{data});
	$self;
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
