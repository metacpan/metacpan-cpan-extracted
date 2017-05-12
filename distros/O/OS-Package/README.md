# About

OS-Package will build software from source and package the software using the native Operating System packaging tools.

It is currently in active development and not ready for production use.  Currently only a Solaris 10 SVR4 plugin is working.

# Installation

If you don't already have [Perl](http://perl.org) installed, use [Perlbrew](http://perlbrew.pl) to install it.

```
cpanm OS::Package
```

# Usage

Use the `ospkg init` to set default paths.

```
$ ospkg init -c ~/projects/ospkg_configs -p /repository/packages/
```

```
$ ospkg build httpd
```

Specify an alternate configuration location, if it's not in `~/.ospkg/configs`.

```
$ ospkg build -c ~/projects/ospkg_configs httpd
```

# Package Configuration

See the `samples` directory for more examples.


```
pkgname: httpd
name: Apache HTTP Server
description: Open-source HTTP Web Server
version: 2.2.29
homepage: http://httpd.apache.org
url: http://archive.apache.org/dist/httpd/httpd-2.2.29.tar.gz
sha1: eea518d4b8be8e05697ae1d6ce449cd474868d0d
md5: 7036a6eb5fb3b85be7a804255438b795
prefix: /opt/sf/apache

compile:
  cflags:
    solaris:
      64: -xtarget=generic -m64 -xO4

build: |
  ./configure --prefix=[% PREFIX %] \
    --with-ssl=/usr/sfw/include \
    --enable-rewrite \
    --enable-ssl \
    --enable-proxy \
    --enable-proxy-http \
    --enable-proxy-balancer \
    --enable-cache \
    --enable-disk-cache \
    --with-mpm=prefork \
    --enable-mods-shared=all
  make
  make install DESTDIR=[% FAKEROOT %]

maintainer:
  author: James F Wilkus
  email: jfwilkus@cpan.org
  nickname: jfwilkus

prune:
  directories:
    - manual
    - man
    - include
    - build
    - cgi-bin
    - conf/extra
    - conf/original
    - icons
    - error
  files:
    - error/README
    - bin/apxs

```

# Development

In order to build and install the module, you must use Dist::Zilla.

[![Build Status](https://api.travis-ci.org/jfwilkus/OS-Package.png)](https://travis-ci.org/jfwilkus/OS-Package)
