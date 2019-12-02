package Mojo::AWS::S3;
use Mojo::Base 'Mojo::AWS';
use Mojo::Util qw(url_escape);

our $VERSION = '0.01';

## https://docs.aws.amazon.com/AmazonS3/latest/API/sig-v4-header-based-auth.html
sub canonical_uri {
    pop->path;
}

1;
