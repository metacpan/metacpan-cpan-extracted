#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'MooseX::Compile::CLI::Base';

use Path::Class;

{
    package Foo;
    use Moose;

    extends qw(MooseX::Compile::CLI::Base);

    # disable MooseX::App::Cmd crap we don't need right now
    has '+usage' => ( required => 0 );
    has '+app' => ( required => 0 );

    sub filter_file {
        my ( $self, $file ) = @_;

        return $file if -f $file and $file->basename =~ / \.pm$ | ^00[12]_\w+\.t$ /x;
    }
}

{
    my $foo = Foo->new(
        dirs    => [dir('t')],
        inc     => [dir('lib')],
        classes => [qw(MooseX::Compile::CLI)],
    );

    is_deeply(
        [ sort map { "$_->{rel}" }$foo->all_files ],
        [ sort qw(
            001_load.t
            002_base.t
            MooseX/Compile/CLI.pm
        )],
        "find target files",
    );
}

{
    my $foo = Foo->new(
        dirs    => [dir('lib')],
    );

    is_deeply(
        [ sort map { $_->{class} } $foo->all_files ],
        [ sort qw(
            MooseX::Compile::CLI
            MooseX::Compile::CLI::Base
            MooseX::Compile::CLI::Command::clean
            MooseX::Compile::CLI::Command::compile
        ) ],
        "find target files",
    );
}
