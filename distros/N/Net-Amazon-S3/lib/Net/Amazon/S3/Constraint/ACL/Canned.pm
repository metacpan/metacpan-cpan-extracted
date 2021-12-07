package Net::Amazon::S3::Constraint::ACL::Canned;
# ABSTRACT: Moose constraint - valid Canned ACL constants
$Net::Amazon::S3::Constraint::ACL::Canned::VERSION = '0.99';
use Moose::Util::TypeConstraints;

# Current list at https://docs.aws.amazon.com/AmazonS3/latest/dev/acl-overview.html#canned-acl
enum __PACKAGE__, [
	'private',
	'public-read',
	'public-read-write',
	'aws-exec-read',
	'authenticated-read',
	'bucket-owner-read',
	'bucket-owner-full-control',
	'log-delivery-write',
];

# Backward compatibility - create alias
subtype 'AclShort', as __PACKAGE__;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Constraint::ACL::Canned - Moose constraint - valid Canned ACL constants

=head1 VERSION

version 0.99

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
