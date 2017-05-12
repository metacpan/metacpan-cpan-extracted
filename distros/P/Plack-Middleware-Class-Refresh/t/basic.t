#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Plack::Test;
use lib 't/lib';
use Test::PMCR;

use File::Copy;
use File::Spec::Functions 'catfile';
use HTTP::Request::Common;

use Plack::Middleware::Class::Refresh;

my $app = sub {
    return [
        200,
        [],
        [join "\n", Foo->call, Foo::Bar->call, Baz::Quux->call]
    ];
};

{
    my $dir = Test::PMCR::setup_temp_dir('basic');

    require Foo;
    require Foo::Bar;
    require Baz::Quux;

    test_psgi
        app    => Plack::Middleware::Class::Refresh->wrap($app),
        client => sub {
            my $cb = shift;
            {
                my $warnings;
                local $SIG{__WARN__} = sub { $warnings .= $_[0] };
                my $res = $cb->(GET 'http://localhost/');
                is($res->code, 200, "right code");
                is($res->content, "Foo\nFoo::Bar\nBaz::Quux");
                is($warnings, undef, "no warnings when not verbose");
            }
            copy(catfile(qw(t data_new basic Foo.pm)), catfile($dir, 'Foo.pm'))
                || die "couldn't copy: $!";
            {
                my $warnings;
                local $SIG{__WARN__} = sub { $warnings .= $_[0] };
                my $res = $cb->(GET 'http://localhost/');
                is($res->code, 200, "right code");
                is($res->content, "FOO\nFoo::Bar\nBaz::Quux", "right content");
                is($warnings, undef, "no warnings when not verbose");
            }
        };
}

Class::Refresh->unload_module($_) for 'Foo', 'Foo::Bar', 'Baz::Quux';

{
    my $dir = Test::PMCR::setup_temp_dir('basic');

    require Foo;
    require Foo::Bar;
    require Baz::Quux;

    test_psgi
        app    => Plack::Middleware::Class::Refresh->wrap($app, verbose => 1),
        client => sub {
            my $cb = shift;
            {
                my $warnings;
                local $SIG{__WARN__} = sub { $warnings .= $_[0] };
                my $res = $cb->(GET 'http://localhost/');
                is($res->code, 200, "right code");
                is($res->content, "Foo\nFoo::Bar\nBaz::Quux");
                is($warnings, undef, "no warnings yet");
            }
            copy(catfile(qw(t data_new basic Foo.pm)), catfile($dir, 'Foo.pm'))
                || die "couldn't copy: $!";
            {
                my $warnings;
                local $SIG{__WARN__} = sub { $warnings .= $_[0] };
                my $res = $cb->(GET 'http://localhost/');
                is($res->code, 200, "right code");
                is($res->content, "FOO\nFoo::Bar\nBaz::Quux", "right content");
                like($warnings, qr/^Class Foo has been changed, refreshing/,
                     "right warning");
            }
        };
}

done_testing;
