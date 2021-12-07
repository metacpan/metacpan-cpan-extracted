package Net::Amazon::S3::ACL::Grantee::Email;
# ABSTRACT: Represents user reference by email address for ACL
$Net::Amazon::S3::ACL::Grantee::Email::VERSION = '0.99';
use Moose;

extends 'Net::Amazon::S3::ACL::Grantee';

has address => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

around BUILDARGS => sub {
	my ($orig, $class) = (shift, shift);
	unshift @_, 'address' if @_ == 1 && ! ref $_[0];

	return $class->$orig (@_);
};

sub format_for_header {
	my ($self) = @_;

	return "emailAddress=\"${\ $self->address }\"";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::ACL::Grantee::Email - Represents user reference by email address for ACL

=head1 VERSION

version 0.99

=head1 SYNOPSIS

	use Net::Amazon::S3::ACL::Grantee::Email;

	my $email = Net::Amazon::S3::ACL::Grantee::Email->new ('foo@bar.com');
	my $email = Net::Amazon::S3::ACL::Grantee::Email->new (address => 'foo@bar.com');

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
