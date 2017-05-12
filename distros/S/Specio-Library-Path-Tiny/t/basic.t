use strict;
use warnings;

use Test::More 0.96;
use Test::Fatal;
use Test::Specio qw( test_constraint describe :vars );

use File::pushd qw( tempd );
use File::Temp 0.18;
use Path::Tiny qw( path rootdir );
use Scalar::Util qw( blessed );
use Specio::Library::Path::Tiny;

my $can_symlink = do {
    local $@ = undef;
    ## no critic (ErrorHandling::RequireCheckingReturnValueOfEval, InputOutput::RequireCheckedSyscalls)
    eval { symlink( q{}, q{} ); 1 };
};

# The glob vars only work when they're use in the same package as where
# they're declared. Globs are weird.
my $GLOB = do {
    ## no critic (TestingAndDebugging::ProhibitNoWarnings)
    no warnings 'once';
    *SOME_GLOB;
};

## no critic (Variables::RequireInitializationForLocalVars)
local *FOO;
my $GLOB_OVERLOAD = _T::GlobOverload->new( \*FOO );

local *BAR;
{
    ## no critic (InputOutput::ProhibitBarewordFileHandles, InputOutput::RequireBriefOpen)
    open BAR, '<', $0 or die "Could not open $0 for the test";
}
my $GLOB_OVERLOAD_FH = _T::GlobOverload->new( \*BAR );

my @all_values = (
    $ZERO,
    $ONE,
    $BOOL_OVERLOAD_TRUE,
    $BOOL_OVERLOAD_FALSE,
    $INT,
    $NEG_INT,
    $NUM,
    $NEG_NUM,
    $NUM_OVERLOAD_ZERO,
    $NUM_OVERLOAD_ONE,
    $NUM_OVERLOAD_NEG,
    $NUM_OVERLOAD_NEG_DECIMAL,
    $NUM_OVERLOAD_DECIMAL,
    $EMPTY_STRING,
    $STRING,
    $NUM_IN_STRING,
    $STR_OVERLOAD_EMPTY,
    $STR_OVERLOAD_FULL,
    $INT_WITH_NL1,
    $INT_WITH_NL2,
    $SCALAR_REF,
    $SCALAR_REF_REF,
    $SCALAR_OVERLOAD,
    $ARRAY_REF,
    $ARRAY_OVERLOAD,
    $HASH_REF,
    $HASH_OVERLOAD,
    $CODE_REF,
    $CODE_OVERLOAD,
    $GLOB,
    $GLOB_REF,
    $GLOB_OVERLOAD,
    $GLOB_OVERLOAD_FH,
    $FH,
    $FH_OBJECT,
    $REGEX,
    $REGEX_OBJ,
    $REGEX_OVERLOAD,
    $FAKE_REGEX,
    $OBJECT,
    $UNDEF,
);

my $tempfile = File::Temp->new;
my $tempdir  = File::Temp->newdir;

my $rel_path = path('foo');
my $abs_path = rootdir->realpath->child('foo');

my $rel_dir = path( path($0)->parent->basename );

my @abs_but_not_real_file;
my @abs_but_not_real_dir;
if ($can_symlink) {
    my $realfile = path( $tempdir, 'realfile' );
    $realfile->touch;
    my $symlinkfile = path( $tempdir, 'symlinkfile' );
    symlink $realfile => $symlinkfile or die $!;

    push @abs_but_not_real_file, $symlinkfile;

    my $realdir = path( $tempdir, 'realdir' );
    $realdir->mkpath;
    my $symlinkdir = path( $tempdir, 'symlinkdir' );
    symlink $realdir => $symlinkdir or die $!;

    push @abs_but_not_real_dir, $symlinkdir;
}

my $actual_file = path($tempfile)->realpath;
my $actual_dir  = path($tempdir)->realpath;

test_constraint(
    t('Path'),
    {
        accept => [
            $rel_path,
            $abs_path,
            @abs_but_not_real_file,
            @abs_but_not_real_dir,
            $rel_dir,
            $actual_file,
            $actual_dir,
        ],
        reject => \@all_values,
    },
    \&_describe,
);

