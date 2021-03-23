package Net::Amazon::S3::ACL::Grantee::Group;
# ABSTRACT: Represents group reference for ACL
$Net::Amazon::S3::ACL::Grantee::Group::VERSION = '0.98';
use Moose;

extends 'Net::Amazon::S3::ACL::Grantee';

has group => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

around BUILDARGS => sub {
	my ($orig, $class) = (shift, shift);
	unshift @_, 'group' if @_ == 1 && ! ref $_[0];

	return $class->$orig (@_);
};

sub format_for_header {
	my ($self) = @_;

	return "uri=\"${\ $self->group }\"";
}

sub AUTHENTICATED_USERS {
	__PACKAGE__->new ('http://acs.amazonaws.com/groups/global/AuthenticatedUsers');
}

sub ALL_USERS {
	__PACKAGE__->new ('http://acs.amazonaws.com/groups/global/AllUsers');
}

sub LOG_DELIVERY {
	__PACKAGE__->new ('http://acs.amazonaws.com/groups/s3/LogDelivery');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::ACL::Grantee::Group - Represents group reference for ACL

=head1 VERSION

version 0.98

=head1 SYNOPSIS

	use Net::Amazon::S3::ACL::Grantee::Group;

	my $group = Net::Amazon::S3::ACL::Grantee::Group->AUTHENTICATED_USERS;
	my $group = Net::Amazon::S3::ACL::Grantee::Group->ALL_USERS;
	my $group = Net::Amazon::S3::ACL::Grantee::Group->LOG_DELIVERY;
	my $group = Net::Amazon::S3::ACL::Grantee::Group->new ('http://...');
	my $group = Net::Amazon::S3::ACL::Grantee::Group->new (group => 'http://...');

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3>.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
