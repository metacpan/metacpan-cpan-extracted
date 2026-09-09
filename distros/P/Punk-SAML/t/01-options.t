#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Punk::SAML ();

# The three provider ABIs resolve, and each is at or above the version
# whose members this dist calls.
#
# The comparison in psaml_abi.h is >=, never == and never against the
# installed header's own constant, so this test is what catches a NEED
# raised in that header without the matching floor raised in
# Makefile.PL: the two are one fact stated twice and they drift apart
# silently otherwise.
#
# The providers are hard prerequisites, so their absence is a broken
# install rather than a failing dist, and this skips by name. It does
# not skip when a provider is present and its table is too old: that is
# the failure this file exists to report.
my @provider = (
    ['File::Raw::XML', 'frx_abi'],
    ['Crypt::JWS',     'jws_abi'],
    ['Fetch',          'fetch_abi'],
);
for my $p (@provider) {
    my ($module) = @$p;
    eval "require $module; 1"
        or plan skip_all => "$module is not installed ($@)";
}

my @have = Punk::SAML::_abi_versions();
my @need = Punk::SAML::_abi_needs();
is scalar @have, 3, 'three provider tables resolve';
is scalar @need, 3, 'and three versions are needed';

for my $i (0 .. $#provider) {
    my ($module, $table) = @{ $provider[$i] };
    ok $have[$i] >= $need[$i],
        "$module $table: have $have[$i], need $need[$i]";
}

# Resolution is cached behind a static, so the second call must answer
# the same thing rather than re-resolving to something else.
is_deeply [Punk::SAML::_abi_versions()], \@have, 'resolution is stable';

done_testing();
