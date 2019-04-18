#!/usr/bin/perl -T

use Test::More tests => 39;
use Paranoid;
use Paranoid::Args qw(:all);
use Paranoid::Debug;

use strict;
use warnings;

psecureEnv();

my ( %options, @args, @errors );
my @templates = ( {
        Short      => 'v',
        Long       => 'verbose',
        CountShort => 1,
    },
    {   Short    => 'V',
        Long     => 'VERBOSE',
        Template => '$',
    },
    {   Short    => 'P',
        Long     => 'pad',
        Template => '$@',
    },
    {   Short     => 'f',
        Long      => 'foo',
        Template  => '$',
        Multiple  => 1,
        CanBundle => 1,
    },
    {   Long     => 'test',
        Template => '$$@$',
    },
    {   Short         => 'x',
        Long          => 'with-x',
        Template      => '$',
        AccompaniedBy => [qw(y)],
    },
    {   Short         => 'y',
        Long          => 'with-y',
        Template      => '$',
        AccompaniedBy => [qw(x)],
    },
    {   Short       => 'z',
        Long        => 'with-z',
        Template    => '$',
        ExclusiveOf => [qw(y x)],
    },
    );

# Test parseArgs
@args = qw(-vvv -V5);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 1a' );
is( $options{v},       3, 'v == 3' );
is( $options{verbose}, 3, 'verbose == 3' );
is( $options{V},       5, 'VERBOSE == 5' );
@args = qw(-V55);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 1b' );
is( $options{V}, 55, 'VERBOSE == 55' );

@args = qw(-vvv --VERBOSE=7 --verbose 1 -v);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 2' );
is( $options{v},       2, 'v == 2' );
is( $options{VERBOSE}, 7, 'VERBOSE == 7' );

@args = qw(-P /tmp foo bar roo);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 3' );
is( $options{P}[0],    '/tmp', 'P/0 == "/tmp"' );
is( $options{P}[1][1], 'bar',  'P/1/1 == "bar"' );

@args = qw(-P /tmp roo -ff foo1 foo2 bar bar roo);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 4' );
is( $options{f}[0],       'foo1', 'f/0 == "foo1"' );
is( $options{f}[1],       'foo2', 'f/1 == "foo2"' );
is( $options{PAYLOAD}[2], 'roo',  'PAYLOAD/2 == "roo"' );

@args = qw(--test one two three four five six seven);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 5' );
is( $options{test}[2][1], 'four',  'test/2/1 == "four"' );
is( $options{test}[3],    'seven', 'test/3 == "seven"' );

@args = qw(-vvv foo bar -- -f --test);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 6' );
is( $options{PAYLOAD}[2], '-f', 'PAYLOAD/2 == "-f"' );

@args = qw(--test one two -- six -P --pad seven);
ok( parseArgs( @templates, %options, @args ), 'parseArgs 7' );
is( $options{test}[2][1], '-P', 'test/2/1 == "-P"' );

@args = qw(--test one two seven);
ok( !parseArgs( @templates, %options, @args ), 'parseArgs 8' );
@errors = Paranoid::Args::listErrors();
like( $errors[0], qr/missing the min/smi, 'error string matches 1' );

@args = qw(--with-x 5 -y334 -z 10);
ok( !parseArgs( @templates, %options, @args ), 'parseArgs 9' );
@errors = Paranoid::Args::listErrors();
like( $errors[0], qr/cannot be called/smi, 'error string matches 2' );

@args = qw(--with-x 5);
ok( !parseArgs( @templates, %options, @args ), 'parseArgs 10' );
@errors = Paranoid::Args::listErrors();
like( $errors[0], qr/must be called/smi, 'error string matches 3' );

@args = qw(--with-x 5 -y 5 --what);
ok( !parseArgs( @templates, %options, @args ), 'parseArgs 10' );
@errors = Paranoid::Args::listErrors();
like( $errors[0], qr/unknown option/smi, 'error string matches 4' );

@args = qw(--with-x 5 -y 5 ---what);
ok( !parseArgs( @templates, %options, @args ), 'parseArgs 10' );
@errors = Paranoid::Args::listErrors();
like( $errors[0], qr/unknown option/smi, 'error string matches 5' );

@templates = ( PA_DEBUG, PA_VERBOSE, PA_VERSION, PA_HELP );
@args = qw(-DDDvv --help --version);
ok( parseArgs( @templates, %options, @args ), 'templates 1' );
@errors = Paranoid::Args::listErrors();
is( scalar @errors,    0, 'template errors 1' );
is( $options{verbose}, 2, 'template verification 1' );
is( $options{debug},   3, 'template verification 2' );
is( $options{help},    1, 'template verification 3' );
is( $options{version}, 1, 'template verification 4' );

