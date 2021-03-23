package Net::Amazon::S3::Request::Role::HTTP::Header::Encryption;
# ABSTRACT: x-amz-server-side-encryption header role
$Net::Amazon::S3::Request::Role::HTTP::Header::Encryption::VERSION = '0.98';
use Moose::Role;

use Net::Amazon::S3::Constants;

with 'Net::Amazon::S3::Request::Role::HTTP::Header' => {
	name => 'encryption',
	header => Net::Amazon::S3::Constants->HEADER_SERVER_ENCRYPTION,
	isa => 'Maybe[Str]',
	required => 0,
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Request::Role::HTTP::Header::Encryption - x-amz-server-side-encryption header role

=head1 VERSION

version 0.98

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
