#!/usr/bin/perl
require 5.006_001;
use Test::More tests => 2;
use strict;
use warnings;
use RPSL::Parser;

my $object = <<RPSL;
person:       I. M. A. Fool
address:      F.A.K.E Corporation
address:      226 Nowhere st
address:      10DD10 Nevercity
              Neverland
phone:        +99-99-999-9999
fax-no:       +99-99-999-9999
e-mail:       xxx\@somewhere.com
nic-hdl:      XXX007-RIPE # Look, ma, I'm 007! ;)
mnt-by:       NICE-GUY-MNT
changed:      xxx\@somewhere.com 20001016
source:       RIPE
RPSL

my $expected_structure = {
    meta => {
        'omit_key' => [4],
        'comment'  => { 8 => q{Look, ma, I'm 007! ;)} },
        'order'    => [
            'person', 'address', 'address', 'address', 'address', 'phone',
            'fax-no', 'e-mail',  'nic-hdl', 'mnt-by',  'changed', 'source'
        ],
    },
    'type' => 'person',
    'data' => {
        'source'  => 'RIPE',
        'mnt-by'  => 'NICE-GUY-MNT',
        'phone'   => '+99-99-999-9999',
        'nic-hdl' => 'XXX007-RIPE',
        'fax-no'  => '+99-99-999-9999',
        'e-mail'  => 'xxx@somewhere.com',
        'changed' => 'xxx@somewhere.com 20001016',
        'person'  => 'I. M. A. Fool',
        'address' => [
            'F.A.K.E Corporation',
            '226 Nowhere st',
            '10DD10 Nevercity',
            'Neverland'
        ]
    },
    'key' => 'I. M. A. Fool'
};

{    # classic interface
    my $parser = new RPSL::Parser;
    my $data   = $parser->parse($object);
    is_deeply( $data, $expected_structure );
}

{    # object-less interface
    my $data = RPSL::Parser->parse($object);
    is_deeply( $data, $expected_structure );
}
