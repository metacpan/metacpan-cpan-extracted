#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::LongString;

use File::Basename;
use File::Spec;

use_ok 'MySQL::Workbench::Parser';

my $mwb = File::Spec->catfile(
    dirname( __FILE__ ),
    'comment.mwb',
);

my $check = qq|---
tables:
  -
    columns:
      -
        autoincrement: '1'
        comment: "{\\n    \\"description\\" : \\"A description of the column\\"\\n}"
        datatype: INT
        default_value: ''
        length: '-1'
        name: test_id
        not_null: '1'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: passphrase
        not_null: '0'
        precision: '-1'
      -
        autoincrement: '0'
        comment: ''
        datatype: VARCHAR
        default_value: ''
        length: '45'
        name: another_phrase
        not_null: '0'
        precision: '-1'
    comment: "{\\n    \\"passphrase\\" : {\\n        \\"passphrase\\"       : \\"rfc2307\\",\\n        \\"passphrase_class\\" : \\"SaltedDigest\\",\\n        \\"passphrase_args\\" : {\\n            \\"algorithm\\"   : \\"SHA-1\\",\\n            \\"salt_random\\" : 20\\n        },\\n        \\"passphrase_check_method\\" : \\"check_passphrase\\"\\n    }\\n}"
    foreign_keys: {}
    indexes:
      -
        columns:
          - test_id
        name: PRIMARY
        type: PRIMARY
    name: Test
    primary_key:
      - test_id
|;

my $parser = MySQL::Workbench::Parser->new( file => $mwb );
is_string $parser->dump, $check;

done_testing();
