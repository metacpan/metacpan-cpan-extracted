use strict;
use warnings;

# respect the configfile value passed into the constructor.

use Test::Requires {
    'MooseX::SimpleConfig' => '()',
    'YAML' => 0,
};
use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Path::Tiny 0.009;

{
    package Foo;
    use Moose;
    with 'MooseX::Getopt', 'MooseX::SimpleConfig';

    has foo => (
        is => 'ro', isa => 'Str',
        default => 'foo default',
    );
}

{
    my $configfile = path(qw(t 112_configfile_constructor_arg.yml))->stringify;

    my $obj = Foo->new_with_options(configfile => $configfile);

    is(
        path($obj->configfile),
        $configfile,
        'configfile value is used from the constructor',
    );
    is(
        $obj->foo,
        'foo value',
        'value is read in from the config file',
    );
}

done_testing;
