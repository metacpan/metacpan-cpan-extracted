#!perl -T
package Test::Role::Kerberos;

use 5.010;
use strict;
use warnings;

use Moo;

with 'Role::Kerberos';

package main;

use Test::More;
use File::Temp;

plan tests => 9;


my $cc = File::Temp::tmpnam();

diag("Storing credential cache in $cc");

END {
    unlink $cc;
}

my $obj = new_ok('Test::Role::Kerberos' => [
    principal => 'yodawg@BOGUS.REALM',
    ccache    => $cc,
], 'object initialized with principal');

is($obj->realm, 'BOGUS.REALM', 'realm has been correctly supplanted');

#my @tickets = $obj->klist;
#ok(@tickets == 0, 'credential cache is empty');

$obj = new_ok('Test::Role::Kerberos' => [
    realm     => 'EXTRA.BOGUS.REALM',
    principal => 'oh-hi',
    ccache    => $cc,
], 'object initialized with realm');

isa_ok($obj->principal, 'Authen::Krb5::Principal', 'coerced principal');

is($obj->principal->realm, 'EXTRA.BOGUS.REALM',
   'realm has been correctly inserted into realm-less principal');

$obj = new_ok('Test::Role::Kerberos' => [
    realm     => 'DEFAULT.REALM',
    principal => 'principal@OTHER.REALM',
    ccache    => $cc,
], 'object initialized with realm and principal');

isnt($obj->realm, $obj->principal->realm, 'realms should be different');

TODO: {
    local $TODO = 'need a strategy for ';
};

SKIP: {
    skip 'Need $ENV{TEST_ROLE_KRB_PRINCIPAL}', 2
        unless $ENV{TEST_ROLE_KRB_PRINCIPAL};

    $obj = Test::Role::Kerberos->new(
        principal => $ENV{TEST_ROLE_KRB_PRINCIPAL},
        ccache    => $cc,
    );

    subtest 'try kinit with keytab' => sub {
        if ($ENV{TEST_ROLE_KRB_KEYTAB}) {
            plan tests => 1;
        }
        else {
            plan skip_all => 'Need $ENV{TEST_ROLE_KRB_KEYTAB}';
        }

        eval { $obj->kinit(keytab => $ENV{TEST_ROLE_KRB_KEYTAB}) };
        ok(!defined $@, 'successful kinit with keytab');
    };

    subtest 'try kinit with password' => sub {
        if ($ENV{TEST_ROLE_KRB_PASSWORD} || $ENV{TEST_ROLE_KRB_PW_PROMPT}) {
            plan tests => 1;
        }
        else {
            plan skip_all => 'Need $ENV{TEST_ROLE_KRB_PASSWORD}';
        }

        my $pw = $ENV{TEST_ROLE_KRB_PASSWORD};

        if ($ENV{TEST_ROLE_KRB_PW_PROMPT}) {
          # SKIP: {
            require Term::ReadPassword;
            #eval { require Term::ReadPassword };
          #       skip 'Need Term::ReadPassword for prompt', 1 if $@;

                # $pw = Term::ReadPassword::read_password
                #     (sprintf('Password for %s: ', $obj->principal->data));
                $pw = Term::ReadPassword::read_password
                    ('# Kerberos password: ');
            #};
        }

        eval { $obj->kinit(password => $pw) };
        diag($@) if $@;
        ok(!$@, 'successful kinit with password');
    };

    #$obj->kdestroy;
};
