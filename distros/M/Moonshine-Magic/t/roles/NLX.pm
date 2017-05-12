package t::roles::NLX;

use Moonshine::Magic;

extends 'UNIVERSAL::Object';

has (
    nlx_spec => sub {
        return {
            rank => 1,
        };
    }
);

sub nlx_rank {
    return $_[0]->nlx_spec->{rank};
}

1;
