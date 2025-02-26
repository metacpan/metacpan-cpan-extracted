# README

This is the README file for the `OrePAN2::S3` distribution. The intent
of this project is to create a so-called DarkPAN mirror that is served
up from an S3 bucket behind a CloudFront distribution.  However, this
project can also support a website enabled S3 bucket without using
CloudFront.

# Prerequisites

* An AWS account
* An S3 bucket
* A CloudFront distribution

You should set up your S3 bucket and CloudFront distribution before
proceeding. You can use this
[project](https://github.com/rlauer6/s3-static-site) to set up your
infrastructure before proceeding. That project will explain how to
create and secure your own private static website hosted on S3.  A
script is included in that project to help you create all of the AWS
artifacts required.

## Install this Distribution from CPAN

```
cpanm -v OrePAN2::S3
```

This will install two scripts:

| Script Name | Description |
| ----------- | ----------- |
| `orepan2-s3` | Used to add new distributions to your DarkPAN | 
| `orepan2-s3-index` | Called by `orepan2-s3` to create an `index.html` |

## `.orepan2-s3.json`

Set up a configuration file that will be used by the scripts. If you
run `orepan2-s3` the first time and there is no configuration, a
default configuration will be installed in your home directory that
looks something like this:

```
{
    "AWS": {
        "profile" : "prod",
        "region" : "us-east-1",
        "bucket" : "my-bucket",
        "prefix" : "orepan2"
    },
    "CloudFront" : {
        "DistributionId" : "**************"
    }
}
```

If you are not using a CloudFront distribution (see below), remove or set the
DistributionId to "".

# Adding a New Distribution to Your DarkPAN

```
orepan2-s3 add {tarball}
```

Example:

```
orepan2-s3 add OrePAN2-S3-0.01.tar.gz
```

By default, the script will also invalidate the CloudFront cache if it
finds a DistributionId in your configuration. You'll need to
invalidate the cache in order to see your updates to the `index.html`
and the DarkPAN index.  If you don't need to do that because your TTL
on your CloudFront distribution is fairly low, use the `-x` option to
prevent the script from invalidating the cache. 

Keep in mind that AWS gives you 1000 invalidations/month for free
after which you pay $.005 per invalidation request. More than one
files can be included in each request. The script will invalidate 4
files on each invalidation request:

* `index.html`
* `02package.details.text.gz`
* `orepan2-cache.json`
* the distribution you just uploaded

# Using a Website Enabled S3 Bucket

As explained [here](https://blog.tbcdevelopmentgroup.com/2025-02-18-post.html),
there are many ways to create static websites. One such way is to use
a feature of S3 that allows you serve directly from the bucket. In
order to use HTTPS however, you would need to front the bucket using
CloudFront and optionally install your own certificate.  However, if
you don't need that kind of security and simply want to plow ahead
with an insecure public bucket, you can do so. In that case you might
want to create a bucket policy to restrict the IPs addresses that can
access your bucket. Caveat Emptor.

To use an insecure bucket, simply remove the DistributionId from the
configuration file.

You'll find a script [here](bin/create-insecure-bucket) that will allow you to create your insecure
website enabled bucket.
