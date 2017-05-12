use strict;
use warnings;
use Test::More 0.96;
use File::Temp 0.18;
use File::pushd qw/tempd/;
use Path::Tiny;

{

    package Foo;
    use Moose;
    use MooseX::Types::Path::Tiny qw/Path File Dir/;

    has a_path => ( is => 'ro', isa => Path, coerce => 1 );
    has a_file => ( is => 'ro', isa => File, coerce => 1 );
    has a_dir  => ( is => 'ro', isa => Dir,  coerce => 1 );
}

{

    package AbsFoo;
    use Moose;
    use MooseX::Types::Path::Tiny qw/AbsPath AbsFile AbsDir/;

    has a_path => ( is => 'ro', isa => AbsPath, coerce => 1 );
    has a_file => ( is => 'ro', isa => AbsFile, coerce => 1 );
    has a_dir  => ( is => 'ro', isa => AbsDir,  coerce => 1 );
}

my $tf = File::Temp->new;
my $td = File::Temp->newdir;

my @cases = (
    # Path
    {
        label    => "coerce string to Path",
        absolute => 0,
        attr     => "a_path",
        input    => "./foo",
    },
    {
        label    => "coerce object to Path",
        absolute => 0,
        attr     => "a_path",
        input    => $tf,
    },
    {
        label    => "coerce array ref to Path",
        absolute => 0,
        attr     => "a_path",
        input    => [qw/foo bar/],
    },
    # AbsPath
    {
        label    => "coerce string to AbsPath",
        absolute => 1,
        attr     => "a_path",
        input    => "./foo",
    },
    {
        label    => "coerce Path to AbsPath",
        absolute => 1,
        attr     => "a_path",
        input    => path($tf),
    },
    {
        label    => "coerce object to AbsPath",
        absolute => 1,
        attr     => "a_path",
        input    => $tf,
    },
    {
        label    => "coerce array ref to AbsPath",
        absolute => 1,
        attr     => "a_path",
        input    => [qw/foo bar/],
    },
    # File
    {
        label    => "coerce string to File",
        absolute => 0,
        attr     => "a_file",
        input    => "$tf",
    },
    {
        label    => "coerce object to File",
        absolute => 0,
        attr     => "a_file",
        input    => $tf,
    },
    {
        label    => "coerce array ref to File",
        absolute => 0,
        attr     => "a_file",
        input    => [$tf],
    },
    # Dir
    {
        label    => "coerce string to Dir",
        absolute => 0,
        attr     => "a_dir",
        input    => "$td",
    },
    {
        label    => "coerce object to Dir",
        absolute => 0,
        attr     => "a_dir",
        input    => $td,
    },
    {
        label    => "coerce array ref to Dir",
        absolute => 0,
        attr     => "a_dir",
        input    => [$td],
    },
    # AbsFile
    {
        label    => "coerce string to AbsFile",
        absolute => 1,
        attr     => "a_file",
        input    => "$tf",
    },
    {
        label    => "coerce object to AbsFile",
        absolute => 1,
        attr     => "a_file",
        input    => $tf,
    },
    {
        label    => "coerce array ref to AbsFile",
        absolute => 1,
        attr     => "a_file",
        input    => [$tf],
    },
    # AbsDir
    {
        label    => "coerce string to AbsDir",
        absolute => 1,
        attr     => "a_dir",
        input    => "$td",
    },
    {
        label    => "coerce object to AbsDir",
        absolute => 1,
        attr     => "a_dir",
        input    => $td,
    },
    {
        label    => "coerce array ref to AbsDir",
        absolute => 1,
        attr     => "a_dir",
        input    => [$td],
    },
);

for my $c (@cases) {
    subtest $c->{label} => sub {
        my $wd       = tempd;
        my $class    = $c->{absolute} ? "AbsFoo" : "Foo";
        my $attr     = $c->{attr};
        my $input    = $c->{input};
        my $expected = path( ref $input eq 'ARRAY' ? @$input : $input );
        $expected = $expected->absolute if $c->{absolute};

        my $obj = eval { $class->new( $attr => $input ); };
        is( $@, '', "object created without exception" );
        isa_ok( $obj->$attr, "Path::Tiny", $attr );
        is( $obj->$attr, $expected, "$attr set correctly" );
    };
}

done_testing;
# COPYRIGHT
