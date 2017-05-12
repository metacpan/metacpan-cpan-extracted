use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 3;

BEGIN { use_ok('PHP::Serialization') };

my $data = PHP::Serialization::unserialize(
    q{a:1:{s:3:"lll";a:2:{i:195;a:1:{i:111;s:3:"bbb";}i:194;a:1:{i:222;s:3:"ccc";}}}}
);

    is_deeply($data,
        {
            'lll' => {
                '195' => {111 => 'bbb'},
                '194' => {222 => 'ccc'},
            }
        },
		'Only numbers as hashindexes works'		
    ) or warn Dumper($data);

$data = PHP::Serialization::unserialize(
    q{a:1:{s:3:"lll";a:2:{i:195;a:2:{i:0;i:111;i:1;s:3:"bbb";}i:194;a:2:{i:0;i:222;i:1;s:3:"ccc";}}}}
);

    is_deeply($data,
        {
            'lll' => {
                '195' => [111, 'bbb'],
                '194' => [222, 'ccc'],
            }
        },
		'Only numbers as hashindexes works with arrays'
    ) or warn Dumper($data);
