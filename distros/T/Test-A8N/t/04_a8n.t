#!/usr/bin/env perl

use strict;
use warnings;
use lib qw(t/mock t/lib);

use Test::More tests => 64;
use Test::Exception;
use Test::Deep;
BEGIN { 
    use_ok('Test::A8N') 
};

Basic_usage: {
    ok( Test::A8N->meta->has_attribute('filenames'), q{filenames attribute}) ;
    ok( Test::A8N->meta->has_attribute('files'), q{files attribute}) ;
    ok( Test::A8N->meta->has_attribute('file_root'), q{file_root attribute}) ;
    ok( Test::A8N->meta->has_attribute('fixture_base'), q{fixture_base attribute}) ;
    ok( Test::A8N->meta->has_attribute('config'), q{config attribute}) ;
    my $obj = Test::A8N->new({
        config => {
            filenames    => [qw( t/testdata/cases/test1.tc )],
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
        }
    });
    isa_ok($obj, 'Test::A8N', q{object constructed}) ;
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});
    is_deeply($obj->file_paths(), [ 't/testdata/cases/test1.tc' ], q{file_paths returned testcase file path});
    ok(ref $obj->files() eq 'ARRAY', q{files returns array ref});
    ok(ref $obj->files()->[0] eq 'Test::A8N::File', q{files returned Test::A8N::File object});

    is_deeply(
        $obj->config(),
        {
            filenames    => [qw( t/testdata/cases/test1.tc )],
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
            verbose      => 0,
            tags         => {
                include => [],
                exclude => [],
            },
            allowed_extensions => [qw( tc st )],
        },
        q{config() returns supplied args with defaults}
    );

    $Test::FITesque::Suite::ADDED_TESTS = [];
    lives_ok {
        $obj->run_tests()
    } "run_tests() doesn't die";
    cmp_deeply(
        $Test::FITesque::Suite::ADDED_TESTS,
        [
            [
                [ 'MockFixture', { testcase => ignore() } ],
                [ 'fixture1'                              ],
                [ 'fixture2', 'foo'                       ],
                [ 'fixture3', { bar => 'baz' }            ],
                [ 'fixture4', [qw( boo bork )]            ],
            ]
        ],
        q{Check that run_tests runs all 4 fixtures}
    );
    isa_ok($Test::FITesque::Suite::ADDED_TESTS->[0][0][1]->{testcase}, 'Test::A8N::TestCase');
}

Different_extension: {
    ok( Test::A8N->meta->has_attribute('filenames'), q{filenames attribute}) ;
    ok( Test::A8N->meta->has_attribute('files'), q{files attribute}) ;
    ok( Test::A8N->meta->has_attribute('file_root'), q{file_root attribute}) ;
    ok( Test::A8N->meta->has_attribute('fixture_base'), q{fixture_base attribute}) ;
    my $obj = Test::A8N->new({
        config => {
            filenames    => [qw( t/testdata/cases/storytest.st )],
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
            allowed_extensions => ["tc","st"],
        }
    });
    isa_ok($obj, 'Test::A8N', q{object constructed}) ;
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});
    is_deeply($obj->file_paths(), [ 't/testdata/cases/storytest.st' ], q{file_paths returned testcase file path});
    ok(ref $obj->files() eq 'ARRAY', q{files returns array ref});
    ok(ref $obj->files()->[0] eq 'Test::A8N::File', q{files returned Test::A8N::File object});

    is_deeply(
        $obj->config(),
        {
            filenames    => [qw( t/testdata/cases/storytest.st )],
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
            verbose      => 0,
            tags         => {
                include => [],
                exclude => [],
            },
            allowed_extensions => [qw( tc st )],
        },
        q{config() returns supplied args with defaults}
    );

    $Test::FITesque::Suite::ADDED_TESTS = [];
    $obj->run_tests();
    cmp_deeply(
        $Test::FITesque::Suite::ADDED_TESTS,
        [
            [
                [ 'MockFixture', { testcase => ignore() } ],
                [ 'fixture1'                              ],
                [ 'fixture2', 'foo'                       ],
                [ 'fixture3', { bar => 'baz' }            ],
                [ 'fixture4', [qw( boo bork )]            ],
            ]
        ],
        q{Check that run_tests runs all 4 fixtures}
    );
    isa_ok($Test::FITesque::Suite::ADDED_TESTS->[0][0][1]->{testcase}, 'Test::A8N::TestCase');
}

