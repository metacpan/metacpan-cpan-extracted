package # hide
Data_Test_Arguments;

use 5.008003;
use warnings;
use strict;



sub valid_args {
    return [
        {
            expected => "<>",
            args => [ 'Prompt: ' ],
        },
        {
            expected => "<default>",
            args => [ 'Prompt: ', 'default' ],
        },
        {
            expected => "<default>",
            args => [ 'Prompt: ', { default => 'default', no_echo => 0 } ],
        },
        {
            expected => "<DEFAULT>",
            args => [ 'Prompt: ', { no_echo => 1, default => "DEFAULT" } ],
        },
        {
            expected => "<123>",
            args => [ "Prompt: ", { no_echo => 2, default => 123 } ],
        },
    ];
}


sub invalid_args {
    return [
        #{
        #    expected => "<>",
        #    args => [],
        #},
        {
            expected => "<readline: a reference is not a valid prompt.>",
            args => [ {} ],
        },
        {
            expected => "<readline: a reference is not a valid prompt.>",
            args => [ [] ],
        },
        {
            expected => "<readline: the (optional) second argument must be a string or a HASH reference>",
            args => [ 'Prompt: ', [] ],
        },
        {
            expected => "<readline: option 'default' : a reference is not a valid value.>",
            args => [ 'Prompt: ', { default => [] } ],
        },
        {
            expected => "<readline: option 'default' : a reference is not a valid value.>",
            args => [ 'Prompt: ', { default => {} } ],
        },
        {
            expected => "<readline: option 'no_echo' : '-1' is not a valid value.>",
            args => [ 'Prompt: ', { no_echo => -1 } ],
        },
        {
            expected => "<readline: option 'no_echo' : '3' is not a valid value.>",
            args => [ 'Prompt: ', { no_echo => 3 } ],
        },
        {
            expected => "<readline: option 'no_echo' : 'a' is not a valid value.>",
            args => [ 'Prompt: ', { no_echo => 'a' } ],
        },
        {
            expected => "<readline: option 'no_echo' : a reference is not a valid value.>",
            args => [ 'Prompt: ', { no_echo => [] } ],
        },
        {
            expected => "<readline: option 'no_echo' : a reference is not a valid value.>",
            args => [ 'Prompt: ', { no_echo => {} } ],
        },
        {
            expected => "<readline: option 'default' : a reference is not a valid value.>",
            args => [ 'Prompt: ', { default => {}, no_echo => 1 } ],
        },
        {
            expected => "<readline: 'hello' is not a valid option name>",
            args => [ 'Prompt: ', { default => 'default', hello => 1, no_echo => 0 } ],
        },
    ];
}


1;

__END__
