use strict;
use warnings;

use Test::More 0.96;

use Specio::Declare;
use Specio::Library::Builtins qw( HashRef Int Str );
use Specio::Library::Structured;

my @types = (
    t('Int'),
    t('HashRef'),
    t( 'HashRef', of => t('Int') ),
    declare(
        'Tuple[ Int, Str ]',
        parent => t(
            'Tuple',
            of => [
                t('Int'),
                t('Str'),
            ],
        ),
    ),
    declare(
        'Dict{ bar => Int, foo => Str }',
        parent => t(
            'Dict',
            of => {
                kv => {
                    foo => t('Str'),
                    bar => t('Int'),
                },
            },
        ),
    ),
    union( 'IntOrStr', of => [ t('Int'), t('Str') ] ),
    intersection( 'IntAndStr', of => [ t('Int'), t('Str') ] ),
    enum( 'Colors', values => [qw( red blue )] ),
    object_does_type('Foo'),
    any_does_type('Foo'),
    object_isa_type('Specio::Constraint::Simple'),
    any_isa_type('Specio::Constraint::Simple'),
    anon( parent => t( 'HashRef', of => t('Str') ) ),
);

for my $type (@types) {
    my $test_name = sprintf( "%s - $type", ref $type );
    subtest(
        $test_name,
        sub {

            unless ( $type->is_anon ) {
                is(
                    "$type", $type->name,
                    sprintf(
                        'stringifying a %s returns its name - %s', ref $type,
                        $type->name,
                    ),
                );
            }
            cmp_ok(
                $type, 'eq', $type,
                'type overloads eq so it is equal to itself'
            );
        }
    );
}

{
    my $anon1 = anon( parent => t( 'HashRef', of => t('Str') ) );
    is(
        "$anon1", '__ANON__(HashRef[Str])',
        "anonymous type stringification of $anon1"
    );

    my $anon2
        = anon( parent => anon( parent => t( 'HashRef', of => t('Str') ) ) );
    is(
        "$anon2", '__ANON__(__ANON__(HashRef[Str]))',
        "anonymous type stringification of $anon2"
    );

    my $anon3
        = anon( parent => enum( values => [qw( red blue )] ) );
    is(
        "$anon3", '__ANON__(__ANON__(Str))',
        "anonymous type stringification of $anon3"
    );
}

done_testing();
