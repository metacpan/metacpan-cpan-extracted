use warnings;
use strict;

{
    package Foo;
    use Moose;
    use MooseX::Types::Path::Class;

    has 'dir' => (
        is       => 'ro',
        isa      => 'Path::Class::Dir',
        required => 1,
        coerce   => 1,
    );

    has 'file' => (
        is       => 'ro',
        isa      => 'Path::Class::File',
        required => 1,
        coerce   => 1,
    );
}

{
    package Bar;
    use Moose;
    use MooseX::Types::Path::Class qw( Dir File );

    has 'dir' => (
        is       => 'ro',
        isa      => Dir,
        required => 1,
        coerce   => 1,
    );

    has 'file' => (
        is       => 'ro',
        isa      => File,
        required => 1,
        coerce   => 1,
    );
}

package main;

use Test::More;
use Path::Class;
plan tests => 10;

my $dir = dir('', 'tmp');
my $file = file('', 'tmp', 'foo');

my $check = sub {
    my $o = shift;
    isa_ok( $o->dir, 'Path::Class::Dir' );
    cmp_ok( $o->dir, 'eq', "$dir", "dir is $dir" );
    isa_ok( $o->file, 'Path::Class::File' );
    cmp_ok( $o->file, 'eq', "$file", "file is $file" );
};

for my $class (qw(Foo Bar)) {
    my $o = $class->new( dir => "$dir", file => [ '', 'tmp', 'foo' ] );
    isa_ok( $o, $class );
    $check->($o);
}
