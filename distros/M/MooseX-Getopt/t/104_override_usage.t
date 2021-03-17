use strict;
use warnings;

use Test::More 0.88;
use Test::Trap;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Moose::Util 'find_meta';

$ENV{COLUMNS} = 80;

{
    package MyScript;
    use Moose;

    with 'MooseX::Getopt';

    has foo => ( isa => 'Int', is => 'ro', documentation => 'A foo
with newline and some 123456789 123456789 123456789 characters' );
}

my $usage = qr/^\Qusage: 104_override_usage.t [-?h] [long options...]\E
.*\t.*--help.+Prints this usage information\.
.*\t--foo (INT)?\s+A foo.+characters/ms;

{
    local @ARGV = ('--foo', '1');
    my $i = trap { MyScript->new_with_options };
    is($i->foo, 1, 'attr is set');
    is($trap->stdout, '', 'nothing printed when option is accepted');
}

{
    local @ARGV = ('--help');
    trap { MyScript->new_with_options };
    like($trap->stdout, qr/\A$usage\Z/, 'usage is printed on --help');
}

{
    local @ARGV = ('-q'); # Does not exist
    trap { MyScript->new_with_options };
    like($trap->die, qr/\AUnknown option: q\n$usage\Z/, 'usage is printed on unknown option');
}

{
    find_meta('MyScript')->add_before_method_modifier(
        print_usage_text => sub {
            print "--- DOCUMENTATION ---\n";
        },
    );

    local @ARGV = ('--help');
    trap { MyScript->new_with_options };
    like(
        $trap->stdout,
        qr/^--- DOCUMENTATION ---\n$usage\Z/,
        'additional text included before normal usage string',
    );
}

{
    find_meta('MyScript')->add_after_method_modifier(
        print_usage_text => sub {
            print "--- DOCUMENTATION ---\n";
        },
    );

    local @ARGV = ('--help');
    trap { MyScript->new_with_options };
    like(
        $trap->stdout,
        qr/$usage\n--- DOCUMENTATION ---\n/,
        'additional text included before normal usage string',
    );
}

{
    package MyScript2;
    use Moose;

    with 'MooseX::Getopt';
    has foo => ( isa => 'Int', is => 'ro', documentation => 'A foo
with newline and some 123456789 123456789 123456789 characters' );
}

{
    # some classes (e.g. ether's darkpan and Catalyst::Runtime) overrode
    # _getopt_full_usage, so we need to keep it in the call stack so we don't
    # break them.
    find_meta('MyScript2')->add_before_method_modifier(
        _getopt_full_usage => sub {
            print "--- DOCUMENTATION ---\n";
        },
    );

    local @ARGV = ('--help');
    trap { MyScript2->new_with_options };
    like(
        $trap->stdout,
        qr/^--- DOCUMENTATION ---\n$usage/,
        'additional text included before normal usage string',
    );
}

done_testing;
