use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::More;
use Test::Deep;
use Test::Warnings;

use UUID::Tiny ':std';

=head1 SETUP

This test runs against a local dynamodb running at http://dynamodb:8000, which conforms to the dynamodb service in docker-compose.yml, so make sure you've done:

  docker-compose up -d dynamodb

You'll need to create a DynamoDB table named 'tmp_dynamodb_local_test' with one partition key of 'doc_id', using fake creds:

  (
      export AWS_ACCESS_KEY_ID=XXXXXXXXX
      export AWS_SECRET_ACCESS_KEY=YYYYYYYYY
      aws dynamodb create-table \
        --table-name tmp_dynamodb_local_test \
        --key-schema "AttributeName=doc_id,KeyType=HASH" \
        --attribute-definitions "AttributeName=doc_id,AttributeType=S" \
        --provisioned-throughput "ReadCapacityUnits=2,WriteCapacityUnits=2" \
        --endpoint-url 'http://localhost:8100'
  )

Finally, run via:

  docker-compose run development prove -l t/local.t

=cut

# These need to match setup instructions above
my $access_key = 'XXXXXXXXX';
my $secret_key = 'YYYYYYYYY';
my $table_name = 'tmp_dynamodb_local_test';

{
    package MyDoc;
    use Moose;
    use MooseX::Storage;
    use Paws;
    use Paws::Credential::Explicit;
    use PawsX::DynamoDB::DocumentClient;

    with Storage(io => [ 'AmazonDynamoDB' => {
        table_name              => $table_name,
        key_attr                => 'doc_id',
        document_client_builder => \&_build_document_client,
    }]);

    sub _build_document_client {
        my $dynamodb = Paws->service(
            'DynamoDB',
            region       => 'us-east-1',
            region_rules => [ { uri => 'http://dynamodb:8000'} ],
            credentials  => Paws::Credential::Explicit->new(
                access_key => $access_key,
                secret_key => $secret_key,
            ),
            max_attempts => 2,
        );
        return PawsX::DynamoDB::DocumentClient->new(dynamodb => $dynamodb);
    }

    has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
    has 'title'   => (is => 'rw', isa => 'Str');
}

my $doc_id = create_uuid_as_string();

my $doc = MyDoc->new(
    doc_id   => $doc_id,
    title    => 'Testing DyanmoDB Local',
);

$doc->store();

my $doc2 = MyDoc->load($doc_id);

cmp_deeply(
    $doc2,
    all(
        isa('MyDoc'),
        methods(
            doc_id   => $doc_id,
            title    => 'Testing DyanmoDB Local',
        ),
    ),
    'retrieved document looks good',
);

done_testing;