Directories: {
    my $obj = Test::A8N->new({
        config => {
            filenames    => [qw( t/testdata/cases/UI )],
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
        }
    });
    ok(ref $obj->file_paths() eq 'ARRAY', q{file_paths returns array ref});

    my @files = grep {/\.tc/} @{ $obj->file_paths };
    is_deeply(
        [ sort @files ],
        [ sort qw(
            t/testdata/cases/UI/Reports/Report_Dashboard.tc
            t/testdata/cases/UI/Config/Certificates/Views_Root_CA.tc
            t/testdata/cases/UI/Config/Accounts/Alert_Recipients.tc
        )],
        q{Check the files returned}
    );
}

Directories_All: {
    my $obj;
    ok($obj = Test::A8N->new({
        config => {
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
        }
    }), 'Create the a8n object');

    is_deeply(
        $obj->config(),
        {
            filenames    => [],
            fixture_base => 'MockFixture',
            file_root    => 't/testdata/cases',
            verbose      => 0,
            tags         => {
                include => [],
                exclude => [],
            },
            allowed_extensions => [qw( tc st )],
        },
        q{config() returns supplied args with defaults}
    );

    is(ref($obj->file_paths), 'ARRAY', 'check that file_paths returns an arrayref');

    my @files = grep {/\.tc/} @{ $obj->file_paths };

    is_deeply(
        [ sort @files ],
        [ sort(
            't/testdata/cases/test1.tc',
            't/testdata/cases/invalid_syntax.tc',
            't/testdata/cases/test with spaces.tc',
            't/testdata/cases/UI/Reports/Report_Dashboard.tc',
            't/testdata/cases/UI/Config/Certificates/Views_Root_CA.tc',
            't/testdata/cases/UI/Config/Accounts/Alert_Recipients.tc',
            't/testdata/cases/System Status/Basic Status.tc',
        )],
        q{Check file list when no filename is selected, e.g. "All Files"}
    );
}

Multiple_Tests: {
    $Test::FITesque::Suite::ADDED_TESTS = [];
    my $a8n = Test::A8N->new({
        config   => {
            filenames    => ['t/testdata/cases/test_multiple.st'],
            file_root    => 't/testdata/cases',
            fixture_base => 'Fixture',
        }
    });
    my $file = $a8n->files->[0];
    is(scalar(@{ $file->data }), 3, q{Proper number of data elements});
    is(scalar(@{ $file->cases }), 3, q{Proper number of test cases});
    my @ids = map {$_->id} @{ $file->cases };
    is_deeply(\@ids, ['test_case_1', 'custom_id', 'some_other_id'], q{Multiple IDs match});
    is_deeply(
        $file->cases->[0]->data,
        {
          'SUMMARY' => 'This is a test summary',
          'NAME' => 'Test Case 1',
          'EXPECTED' => 'Some output',
          'INSTRUCTIONS' => [
                              'fixture1',
                              {
                                'fixture2' => 'foo'
                              },
                              {
                                'fixture3' => {
                                                'bar' => 'baz'
                                              }
                              },
                              {
                                'fixture4' => [
                                                'boo',
                                                'bork'
                                              ]
                              }
                            ],
          'TAGS' => [ 'tag1', 'tag2' ]
        },
        q{First testcase data looks good}
    );
    is_deeply(
        $file->cases->[1]->data,
        {
          'SUMMARY' => 'This is a test summary',
          'ID' => 'custom_id',
          'NAME' => 'Test Case 2',
          'EXPECTED' => 'Some output',
          'INSTRUCTIONS' => [
                              'fixture1',
                              { 'fixture2' => 'foo' },
                              { 'fixture3' => { 'bar' => 'baz' } },
                              { 'fixture4' => [ 'boo', 'bork' ] }
                            ],
          'TAGS' => [ 'tag1' ]
        },
        q{Second testcase data looks good}
    );
    is_deeply(
        $file->cases->[2]->data,
        {
          'ID' => 'some_other_id',
          'SUMMARY' => 'This is a test summary',
          'NAME' => 'Test Case 3',
          'EXPECTED' => 'Some output',
          'INSTRUCTIONS' => [
                              'fixture1',
                              { 'fixture2' => 'foo' },
                              { 'fixture3' => { 'bar' => 'baz' } },
                              { 'fixture4' => [ 'boo', 'bork' ] }
                            ],
          'TAGS' => [ 'tag3' ]
        },
        q{First testcase data looks good}
    );

    $a8n->run_tests();
    is(scalar(@{ $Test::FITesque::Suite::ADDED_TESTS }), 3, q{Run tests returns 3 outputs});
}

