package Net::Amazon::S3::Request::Role::HTTP::Header::ACL;
# ABSTRACT: Headers builders for ACL
$Net::Amazon::S3::Request::Role::HTTP::Header::ACL::VERSION = '0.991';
use Moose::Role;
use Moose::Util::TypeConstraints;

use Carp ();

with 'Net::Amazon::S3::Role::ACL';

around _request_headers => sub {
	my ($inner, $self) = @_;

	return +(
		$self->$inner,
		$self->acl ? $self->acl->build_headers : (),
	);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::ACL - Headers builders for ACL

=head1 VERSION

version 0.991

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
