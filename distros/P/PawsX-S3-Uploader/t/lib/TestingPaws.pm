package TestingPaws;
use Test2::V0;
use Paws;
use Paws::Credential::Explicit;
use Paws::Net::MultiplexCaller;
use PawsX::FakeImplementation::Instance;

sub build_test_paws {
    my $etag='aaa';
    my $fake_s3 = mock {} => (
        track => 1,
        add => [
            CreateMultipartUpload   => sub { return { UploadId => 'testing' } },
            UploadPart              => sub { return { ETag => $etag++ } },
            AbortMultipartUpload    => sub { return {} },
            CompleteMultipartUpload => sub { return { Location => 'foo' } },
            PutObject               => sub { return { ETag => $etag++ } },
        ],
    );

    my $paws = Paws->new(
        config => {
            credentials => Paws::Credential::Explicit->new(
                access_key => 'a',
                secret_key => 'b',
            ),
            caller => Paws::Net::MultiplexCaller->new(
                caller_for => {
                    S3 => PawsX::FakeImplementation::Instance->new(
                        api_class => 'mocked',
                        instance => $fake_s3,
                    ),
                }
            ),
        },
    );

    local $ENV{PAWS_SILENCE_UNSTABLE_WARNINGS}=1;
    my $s3 = $paws->service(S3 => ( region => 'eu-west-1' ));
    my ($mock_object) = mocked($fake_s3);

    return ($s3, $mock_object);
}

1;
