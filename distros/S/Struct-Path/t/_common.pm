package _common;

# common parts for Struct::Path tests

use parent qw(Exporter);

our @EXPORT_OK = qw($s_array $s_hash $s_mixed);

our $s_array = [ 3, 1, 5, [9, [13], 7], 11];

our $s_hash = {a => 'av', b => {ba => 'vba', vb => 'vbb'}, c => {}};

our $s_mixed = {
    'a' => [
        {
            'a2a' => { 'a2aa' => 0 },
            'a2b' => { 'a2ba' => undef },
            'a2c' => { 'a2ca' => [] },
        },
        [ 'a0', 'a1' ],
    ],
    'b' => {
        'ba' => 'vba',
        'bb' => 'vbb',
    },
    'c' => 'vc',
};

1;