Testcase_ID: {
    $Test::FITesque::Suite::ADDED_TESTS = [];
    my $a8n = Test::A8N->new({
        config   => {
            filenames    => ['t/testdata/cases/test_multiple.st'],
            file_root    => 't/testdata/cases',
            fixture_base => 'Fixture',
            testcase_id  => 'custom_id',
        }
    });
    $a8n->run_tests();
    is(scalar(@{ $Test::FITesque::Suite::ADDED_TESTS }), 1, q{run_tests only runs 1 test with a custom ID});
}

Tags: {
    my $a8n;

    my @tag_tests = (
        { tests => 3, include => [qw()],                exclude => [qw()] },
        { tests => 2, include => [qw( tag1 )],          exclude => [qw()] },
        { tests => 1, include => [qw( tag1 )],          exclude => [qw( tag2 )] },
        { tests => 1, include => [qw( tag2 )],          exclude => [qw()] },
        { tests => 0, include => [qw( tag2 )],          exclude => [qw( tag1 )] },
        { tests => 1, include => [qw( tag3 )],          exclude => [qw()] },
        { tests => 1, include => [qw( tag3 )],          exclude => [qw( tag1 )] },
        { tests => 1, include => [qw( tag3 )],          exclude => [qw( tag1 tag2 )] },
        { tests => 0, include => [qw( foo )],           exclude => [qw()] },
        { tests => 0, include => [qw( foo bar )],       exclude => [qw()] },
        { tests => 0, include => [qw( tag1 foo )],      exclude => [qw()] },
        { tests => 0, include => [qw( tag2 foo )],      exclude => [qw()] },
        { tests => 0, include => [qw( tag2 foo )],      exclude => [qw()] },
        { tests => 1, include => [qw( tag1 tag2 )],     exclude => [qw()] },
        { tests => 1, include => [qw( tag1 tag2 )],     exclude => [qw( tag3 )] },
        { tests => 1, include => [qw( tag1 tag2 )],     exclude => [qw()] },
        { tests => 0, include => [qw( tag1 tag2 tag3)], exclude => [qw()] },
        { tests => 1, include => [qw( )],               exclude => [qw( tag1 tag2 )] },
        { tests => 0, include => [qw( )],               exclude => [qw( tag1 tag3 )] },
        { tests => 1, include => [qw( )],               exclude => [qw( tag2 tag3 )] },
        { tests => 3, include => [qw( )],               exclude => [qw( foo )] },
    );
    foreach my $tag_test (@tag_tests) {
        $Test::FITesque::Suite::ADDED_TESTS = [];
        $a8n = Test::A8N->new({
            config   => {
                filenames    => ['t/testdata/cases/test_multiple.st'],
                file_root    => 't/testdata/cases',
                fixture_base => 'Fixture',
                tags         => {
                    include => $tag_test->{include},
                    exclude => $tag_test->{exclude},
                },
            }
        });
        $a8n->run_tests();
        is(
            scalar(@{ $Test::FITesque::Suite::ADDED_TESTS }),
            $tag_test->{tests},
            sprintf(
                q{run_tests runs %d tests with tags "%s" and without "%s"},
                $tag_test->{tests},
                join('", "', @{ $tag_test->{include} }),
                join('", "', @{ $tag_test->{exclude} })
            )
        );
    }
}

Invalid_syntax: {
    my $obj;
    lives_ok {
        $obj = Test::A8N->new({
            config => {
                filenames    => [qw( t/testdata/cases/invalid_syntax.tc )],
                fixture_base => 'MockFixture',
                file_root    => 't/testdata/cases',
                allowed_extensions => ["tc","st"],
            }
        });
    } "Creating a Test::A8N object with an invalid testcase doesn't die";
    isa_ok($obj, 'Test::A8N', q{object constructed}) ;
}

