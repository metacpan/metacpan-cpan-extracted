Plack::Middleware::ETag - Adds automatically an ETag header.

[![Build
Status](https://travis-ci.org/franckcuny/plack-middleware-etag.svg?branch=travis-ci)](https://travis-ci.org/franckcuny/plack-middleware-etag)

## SYNOPSIS

```perl
use Plack::Builder;

my $app = builder {
  enable "Plack::Middleware::ETag", file_etag => [qw/inode mtime size/];
  sub {['200', ['Content-Type' => 'text/html'}, ['hello world']]};
};
```

## DESCRIPTION

Plack::Middleware::ETag adds automatically an ETag header. You may want to use it with
"Plack::Middleware::ConditionalGET".

```perl
my $app = builder {
  enable "Plack::Middleware::ConditionalGET";
  enable "Plack::Middleware::ETag", file_etag => "inode";
  sub {['200', ['Content-Type' => 'text/html'}, ['hello world']]};
};
```

## CONFIGURATION

### file_etag

If the content is a file handle, the ETag will be set using the
inode, modified time and the file size. You can select which
attributes of the file will be used to set the ETag:

```perl
enable "Plack::Middleware::ETag", file_etag => [qw/size/];
```

### cache_control

It's possible to add 'Cache-Control' header.

```perl
enable "Plack::Middleware::ETag", cache_control => 1;
```

Will add "Cache-Control: must-revalidate" to the headers.

```perl
enable "Plack::Middleware::ETag", cache_control => [ 'must-revalidate', 'max-age=3600' ];
```

Will add "Cache-Control: must-revalidate, max-age=3600" to the headers.

```perl
check_last_modified_header
```

Will not add an ETag if there is already a Last-Modified header.

## AUTHOR

Franck Cuny <franckcuny@gmail.com>

## LICENSE

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

