#
# This file is part of Plack-Middleware-ExtractUriLanguage
#
# This software is Copyright (c) 2013 by BURNERSK.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More tests => 1 + 11;
use Test::NoWarnings;

use Plack::Middleware::ExtractUriLanguage;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::ExtractUriLanguage::Type ':all';

############################################################################

my $handler = builder {
  enable 'Plack::Middleware::ExtractUriLanguage';
  sub {
    my ($env) = @_;
    [
      200,
      [ 'Content-Type' => 'text/plain' ],
      [ sprintf "%s\n%s", $env->{$PATH_INFO_FIELD} // '', $env->{$DEFAULT_LANGUAGE_TAG_FIELD} // '' ],
    ];
    }
};

my $handler_orig = builder {
  enable 'Plack::Middleware::ExtractUriLanguage';
  sub {
    my ($env) = @_;
    [
      200,
      [ 'Content-Type' => 'text/plain' ],
      [ sprintf "%s", $env->{$DEFAULT_PATH_INFO_ORIG_FIELD} // '' ],
    ];
    }
};

############################################################################

my %test = (
  client => sub {
    my ($cb) = @_;
    my $uri_base = 'http://localhost';

    # No language tags
    foreach my $path (qw( / /page /page/subpage )) {
      my $res = $cb->( GET "$uri_base$path" );
      is( $res->content, "$path\n", "no language tag $path" );
    }

    # Valid language tags
    foreach my $lang (qw( de de-de de-DE )) {
      my $path = '/page';
      my $res  = $cb->( GET "$uri_base/$lang$path" );
      is( $res->content, "$path\n$lang", "language tag $lang" );
    }

    # Malformed language tags
    foreach my $lang (qw( dex de- de-x de-xxx )) {
      my $path = '/page';
      my $res  = $cb->( GET "$uri_base/$lang$path" );
      is( $res->content, "/$lang$path\n", "broken language tag $lang" );
    }

    return;
  },
  app => $handler,
);

test_psgi %test;

############################################################################

my %test_orig = (
  client => sub {
    my ($cb) = @_;

    # Original unmodified PATH_INFO
    {
      my $path = '/de/path';
      my $res  = $cb->( GET "http://localhost$path" );
      is( $res->content, "$path", "original unmodified $PATH_INFO_FIELD" );
    }

    return;
  },
  app => $handler_orig,
);

test_psgi %test_orig;

############################################################################
1;
