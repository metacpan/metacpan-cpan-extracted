#!/usr/bin/perl
use List::Util qw(any);
use LWP::Online qw(:skip_all);
use Test::More;
use URI;
use JSON;
use strict;

my $class = q{Net::RDAP};

require_ok $class;

my $rdap = $class->new;

isa_ok($rdap, $class);

my $domain = $rdap->domain('perl.org');

isa_ok($domain, $class.'::Object::Domain');

my $rar = [grep { any { 'registrar' eq $_ } $_->roles } $domain->entities]->[0];

isa_ok($rar, $class.'::Object::Entity');

isa_ok($rar->parent, $class.'::Object::Domain');

isa_ok($rar->top, $class.'::Object::Domain');

my @chain = $rar->chain;
cmp_ok(scalar(@chain), '==', 2);

my $abuse = [grep { any { 'abuse' eq $_ } $_->roles } $rar->entities]->[0];

isa_ok($abuse, $class.'::Object::Entity');

isa_ok($abuse->parent, $class.'::Object::Entity');

isa_ok($rar->top, $class.'::Object::Domain');

@chain = $abuse->chain;
cmp_ok(scalar(@chain), '==', 3);

done_testing;
