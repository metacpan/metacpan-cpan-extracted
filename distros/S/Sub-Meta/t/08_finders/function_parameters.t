use Test2::V0;
use Test2::Require::Module 'Function::Parameters', '2.000003';

use Function::Parameters;

use Sub::Meta::Creator;
use Sub::Meta::Finder::FunctionParameters;

sub find_materials { goto &Sub::Meta::Finder::FunctionParameters::find_materials }
sub param { Sub::Meta::Param->new(@_) }

sub Str() { bless {}, 'SomeStr' }
sub Int() { bless {}, 'SomeInt' }

sub not_function_paramters {};
fun case_fun_positional(Str $a) {};
fun case_fun_positional_optional(Str $a='aaa') {};
fun case_fun_named(Str :$a) {};
fun case_fun_named_optional(Str :$a='aaa') {};
fun case_fun_positional_and_optional(Str $a, Int $b=123) {};
fun case_fun_slurpy(@args) {};
fun case_fun_slurpy_with_type(Str @args) {};
method case_method() {}
method case_class_method($class: ) {}
method case_class_method_with_type(Str $class: ) {}

subtest 'find_materials' => sub {
    is find_materials(\&not_function_paramters), undef, 'not_function_paramters';
    is find_materials(\&case_fun_positional), {
        sub       => \&case_fun_positional,
        is_method => !!0,
        parameters => {
            args   => [ { type => Str, name => '$a', positional => 1, required => 1 } ],
            nshift => 0,
        },
    }, 'case_fun_positional';

    is find_materials(\&case_fun_positional_optional), {
        sub       => \&case_fun_positional_optional,
        is_method => !!0,
        parameters => {
            args   => [ { type => Str, name => '$a', positional => 1, required => 0 } ],
            nshift => 0,
        },
    }, 'case_fun_positional_optional';
    
    is find_materials(\&case_fun_named), {
        sub       => \&case_fun_named,
        is_method => !!0,
        parameters => {
            args   => [ { type => Str, name => '$a', named => 1, required => 1 } ],
            nshift => 0,
        },
    }, 'case_fun_named';

    is find_materials(\&case_fun_named_optional), {
        sub       => \&case_fun_named_optional,
        is_method => !!0,
        parameters => {
            args   => [ { type => Str, name => '$a', named => 1, required => 0 } ],
            nshift => 0,
        },
    }, 'case_fun_named_optional';

    is find_materials(\&case_fun_positional_and_optional), {
        sub       => \&case_fun_positional_and_optional,
        is_method => !!0,
        parameters => {
            args   => [
                { type => Str, name => '$a', positional => 1, required => 1 },
                { type => Int, name => '$b', positional => 1, required => 0 },
            ],
            nshift => 0,
        },
    }, 'case_fun_positional_and_optional';

    is find_materials(\&case_fun_slurpy), {
        sub       => \&case_fun_slurpy,
        is_method => !!0,
        parameters => {
            args   => [  ],
            nshift => 0,
            slurpy => { name => '@args' },
        },
    }, 'case_fun_slurpy';

    is find_materials(\&case_fun_slurpy_with_type), {
        sub       => \&case_fun_slurpy_with_type,
        is_method => !!0,
        parameters => {
            args   => [  ],
            nshift => 0,
            slurpy => { name => '@args', type => Str },
        },
    }, 'case_fun_slurpy_with_type';

    is find_materials(\&case_method), {
        sub       => \&case_method,
        is_method => !!1,
        parameters => {
            args   => [ ],
            nshift => 1,
            invocant => { name => '$self' },
        },
    }, 'case_method';

    is find_materials(\&case_class_method), {
        sub       => \&case_class_method,
        is_method => !!1,
        parameters => {
            args   => [ ],
            nshift => 1,
            invocant => { name => '$class' },
        },
    }, 'case_class_method';

    is find_materials(\&case_class_method_with_type), {
        sub       => \&case_class_method_with_type,
        is_method => !!1,
        parameters => {
            args   => [ ],
            nshift => 1,
            invocant => { name => '$class', type => Str },
        },
    }, 'case_class_method_with_type';
};

subtest 'create' => sub {
    my $creator = Sub::Meta::Creator->new(
        finders => [ \&Sub::Meta::Finder::FunctionParameters::find_materials ],
    );

    subtest 'not_function_paramters' => sub {
        is $creator->create(\&not_function_paramters), undef, 'not_function_paramters';
    };

    subtest 'case_fun_positional' => sub {
        my $sub = \&case_fun_positional;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [ param(type => Str, name => '$a', positional => 1, required => 1) ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_fun_positional_optional' => sub {
        my $sub = \&case_fun_positional_optional;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [ param(type => Str, name => '$a', positional => 1, required => 0) ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_fun_named' => sub {
        my $sub = \&case_fun_named;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [ param(type => Str, name => '$a', named => 1, required => 1) ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_fun_named_optional' => sub {
        my $sub = \&case_fun_named_optional;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [ param(type => Str, name => '$a', named => 1, required => 0) ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_fun_positional_and_optional' => sub {
        my $sub = \&case_fun_positional_and_optional;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [
            param(type => Str, name => '$a', positional => 1, required => 1),
            param(type => Str, name => '$b', positional => 1, required => 0),
        ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_fun_slurpy' => sub {
        my $sub = \&case_fun_slurpy;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [ ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        is $meta->slurpy, param(name => '@args'), 'slurpy';
    };

    subtest 'case_fun_slurpy_with_type' => sub {
        my $sub = \&case_fun_slurpy_with_type;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!0, 'is_method';
        is $meta->args, [ ], 'args';
        is $meta->nshift, 0, 'nshift';
        ok !$meta->invocant, 'invocant';
        is $meta->slurpy, param(type => Str, name => '@args'), 'slurpy';
    };

    subtest 'case_method' => sub {
        my $sub = \&case_method;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!1, 'is_method';
        is $meta->args, [ ], 'args';
        is $meta->nshift, 1, 'nshift';
        is $meta->invocant, param(name => '$self', invocant => 1), 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_class_method' => sub {
        my $sub = \&case_class_method;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!1, 'is_method';
        is $meta->args, [ ], 'args';
        is $meta->nshift, 1, 'nshift';
        is $meta->invocant, param(name => '$class', invocant => 1), 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

    subtest 'case_class_method_with_type' => sub {
        my $sub = \&case_class_method_with_type;

        my $meta = $creator->create($sub);
        is $meta->sub, $sub, 'sub';
        is $meta->is_method, !!1, 'is_method';
        is $meta->args, [ ], 'args';
        is $meta->nshift, 1, 'nshift';
        is $meta->invocant, param(name => '$class', type => Str, invocant => 1), 'invocant';
        ok !$meta->slurpy, 'slurpy';
    };

};

done_testing;
