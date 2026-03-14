#!/usr/bin/env perl

# verify_token.pl — Verify a Zitadel JWT using Net::Async::Zitadel
#
# Usage:
#   ZITADEL_ISSUER=https://zitadel.example.com \
#   ZITADEL_TOKEN=eyJ... \
#   perl examples/verify_token.pl

use strict;
use warnings;
use IO::Async::Loop;
use Net::Async::Zitadel;

my $issuer = $ENV{ZITADEL_ISSUER} or die "ZITADEL_ISSUER required\n";
my $token  = $ENV{ZITADEL_TOKEN}  or die "ZITADEL_TOKEN required\n";

my $loop = IO::Async::Loop->new;

my $z = Net::Async::Zitadel->new(issuer => $issuer);
$loop->add($z);

my $claims = $z->oidc->verify_token_f($token)->get;

printf "Subject:  %s\n", $claims->{sub}  // '(none)';
printf "Issuer:   %s\n", $claims->{iss}  // '(none)';
printf "Audience: %s\n", ref $claims->{aud} ? join(', ', @{$claims->{aud}}) : ($claims->{aud} // '(none)');
printf "Expires:  %s\n", $claims->{exp} ? scalar localtime($claims->{exp}) : '(none)';
