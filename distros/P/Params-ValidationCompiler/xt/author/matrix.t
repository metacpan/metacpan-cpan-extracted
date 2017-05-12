## no critic (Moose::RequireCleanNamespace)
use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Plugin::NoWarnings;
use Test2::Require::Perl '5.012';

use Hash::Merge qw( merge );
use List::AllUtils qw( first_index reduce );
use Params::ValidationCompiler qw( validation_for );
use Set::Scalar;

# It'd be nice to add a third parameter and test with three but that ends up
# running a ridiculous number of tests.
my %foo = _one_param_permutations('foo');
my %bar = _one_param_permutations('bar');

my %slurpy = _slurpy_param_permutations('slurpy');

OUTER:
for my $foo_desc ( sort keys %foo ) {
    subtest 'one parameter' => sub {
        my $p = $foo{$foo_desc};

        subtest $foo_desc => sub {
            subtest 'named params' => sub {
                _named_params_tests($p);
            };

            subtest 'positional params' => sub {
                _positional_params_tests($p);
            };

            subtest 'named_to_list params' => sub {
                _named_to_list_params_tests($p);
            };

            for my $slurpy_desc ( sort keys %slurpy ) {
                subtest 'slurpy named params' => sub {
                    _named_slurpy_tests( $p, $slurpy{$slurpy_desc} );
                };
                subtest 'slurpy positional params' => sub {
                    _positional_slurpy_tests( $p, $slurpy{$slurpy_desc} );
                };
            }
        };
    } or last OUTER;

    for my $bar_desc ( sort keys %bar ) {
        subtest 'two parameters' => sub {
            my @p = ( $foo{$foo_desc}, $bar{$bar_desc} );

            subtest "$foo_desc + $bar_desc" => sub {
                subtest 'named params' => sub {
                    _named_params_tests(@p);
                };

                subtest 'positional params' => sub {
                    _positional_params_tests(@p);
                };

                subtest 'named_to_list params' => sub {
                    _named_to_list_params_tests(@p);
                };
            };
        } or last OUTER;
    }
}

done_testing();

sub _named_params_tests {
    my @p = @_;

    my $named_v;
    is(
        dies {
            $named_v = validation_for(
                params => { map { $_->{key} => $_->{spec} } @p } );
        },
        undef,
        'no exception compiling named params validator'
    ) or return;

    _run_param_tests(
        \@p,
        'named',
        sub {
            my $input  = shift;
            my $output = shift;

            is(
                { $named_v->( %{$input} ) },
                $output,
                'input as k/v pairs'
            );

            is(
                { $named_v->($input) },
                $output,
                'input as hashref'
            );
        },
    );
}

sub _positional_params_tests {
    my @p = @_;

    # If this permutation has an optional param before a required param then
    # we cannot run these tests, as this is not allowed.
    my $first_o
        = first_index { $_->{spec}{optional} || exists $_->{spec}{default} }
    @p;
    my $first_r = first_index {
        !( $_->{spec}{optional} || exists $_->{spec}{default} )
    }
    @p;

    if ( $first_o >= 0 && $first_o < $first_r ) {
    SKIP: {
            skip(
                'test would end up with optional params before required',
                1
            );
        }
        return;
    }

    my $pos_v;
    is(
        dies {
            $pos_v = validation_for( params => [ map { $_->{spec} } @p ] )
        },
        undef,
        'no exception compiling positional params validator'
    ) or return;

    _run_param_tests(
        \@p,
        'pos',
        sub {
            my $input  = shift;
            my $output = shift;

            is(
                [ $pos_v->( @{$input} ) ],
                $output,
                'input as list'
            );
        },
    );
}

sub _named_to_list_params_tests {
    my @p = @_;

    my @sorted_p = sort { $a->{key} cmp $b->{key} } @p;

    my $ntl_v;
    is(
        dies {
            $ntl_v = validation_for(
                params => [ map { $_->{key} => $_->{spec} } @sorted_p ],
                named_to_list => 1,
            );
        },
        undef,
        'no exception compiling positional params validator with named_to_list'
    ) or return;

    _run_param_tests(
        \@p,
        'named',
        sub {
            my $input  = shift;
            my $output = shift;

            is(
                [ $ntl_v->($input) ],
                [ map { $output->{$_} } map { $_->{key} } @sorted_p ],
            );
        },
    );
}

