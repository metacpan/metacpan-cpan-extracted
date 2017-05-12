#
# This file is part of Plack-Middleware-ExtractUriLanguage
#
# This software is Copyright (c) 2013 by BURNERSK.
#
# This is free software, licensed under:
#
#   The Artistic License 2.0 (GPL Compatible)
#
package Plack::Middleware::ExtractUriLanguage::examples::websimple;
use Web::Simple;

use FindBin '$RealBin';
use lib "$FindBin::Bin/../lib";

use Plack::Middleware::ExtractUriLanguage;

sub dispatch_request {
  my ( $self, $env ) = @_;

  sub () {
    Plack::Middleware::ExtractUriLanguage->new;
    }, sub () {
    my $content = "HelloExtractUriLanguage Test Script\n\n";
    $content .= sprintf "PATH_INFO:       %s\n", $env->{PATH_INFO}      // 'N/A';
    $content .= sprintf "PATH_INFO_ORIG:  %s\n", $env->{PATH_INFO_ORIG} // 'N/A';
    $content .= sprintf "LANGUAGE_TAG:    %s\n", $env->{LANGUAGE_TAG}   // 'N/A';
    [ 200, [ 'Content-Type' => 'text/plain' ], [$content] ];
    }
}

Plack::Middleware::ExtractUriLanguage::examples::websimple->run_if_script;
