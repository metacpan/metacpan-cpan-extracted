package Net::Amazon::S3::Constants;
# Abstract: Misc constants used by S3
$Net::Amazon::S3::Constants::VERSION = '0.97';
use constant {
	HEADER_BUCKET_REGION        => 'x-amz-bucket-region',
	HEADER_CANNED_ACL           => 'x-amz-acl',
	HEADER_COPY_SOURCE          => 'x-amz-copy-source',
	HEADER_DATE                 => 'x-amz-date',
	HEADER_DELETE_MARKER        => 'x-amz-delete-marker',
	HEADER_GRANT_FULL_CONTROL   => 'x-amz-grant-full-control',
	HEADER_GRANT_READ           => 'x-amz-grant-read',
	HEADER_GRANT_READ_ACP       => 'x-amz-grant-read-acp',
	HEADER_GRANT_WRITE          => 'x-amz-grant-write',
	HEADER_GRANT_WRITE_ACP      => 'x-amz-grant-write-acp',
	HEADER_ID_2                 => 'x-amz-id-2',
	HEADER_METADATA_DIRECTIVE   => 'x-amz-metadata-directive',
	HEADER_REQUEST_ID           => 'x-amz-request-id',
	HEADER_SERVER_ENCRYPTION    => 'x-amz-server-side-encryption',
	HEADER_VERSION_ID           => 'x-amz-version-id',
	S3_NAMESPACE_URI            => 'http://s3.amazonaws.com/doc/2006-03-01/',
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Amazon::S3::Constants

=head1 VERSION

version 0.97

=head1 DESCRIPTION

Module provides misc Amazon S3 string constants as symbols.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This module is part of L<Net::Amazon::S3> distribution.

=head1 AUTHOR

Branislav Zahradník <barney@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover, Branislav Zahradník.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