sub _named_slurpy_tests {
    my $p      = shift;
    my $slurpy = shift;

    my $slurpy_v;
    is(
        dies {
            $slurpy_v = validation_for(
                params => { $p->{key} => $p->{spec} },
                slurpy => ( $slurpy->{spec}{type} || 1 ),
            );
        },
        undef,
        'no exception compiling named params + slurpy validator'
    ) or return;

    _run_param_tests(
        [ $p, $slurpy ],
        'named',
        sub {
            my $input  = shift;
            my $output = shift;

            is(
                { $slurpy_v->( %{$input} ) },
                $output,
                'input as k/v pairs'
            );
        },
    );
}

sub _positional_slurpy_tests {
    my $p      = shift;
    my $slurpy = shift;

    my $slurpy_v;
    is(
        dies {
            $slurpy_v = validation_for(
                params => [ $p->{spec} ],
                slurpy => ( $slurpy->{spec}{type} || 1 ),
            );
        },
        undef,
        'no exception compiling positional params + slurpy validator'
    ) or return;

    _run_param_tests(
        [ $p, $slurpy ],
        'pos',
        sub {
            my $input  = shift;
            my $output = shift;

            is(
                [ $slurpy_v->( @{$input} ) ],
                $output,
                'input as list'
            );
        },
    );
}

sub _run_param_tests {
    my $p         = shift;
    my $type      = shift;
    my $test_code = shift;

    my @sets
        = map { Set::Scalar->new( keys %{ $_->{tests} } ) } @{$p};

    my $iter = Set::Scalar->cartesian_product_iterator(@sets);
    while ( my @test_keys = $iter->() ) {
        my $subtest = join q{ + }, @test_keys;

        # If we're testing positional params with more than 1 parameter, and
        # any parameter but the last has an empty input list, then we cannot
        # run that particular test set. We'd end up with an array built from
        # [], [42], [{ foo => 1 }] as the list of inputs, which gets turned
        # into a 2 element array when 3 need to be passed in.
        if ( $type eq 'pos' && @{$p} > 1 ) {
            for my $i ( 0 .. $#test_keys - 1 ) {
                if ( @{ $p->[$i]->{tests}{ $test_keys[$i] }{$type}{input} }
                    == 0 ) {
                    subtest $subtest => sub {
                    SKIP: {
                            skip
                                'Cannot run a test set where any non-last parameter has an empty input list',
                                1;
                        }
                    };
                    return;
                }
            }
        }

        my $in_out = reduce { merge( $a, $b ) }
        map { $p->[$_]->{tests}{ $test_keys[$_] }{$type} } 0 .. $#test_keys;

        subtest $subtest => sub {
            $test_code->( $in_out->{input}, $in_out->{output} );
        };
    }
}

sub _one_param_permutations {
    my $key = shift;

    my %types = (
        'no type' => undef,
        _one_type_permutations(),
    );

    my %optional = (
        required => 0,
        optional => 1,
    );

    my %default = (
        none            => undef,
        'simple scalar' => 42,
        'subroutine'    => sub {42},
    );

    my %perms;

    for my $t ( sort keys %types ) {
        for my $o ( sort keys %optional ) {
            for my $d ( sort keys %default ) {
                my $desc = "type = $t";

                my %spec;
                my %tests = (
                    (
                        $t eq 'no type'
                        ? 'any value is accepted'
                        : 'value passes type check'
                    ) => {
                        named => {
                            input  => { $key => 700 },
                            output => { $key => 700 },
                        },
                        pos => {
                            input  => [700],
                            output => [700],
                        },
                    },
                );

                if ( $t =~ /coercion/ ) {
                    $tests{'value is coerced'} = {
                        named => {
                            input  => { $key => [ 1 .. 4 ] },
                            output => { $key => 4 },
                        },
                        pos => {
                            input => [ [ 1 .. 4 ] ],
                            output => [4],
                        },
                    };
                }

                if ( $optional{$o} ) {
                    $spec{optional} = 1;
                    $desc .= "; $o";

                    $tests{'no value given for optional param'} = {
                        named => {
                            input  => {},
                            output => {},
                        },
                        pos => {
                            input  => [],
                            output => [],
                        }
                    };
                }
                else {
                    $spec{default} = $default{$d} if $default{$d};

                    if ( $d eq 'none' ) {
                        $desc .= "; $o; default = $d";
                    }
                    else {
                        $tests{'no value given for param with default'} = {
                            named => {
                                input  => {},
                                output => { $key => 42 },
                            },
                            pos => {
                                input  => [],
                                output => [42],
                            }
                        };

                        $desc .= "; default = $d";
                    }
                }

                $spec{type} = $types{$t} if $types{$t};

                $perms{$desc} = {
                    key   => $key,
                    spec  => \%spec,
                    tests => \%tests,
                };
            }
        }
    }

    return %perms;
}

