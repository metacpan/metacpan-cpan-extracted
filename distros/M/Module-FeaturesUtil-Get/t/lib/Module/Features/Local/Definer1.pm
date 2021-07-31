package Module::Features::Local::Definer1;

use 5.010001;
use strict;
use warnings;

our %FEATURES_DEF = (
    v => 1,
    summary => 'Dummy feature set, for testing',
    features => {
        feature1 => {
            summary => 'First feature, a bool',
        },
        feature2 => {
            summary => 'Second feature, a bool, required',
            req => 1,
        },
        feature3 => {
            summary => 'Second feature, a string',
            schema => ['str*', in=>['a','b','c']],
        },
    },
);

1;
