use strict;
use warnings;

use MooseX::Runnable::Util::ArgParser;

use Test::TableDriven (
    class_name => {
        'Foo' => 'Foo',
        '-Ilib Foo' => 'Foo' ,
        '-I/foo/bar/lib -Ilib -IFoo module with lots of args' => 'module' ,
        '-- Foo' => 'Foo',
        '-Ilib -- Foo' => 'Foo',
        '-Ilib -MFoo::Bar -- Foo::Baz' => 'Foo::Baz',
        '-MFoo Bar' => 'Bar',
        '+Plugin1 --args --go --here -- Foo' => 'Foo',
        '+P --args --arehere +Q --more --args -- Foo' => 'Foo',
        '-Ilib +P --args --arehere +Q --more --args -Ilib -- Foo' => 'Foo',
        '+P --args -- Foo -- Bar' => 'Foo',
        '-Ilib +Debug -- PlanFinder' => 'PlanFinder',
        '-Ilib -Iexample +Debug --prefix 42 -- MyApp' => 'MyApp',
    },

    modules => {
        'Foo' => [],
        'Foo -MFoo' => [],
        '-MFoo' => ['Foo'],
        '-MFoo Foo' => ['Foo'],
        '-MFoo Foo' => ['Foo'],
        '-MFoo -MFoo Foo' => ['Foo', 'Foo'],
        '-MFoo -MBar -MBaz::Quux -Ilib OH::HAI' => ['Foo','Bar','Baz::Quux'],
        '+End -MFoo -MBar -- OH::HAI' => [],
        '-Ilib +End -MFoo -- OH::HAI' => [],
        '-Ilib -MFoo OH::HAI' => ['Foo'],
        '-Ilib -MFoo +End -MBar -- OH::HAI' => ['Foo'],
        '-Ilib +Debug -- PlanFinder' => [],
        '-Ilib -Iexample +Debug --prefix 42 -- MyApp' => [],
    },

    include_paths => {
        'Foo' => [],
        'Foo -Ilib' => [],
        '-Ilib Foo' => ['lib'],
        '-MFoo Foo' => [],
        '-MFoo -MBar -MBaz::Quux -Ilib OH::HAI' => ['lib'],
        '+End -MFoo -MBar -- OH::HAI' => [],
        '-Ilib +End -MFoo -- OH::HAI' => ['lib'],
        '-Ilib -MFoo OH::HAI' => ['lib'],
        '-Ilib -MFoo +End -IBar -- OH::HAI' => ['lib'],
        '-Ilib -MFoo -I../../../../lib +End -IBar -- OH::HAI' =>
              ['lib', '../../../../lib'],
        '-Ilib +Debug -- PlanFinder' => ['lib'],
        '-Ilib -Iexample +Debug --prefix 42 -- MyApp' => ['lib', 'example'],
    },

    plugins => {
        'Foo' => {},
        '-Ilib Foo' => {},
        '-Ilib -MFoo -- Bar' => {},
        '+One --arg +Two --arg2 -- End' => { One => ['--arg'], Two => ['--arg2'] },
        '+Debug +PAR +Foo::Bar -- Baz' => { Debug => [], PAR => [], 'Foo::Bar' => [] },
        '-Ilib +Debug -- PlanFinder' => { Debug => [] },
        '++Foo -- Bar' => { '+Foo' => [] },
        '-Ilib -Iexample +Debug --prefix 42 -- MyApp' => { Debug => [ '--prefix', '42' ] },
    },

    is_help => {
        '--help' => 1,
        '-h' => 1,
        '-?' => 1,
        '--?' => 0,
        '--h' => 0,
        '+Foo --help' => 0,
        'Foo' => 0,
        '-Ilib -MFoo --help' => 1,
        '-- Foo --help' => 0,
        'Foo --help' => 0,
        'Foo -?' => 0,
        'Foo -h' => 0,
        '-Ilib +Debug -- PlanFinder' => 0,
        '-Ilib -Iexample +Debug --prefix 42 -- MyApp' => 0,
    },

    app_args => {
        'Foo' => [],
        '-Ilib Foo' => [],
        '-Ilib -MFoo Bar' => [],
        'Foo Bar' => ['Bar'],
        'Foo Bar Baz' => ['Bar', 'Baz'],
        '-- Foo Bar Baz' => ['Bar', 'Baz'],
        '-Ilib Foo -Ilib' => ['-Ilib'],
        '-MFoo Foo -MFoo' => ['-MFoo'],
        '-MFoo -MFoo Foo -MFoo' => ['-MFoo'],
        '-- Foo --help' => ['--help'],
        '-Ilib +Debug -- PlanFinder' => [],
        '-Ilib -Iexample +Debug --prefix 42 -- MyApp' => [],
    },
);

sub class_name {
    my ($argv) = @_;
    my $p = MooseX::Runnable::Util::ArgParser->new( argv => [split / /, $argv] );
    return $p->class_name;
}

sub modules {
    my ($argv) = @_;
    my $p = MooseX::Runnable::Util::ArgParser->new( argv => [split / /, $argv] );
    return $p->modules;
}

sub include_paths {
    my ($argv) = @_;
    my $p = MooseX::Runnable::Util::ArgParser->new( argv => [split / /, $argv] );
    return [ map { $_->stringify } $p->include_paths ];
}

sub plugins {
    my ($argv) = @_;
    my $p = MooseX::Runnable::Util::ArgParser->new( argv => [split / /, $argv] );
    return $p->plugins;
}

sub is_help {
    my ($argv) = @_;
    my $p = MooseX::Runnable::Util::ArgParser->new( argv => [split / /, $argv] );
    return $p->is_help ? 1 : 0;
}

sub app_args {
    my ($argv) = @_;
    my $p = MooseX::Runnable::Util::ArgParser->new( argv => [split / /, $argv] );
    return $p->app_args;
}

runtests;