sub _slurpy_param_permutations {
    my $key = shift;

    my %types = (
        'no type' => undef,
        _one_type_permutations(),
    );

    my %perms;

    for my $t ( sort keys %types ) {
        my $desc = "type = $t";

        my %spec;
        my %tests = (
            (
                $t eq 'no type'
                ? 'any value is accepted'
                : 'value passes type check'
            ) => {
                named => {
                    input  => { $key => 700 },
                    output => { $key => 700 },
                },
                pos => {
                    input  => [700],
                    output => [700],
                },
            },
        );

        if ( $t =~ /coercion/ ) {
            $tests{'value is coerced'} = {
                named => {
                    input  => { $key => [ 1 .. 4 ] },
                    output => { $key => 4 },
                },
                pos => {
                    input => [ [ 1 .. 4 ] ],
                    output => [4],
                },
            };
        }

        $spec{type} = $types{$t} if $types{$t};

        $spec{$desc} = {
            key   => $key,
            spec  => \%spec,
            tests => \%tests,
        };
    }

    return %perms;
}

sub _one_type_permutations {
    my %subs = (
        'inlinable type'                     => 'inl_type',
        'inlinable type, inlinable coercion' => 'inl_type_with_inl_coercion',
        'inlinable type, non-inlinable coercion' =>
            'inl_type_with_no_inl_coercion',
        'non-inlinable type' => 'no_inl_type',
        'non-inlinable type, inlinable coercion' =>
            'no_inl_type_with_inl_coercion',
        'non-inlinable type, non-inlinable coercion' =>
            'no_inl_type_with_no_inl_coercion',
        'inlinable type with closed-over variables' => 'closure_inl_env_type',
    );

    my %perms;

    for my $flavor (qw( Moose TT Specio )) {
        my $pkg = '_Types::' . $flavor;

        for my $k ( sort keys %subs ) {
            my $s = $subs{$k};
            next unless $pkg->can($s);

            $perms{"$flavor - $k"} = $pkg->$s();
        }
    }

    return %perms;
}

## no critic (Modules::ProhibitMultiplePackages)

{
    package _Types::Moose;

    use Moose::Util::TypeConstraints;

    ## no critic (Subroutines::ProtectPrivateSubs)

    sub inl_type {
        my $type = subtype(
            as 'Int',
            where { $_ > 0 },
            inline_as {
                $_[0]->parent->_inline_check( $_[1] ) . " && $_[1] > 0"
            },
        );

        return $type;
    }

    sub inl_type_with_no_inl_coercion {
        my $type = subtype(
            as 'Int',
            where { $_ > 0 },
            inline_as {
                $_[0]->parent->_inline_check( $_[1] ) . " && $_[1] > 0"
            },
        );

        coerce(
            $type,
            from 'ArrayRef',
            via { scalar @{$_} },
        );

        return $type;
    }

    sub no_inl_type {
        my $type = subtype(
            as 'Int',
            where { $_ > 0 },
        );

        return $type;
    }

    sub no_inl_type_with_no_inl_coercion {
        my $type = subtype(
            as 'Int',
            where { $_ > 0 },
        );

        coerce(
            $type,
            from 'ArrayRef',
            via { scalar @{$_} },
        );

        return $type;
    }

    sub closure_inl_env_type {
        return enum( [ 42, 43, 44, 700 ] );
    }
}

