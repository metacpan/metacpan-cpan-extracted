package Shared::Examples::Net::Amazon::S3::Error;
# ABSTRACT: used for testing and as example
$Shared::Examples::Net::Amazon::S3::Error::VERSION = '0.88';
use strict;
use warnings;

use parent qw[ Exporter::Tiny ];

use HTTP::Status;

our @EXPORT_OK = (
    qw[ fixture_error_access_denied ],
    qw[ fixture_error_bucket_already_exists ],
    qw[ fixture_error_bucket_not_empty ],
    qw[ fixture_error_invalid_bucket_name ],
    qw[ fixture_error_no_such_bucket ],
    qw[ fixture_error_no_such_key ],
);

sub _error_fixture {
    my ($error_code, $http_status) = @_;

    my $error_message = $error_code;
    $error_message =~ s/ (?<=[[:lower:]]) ([[:upper:]])/ \L$1\E/gx;
    +(
        with_response_code => $http_status,
        with_response_data => <<"XML",
<?xml version="1.0" encoding="UTF-8"?>
<Error>
  <Code>$error_code</Code>
  <Message>$error_message error message</Message>
  <Resource>/some-resource</Resource>
  <RequestId>4442587FB7D0A2F9</RequestId>
</Error>
XML
    );
}

sub fixture_error_access_denied {
    _error_fixture AccessDenied => HTTP::Status::HTTP_FORBIDDEN;
}

sub fixture_error_bucket_already_exists {
    _error_fixture BucketAlreadyExists => HTTP::Status::HTTP_CONFLICT;
}

sub fixture_error_bucket_not_empty {
    _error_fixture BucketNotEmpty => HTTP::Status::HTTP_CONFLICT;
}

sub fixture_error_invalid_bucket_name {
    _error_fixture InvalidBucketName => HTTP::Status::HTTP_BAD_REQUEST;
}

sub fixture_error_no_such_bucket {
    _error_fixture NoSuchBucket => HTTP::Status::HTTP_NOT_FOUND;
}

sub fixture_error_no_such_key {
    _error_fixture NoSuchKey => HTTP::Status::HTTP_NOT_FOUND;
}

__END__

=pod

=encoding UTF-8

=head1 NAME

Shared::Examples::Net::Amazon::S3::Error - used for testing and as example

=head1 VERSION

version 0.88

=head1 AUTHOR

Leo Lapworth <llap@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Amazon Digital Services, Leon Brocard, Brad Fitzpatrick, Pedro Figueiredo, Rusty Conover.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
