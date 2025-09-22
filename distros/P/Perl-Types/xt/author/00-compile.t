use 5.006;
use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.058

use Test::More;

plan tests => 97;

my @module_files = (
    'Perl.pm',
    'Perl/Class.pm',
    'Perl/Config.pm',
    'Perl/HelperFunctions_cpp.pm',
    'Perl/Inline.pm',
    'Perl/Object.pm',
    'Perl/Structure.pm',
    'Perl/Structure/Array.pm',
    'Perl/Structure/Array/Reference.pm',
    'Perl/Structure/Array/SubTypes.pm',
    'Perl/Structure/Array/SubTypes1D.pm',
    'Perl/Structure/Array/SubTypes2D.pm',
    'Perl/Structure/Array/SubTypes3D.pm',
    'Perl/Structure/Array_cpp.pm',
    'Perl/Structure/CodeReference.pm',
    'Perl/Structure/GSLMatrix.pm',
    'Perl/Structure/GSLMatrix_cpp.pm',
    'Perl/Structure/Graph.pm',
    'Perl/Structure/Graph/AdjacencyList.pm',
    'Perl/Structure/Graph/Matrix.pm',
    'Perl/Structure/Graph/ObjectPointer.pm',
    'Perl/Structure/Graph/Tree.pm',
    'Perl/Structure/Graph/Tree/Binary.pm',
    'Perl/Structure/Graph/Tree/Binary/AVL.pm',
    'Perl/Structure/Graph/Tree/Binary/Node.pm',
    'Perl/Structure/Graph/Tree/Binary/RedBlack.pm',
    'Perl/Structure/Graph/Tree/Binary/Splay.pm',
    'Perl/Structure/Graph/Tree/KD.pm',
    'Perl/Structure/Graph/Tree/NAry.pm',
    'Perl/Structure/Graph/Tree/Suffix.pm',
    'Perl/Structure/Graph/Tree/Trie.pm',
    'Perl/Structure/Graph/TreeReference.pm',
    'Perl/Structure/GraphReference.pm',
    'Perl/Structure/Hash.pm',
    'Perl/Structure/Hash/Properties.pm',
    'Perl/Structure/Hash/Reference.pm',
    'Perl/Structure/Hash/SubTypes.pm',
    'Perl/Structure/Hash/SubTypes1D.pm',
    'Perl/Structure/Hash/SubTypes2D.pm',
    'Perl/Structure/Hash/SubTypes3D.pm',
    'Perl/Structure/Hash_cpp.pm',
    'Perl/Structure/LinkedList.pm',
    'Perl/Structure/LinkedList/Node.pm',
    'Perl/Structure/MongoDBBSON.pm',
    'Perl/Structure/SSENumberPair.pm',
    'Perl/Type.pm',
    'Perl/Type/Boolean.pm',
    'Perl/Type/Boolean_cpp.pm',
    'Perl/Type/Character.pm',
    'Perl/Type/Character_cpp.pm',
    'Perl/Type/FileHandle.pm',
    'Perl/Type/GMPInteger.pm',
    'Perl/Type/GMPInteger_cpp.pm',
    'Perl/Type/Integer.pm',
    'Perl/Type/Integer_cpp.pm',
    'Perl/Type/Modifier.pm',
    'Perl/Type/Modifier/Reference.pm',
    'Perl/Type/NonsignedInteger.pm',
    'Perl/Type/NonsignedInteger_cpp.pm',
    'Perl/Type/Number.pm',
    'Perl/Type/Number_cpp.pm',
    'Perl/Type/Scalar.pm',
    'Perl/Type/String.pm',
    'Perl/Type/String_cpp.pm',
    'Perl/Type/Unknown.pm',
    'Perl/Type/Void.pm',
    'Perl/Types.pm',
    'perlapinames_generated.pm',
    'perlgmp.pm',
    'perlgsl.pm',
    'perlsse.pm',
    'perltypes.pm',
    'perltypesconv.pm',
    'perltypesnames.pm',
    'perltypesnamespaces.pm',
    'perltypesnamespaces_generated.pm',
    'perltypessizes.pm',
    'types.pm'
);

my @scripts = (
    'bin/dev/GMP/gmp_manual.pl',
    'bin/dev/GMP/gmp_manual_orig.pl',
    'bin/dev/GMP/gmp_symtab_dump.pl',
    'bin/dev/GSL/gsl_cpp_manual.pl',
    'bin/dev/namespaces_regenerate.pl',
    'bin/dev/perl_types_refactor_cpp_namespaces.pl',
    'bin/dev/perl_types_refactor_headers.pl',
    'bin/dev/perl_types_refactor_names.pl',
    'bin/dev/perl_types_refactor_names_parser.pl',
    'bin/dev/perlapinames_regenerate.pl',
    'bin/dev/refactor_names_map_create_groups.pl',
    'bin/dev/unused/data_structure_array_test.pl',
    'bin/dev/unused/data_structure_hash_test.pl',
    'bin/dev/unused/data_structure_tree_test.pl',
    'bin/dev/unused/data_type_integer_precision.pl',
    'bin/dev/unused/data_type_number_floating_point_error.pl',
    'bin/dev/unused/data_type_scalar_test.pl',
    'bin/dev/unused/data_type_string_backslashes.pl'
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
        and not eval { +require blib; blib->VERSION('1.01') };

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

    close $fh and skip("$file uses -T; not testable with PERL5LIB", 1)
        if grep { $_ eq '-T' } @switches and $ENV{PERL5LIB};

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
        and not eval { +require blib; blib->VERSION('1.01') };

    # in older perls, -c output is simply the file portion of the path being tested
    if (@_warnings = grep { !/\bsyntax OK$/ }
        grep { chomp; $_ ne (File::Spec->splitpath($file))[2] } @_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
} }



is(scalar(@warnings), 0, 'no warnings found')
    or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) );


