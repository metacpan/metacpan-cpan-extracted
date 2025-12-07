# Mojo::UserAgent::Role::AWSSignature4

Add AWS Signature Version 4 to Mojo::UserAgent requests

## Version

0.01

## Synopsis

```perl
use Mojo::Base -strict;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->with_roles('+AWSSignature4')->new;
my $url = 'https://my-bucket.s3.us-east-1.amazonaws.com/my-object.txt';
$ua->put($url => awssig4 => {service => 's3'})->result;
```

## Description

This role adds AWS Signature Version 4 capabilities to [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent) HTTP requests. It signs requests using the AWS Signature Version 4 signing process, which is required for authenticating requests to AWS services. It supports setting various parameters such as access key, secret key, region, service, and expiration time. Additionally, it can handle unsigned payloads and debug mode for troubleshooting.

This role is useful for developers who need to interact with AWS services using [Mojolicious](https://mojolicious.org) and want to ensure their requests are properly signed according to AWS security standards.

Note that this module can be used with any service that requires AWS Signature Version 4 signing, not just AWS services.

A `Mojo::UserAgent::Transactor` generator named `awssig4` is added to handle the signing process. To use it, simply specify `awssig4` as a generator when making requests with the user agent and specify the required configuration options as a hash reference.

## Installation

Install using your favorite CPAN installer:

```bash
cpanm Mojo::UserAgent::Role::AWSSignature4
```

Or manually:

```bash
perl Makefile.PL
make
make test
make install
```

## Attributes

`Mojo::UserAgent::Role::AWSSignature4` adds the following attributes:

### access_key

The AWS access key ID used for signing requests.

Defaults to `$ENV{AWS_ACCESS_KEY}`. Required unless provided via environment variable.

### aws_algorithm

The AWS signing algorithm used.

Defaults to `'AWS4-HMAC-SHA256'`.

### content

Path to a file containing the request payload to be signed. Will be read and used as the request body during signing.

The value is provided as the `path` attribute to create a `Mojo::Asset::File` object and set as the request content asset.

No default value (i.e. `undef`).

### debug

Enables debug mode for signing process. When enabled, warns debug information about the canonical request and string to sign.

Defaults to `0`.

### expires

The expiration time for the signed request in seconds. If set to 0, no `X-Amz-Expires` header is added.

Defaults to `86_400` (24 hours).

### region

The AWS region for the request.

Defaults to `'us-east-1'`.

### secret_key

The AWS secret access key used for signing requests.

Defaults to `$ENV{AWS_SECRET_KEY}`. Required unless provided via environment variable.

### service

The AWS service name for the request (e.g., 's3', 'sqs', 'dynamodb').

Has no default value and must be provided; dies if not set.

### session_token

The AWS session token for temporary credentials.

Defaults to `$ENV{AWS_SESSION_TOKEN}` or `undef`.

### unsigned_payload

Indicates whether to use an unsigned payload. When enabled, uses the string `'UNSIGNED-PAYLOAD'` instead of hashing the request body.

Defaults to `0`.

## Methods

### authorization

Returns the AWS Signature Version 4 authorization header value, in the format:

```
AWS4-HMAC-SHA256 Credential=ACCESS_KEY/DATE/REGION/SERVICE/aws4_request, SignedHeaders=SIGNED_HEADER_LIST, Signature=SIGNATURE
```

### canonical_headers

Returns the AWS Signature Version 4 canonical sorted headers string, in the format:

```
header1:value1
header2:value2
...
```

Headers are lowercased and sorted alphabetically.

### canonical_qstring

Returns the canonical query string from the request URL.

### canonical_request

Returns the AWS Signature Version 4 canonical request string, in the format:

```
HTTP_METHOD
CANONICAL_URI
CANONICAL_QUERY_STRING
CANONICAL_HEADERS
SIGNED_HEADER_LIST
HASHED_PAYLOAD
```

Will warn debug information if `debug` is enabled.

### credential_scope

Returns the AWS Signature Version 4 credential scope string, in the format:

```
DATE/REGION/SERVICE/aws4_request
```

### date

Returns the current date in YYYYMMDD format (e.g., '20240301').

### date_timestamp

Returns the current date and time in YYYYMMDD'T'HHMMSS'Z' format (e.g., '20240301T120000Z').

### hashed_payload

Returns the SHA256 hash of the request payload, or the string `'UNSIGNED-PAYLOAD'` if `unsigned_payload` is set.

### header_list

Returns a sorted array reference of the request header names.

### signature

Calculates and returns the AWS Signature Version 4 signature using the signing key and string to sign.

### signed_header_list

Returns a semicolon-separated list of signed header names (lowercased).

### signed_qstring

Modifies the request URL query string to add the `X-Amz-Signature` parameter.

### signing_key

Calculates and returns the AWS Signature Version 4 signing key through a series of HMAC-SHA256 operations.

### string_to_sign

Returns the AWS Signature Version 4 string to sign, in the format:

```
AWS4-HMAC-SHA256
DATE_TIMESTAMP
CREDENTIAL_SCOPE
HASHED_CANONICAL_REQUEST
```

Will warn debug information if `debug` is enabled.

### time

Returns the current time as a [Time::Piece](https://metacpan.org/pod/Time::Piece) object in UTC.

## Examples

### Basic S3 PUT Request

```perl
use Mojo::Base -strict;
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->with_roles('+AWSSignature4')->new;

# With environment variables
$ENV{AWS_ACCESS_KEY} = 'your-access-key';
$ENV{AWS_SECRET_KEY} = 'your-secret-key';

my $url = 'https://my-bucket.s3.us-east-1.amazonaws.com/my-object.txt';
my $tx = $ua->put($url => awssig4 => {service => 's3'} => 'Hello World');
```

### Custom Region and Expires

```perl
my $tx = $ua->post(
  'https://dynamodb.eu-west-1.amazonaws.com/' => awssig4 => {
    service => 'dynamodb',
    region  => 'eu-west-1',
    expires => 3600,
  } => json => { TableName => 'MyTable' }
);
```

### With File Content

```perl
my $tx = $ua->put(
  'https://my-bucket.s3.amazonaws.com/large-file.bin' => awssig4 => {
    service => 's3',
    content => '/path/to/file',
  }
);
```

### Unsigned Payload (for streaming)

```perl
my $tx = $ua->post(
  'https://api.example.com/upload' => awssig4 => {
    service          => 'custom-service',
    unsigned_payload => 1,
    expires          => 900,
  }
);
```

### Debug Mode

```perl
my $tx = $ua->get(
  'https://my-bucket.s3.amazonaws.com/object' => awssig4 => {
    service => 's3',
    debug   => 1,  # Enables warnings for canonical request and string to sign
  }
);
```

## Supported Services

This role can be used with any AWS service or compatible service that requires AWS Signature Version 4 signing, including:

- S3 (Simple Storage Service)
- DynamoDB
- SQS (Simple Queue Service)
- SNS (Simple Notification Service)
- Lambda
- API Gateway
- CloudWatch
- And any other service using SigV4

## Requirements

- Perl 5.20.0 or higher
- [Mojolicious](https://metacpan.org/pod/Mojolicious) 9.38 or higher
- [Digest::SHA](https://metacpan.org/pod/Digest::SHA)
- [Time::Piece](https://metacpan.org/pod/Time::Piece)

## See Also

- [Mojolicious](https://mojolicious.org)
- [Mojo::UserAgent](https://metacpan.org/pod/Mojo::UserAgent)
- [AWS Signature Version 4 Signing Process](https://docs.aws.amazon.com/general/latest/gr/signature-version-4.html)
- [Mojo::UserAgent::Role::AWSSignature4 on MetaCPAN](https://metacpan.org/pod/Mojo::UserAgent::Role::AWSSignature4)

## Author

Stefan Adams <sadams@cpan.org>

## Copyright and License

This software is copyright (c) 2025+ by Stefan Adams <sadams@cpan.org>.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
