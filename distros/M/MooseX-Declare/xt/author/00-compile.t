use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More 0.94;

plan tests => 25;

my @module_files = (
    'MooseX/Declare.pm',
    'MooseX/Declare/Context.pm',
    'MooseX/Declare/Context/Namespaced.pm',
    'MooseX/Declare/Context/Parameterized.pm',
    'MooseX/Declare/Context/WithOptions.pm',
    'MooseX/Declare/StackItem.pm',
    'MooseX/Declare/Syntax/EmptyBlockIfMissing.pm',
    'MooseX/Declare/Syntax/Extending.pm',
    'MooseX/Declare/Syntax/InnerSyntaxHandling.pm',
    'MooseX/Declare/Syntax/Keyword/Class.pm',
    'MooseX/Declare/Syntax/Keyword/Clean.pm',
    'MooseX/Declare/Syntax/Keyword/Method.pm',
    'MooseX/Declare/Syntax/Keyword/MethodModifier.pm',
    'MooseX/Declare/Syntax/Keyword/Namespace.pm',
    'MooseX/Declare/Syntax/Keyword/Role.pm',
    'MooseX/Declare/Syntax/Keyword/With.pm',
    'MooseX/Declare/Syntax/KeywordHandling.pm',
    'MooseX/Declare/Syntax/MethodDeclaration.pm',
    'MooseX/Declare/Syntax/MethodDeclaration/Parameterized.pm',
    'MooseX/Declare/Syntax/MooseSetup.pm',
    'MooseX/Declare/Syntax/NamespaceHandling.pm',
    'MooseX/Declare/Syntax/OptionHandling.pm',
    'MooseX/Declare/Syntax/RoleApplication.pm',
    'MooseX/Declare/Util.pm'
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
