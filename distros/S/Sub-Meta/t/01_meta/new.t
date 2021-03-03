use Test2::V0;

use Sub::Meta;
use Sub::Meta::Parameters;

use JSON::PP;
my $json = JSON::PP->new->allow_nonref->convert_blessed->canonical;

subtest 'args: parameters' => sub {
    my $meta = Sub::Meta->new(
        parameters => { args => ['Str'] },
    );
    is $meta->parameters, Sub::Meta::Parameters->new(args => ['Str']);
};

subtest 'args: args' => sub {

    my $check = sub {
        my ($a, $b) = @_;
        my $meta = Sub::Meta->new($a);
        my $parameters = Sub::Meta::Parameters->new($b);
        is $meta->parameters, $parameters, $json->encode($a);
    };

    $check->({args => ['Str']}, {args => ['Str']});
    $check->({args => ['Str'], slurpy => 1}, {args => ['Str'], slurpy => 1});
    $check->({args => ['Str'], nshift => 1}, {args => ['Str'], nshift => 1});
    $check->({args => ['Str'], is_method => 1}, {args => ['Str'], nshift => 1}, 'if is_method flag is set, then set nshift to 1' );
    $check->({args => ['Str'], is_method => 0}, {args => ['Str'], nshift => 0});
    $check->({args => ['Str'], nshift => 1, is_method => 0}, {args => ['Str'], nshift => 1}, 'nshift has priority');
};

done_testing;
