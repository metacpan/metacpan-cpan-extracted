
use strict;
use warnings;

sub expect_error;

sub expect_s3_error_access_denied {
	expect_error AccessDenied => 'Access denied error message';
}

sub expect_s3_error_bucket_not_empty {
	expect_error BucketNotEmpty => 'Bucket not empty error message';
}

sub expect_s3_error_bucket_not_found {
	expect_error NoSuchBucket => 'No such bucket error message';
}

sub expect_http_error_bad_request {
	expect_error 400 => 'Bad Request';
}

1;


