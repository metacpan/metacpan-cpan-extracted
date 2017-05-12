use strict;
use warnings;
use autodie;

use Test::More 0.88;

use File::Temp qw( tempdir );
use Path::Class qw( dir file );

{
    package Conf;

    use Moose;
    use MooseX::Configuration;
    use MooseX::Types::Moose qw( ArrayRef Int Num Str );

    has root_key_a => (
        is       => 'ro',
        isa      => Str,
        key      => 'a',
        required => 1,
    );

    has root_key_b => (
        is            => 'ro',
        isa           => Int,
        key           => 'b',
        default       => 'value of b',
        documentation => 'This is the b key',
    );

    has foo_key_c => (
        is            => 'ro',
        isa           => Num,
        section       => 'foo',
        key           => 'c',
        documentation => 'This is the c key',
    );

    has foo_key_d => (
        is            => 'ro',
        isa           => Num,
        section       => 'foo',
        key           => 'd',
        default       => 42,
        documentation => 'This is the d key',
    );

    has not_config => (
        is  => 'ro',
        isa => ArrayRef,
    );
}

{
    ok(
        Conf->new( root_key_a => 'x' ),
        'can create a Conf object without reading a config file'
    );
}

my $tempdir = dir( tempdir( CLEANUP => 1 ) );

{
    my $file = $tempdir->file('test1.conf');

    open my $fh, '>', $file;
    print {$fh} <<'EOF';
a = Foo
b = 42

[foo]
c = 4.2
EOF
    close $fh;

    my $conf = Conf->new( config_file => $file );

    is(
        $conf->root_key_a(), 'Foo',
        'got root_key_a from config file'
    );

    is(
        $conf->root_key_b(), 42,
        'got root_key_b from config file'
    );

    is(
        $conf->foo_key_c(), 4.2,
        'got foo_key_c from config file'
    );

    my $buffer = q{};
    open $fh, '>', \$buffer;

    $conf->write_config_file(
        generated_by => 'Test code',
        file         => $fh,
    );

    my $expect = <<'EOF';
; Test code

; This configuration key is required.
a = Foo

; This is the b key
; Defaults to "value of b"
b = 42

[foo]
; This is the c key
c = 4.2

; This is the d key
; Defaults to 42
; d =

EOF

    is(
        $buffer,
        $expect,
        'write_file generates expected file'
    );
}

done_testing();
