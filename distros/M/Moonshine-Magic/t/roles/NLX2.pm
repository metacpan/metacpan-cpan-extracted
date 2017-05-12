package t::roles::NLX2;

use Moonshine::Magic;

extends 'UNIVERSAL::Object';
with 't::roles::NLX';

sub nlx_spec {
    return {
        rank => 5,
    };
}

1;
