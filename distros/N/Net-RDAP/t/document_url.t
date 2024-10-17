#!/usr/bin/perl
use LWP::Online qw(:skip_all);
use Test::More;
use URI;
use JSON;
use strict;

my $class = q{Net::RDAP};

require_ok $class;

my $rdap = $class->new;

isa_ok($rdap, $class);

my $domain = $rdap->domain('example.com');

isa_ok($domain, $class.'::Object::Domain');

isa_ok($domain->document_url, 'URI');

foreach my $entity ($domain->entities) {
    isa_ok($entity, $class.'::Object::Entity');
    isa_ok($entity->document_url, 'URI');
    is($entity->document_url->as_string, $domain->document_url->as_string);

    check_links($entity->links);
}

foreach my $nameserver ($domain->nameservers) {
    isa_ok($nameserver, $class.'::Object::Nameserver');
    isa_ok($nameserver->document_url, 'URI');
    is($nameserver->document_url->as_string, $domain->document_url->as_string);

    check_links($nameserver->links);
}

foreach my $event ($domain->events) {
    isa_ok($event, $class.'::Event');
    isa_ok($event->document_url, 'URI');
    is($event->document_url->as_string, $domain->document_url->as_string);

    check_links($event->links);
}

foreach my $remark ($domain->remarks) {
    isa_ok($remark, $class.'::Remark');
    isa_ok($remark->document_url, 'URI');
    is($remark->document_url->as_string, $domain->document_url->as_string);

    check_links($remark->links);
}

foreach my $notice ($domain->notices) {
    isa_ok($notice, $class.'::Notice');
    isa_ok($notice->document_url, 'URI');
    is($notice->document_url->as_string, $domain->document_url->as_string);

    check_links($notice->links);
}

check_links($domain->links);

sub check_links {
    foreach my $link (@_) {
        isa_ok($link, $class.'::Link');

        isa_ok($link->context, 'URI');
        isa_ok($link->href, 'URI');
    }
}

done_testing;
