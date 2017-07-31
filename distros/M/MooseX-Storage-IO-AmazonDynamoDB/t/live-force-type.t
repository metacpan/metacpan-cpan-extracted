use strict;
use warnings;

use Test::DescribeMe qw(author);
use Test::Fatal;
use Test::More;
use Test::Warnings;

use UUID::Tiny ':std';

#
# This runs a basic set of tests, running against a real DynamoDB server.
# BE AWARE THIS WILL COST YOU MONEY EVERY TIME IT RUNS.
# You'll need to create a DynamoDB table with one partition key of 'doc_id',
# that's a string, and put its name in the TEST_DYNAMODB_TABLE envar.
#

my $table_name = $ENV{TEST_DYNAMODB_TABLE}
    || die "please set TEST_DYNAMODB_TABLE";

{
    package MyDocNoForceType;
    use Moose;
    use MooseX::Storage;

    with Storage(io => [ 'AmazonDynamoDB' => {
        table_name => $table_name,
        key_attr   => 'doc_id',
    }]);

    has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
    has 'title'   => (is => 'rw', isa => 'Str');
}

{
    package MyDocWithForceType;
    use Moose;
    use MooseX::Storage;

    with Storage(io => [ 'AmazonDynamoDB' => {
        table_name => $table_name,
        key_attr   => 'doc_id',
        force_type => {
            doc_id => 'S',
        },
    }]);

    has 'doc_id'  => (is => 'ro', isa => 'Str', required => 1);
    has 'title'   => (is => 'rw', isa => 'Str');
}

my $doc_id = int(rand(1_000_000));

like(
    exception {
        my $doc = MyDocNoForceType->new(
            doc_id   => $doc_id,
            title    => 'Foo',
        );
        $doc->store();
    },
    qr/Type mismatch for key doc_id/,
    'exception thrown trying to store a number to a string attr w/o force_type',
);

is(
    exception {
        my $doc = MyDocWithForceType->new(
            doc_id   => $doc_id,
            title    => 'Foo',
        );
        $doc->store();
    },
    undef,
    'OK to store a number to a string attr when force_type specified',
);

like(
    exception {
        my $doc = MyDocNoForceType->load($doc_id);
    },
    qr/The provided key element does not match the schema/,
    'exception thrown trying to use a number as a key for load w/o force_type',
);

is(
    exception {
        my $doc = MyDocWithForceType->load($doc_id);
    },
    undef,
    'OK to use a number as a key for load when force_type specified',
);

done_testing;
