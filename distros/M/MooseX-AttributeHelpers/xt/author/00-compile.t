use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More 0.94;

plan tests => 32;

my @module_files = (
    'MooseX/AttributeHelpers.pm',
    'MooseX/AttributeHelpers/Bool.pm',
    'MooseX/AttributeHelpers/Collection/Array.pm',
    'MooseX/AttributeHelpers/Collection/Bag.pm',
    'MooseX/AttributeHelpers/Collection/Hash.pm',
    'MooseX/AttributeHelpers/Collection/ImmutableHash.pm',
    'MooseX/AttributeHelpers/Collection/List.pm',
    'MooseX/AttributeHelpers/Counter.pm',
    'MooseX/AttributeHelpers/Meta/Method/Curried.pm',
    'MooseX/AttributeHelpers/Meta/Method/Provided.pm',
    'MooseX/AttributeHelpers/MethodProvider/Array.pm',
    'MooseX/AttributeHelpers/MethodProvider/Bag.pm',
    'MooseX/AttributeHelpers/MethodProvider/Bool.pm',
    'MooseX/AttributeHelpers/MethodProvider/Counter.pm',
    'MooseX/AttributeHelpers/MethodProvider/Hash.pm',
    'MooseX/AttributeHelpers/MethodProvider/ImmutableHash.pm',
    'MooseX/AttributeHelpers/MethodProvider/List.pm',
    'MooseX/AttributeHelpers/MethodProvider/String.pm',
    'MooseX/AttributeHelpers/Number.pm',
    'MooseX/AttributeHelpers/String.pm',
    'MooseX/AttributeHelpers/Trait/Base.pm',
    'MooseX/AttributeHelpers/Trait/Bool.pm',
    'MooseX/AttributeHelpers/Trait/Collection.pm',
    'MooseX/AttributeHelpers/Trait/Collection/Array.pm',
    'MooseX/AttributeHelpers/Trait/Collection/Bag.pm',
    'MooseX/AttributeHelpers/Trait/Collection/Hash.pm',
    'MooseX/AttributeHelpers/Trait/Collection/ImmutableHash.pm',
    'MooseX/AttributeHelpers/Trait/Collection/List.pm',
    'MooseX/AttributeHelpers/Trait/Counter.pm',
    'MooseX/AttributeHelpers/Trait/Number.pm',
    'MooseX/AttributeHelpers/Trait/String.pm'
);



# no fake home requested

my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', explain(\@warnings);

BAIL_OUT("Compilation problems") if !Test::More->builder->is_passing;
