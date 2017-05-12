package Protocol::XMPP::User;
$Protocol::XMPP::User::VERSION = '0.006';
use strict;
use warnings;

=head1 NAME

Protocol::XMPP::User - user-related functionality

=head1 VERSION

Version 0.006

=cut

use Protocol::XMPP::Roster;

sub new {
	my $class = shift;
	my $self = bless { }, $class;
	return $self;
}

sub name {

}

sub roster {
	my $self = shift;
	return Protocol::XMPP::Roster->new($self);
}

1;

__END__

=head1 AUTHOR

Tom Molesworth <cpan@entitymodel.com>

=head1 LICENSE

Copyright Tom Molesworth 2010-2014. Licensed under the same terms as Perl itself.
