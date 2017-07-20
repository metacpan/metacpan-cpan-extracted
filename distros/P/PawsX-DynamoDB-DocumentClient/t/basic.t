use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Paws;

BEGIN { use_ok('PawsX::DynamoDB::DocumentClient'); }

$ENV{AWS_ACCESS_KEY_ID} = 'AAAAAAAAAAAA';
$ENV{AWS_SECRET_ACCESS_KEY} = 'XXXXXXXXXXXXXXXXXXXX';

is(
    exception {
        my $dynamodb = PawsX::DynamoDB::DocumentClient->new(
            region => 'us-east-1',
        );
    },
    undef,
    'constructor lives if region specified',
);

{
    local $ENV{AWS_DEFAULT_REGION} = 'us-east-1';
    is(
        exception {
            my $dynamodb = PawsX::DynamoDB::DocumentClient->new();
        },
        undef,
        'constructor lives if region specified in envar',
    );
}

{
    local $ENV{AWS_DEFAULT_REGION} = undef;
    my $paws = Paws->new(config => { region => 'us-east-1' });
    is(
        exception {
            my $dynamodb = PawsX::DynamoDB::DocumentClient->new(
                paws => $paws,
            );
        },
        undef,
        'constructor lives if given Paws object with region',
    );
}

{
    local $ENV{AWS_DEFAULT_REGION} = undef;
    my $paws = Paws->new(config => { region => 'us-east-1' });
    my $service = $paws->service('DynamoDB');
    is(
        exception {
            my $dynamodb = PawsX::DynamoDB::DocumentClient->new(
                dynamodb => $service,
            );
        },
        undef,
        'constructor lives if given Paws::DynamoDB object',
    );
}

{
    local $ENV{AWS_DEFAULT_REGION} = undef;
    like(
        exception {
            my $dynamodb = PawsX::DynamoDB::DocumentClient->new();
        },
        qr/unable to determine region/,
        'error thrown if no region or dynamodb object specified',
    );
}

done_testing;
