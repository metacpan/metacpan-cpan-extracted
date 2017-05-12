#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 25;
use Test::Exception;
use Test::Deep;
use lib qw(t/mock t/lib);

BEGIN { 
    use_ok('Test::A8N::File') 
};

my %extra_defaults = (
    filenames    => [],
    verbose      => 0,
    tags         => {
        include => [],
        exclude => [],
    },
    allowed_extensions => [qw( tc st )],
);

Basic_usage: {
    ok(Test::A8N::File->meta->has_attribute('filename'), q{filename attribute});
    ok(Test::A8N::File->meta->has_attribute('file_root'), q{file_root attribute});
    ok(Test::A8N::File->meta->has_attribute('fixture_base'), q{fixture_base attribute});
    ok(Test::A8N::File->meta->has_attribute('fixture_class'), q{fixture attribute});
    ok(Test::A8N::File->meta->has_attribute('data'), q{data attribute});
    ok(Test::A8N::File->meta->has_attribute('cases'), q{cases attribute});
    ok(Test::A8N::File->meta->has_attribute('config'), q{config attribute});

    throws_ok(
        sub {
            Test::A8N::File->new({
                filename => 't/testdata/cases/test_doesnt_exist.tc',
                config   => {
                    file_root    => 't/testdata/cases',
                    parser       => 'Test::Sophos::Parser',
                    fixture_base => 'Test::Sophos::Fixture',
                    %extra_defaults,
                }
            });
        },
        qr{Could not find a8n file "t/testdata/cases/test_doesnt_exist.tc"},
        q{File not existing}
    );
}

Simple_File: {
    $Test::FITesque::ADDED_TESTS = [];
    my $file = Test::A8N::File->new({
        filename => 't/testdata/cases/test1.tc',
        config   => {
            file_root    => 't/testdata/cases',
            fixture_base => 'MockFixture',
            %extra_defaults,
        }
    });
    isa_ok($file, 'Test::A8N::File', q{Created File object for test1.tc});
    is($file->filename, 't/testdata/cases/test1.tc', q{Filename property contains valid value});

    my $test1 = {
        'NAME'         => 'Test Case 1',
        'ID'           => 'some_test_case_1',
        'SUMMARY'      => 'This is a test summary',
        'TAGS'         => [qw( tag1 tag2 )],
        'INSTRUCTIONS' => [
            'fixture1',
            { 'fixture2' => 'foo' },
            { 'fixture3' => { 'bar' => 'baz' } },
            { 'fixture4' => [ 'boo', 'bork' ] }
        ],
        'EXPECTED'     => 'Some output',
    };
    is_deeply($file->data, [$test1], q{YAML data returned correctly});
    isa_ok($file->cases->[0], 'Test::A8N::TestCase', q{cases() returned a Test::A8N::TestCase object});
    is($file->fixture_base, 'MockFixture', q{fixture_base property matches what was supplied});
    is($file->fixture_class, 'MockFixture', q{Correct fixture class located});
}

Files_with_spaces: {
    $Test::FITesque::ADDED_TESTS = [];
    my $file = Test::A8N::File->new({
        filename => 't/testdata/cases/test with spaces.tc',
        config   => {
            file_root    => 't/testdata/cases',
            fixture_base => 'MockFixture',
            %extra_defaults,
        }
    });
    isa_ok($file, 'Test::A8N::File', q{Created File object for "test with spaces.tc"});
    is($file->filename, 't/testdata/cases/test with spaces.tc', q{Filename property contains valid value});
}

Files_with_different_extensions: {
    $Test::FITesque::ADDED_TESTS = [];
    my $file = Test::A8N::File->new({
        filename => 't/testdata/cases/storytest.st',
        config   => {
            file_root    => 't/testdata/cases',
            fixture_base => 'MockFixture',
            %extra_defaults,
        }
    });
    isa_ok($file, 'Test::A8N::File', q{Created File object for "storytest.st"});
    is($file->filename, 't/testdata/cases/storytest.st', q{Filename property contains valid value});
}

Inherited_Fixtures: {
    $Test::FITesque::ADDED_TESTS = [];
    my $file = Test::A8N::File->new({
        filename => 't/testdata/cases/UI/Config/Accounts/Alert_Recipients.tc',
        config   => {
            file_root    => 't/testdata/cases',
            fixture_base => 'Fixture',
            %extra_defaults,
        }
    });
    isa_ok($file, 'Test::A8N::File', q{Created File object for Alert_Recipients.tc});
    is($file->fixture_class, 'Fixture::UI::Config', q{Inherited fixture class located});
}

Fixtures_With_Spaces: {
    $Test::FITesque::ADDED_TESTS = [];
    my $file = Test::A8N::File->new({
        filename => 't/testdata/cases/System Status/Basic Status.tc',
        config   => {
            file_root    => 't/testdata/cases',
            fixture_base => 'Fixture',
            %extra_defaults,
        }
    });
    is($file->fixture_class, 'Fixture::SystemStatus', q{Fixture class has been found for a directory with a space});
}

Invalid_Syntax: {
    $Test::FITesque::ADDED_TESTS = [];
    my $file;
    lives_ok {
        $file = Test::A8N::File->new({
            filename => 't/testdata/cases/invalid_syntax.tc',
            config   => {
                file_root    => 't/testdata/cases',
                fixture_base => 'Fixture',
                %extra_defaults,
            }
        });
    } "Loading file with invalid syntax doesn't die";
    isa_ok($file, 'Test::A8N::File', q{Created File object for invalid_syntax.tc});
    is_deeply($file->data, [], q{Invalid file's contents is empty});
}

