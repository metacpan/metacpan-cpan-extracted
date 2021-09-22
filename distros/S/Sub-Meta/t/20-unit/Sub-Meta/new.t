use Test2::V0;

use Sub::Meta;
use Sub::Meta::Parameters;

subtest 'args: parameters' => sub {
    subtest "{ args => ['Str'] }" => sub {
        my $parameters = { args => ['Str'] };
        my $meta = Sub::Meta->new(parameters => $parameters);
        is $meta->parameters, Sub::Meta::Parameters->new($parameters);
        ok !$meta->is_method;
    };

    subtest "{ args => ['Str'], nshift => 1 }" => sub {
        my $parameters = { args => ['Str'], nshift => 1 };
        my $meta = Sub::Meta->new(parameters => $parameters);
        is $meta->parameters, Sub::Meta::Parameters->new($parameters);
        ok $meta->is_method;
    };

    subtest "{ args => ['Str'], invocant => { name => 'class' } }" => sub {
        my $parameters = { args => ['Str'], invocant => { name => 'class' } };
        my $meta = Sub::Meta->new(parameters => $parameters);
        is $meta->parameters, Sub::Meta::Parameters->new($parameters);
        ok $meta->is_method;
    };
};

subtest 'args: args' => sub {

    my $invocant = Sub::Meta::Param->new(invocant => 1);

    my @tests = (
        "{args => ['Str']}"                        => {args => ['Str']}                                         => {args => ['Str']},
        "{args => ['Str'], slurpy => 1}"           => {args => ['Str'], slurpy => 1}                            => {args => ['Str'], slurpy => 1},
        "{args => ['Str'], nshift => 1}"           => {args => ['Str'], nshift => 1}                            => {args => ['Str'], nshift => 1},
        "if is_method is 1, then nshift is 1"      => {args => ['Str'], is_method => 1}                         => {args => ['Str'], nshift => 1},
        "if is_method is 0, then nshift is 0"      => {args => ['Str'], is_method => 0}                         => {args => ['Str'], nshift => 0},
        "priority: nshift > is_method"             => {args => ['Str'], is_method => 0, nshift => 1}            => {args => ['Str'], nshift => 1},
        "priority: invocant > is_method"           => {args => ['Str'], is_method => 0, invocant => $invocant } => {args => ['Str'], nshift => 1, invocant => $invocant },
        "priority: invocant > nshift"              => {args => ['Str'], nshift => 0, invocant => $invocant }    => {args => ['Str'], nshift => 1, invocant => $invocant },
        "if invocant is set, then set nshift to 1" => {args => ['Str'], invocant => { name => '$class' }}       => {args => ['Str'], nshift => 1, invocant => { name => '$class' }},
    );

    while (my ($message, $a, $b) = splice @tests, 0, 3) {
        my $meta = Sub::Meta->new($a);
        my $parameters = Sub::Meta::Parameters->new($b);

        subtest $message => sub {
            is $meta->args, $parameters->args, 'args';
            is $meta->is_method, !!$parameters->nshift, 'is_method';
            is $meta->slurpy, $parameters->slurpy, 'slurpy';
            is $meta->nshift, $parameters->nshift, 'nshift';
            is $meta->invocant, $parameters->invocant, 'invocant';
        };
    }
};

done_testing;