test_constraint(
    t('AbsPath'),
    {
        accept => [
            $abs_path,
            @abs_but_not_real_file,
            @abs_but_not_real_dir,
            $actual_file,
            $actual_dir,
        ],
        reject => [
            $rel_path,
            $rel_dir,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('RealPath'),
    {
        accept => [
            $abs_path,
            $actual_file,
            $actual_dir,
        ],
        reject => [
            $rel_path,
            $rel_dir,
            @abs_but_not_real_file,
            @abs_but_not_real_dir,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('File'),
    {
        accept => [
            @abs_but_not_real_file,
            $actual_file,
        ],
        reject => [
            $rel_path,
            $rel_dir,
            $abs_path,
            $actual_dir,
            @abs_but_not_real_dir,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('AbsFile'),
    {
        accept => [
            @abs_but_not_real_file,
            $actual_file,
        ],
        reject => [
            $rel_path,
            $rel_dir,
            $abs_path,
            $actual_dir,
            @abs_but_not_real_dir,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('RealFile'),
    {
        accept => [
            $actual_file,
        ],
        reject => [
            $rel_path,
            $rel_dir,
            $abs_path,
            @abs_but_not_real_file,
            @abs_but_not_real_dir,
            $actual_dir,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('Dir'),
    {
        accept => [
            $rel_dir,
            $actual_dir,
            @abs_but_not_real_dir,
        ],
        reject => [
            @abs_but_not_real_file,
            $actual_file,
            $rel_path,
            $abs_path,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('AbsDir'),
    {
        accept => [
            $actual_dir,
            @abs_but_not_real_dir,
        ],
        reject => [
            @abs_but_not_real_file,
            $rel_path,
            $rel_dir,
            $abs_path,
            $actual_file,
            @all_values,
        ],
    },
    \&_describe,
);

test_constraint(
    t('RealDir'),
    {
        accept => [
            $actual_dir,
        ],
        reject => [
            @abs_but_not_real_file,
            $rel_path,
            $rel_dir,
            $abs_path,
            @abs_but_not_real_file,
            $actual_file,
            @all_values,
        ],
    },
    \&_describe,
);

my @coercion_tests = (

    # Path
    {
        label => 'coerce string to Path',
        type  => t('Path'),
        input => 'foo',
    },
    {
        label => 'coerce object to Path',
        type  => t('Path'),
        input => $tempfile,
    },
    {
        label => 'coerce array ref to Path',
        type  => t('Path'),
        input => [qw/foo bar/],
    },

    # AbsPath
    {
        label => 'coerce string to AbsPath',
        type  => t('AbsPath'),
        input => 'foo',
    },
    {
        label => 'coerce Path to AbsPath',
        type  => t('AbsPath'),
        input => path($tempfile),
    },
    {
        label => 'coerce object to AbsPath',
        type  => t('AbsPath'),
        input => $tempfile,
    },
    {
        label => 'coerce array ref to AbsPath',
        type  => t('AbsPath'),
        input => [qw/foo bar/],
    },

    # RealPath
    {
        label => 'coerce string to RealPath',
        type  => t('RealPath'),
        input => 'foo',
    },
    {
        label => 'coerce Path to RealPath',
        type  => t('RealPath'),
        input => path($tempfile),
    },
    {
        label => 'coerce object to RealPath',
        type  => t('RealPath'),
        input => $tempfile,
    },
    {
        label => 'coerce array ref to RealPath',
        type  => t('RealPath'),
        input => [qw/. foo/],
    },

    # File
    {
        label => 'coerce string to File',
        type  => t('File'),
        input => "$tempfile",
    },
    {
        label => 'coerce object to File',
        type  => t('File'),
        input => $tempfile,
    },
    {
        label => 'coerce array ref to File',
        type  => t('File'),
        input => [$tempfile],
    },

    # AbsFile
    {
        label => 'coerce string to AbsFile',
        type  => t('AbsFile'),
        input => "$tempfile",
    },
    {
        label => 'coerce object to AbsFile',
        type  => t('AbsFile'),
        input => $tempfile,
    },
    {
        label => 'coerce array ref to AbsFile',
        type  => t('AbsFile'),
        input => [$tempfile],
    },

    # RealFile
    {
        label => 'coerce string to RealFile',
        type  => t('RealFile'),
        input => "$tempfile",
    },
    {
        label => 'coerce object to RealFile',
        type  => t('RealFile'),
        input => $tempfile,
    },
    {
        label => 'coerce array ref to RealFile',
        type  => t('RealFile'),
        input => [$tempfile],
    },

    # Dir
    {
        label => 'coerce string to Dir',
        type  => t('Dir'),
        input => "$tempdir",
    },
    {
        label => 'coerce object to Dir',
        type  => t('Dir'),
        input => $tempdir,
    },
    {
        label => 'coerce array ref to Dir',
        type  => t('Dir'),
        input => [$tempdir],
    },

    # AbsDir
    {
        label => 'coerce string to AbsDir',
        type  => t('AbsDir'),
        input => "$tempdir",
    },
    {
        label => 'coerce object to AbsDir',
        type  => t('AbsDir'),
        input => $tempdir,
    },
    {
        label => 'coerce array ref to AbsDir',
        type  => t('AbsDir'),
        input => [$tempdir],
    },

    # RealDir
    {
        label => 'coerce string to RealDir',
        type  => t('RealDir'),
        input => "$tempdir",
    },
    {
        label => 'coerce object to RealDir',
        type  => t('RealDir'),
        input => $tempdir,
    },
    {
        label => 'coerce array ref to RealDir',
        type  => t('RealDir'),
        input => [$tempdir],
    },
);

for my $c (@coercion_tests) {
    subtest(
        $c->{label},
        sub {
            my $wd       = tempd();
            my $type     = $c->{type};
            my $input    = $c->{input};
            my $expected = path( ref $input eq 'ARRAY' ? @{$input} : $input );
            $expected = $expected->absolute if $type->name =~ /^Abs/;
            $expected = $expected->realpath if $type->name =~ /^Real/;

            my $output;
            is(
                exception { $output = $type->coerce_value($input) },
                undef,
                'coerced value without dying'
            ) or return;

            isa_ok( $output, 'Path::Tiny', '$output' );
            is( $output, $expected, 'coercion returned expected value' );
        }
    );
}

my @messages_tests = (
    [
        t('Path'),
        42      => qr/42 is not an object/,
        $OBJECT => qr/is not a Path::Tiny object/,
    ],
    [
        t('AbsPath'),
        42        => qr/42 is not an object/,
        $OBJECT   => qr/is not a Path::Tiny object/,
        $rel_path => qr/is not an absolute path/,
    ],
    [
        t('RealPath'),
        42        => qr/42 is not an object/,
        $OBJECT   => qr/is not a Path::Tiny object/,
        $rel_path => qr/is not a real path/,
        (
            @abs_but_not_real_file
            ? ( $abs_but_not_real_file[0] => qr/is not a real path/ )
            : ()
        ),
    ],
    [
        t('File'),
        42          => qr/42 is not an object/,
        $OBJECT     => qr/is not a Path::Tiny object/,
        $actual_dir => qr/is not a file on disk/,
    ],
    [
        t('AbsFile'),
        42          => qr/42 is not an object/,
        $OBJECT     => qr/is not a Path::Tiny object/,
        $actual_dir => qr/is not a file on disk/,
    ],
    [
        t('RealFile'),
        42          => qr/42 is not an object/,
        $OBJECT     => qr/is not a Path::Tiny object/,
        $actual_dir => qr/is not a file on disk/,
        (
            @abs_but_not_real_file
            ? ( $abs_but_not_real_file[0] => qr/is not a real path/ )
            : ()
        ),
    ],
    [
        t('Dir'),
        42           => qr/42 is not an object/,
        $OBJECT      => qr/is not a Path::Tiny object/,
        $actual_file => qr/is not a directory on disk/,
    ],
    [
        t('AbsDir'),
        42           => qr/42 is not an object/,
        $OBJECT      => qr/is not a Path::Tiny object/,
        $actual_file => qr/is not a directory on disk/,
    ],
    [
        t('RealDir'),
        42           => qr/42 is not an object/,
        $OBJECT      => qr/is not a Path::Tiny object/,
        $actual_file => qr/is not a directory on disk/,
        (
            @abs_but_not_real_dir
            ? ( $abs_but_not_real_dir[0] => qr/is not a real path/ )
            : ()
        ),
    ],
);

for my $m (@messages_tests) {
    my $type = shift @{$m};

    subtest(
        'message for ' . $type->name . ' check failure',
        sub {

            while ( my ( $val, $expect ) = splice @{$m}, 0, 2 ) {
                like(
                    exception { $type->validate_or_die($val) },
                    $expect,
                    'value = ' . describe($val),
                );
            }
        }
    );
}

done_testing;

sub _describe {
    my $value = shift;

    if ( blessed $value && $value->isa('Path::Tiny') ) {
        my $d = "Path::Tiny object for [$value]";
        my @attr;

        if ( $value->is_absolute ) {
            push @attr, 'absolute';
        }

        if ( $value->realpath eq $value ) {
            push @attr, 'realpath';
        }

        if ( $value->is_file ) {
            push @attr, 'file';
        }
        elsif ( $value->is_dir ) {
            push @attr, 'dir';
        }

        push @attr, 'symlink'
            if -l $value;

        if (@attr) {
            $d .= ' (' . ( join ', ', @attr ) . ')';
        }

        return $d;
    }

    return describe($value);
}

