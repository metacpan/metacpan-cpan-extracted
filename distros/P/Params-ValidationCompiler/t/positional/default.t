use strict;
use warnings;

use Test2::V0;
use Test2::Plugin::NoWarnings;

use Params::ValidationCompiler qw( validation_for );
use Specio::Declare;
use Specio::Library::Builtins;

{
    my $validator = validation_for(
        params => [
            { type => t('Int') },
            {
                default => 10,
            },
        ],
    );

    is(
        [ $validator->(3) ],
        [ 3, 10 ],
        'able to set defaults on positional validator'
    );

    is(
        [ $validator->( 3, undef ) ],
        [ 3, undef ],
        'default is only set when element does not exist'
    );
}

{
    my $validator = validation_for(
        params => [
            1,
            { default => 0 },
        ],
    );

    is(
        [ $validator->(0) ],
        [ 0, 0 ],
        'positional params with default are optional'
    );
}

{
    my $x         = 1;
    my $validator = validation_for(
        params => [
            1,
            {
                default => sub { $x++ }
            },
        ],
    );

    is(
        [ $validator->(0) ],
        [ 0, 1 ],
        'default sub for positional params is called'
    );
    is(
        [ $validator->(0) ],
        [ 0, 2 ],
        'default sub for positional params is called again'
    );
}

{
    declare(
        'UCStr',
        parent => t('Str'),
        where  => sub { $_[0] =~ /^[A-Z]+$/ },
    );
    coerce(
        t('UCStr'),
        from  => t('Str'),
        using => sub { uc $_[0] },
    );

    my $validator = validation_for(
        params => [
            1,
            {
                type    => t('UCStr'),
                default => sub {'ABC'}
            },
        ],
    );

    is(
        [ $validator->( 0, 'xyz' ) ],
        [ 0, 'XYZ' ],
        'coercion for positional param is called'
    );
    is(
        [ $validator->(0) ],
        [ 0, 'ABC' ],
        'default for position param with coercion is called'
    );
}

done_testing();
