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

use Test::More tests => 1 + 2;
use Test::NoWarnings;

use Plack::Middleware::ExtractUriLanguage;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

############################################################################

{
  my %test = (
    client => sub {
      my ($cb) = @_;
      my $res = $cb->( GET "http://localhost/de/path" );
      is( $res->content, "de", "ExtractUriLanguageTag" );
      return;
    },
    app => builder {
      enable 'Plack::Middleware::ExtractUriLanguage', ExtractUriLanguageTag => 'MYLANGUAGETAG';
      sub {
        my ($env) = @_;
        [
          200,
          [ 'Content-Type' => 'text/plain' ],
          [ sprintf "%s", $env->{MYLANGUAGETAG} // '' ],
        ];
        }
    },
  );

  test_psgi %test;
}

############################################################################

{
  my %test = (
    client => sub {
      my ($cb) = @_;
      my $res = $cb->( GET "http://localhost/de/path" );
      is( $res->content, "/de/path", "ExtractUriLanguageOrig" );
      return;
    },
    app => builder {
      enable 'Plack::Middleware::ExtractUriLanguage', ExtractUriLanguageOrig => 'MYPATHORIG';
      sub {
        my ($env) = @_;
        [
          200,
          [ 'Content-Type' => 'text/plain' ],
          [ sprintf "%s", $env->{MYPATHORIG} // '' ],
        ];
        }
    },
  );

  test_psgi %test;
}

############################################################################
1;
