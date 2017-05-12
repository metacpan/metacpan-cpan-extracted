use strict;
use warnings;

use Test::More tests => 3;
use Mock::Quick;
use Test::Exception;
use Test::Deep;

my $mock_memory = qclass(
    -implement => 'Net::AmazonS3::Simple::Object::Memory',
    create_from_response => sub {
        my ($class, %options) = @_;

        is_deeply(
            \%options,
            {validate => 1, response => qobj()},
            "$class->create_from_response parameters"
        );

        return bless {}, $class;
    }
);

my $mock_file = qclass(
    -implement => 'Net::AmazonS3::Simple::Object::File',
    create_from_response => sub {
        my ($class, %options) = @_;

        cmp_deeply(
            \%options,
            {validate => 1, response => obj_isa('Mock::Quick::Object'), file_path => re(qr/.+/)},
            "$class->create_from_response parameters"
        );

        return bless {}, $class;
    }
);

use_ok('Net::AmazonS3::Simple');

my $s3 = Net::AmazonS3::Simple->new(
    aws_access_key_id     => 'aws_access_key_id',
    aws_secret_access_key => 'aws_secret_access_key',
);

my $mock_s3_http = qtakeover 'Net::AmazonS3::Simple::HTTP' => (
    request => sub {
        return qobj();
    }
);

subtest 'get_object' => sub {
    isa_ok(
        $s3->get_object('test-bucket', 'test-key'),
        'Net::AmazonS3::Simple::Object::Memory',
        'get_object return Memory'
    );

    done_testing(2);
};

subtest 'save_object_to_file' => sub {
    isa_ok(
        $s3->save_object_to_file('test-bucket', 'test-key'),
        'Net::AmazonS3::Simple::Object::File',
        'get_object return File'
    );

    done_testing(2);
};
