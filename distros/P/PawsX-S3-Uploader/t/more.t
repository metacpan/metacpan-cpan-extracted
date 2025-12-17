use Test2::V0;
use lib 't/lib';
use TestingPaws;
use builtin::compat 0.003003 qw(true false);
use PawsX::S3::Uploader;

subtest 'always multipart' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my @events;
    my $uploader = PawsX::S3::Uploader->new(
        s3              => $s3,
        bucket          => 'testbucket',
        key             => 'testkey',
        callback        => sub { push @events, [@_] },
        always_multipart => true,
    );

    $uploader->add('thing');
    $uploader->finish();

    is \@events, [
        [ add                => { size => 5 } ],
        [ start_multipart    => { upload_id => 'testing' } ],
        [ upload_part        => { size => 5, part_number => 1 } ],
        [ complete_multipart => { } ],
        [ finish             => { output => object { call Location => 'foo' } } ],
    ], 'always_multipart should do what it says';
};

subtest 'failures' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();
    $mock_object->override(
        UploadPart => sub { die "boom" },
    );

    my @events;
    my $uploader = PawsX::S3::Uploader->new(
        s3              => $s3,
        bucket          => 'testbucket',
        key             => 'testkey',
        callback        => sub { push @events, [@_] },
        always_multipart => true,
    );

    $uploader->add('thing');

    like(
        dies { $uploader->finish() },
        qr{boom},
        'exceptions should be propagated',
    );

    is \@events, [
        [ add             => { size => 5 } ],
        [ start_multipart => { upload_id => 'testing' } ],
        [ abort_multipart => { size => 5, part_number => 1 } ],
    ], 'always_multipart should do what it says';
};

subtest 'without callback' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $uploader = PawsX::S3::Uploader->new(
        s3     => $s3,
        bucket => 'testbucket',
        key    => 'testkey',
    );

    $uploader->add('thing');
    $uploader->finish();

    is $uploader->output(),
        object { call ETag => 'aaa' },
        'upload should work without a callback';
};

subtest 'empty body, no multipart' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $uploader = PawsX::S3::Uploader->new(
        s3     => $s3,
        bucket => 'testbucket',
        key    => 'testkey',
    );

    $uploader->add('');
    $uploader->finish();

    like $mock_object->call_tracking, array {
        item {
            sub_name => 'PutObject',
            args => [
                D(),
                object { call Body => '' },
            ],
        };
        end;
    }, 'should still call PutObject';
};

subtest 'empty body, multipart' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $uploader = PawsX::S3::Uploader->new(
        s3               => $s3,
        bucket           => 'testbucket',
        key              => 'testkey',
        always_multipart => true,
    );

    $uploader->add('');
    $uploader->finish();

    like $mock_object->call_tracking, array {
        item { sub_name => 'CreateMultipartUpload' };
        item {
            sub_name => 'UploadPart',
            args => [
                D(),
                object { call Body => '' },
            ],
        };
        item { sub_name => 'CompleteMultipartUpload' };
        end;
    }, 'should do a multpart upload';
};

subtest 're-using is fatal' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $uploader = PawsX::S3::Uploader->new(
        s3     => $s3,
        bucket => 'testbucket',
        key    => 'testkey',
    );

    $uploader->add('something');
    $uploader->finish();

    like dies { $uploader->add('...') }, qr{already completed},
        'adding after finish should throw';
    like dies { $uploader->finish }, qr{already completed},
        'finish after finish should throw';
    like dies { $uploader->abort }, qr{already completed},
        'abort after finish should throw';
};

subtest 'manual abort, no multipart' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $uploader = PawsX::S3::Uploader->new(
        s3               => $s3,
        bucket           => 'testbucket',
        key              => 'testkey',
    );

    $uploader->add('something');
    $uploader->abort();

    # PutObject would be called by ->finish, but we ->abort, so
    # nothing actually happens
    like $mock_object->call_tracking, array {
        end;
    }, 'should not do anything';

    like dies { $uploader->finish }, qr{aborted},
        'finish after abort should throw';
    like dies { $uploader->add('...') }, qr{aborted},
        'adding after abort should throw';
    like dies { $uploader->abort }, undef,
        'abort after abort should do nothing';
};

subtest 'manual abort, multipart' => sub {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my $uploader = PawsX::S3::Uploader->new(
        s3               => $s3,
        bucket           => 'testbucket',
        key              => 'testkey',
        always_multipart => true,
        _under_testing  => true,
        min_part_size   => 5,
    );

    $uploader->add('something');
    $uploader->abort();

    like $mock_object->call_tracking, array {
        item { sub_name => 'CreateMultipartUpload' };
        item { sub_name => 'UploadPart' };
        item { sub_name => 'AbortMultipartUpload' };
        end;
    }, 'should abort';

    like dies { $uploader->finish }, qr{aborted},
        'finish after abort should throw';
    like dies { $uploader->add('...') }, qr{aborted},
        'adding after abort should throw';
    like dies { $uploader->abort }, undef,
        'abort after abort should do nothing';
};

done_testing;
