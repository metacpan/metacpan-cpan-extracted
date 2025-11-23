package Net::Amazon::S3::ACL::Set;
# ABSTRACT: Representation of explicit ACL
$Net::Amazon::S3::ACL::Set::VERSION = '0.992';
use Moose 0.85;
use MooseX::StrictConstructor 0.16;
use Moose::Util::TypeConstraints;

use Ref::Util ();
use Safe::Isa ();

use Net::Amazon::S3::Constants;
use Net::Amazon::S3::ACL::Grantee::User;
use Net::Amazon::S3::ACL::Grantee::Group;
use Net::Amazon::S3::ACL::Grantee::Email;

class_type 'Net::Amazon::S3::ACL::Set';

my %permission_map = (
	full_control    => Net::Amazon::S3::Constants::HEADER_GRANT_FULL_CONTROL,
	read            => Net::Amazon::S3::Constants::HEADER_GRANT_READ,
	read_acp        => Net::Amazon::S3::Constants::HEADER_GRANT_READ_ACP,
	write           => Net::Amazon::S3::Constants::HEADER_GRANT_WRITE,
	write_acp       => Net::Amazon::S3::Constants::HEADER_GRANT_WRITE_ACP,
);

my %grantees_map = (
	id    => 'Net::Amazon::S3::ACL::Grantee::User',
	user  => 'Net::Amazon::S3::ACL::Grantee::User',
	uri   => 'Net::Amazon::S3::ACL::Grantee::Group',
	group => 'Net::Amazon::S3::ACL::Grantee::Group',
	email => 'Net::Amazon::S3::ACL::Grantee::Email',
);

has _grantees => (
	is => 'ro',
	default => sub { +{} },
);

sub build_headers {
	my ($self) = @_;

	my %headers;
	while (my ($header, $grantees) = each %{ $self->_grantees }) {
		$headers{$header} = join ', ', map $_->format_for_header, @$grantees;
	}

	%headers;
}

sub grant_full_control {
	my ($self, @grantees) = @_;

	$self->_grant (full_control => @grantees);
}

sub grant_read {
	my ($self, @grantees) = @_;

	$self->_grant (read => @grantees);
}

sub grant_read_acp {
	my ($self, @grantees) = @_;

	$self->_grant (read_acp => @grantees);
}

sub grant_write {
	my ($self, @grantees) = @_;

	$self->_grant (write => @grantees);
}

sub grant_write_acp {
	my ($self, @grantees) = @_;

	$self->_grant (write_acp => @grantees);
}

sub _grant {
	my ($self, $permission, @grantees) = @_;
	$self = $self->new unless ref $self;

	my $key = lc $permission;
	$key =~ tr/-/_/;

	die "Unknown permission $permission"
		unless exists $permission_map{$key};

	return unless @grantees;

	my $list = $self->_grantees->{$permission_map{$key}} ||= [];
	while (@grantees) {
		my $type = shift @grantees;

		if ($type->$Safe::Isa::_isa ('Net::Amazon::S3::ACL::Grantee')) {
			push @{ $list }, $type;
			next;
		}

		die "Unknown grantee type $type"
			unless exists $grantees_map{$type};

		die "Grantee type $type requires one argument"
			unless @grantees;

		my @grantee = (shift @grantees);
		@grantees = @{ $grantee[0] }
			if Ref::Util::is_plain_arrayref ($grantee[0]);

		push @{ $list }, map $grantees_map{$type}->new ($_), @grantee;
	}

	return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::ACL::Set - Representation of explicit ACL

=head1 VERSION

version 0.992

=head1 SYNOPSIS

	use Net::Amazon::S3::ACL;

	$acl = Net::Amazon::S3::ACL->new
		->grant_full_control (
			id => 11112222333,
			id => 444455556666,
			uri => 'predefined group uri',
			email => 'email-address',
		)
		->grant_write (
			...
		)
		;

=head1 DESCRIPTION

Class representing explicit Amazon S3 ACL configuration.

=head1 METHODS

=head2 new

Creates new instance.

=head2 grant_full_control (@grantees)

=head2 grant_read (@grantees)

=head2 grant_read_acp (@grantees)

=head2 grant_write (@grantees)

=head2 grant_write_acp (@grantees)

=head1 GRANTEES

See also L<"Who Is a Grantee?"|https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#specifying-grantee>
in Amazon S3 documentation.

Each grant_* method accepts list of grantees either in key-value format or as an
instance of C<Net::Amazon::S3::ACL::Grantee::*>.

=over

=item canonical user ID

	->grant_read (
		id => 123,
		Net::Amazon::S3::ACL::Grantee::User->new (123),
	)

=item predefined group uri

	->grant_read (
		uri => 'http://...',
		Net::Amazon::S3::ACL::Grantee::Group->new ('http://...'),
		Net::Amazon::S3::ACL::Grantee::Group->ALL_USERS,
	)

=item email address

	->grant_read (
		email => 'foo@bar.baz',
		Net::Amazon::S3::ACL::Grantee::Email->new ('foo@bar.baz'),
	);

=back

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3>.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
