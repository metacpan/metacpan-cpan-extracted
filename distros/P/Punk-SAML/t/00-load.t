#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

BEGIN { use_ok('Punk::SAML') || print "Bail out!\n" }

# Every .pm does `use Punk::SAML ()` and nothing else, so the bundle is
# bootstrapped once by whichever loads first. Load each on its own terms.
use_ok($_) for qw(
    Punk::SAML::Error
    Punk::SAML::IdP
    Punk::SAML::Metadata
    Punk::SAML::Request
    Punk::SAML::Response
    Punk::SAML::Signature
    Punk::SAML::Time
    Punk::Plugin::SAML
    Punk::Command::SAML
);

diag("Testing Punk::SAML $Punk::SAML::VERSION, Perl $], $^X");

# The blessed error, thrown from C. This is here rather than in a phase-6
# test because it exercises the croak_sv shim in psaml_compat.h, and a
# shim behind #ifndef ships unrun otherwise: nothing local compiles one
# line of it. See the comment in that header for what this does and does
# not prove.
{
    my $err = do { local $@; eval { Punk::SAML::_throw('config') }; $@ };
    isa_ok $err, 'Punk::SAML::Error', 'a refusal throws an object';
    is $err->{code}, 'config', 'the code survives the throw';
    ok defined $err->{message}, 'and a message comes with it';
}

# The shim body itself, compiled unconditionally and driven directly, so
# it runs on this perl whether or not this perl selects it.
{
    my $obj = bless { code => 'probe' }, 'Punk::SAML::Error';
    my $got = do { local $@; eval { Punk::SAML::_croak_sv_selftest($obj) }; $@ };
    is ref($got), 'Punk::SAML::Error', 'the shim keeps a blessed error blessed';
    is $got->{code}, 'probe', 'and does not flatten it to a string';

    my $str = do { local $@; eval { Punk::SAML::_croak_sv_selftest("plain\n") }; $@ };
    is $str, "plain\n", 'and passes a string through unchanged';
}

done_testing();
