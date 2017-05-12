
use Test::Most;
use if $ENV{AUTHOR_TESTING} || $ENV{RELEASE_TESTING}, 'Test::Warnings';

use_ok('Object::Signature::Portable');

is signature(), '37a6259cc0c1dae299a7866489dff0bd', 'MD5 no args';

is signature(undef), '37a6259cc0c1dae299a7866489dff0bd', 'MD5 undef';

is signature(''), '9d4568c009d203ab10e33ea9953a0264', 'MD5 blank string';

is signature( digest => 'MD5', data => '' ),
    '9d4568c009d203ab10e33ea9953a0264', 'MD5 blank string';

is signature(''), '9d4568c009d203ab10e33ea9953a0264', 'MD5 blank string';

is signature( digest => 'MD5', data => '' ),
    '9d4568c009d203ab10e33ea9953a0264', 'MD5 blank string';

is signature( digest => 'MD5', prefix => 1, data => '' ),
    'MD5:9d4568c009d203ab10e33ea9953a0264', 'MD5 blank string with prefix';

is signature( digest => 'MD5', format => 'b64udigest', data => '' ),
    'nUVowAnSA6sQ4z6plToCZA', 'MD5 blank string';

is signature('a'), '6067924ae1b1832abce3d12fe83755a9', 'MD5 string';

is signature( { foo => 1 } ), '51014459947d55c836fe74faf224e54a', 'MD5 hash';

done_testing;
