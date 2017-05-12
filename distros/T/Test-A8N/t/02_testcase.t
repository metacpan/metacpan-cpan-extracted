#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 45;
use Test::Exception;

BEGIN { 
    use_ok('Test::A8N::TestCase') 
};
my %config_defaults = (
    fixture_base       => "Fixture",
    file_root          => "t/testdata/cases",
    filenames          => [],
    verbose            => 0,
    tags         => {
        include => [],
        exclude => [],
    },
    allowed_extensions => [qw( tc st )],
);

Basic_usage: {
    ok( Test::A8N::TestCase->meta->has_attribute('data'), q{data attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('index'), q{index attribute}) ;

    ok( Test::A8N::TestCase->meta->has_attribute('id'), q{id attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('name'), q{name attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('filename'), q{filename attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('tags'), q{tags attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('summary'), q{summary attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('configuration'), q{configuration attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('instructions'), q{instructions attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('preconditions'), q{preconditions attribute}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('expected'), q{expected attribute}) ;

    ok( Test::A8N::TestCase->meta->has_attribute('is_valid'), q{is_valid property}) ;
    ok( Test::A8N::TestCase->meta->has_attribute('test_data'), q{test_data property}) ;
    
    my $tc = Test::A8N::TestCase->new({
        index => 1,
        filename => "file name",
        data => {
            ID => "some_id",
            NAME => "Test Name",
            SUMMARY => "Summary Test Description",
            TAGS => [qw( tag1 tag2 )],
            EXPECTED => [qw(expected1 expected2)],
            INSTRUCTIONS => [
                'fixture1',
                { 'fixture2' => 'foo' },
                { 'fixture3' => { 'bar' => 'baz' } },
                { 'fixture4' => [ 'boo', 'bork' ] }
            ],
        },
        config => \%config_defaults,
    });
    isa_ok($tc, 'Test::A8N::TestCase', q{Created TestCase object});
    ok($tc->is_valid, q{TC is valid});
    is($tc->id, 'some_id', q{TC "ID" correct});
    is($tc->name, 'Test Name', q{TC "name" correct});
    is($tc->filename, 'file name', q{TC "filename" correct});
    is($tc->summary, 'Summary Test Description', q{TC "summary" correct});

    is_deeply($tc->tags, [qw( tag1 tag2 )], q{TC "tags" correct});
    ok($tc->hasTags(), q{hasTags defaults to true});
    ok($tc->hasTags(qw( tag1 tag2 )), q{hasTags tag1, tag2});
    ok($tc->hasTags(qw( tag1 )), q{hasTags tag1});
    ok($tc->hasTags(qw( tag2 )), q{hasTags tag2});
    ok(!$tc->hasTags(qw( foo )), q{doesn't hasTags foo});
    ok(!$tc->hasTags(qw( tag1 foo )), q{doesn't hasTags tag1, foo});
    ok(!$tc->hasTags(qw( tag2 foo )), q{doesn't hasTags tag2, foo});
    ok(!$tc->hasTags(qw( tag1 tag2 foo )), q{doesn't hasTags tag1, tag2, foo});

    is_deeply($tc->expected, [qw( expected1 expected2 )], q{TC "expected" correct});
    is_deeply(
        $tc->instructions,
        [
            'fixture1',
            { 'fixture2' => 'foo' },
            { 'fixture3' => { 'bar' => 'baz' } },
            { 'fixture4' => [ 'boo', 'bork' ] }
        ],
        q{TC "instructions" correct}
    );
    is_deeply(
        $tc->test_data,
        [
            [ 'fixture1' ],
            [ 'fixture2', 'foo' ],
            [ 'fixture3', { 'bar' => 'baz' } ],
            [ 'fixture4', [ 'boo', 'bork' ] ]
        ],
        q{TC test_data correct}
    );
}

Invalid_TC: {
    my $tc = Test::A8N::TestCase->new({
        index => 1,
        filename => "file name",
        data => {
            NAME => "Test Name",
        },
        config => {
            %config_defaults
        }
    });
    ok(!$tc->is_valid, q{TC is not valid});
}

Invalid_Configuration: {
    my $tc;
    throws_ok {
        $tc = Test::A8N::TestCase->new({
            index => 1,
            filename => "file name",
            data => {
                NAME => "Test Name",
                CONFIGURATION => [qw( foo )],
            },
            config => {
                %config_defaults
            }
        });
    } qr{Can't load configuration file "t/testdata/cases/foo" for testcase "Test Name" in file "file name"}, "bad config file throws an exception";
}

Good_Configuration: {
    my $tc;
    lives_ok {
        $tc = Test::A8N::TestCase->new({
            index => 1,
            filename => "file name",
            data => {
                NAME => "Test Name",
                CONFIGURATION => [qw( UI/Config/Accounts/Alert_Recipients.conf )],
            },
            config => {
                %config_defaults
            }
        });
    } "testcase loads with config data";
    is_deeply(
        $tc->config,
        {
            %config_defaults,
            alert => ['bob@foo.org']
        },
        q{testcase config data loaded}
    );
}

Implicit_IDs: {
    my $tc = Test::A8N::TestCase->new({
        index => 1,
        filename => "file name",
        data => {
            NAME => "Test Name",
            SUMMARY => "Summary Test Description",
            TAGS => [qw( tag1 tag2 )],
            INSTRUCTIONS => [
                { 'some test' => [] },
                { 'some other test' => [] },
                { 'some final test' => [] },
            ],
        },
        config => {
            %config_defaults
        }
    });
    is($tc->id, 'test_name', q{Implied test ID works});
}

Parse_Data: {
    my $tc = Test::A8N::TestCase->new({
        index => 1,
        filename => "file name",
        data => {
            NAME => "Test Name",
            SUMMARY => "Summary Test Description",
            TAGS => [qw( tag1 tag2 )],
            INSTRUCTIONS => [
                { 'some test' => [] },
            ],
        },
        config => {
            %config_defaults
        }
    });
    is_deeply(
        $tc->parse_data([ qw( foo ) ]),
        [[qw(foo)]],
        q{Parse one plain-string fixture}
    );
    is_deeply(
        $tc->parse_data([ qw( foo bar ) ]),
        [['foo'],['bar']],
        q{Parse multiple plain-string fixture}
    );
    is_deeply(
        $tc->parse_data([{ foo => 'bar'}]),
        [[qw(foo bar)]],
        q{Parse single string value fixture}
    );
    is_deeply(
        $tc->parse_data([{ foo => [qw(bar baz)]}]),
        [['foo', [qw(bar baz)]]],
        q{Parse array value fixture}
    );
    is_deeply(
        $tc->parse_data([{ foo => { baz => 'boo' }}]),
        [['foo', { baz => 'boo' }]],
        q{Parse hash value fixture}
    );
    throws_ok {
        $tc->parse_data([[{ foo => { baz => 'boo' }}]]),
    } qr{Unable to parse structure of type 'ARRAY'},
      q{Parse nested value fixture};
}

Preconditions: {
    my $tc = Test::A8N::TestCase->new({
        index => 1,
        filename => "file name",
        data => {
            NAME => "Test Name",
            SUMMARY => "Summary Test Description",
            TAGS => [qw( tag1 tag2 )],
            PRECONDITIONS => [
                { 'pre condition' => 'a' },
            ],
            INSTRUCTIONS => [
                { 'some test' => 'b' },
            ],
        },
        config => {
            %config_defaults
        }
    });
    is_deeply(
        $tc->preconditions,
        [
            { 'pre condition' => 'a' },
        ],
        q{TC preconditions returned properly}
    );
    is_deeply(
        $tc->test_data,
        [
            [ 'pre condition', 'a' ],
            [ 'some test', 'b' ],
        ],
        q{TC preconditions returned in the data property}
    );
}

Test_Munger: {
    my $tc = Test::A8N::TestCase->new({
        index => 1,
        filename => "file name",
        data => {
            NAME => "Test Name",
            SUMMARY => "Summary Test Description",
            TAGS => [qw( tag1 tag2 )],
            INSTRUCTIONS => [
                { 'some test' => [] },
            ],
        },
        config => {
            %config_defaults
        }
    });
}
