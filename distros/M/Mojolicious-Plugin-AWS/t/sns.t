#!perl
use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;
use Mojo::JSON 'encode_json';

## The AWS user identified here with access/secret keys must have
## AmazonSNSFullAccess to publish. I created a group with that permission, and
## then added a user to the group
if ($ENV{AWS_REGION} && $ENV{AWS_SNS_TOPIC_ARN} && $ENV{AWS_ACCESS_KEY} && $ENV{AWS_SECRET_KEY})
{
    plugin 'Mojolicious::Plugin::AWS' => {
        region     => $ENV{AWS_REGION},
        access_key => $ENV{AWS_ACCESS_KEY},
        secret_key => $ENV{AWS_SECRET_KEY},
    };

    my $t = Test::Mojo->new;

    my $topic = $ENV{AWS_SNS_TOPIC_ARN};
    $t->app->sns_publish(
        topic   => $topic,
        subject => 'Automatic Message',
        message => {
            default => 'default message',
            https   => encode_json({message => 'this is lamer than flour'})
        }
    )->then(
        sub {
            my $tx = shift;
            ok $tx->res->json('/PublishResponse/PublishResult/MessageId'),
              'response has message id'
              or diag explain $tx->res->json;
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred" or diag "Error: $err";
        }
    )->wait;
}

done_testing();
