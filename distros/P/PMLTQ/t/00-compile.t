use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.054

use Test::More;

plan tests => 69 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'PMLTQ.pm',
    'PMLTQ/Base.pm',
    'PMLTQ/BtredEvaluator.pm',
    'PMLTQ/CGI.pm',
    'PMLTQ/Command.pm',
    'PMLTQ/Command/convert.pm',
    'PMLTQ/Command/delete.pm',
    'PMLTQ/Command/init.pm',
    'PMLTQ/Command/initdb.pm',
    'PMLTQ/Command/load.pm',
    'PMLTQ/Command/query.pm',
    'PMLTQ/Command/verify.pm',
    'PMLTQ/Command/version.pm',
    'PMLTQ/Command/webdelete.pm',
    'PMLTQ/Command/webload.pm',
    'PMLTQ/Command/webverify.pm',
    'PMLTQ/Commands.pm',
    'PMLTQ/Common.pm',
    'PMLTQ/Grammar.pm',
    'PMLTQ/Loader.pm',
    'PMLTQ/NG2PMLTQ.pm',
    'PMLTQ/PML2BASE.pm',
    'PMLTQ/ParserError.pm',
    'PMLTQ/Planner.pm',
    'PMLTQ/Relation.pm',
    'PMLTQ/Relation/AncestorIterator.pm',
    'PMLTQ/Relation/AncestorIteratorWithBoundedDepth.pm',
    'PMLTQ/Relation/ChildnodeIterator.pm',
    'PMLTQ/Relation/CurrentFileIterator.pm',
    'PMLTQ/Relation/CurrentFilelistIterator.pm',
    'PMLTQ/Relation/CurrentFilelistTreesIterator.pm',
    'PMLTQ/Relation/CurrentTreeIterator.pm',
    'PMLTQ/Relation/DepthFirstFollowsIterator.pm',
    'PMLTQ/Relation/DepthFirstPrecedesIterator.pm',
    'PMLTQ/Relation/DepthFirstRangeIterator.pm',
    'PMLTQ/Relation/DescendantIterator.pm',
    'PMLTQ/Relation/DescendantIteratorWithBoundedDepth.pm',
    'PMLTQ/Relation/FSFileIterator.pm',
    'PMLTQ/Relation/Iterator.pm',
    'PMLTQ/Relation/MemberIterator.pm',
    'PMLTQ/Relation/OptionalIterator.pm',
    'PMLTQ/Relation/OrderIterator.pm',
    'PMLTQ/Relation/PDT.pm',
    'PMLTQ/Relation/PDT/AEChildIterator.pm',
    'PMLTQ/Relation/PDT/AEParentIterator.pm',
    'PMLTQ/Relation/PDT/ALexOrAuxRFIterator.pm',
    'PMLTQ/Relation/PDT/TEChildIterator.pm',
    'PMLTQ/Relation/PDT/TEParentIterator.pm',
    'PMLTQ/Relation/PMLREFIterator.pm',
    'PMLTQ/Relation/ParentIterator.pm',
    'PMLTQ/Relation/SameTreeIterator.pm',
    'PMLTQ/Relation/SiblingIterator.pm',
    'PMLTQ/Relation/SiblingIteratorWithDistance.pm',
    'PMLTQ/Relation/SimpleListIterator.pm',
    'PMLTQ/Relation/TransitiveIterator.pm',
    'PMLTQ/Relation/TreeIterator.pm',
    'PMLTQ/Relation/Treex.pm',
    'PMLTQ/Relation/Treex/AEChildCIterator.pm',
    'PMLTQ/Relation/Treex/AEChildIterator.pm',
    'PMLTQ/Relation/Treex/AEParentCIterator.pm',
    'PMLTQ/Relation/Treex/AEParentIterator.pm',
    'PMLTQ/Relation/Treex/TEChildIterator.pm',
    'PMLTQ/Relation/Treex/TEParentIterator.pm',
    'PMLTQ/Relation/TreexFileIterator.pm',
    'PMLTQ/Relation/TreexFilelistIterator.pm',
    'PMLTQ/SQLEvaluator.pm',
    'PMLTQ/TypeMapper.pm',
    'PMLTQ/_Parser.pm'
);

my @scripts = (
    'script/pmltq'
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

foreach my $file (@scripts)
{ SKIP: {
    open my $fh, '<', $file or warn("Unable to open $file: $!"), next;
    my $line = <$fh>;

    close $fh and skip("$file isn't perl", 1) unless $line =~ /^#!\s*(?:\S*perl\S*)((?:\s+-\w*)*)(?:\s*#.*)?$/;
    my @flags = $1 ? split(' ', $1) : ();

    my $stderr = IO::Handle->new;

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, $inc_switch, @flags, '-c', $file);
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$file compiled ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};


