#!perl
use strict;
use warnings all => 'FATAL';
use Test::More;

{

    package t;
    use Moo;
    use MooX::Options;

    option 't' => ( is => 'ro' );

    1;
}

my $test = t->new_with_options;

my %ignore_methods;
@ignore_methods{
    qw/
        TEST::
        AUTOLOAD
        BEGIN
        BUILD
        BUILDARGS
        DEMOLISH
        DOES
        AFTER
        BEFORE
        EXTENDS
        HAS
        ISA
        CAN
        __ANON__
        DESTROY
        WITH
        AROUND
        /
} = ();

my @methods;
{
    no strict 'refs';
    @methods = sort { $a cmp $b }
        grep { !exists $ignore_methods{ uc($_) } }
        keys %{ ref($test) . "::" };
}

is_deeply(
    \@methods,
    [   qw/
            __
            __n
            __p
            _options_config
            _options_data
            _options_prog_name
            _options_sub_commands
            new
            new_with_options
            option
            options_help
            options_man
            options_short_usage
            options_usage
            parse_options
            t
            /
    ],
    'methods ok'
) or diag "Found : ", join( ', ', @methods );

done_testing;
