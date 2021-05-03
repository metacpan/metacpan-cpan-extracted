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
    my $check = sub {
        my ($a, $b) = @_;
        my $meta = Sub::Meta->new($a);
        my $parameters = Sub::Meta::Parameters->new($b);
        is $meta->parameters, $parameters;
    };

    $check->({args => ['Str']}, {args => ['Str']});
    $check->({args => ['Str'], slurpy => 1}, {args => ['Str'], slurpy => 1});
    $check->({args => ['Str'], nshift => 1}, {args => ['Str'], nshift => 1});

    $check->({args => ['Str'], is_method => 1}, {args => ['Str'], nshift => 1},
            'if is_method flag is set, then set nshift to 1' );
    $check->({args => ['Str'], is_method => 0}, {args => ['Str'], nshift => 0});
    $check->({args => ['Str'], nshift => 1, is_method => 0}, {args => ['Str'], nshift => 1}, 'nshift has priority');

    $check->({args => ['Str'], invocant => { name => '$class' }}, {args => ['Str'], nshift => 1, invocant => { name => '$class' }},
            'if invocant is set, then set nshift to 1' );
};

done_testing;