{
    package _Types::TT;

    use Types::Standard qw( Int ArrayRef );
    use Type::Utils -all;

    sub inl_type {
        my $type = subtype(
            as Int,
            where { $_ > 0 },
            inline_as {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0"
            },
        );

        return $type;
    }

    sub inl_type_with_inl_coercion {
        my $type = subtype(
            as Int,
            where { $_ > 0 },
            inline_as {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0"
            },
        );

        return $type->plus_coercions( ArrayRef, 'scalar @{ $_ }' );
    }

    sub inl_type_with_no_inl_coercion {
        my $type = subtype(
            as Int,
            where { $_ > 0 },
            inline_as {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0"
            },
        );

        return $type->plus_coercions( ArrayRef, sub { scalar @{$_} } );
    }

    sub no_inl_type {
        my $type = subtype(
            as Int,
            where { $_ > 0 }
        );

        return $type;
    }

    sub no_inl_type_with_inl_coercion {
        my $type = subtype(
            as Int,
            where { $_ > 0 }
        );

        return $type->plus_coercions( ArrayRef, 'scalar @{ $_ }' );
    }

    sub no_inl_type_with_no_inl_coercion {
        my $type = subtype(
            as Int,
            where { $_ > 0 }
        );

        return $type->plus_coercions( ArrayRef, sub { scalar @{$_} } );
    }
}

{
    package _Types::Specio;

    use Specio::Declare;
    use Specio::Library::Builtins;

    sub inl_type {
        my $type = anon(
            parent => t('Int'),
            inline => sub {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0";
            },
        );

        return $type;
    }

    sub inl_type_with_inl_coercion {
        my $type = anon(
            parent => t('Int'),
            inline => sub {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0";
            },
        );

        coerce(
            $type,
            from   => t('ArrayRef'),
            inline => sub {"scalar \@{ $_[1] }"},
        );

        return $type;
    }

    sub inl_type_with_no_inl_coercion {
        my $type = anon(
            parent => t('Int'),
            inline => sub {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0";
            },
        );

        coerce(
            $type,
            from  => t('ArrayRef'),
            using => sub { scalar @{ $_[0] } },
        );

        return $type;
    }

    sub no_inl_type {
        my $type = anon(
            parent => t('Int'),
            inline => sub {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0";
            },
        );

        return $type;
    }

    sub no_inl_type_with_inl_coercion {
        my $type = anon(
            parent => t('Int'),
            inline => sub {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0";
            },
        );

        coerce(
            $type,
            from   => t('ArrayRef'),
            inline => sub {"scalar \@{ $_[1] }"},
        );

        return $type;
    }

    sub no_inl_type_with_no_inl_coercion {
        my $type = anon(
            parent => t('Int'),
            inline => sub {
                $_[0]->parent->inline_check( $_[1] ) . " && $_[1] > 0";
            },
        );

        coerce(
            $type,
            from  => t('ArrayRef'),
            using => sub { scalar @{ $_[0] } },
        );

        return $type;
    }

    sub closure_inl_env_type {
        return enum( values => [ 42, 43, 44, 700 ] );
    }
}

__END__

## Parameter specs

### Type

* No type, just required
* Has a type -> [Types](#types)

### Required or not

* Required
* Optional

### Defaults

* No default
* Has a non-sub default
* Has a subroutine default

## Slurpy

* Any type
* A specific type -> [Types](#types)

## Parameter passing style

* Named
  * As k/v pairs
  * As hashref
* Named to list
* Positional

## Types

### Type System

* Moose
* Specio
* Type::Tiny

### Inlining

* Type can be inlined
  * Type inlining requires "env" vars
  * Coercion inlining requires "env" vars
* Type cannot be inlined

### Coercions

* No coercion
* With coercion(s)
  * that can all be inlined
  * none of which can be inlined
  * some of which can be inlined
