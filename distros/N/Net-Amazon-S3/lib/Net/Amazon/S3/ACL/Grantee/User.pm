package Net::Amazon::S3::ACL::Grantee::User;
# ABSTRACT: Represents user reference for ACL
$Net::Amazon::S3::ACL::Grantee::User::VERSION = '0.94';
use Moose;

extends 'Net::Amazon::S3::ACL::Grantee';

has id => (
	is => 'ro',
	isa => 'Str',
	required => 1,
);

around BUILDARGS => sub {
	my ($orig, $class) = (shift, shift);
	unshift @_, 'id' if @_ == 1 && ! ref $_[0];

	return $class->$orig (@_);
};

sub format_for_header {
	my ($self) = @_;

	return "id=\"${\ $self->id }\"";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::ACL::Grantee::User - Represents user reference for ACL

=head1 VERSION

version 0.94

=head1 SYNOPSIS

	use Net::Amazon::S3::ACL::Grantee::User;

	my $user = Net::Amazon::S3::ACL::Grantee::User->new (123);
	my $user = Net::Amazon::S3::ACL::Grantee::User->new (id => 123);

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3>.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
