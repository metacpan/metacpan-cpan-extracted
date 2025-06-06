#!/usr/bin/env perl -T
use Carp::Always;
use LWP::Online qw(:skip_all);
use Net::DNS;
use Net::IP;
use Net::ASN;
use List::Util qw(any);
use Test::More;
use URI;
use JSON;
use strict;

my $class = q{Net::RDAP};

require_ok $class;

my $rdap = $class->new;

isa_ok($rdap, $class);

$rdap->exists(Net::DNS::Domain->new('perl.org'));

my @tests = (
    [\&Net::RDAP::domain,   'perl.org',                         $class.q{::Object::Domain}],
    [\&Net::RDAP::domain,   Net::DNS::Domain->new('perl.com'),  $class.q{::Object::Domain}],
    [\&Net::RDAP::ip,       '8.8.8.8',                          $class.q{::Object::IPNetwork}],
    [\&Net::RDAP::ip,       Net::IP->new('8.8.8.8'),            $class.q{::Object::IPNetwork}],
    [\&Net::RDAP::autnum,   1701,                               $class.q{::Object::Autnum}],
    [\&Net::RDAP::autnum,   Net::ASN->new(1701),                $class.q{::Object::Autnum}],
    [\&Net::RDAP::domain,   'test.invalid',                     $class.q{::Error}],
);

foreach my $test (@tests) {
    my $object = $test->[0]->($rdap, $test->[1]);
    isa_ok($object, $test->[2]);

    if ($object->isa($class.q{::Error})) {
        ok(int($object->errorCode) == $object->errorCode);
        ok($object->title);

    } else {
        foreach my $event ($object->events) {
            $event->action;
            $event->actor;
            $event->date;
        }

        $object->class;
        $object->handle;
        $object->port43;
        $object->name if ($object->can('name'));
        $object->unicodeName if ($object->can('unicodeName'));
        $object->start if ($object->can('start'));
        $object->end if ($object->can('end'));
        $object->type if ($object->can('type'));
        $object->country if ($object->can('country'));

        $object->TO_JSON;

        cmp_ok(scalar($object->status), '>=', 0);
        cmp_ok(scalar($object->conformance), '>', 0);

        foreach my $entity ($object->entities) {
            foreach my $id ($entity->ids) {
                $id->type;
                $id->identifier;
            }

            cmp_ok(scalar($entity->roles), '>', 0);

            isa_ok($entity->jcard, $class.q{::JCard});
        }

        foreach my $link ($object->links) {
            $link->rel;
            $link->context;
            $link->href;
            $link->hreflang;
            $link->type;
            $link->title;
            $link->media;
            $link->is_rdap;
            $link->TO_JSON;
        }

        foreach my $remark ($object->remarks, $object->notices) {
            $remark->title;
            $remark->type;
            $remark->description;
        }
    }
}

my $result = $rdap->domain((q{test.} x 13).q{com});
isa_ok($result, $class.q{::Error});

my $domain = $rdap->domain('perl.org');
ok($domain->zoneSigned || 1);
ok($domain->delegationSigned || 1);
cmp_ok(scalar($domain->ds), '>', 0);

isa_ok($domain->event('registration'),  $class.q{::Event});
isa_ok($domain->registrar,              $class.q{::Object::Entity});

my $link = $domain->related;
isa_ok($link, $class.q{::Link});

my $rar_record = $rdap->fetch($link);
isa_ok($rar_record,             $class.q{::Object::Domain});
isa_ok($rar_record->registrant, $class.q{::Object::Entity});

done_testing;
