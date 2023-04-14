#!perl
use strict;
use warnings;
use Test2::V0;
use IO::Socket::SSL;

my @modules = <<'EOM' =~ m/([A-Z][A-Za-z0-9:]+)/g;
Net::Gemini::Server
Net::Gemini
EOM

my $loaded = 0;
for my $m (@modules) {
    local $@;
    eval "require $m";
    if ($@) { bail_out("require failed '$m': $@") }
    $loaded++;
}

diag("Testing Net::Gemini $Net::Gemini::VERSION, Perl $], $^X");
is( $loaded, scalar @modules );

# gemini needs SNI so we probably should ensure that that is around.
# this might be a problem on way old systems with way outdated OpenSSL.
# is there a minimum IO::Socket::SSL version we should pin to for SNI?
eval { is( IO::Socket::SSL->can_client_sni, 1 ) }
  or bail_out("IO::Socket::SSL cannot SNI??");

done_testing 2
