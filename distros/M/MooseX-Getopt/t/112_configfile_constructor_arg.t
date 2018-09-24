use strict;
use warnings;

# respect the configfile value passed into the constructor.

use Test::Needs 'MooseX::SimpleConfig', 'YAML';
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

    has _somename => ( is => 'ro', isa => 'Str', required => 1, init_arg => 'somename' );
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
    is(
        $obj->_somename,
        "franz",
        'public value is read in from the config file and goes through init_arg to private attribute',
    );
}

done_testing;
