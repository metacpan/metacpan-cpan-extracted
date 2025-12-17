use Test2::V0;
use lib 't/lib';
use TestingPaws;
use builtin::compat 0.003003 qw(true false);
use PawsX::S3::Uploader;

sub build_test_uploader {
    my ($s3, $mock_object) = TestingPaws::build_test_paws();

    my @events;
    my $uploader = PawsX::S3::Uploader->new(
        s3              => $s3,
        bucket          => 'testbucket',
        key             => 'testkey',
        callback        => sub { push @events, [@_] },
        extra_arguments => { ServerSideEncryption => 'aws:kms' },
        _under_testing  => true,
        min_part_size   => 100,
    );

    return ($uploader, $mock_object, \@events);
}

subtest 'small object' => sub {
    my ($uploader, $s3_mock, $events) = build_test_uploader();

    $uploader->add('some small amount of data');
    my $output = $uploader->finish;

    like $s3_mock->call_tracking, array {
        item {
            sub_name => 'PutObject',
            args => [
                D(),
                object {
                    call Bucket               => 'testbucket';
                    call Key                  => 'testkey';
                    call ServerSideEncryption => 'aws:kms';
                    call Body                 => 'some small amount of data';
                },
            ],
        };
        end;
    }, 'should only call PutObject';
    is $events, [
        [ add        => { size => 25 } ],
        [ put_object => { size => 25 } ],
        [ finish     => { output => $output } ],
    ], 'should tell us the same thing via the callback';

    is $output, $uploader->output,
        'output should be returned';
    is $output, object {
        prop blessed => 'Paws::S3::PutObjectOutput';
        call ETag => 'aaa';
    }, 'output should be from PutObject';
};

subtest 'large object' => sub {
    my ($uploader, $s3_mock, $events) = build_test_uploader();

    $uploader->add('a' x 95) for 0..10;
    my $output = $uploader->finish;

    like $s3_mock->call_tracking, array {
        item {
            sub_name => 'CreateMultipartUpload',
            args => [
                D(),
                object {
                    call Bucket               => 'testbucket';
                    call Key                  => 'testkey';
                    call ServerSideEncryption => 'aws:kms';
                },
            ],
        };

        item {
            sub_name => 'UploadPart',
            args => [
                D(),
                object {
                    call Bucket     => 'testbucket';
                    call Key        => 'testkey';
                    call PartNumber => $_;
                    call UploadId   => 'testing';
                    call Body       => match(qr{^a{190}$});
                },
            ],
        } for 1..5;

        item {
            sub_name => 'UploadPart',
            args => [
                D(),
                object {
                    call Bucket     => 'testbucket';
                    call Key        => 'testkey';
                    call PartNumber => 6;
                    call UploadId   => 'testing';
                    call Body       => match(qr{^a{95}$});
                },
            ],
        };

        my $expected_etag='aaa';
        item {
            sub_name => 'CompleteMultipartUpload',
            args => [
                D(),
                object {
                    call Bucket          => 'testbucket';
                    call Key             => 'testkey';
                    call MultipartUpload => object {
                        call Parts => array {
                            item object {
                                call PartNumber => $_;
                                call ETag       => $expected_etag++;
                            } for 1..6;
                        };
                    };
                },
            ],
        };

        end;
    }, 'should do a multipart';

    is $events, [
        [ add             => { size => 95 } ],
        [ add             => { size => 95 } ],
        [ start_multipart => { upload_id => 'testing' } ],
        [ upload_part     => { size => 190, part_number => 1 } ],

        (map { (
            [ add         => { size => 95 } ],
            [ add         => { size => 95 } ],
            [ upload_part => { size => 190, part_number => $_ } ],
        ) } 2..5),

        [ add         => { size => 95 } ],
        [ upload_part => { size => 95, part_number => 6 } ],

        [ complete_multipart => { } ],

        [ finish => { output => $output } ],
    ], 'should tell us the same thing via the callback';

    is $output, $uploader->output,
        'output should be returned';
    is $output, object {
        prop blessed => 'Paws::S3::CompleteMultipartUploadOutput';
        call Location => 'foo';
    }, 'output should be from PutObject';
};

done_testing;
