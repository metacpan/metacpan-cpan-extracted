use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.056

use Test::More;

plan tests => 37 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'Muster.pm',
    'Muster/Assemble.pm',
    'Muster/Command/init.pm',
    'Muster/Command/scan.pm',
    'Muster/Generator.pm',
    'Muster/Hook.pm',
    'Muster/Hook/Costings.pm',
    'Muster/Hook/Counter.pm',
    'Muster/Hook/DeriveFields.pm',
    'Muster/Hook/Directives.pm',
    'Muster/Hook/DynamicField.pm',
    'Muster/Hook/FieldSubst.pm',
    'Muster/Hook/GraphViz.pm',
    'Muster/Hook/HeadFoot.pm',
    'Muster/Hook/Img.pm',
    'Muster/Hook/Include.pm',
    'Muster/Hook/Links.pm',
    'Muster/Hook/Map.pm',
    'Muster/Hook/Meta.pm',
    'Muster/Hook/Shortcut.pm',
    'Muster/Hook/SqlReport.pm',
    'Muster/Hook/Table.pm',
    'Muster/Hook/Template.pm',
    'Muster/Hooks.pm',
    'Muster/LeafFile.pm',
    'Muster/LeafFile/EXIF.pm',
    'Muster/LeafFile/epub.pm',
    'Muster/LeafFile/gif.pm',
    'Muster/LeafFile/jpg.pm',
    'Muster/LeafFile/mdwn.pm',
    'Muster/LeafFile/pdf.pm',
    'Muster/LeafFile/png.pm',
    'Muster/LeafFile/txt.pm',
    'Muster/MetaDb.pm',
    'Muster/PagesHelper.pm',
    'Muster/Scanner.pm'
);

my @scripts = (
    'scripts/muster'
);

# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
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
    @switches = (@switches, split(' ', $1)) if $1;

    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'} . $str . q{'} }
            $^X, @switches, '-c', $file))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-c', $file);
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


