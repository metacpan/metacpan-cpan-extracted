use strict;
use warnings;
use Test::More;
use Storable qw( dclone );

use Papery::Util qw( merge_meta );

my @tests = (
    [ 'empty empty empty', {}, {}, {} ],
    [ 'add to empty', {}, { zlonk => 'bam' }, { zlonk => 'bam' } ],
    [ 'add empty', { zlonk => 'bam' }, {}, { zlonk => 'bam' } ],
    [   'append string',
        { zlonk    => 'bam' },
        { 'zlonk+' => ' kapow' },
        { zlonk    => 'bam kapow' }
    ],
    [   'append string to naught',
        {},
        { 'zlonk+' => 'kapow' },
        { zlonk    => 'kapow' }
    ],
    [   'prepend string',
        { zlonk    => 'bam' },
        { 'zlonk-' => 'kapow ' },
        { zlonk    => 'kapow bam' }
    ],
    [   'prepend string to naught',
        {},
        { 'zlonk-' => 'kapow' },
        { zlonk    => 'kapow' }
    ],
    [   'update array at the end',
        { zlonk    => [ 'bam', 'kapow' ] },
        { 'zlonk+' => ['awk'] },
        { zlonk => [ 'bam', 'kapow', 'awk' ] }
    ],
    [   'update array at the beginning',
        { zlonk    => [ 'bam', 'kapow' ] },
        { 'zlonk-' => ['awk'] },
        { zlonk => [ 'awk', 'bam', 'kapow' ] }
    ],
    [   'update hash, deep string',
        {   zlonk => { bam => 'kapow', awk => 'zzzzzwap' },
            aie   => 'clunk_eth'
        },
        { 'zlonk+' => { bam => 'vronk', 'awk+' => ' urkkk' } },
        {   zlonk => { bam => 'vronk', 'awk' => 'zzzzzwap urkkk' },
            aie   => 'clunk_eth'
        },
    ],
    [   'update hashe',
        { zlonk    => { vronk => [ 'bam', 'kapow' ] } },
        { 'zlonk+' => { vronk => ['awk'] } },
        { zlonk    => { vronk => ['awk'] } }
    ],
    [   'deep array update, at the end',
        { zlonk    => { vronk    => [ 'bam', 'kapow' ] } },
        { 'zlonk+' => { 'vronk+' => ['awk'] } },
        { zlonk => { vronk => [ 'bam', 'kapow', 'awk' ] } }
    ],
    [   'deep array update, at the beginning',
        { zlonk    => { vronk    => [ 'bam', 'kapow' ] } },
        { 'zlonk+' => { 'vronk-' => ['awk'] } },
        { zlonk => { vronk => [ 'awk', 'bam', 'kapow' ] } }
    ],
    [   'ignore internal keys',
        { __private => 'zlonk' },
        { __private => 'bam' },
        { __private => 'zlonk' },
    ],
);

plan tests => 2 * @tests;

for my $t (@tests) {
    my ( $desc, $meta, $extra, $expected ) = @$t;
    my $extra_clone = dclone($extra);
    is_deeply( merge_meta( $meta, $extra ), $expected,
        "Merged meta ($desc)" );
    is_deeply( $extra, $extra_clone,
        '... without modifying the $extra hash' );
}

