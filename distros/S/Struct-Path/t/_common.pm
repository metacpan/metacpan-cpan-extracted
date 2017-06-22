package _common;

# common parts for Struct::Path tests

use parent qw(Exporter);
use Data::Dumper;

our @EXPORT_OK = qw($s_array $s_hash $s_mixed t_dump);

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

# return neat one-line string of perl serialized structure
sub t_dump {
    return Data::Dumper->new([shift])->Terse(1)->Sortkeys(1)->Quotekeys(0)->Indent(0)->Deepcopy(1)->Dump();
}

1;
