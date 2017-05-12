[![Build Status](https://travis-ci.org/JaSei/Net-AmazonS3-Simple.svg?branch=master)](https://travis-ci.org/JaSei/Net-AmazonS3-Simple)
# NAME

Net::AmazonS3::Simple - simple S3 client support signature v4

# SYNOPSIS

    my $s3 = Net::AmazonS3::Simple->new(
        aws_access_key_id     => 'XXX',
        aws_secret_access_key => 'YYY',
    );

    $s3->get_object($bucket, $key);

    #or for big file is better
    
    $s3->save_object_to_file($bucket, $key, $file);

# DESCRIPTION

This S3 client have really simple interface and support only get object (yet).

This S3 client use [AWS::Signature4](https://metacpan.org/pod/AWS::Signature4). Signature v4 is [needed](http://stackoverflow.com/questions/26533245/the-authorization-mechanism-you-have-provided-is-not-supported-please-use-aws4) for EU AWS region (for other regions is optionable).
If you need other region, I recommend some other S3 client ([SEE\_ALSO](#see_also)).

# METHODS

## new(%attributes)

### %attributes

#### aws\_access\_key\_id

#### aws\_secret\_access\_key

#### region

default _us-west-1_

#### auto\_region

is is set _wrong_ `region`, is automaticaly changed to _expecting_ region 

default _1_

#### validate

object after get is validate (recalculate MD5 checksum)

default _1_

#### secure

is is set, then use _https_ protocol

default _1_

#### host

default _s3.amazonaws.com_

## get\_object($bucket, $key)

`$bucket` - bucket name

`$key` - object key

return [Net::AmazonS3::Simple::Object::Memory](https://metacpan.org/pod/Net::AmazonS3::Simple::Object::Memory)

## save\_object\_to\_file($bucket, $key, $file)

`$bucket` - bucket name

`$key` - object key

`$file` - file to save, optional, default is `tempfile` 

return [Net::AmazonS3::Simple::Object::File](https://metacpan.org/pod/Net::AmazonS3::Simple::Object::File)

# SEE\_ALSO

[Paws::S3](https://metacpan.org/pod/Paws::S3) - support version 4 signature too,
[Paws](https://metacpan.org/pod/Paws) support more AWS services,
some dependency of this module don't work on windows

[Net::Amazon::S3](https://metacpan.org/pod/Net::Amazon::S3) - don't support version 4 signature,
some dependency of this module don't work on windows

[AWS::S3](https://metacpan.org/pod/AWS::S3) - don't support version 4 signature,
object is get to memory only (no direct to file - it's not good for downloading big files),
similar interface like [Net::Amazon::S3](https://metacpan.org/pod/Net::Amazon::S3)

[Amazon::S3](https://metacpan.org/pod/Amazon::S3) - don't support version 4 signature,
similar interface like [Net::Amazon::S3](https://metacpan.org/pod/Net::Amazon::S3),
last update Aug 15, 2009

[Amazon::S3::Thin](https://metacpan.org/pod/Amazon::S3::Thin) - don't support version 4 signature,
simple interface

[Furl::S3](https://metacpan.org/pod/Furl::S3) - don't support version 4 signature,
simple interface (similar like [Amazon::S3::Thin](https://metacpan.org/pod/Amazon::S3::Thin)),
last update May 16, 2012

# LICENSE

Copyright (C) Avast Software.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Jan Seidl <seidl@avast.com>
