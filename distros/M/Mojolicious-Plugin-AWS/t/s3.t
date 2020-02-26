#!perl
use Mojo::Base -strict;
use Test::More;
use Mojolicious::Lite;
use Test::Mojo;

## s3 object lifecycle tests
## FIXME: put v1, put v2, get v2, delete v2, get v1, delete v1, get (no version) == 404
if (   $ENV{AWS_REGION}
    && $ENV{AWS_S3_BUCKET}
    && $ENV{AWS_S3_OBJECT}
    && $ENV{AWS_ACCESS_KEY}
    && $ENV{AWS_SECRET_KEY})
{

    plugin 'Mojolicious::Plugin::AWS' => {
        region     => $ENV{AWS_REGION},
        access_key => $ENV{AWS_ACCESS_KEY},
        secret_key => $ENV{AWS_SECRET_KEY},
    };

    my $t = Test::Mojo->new;

    my $s3_bucket = $ENV{AWS_S3_BUCKET};
    my $s3_object = $ENV{AWS_S3_OBJECT};

    my $obj_version = '';
    my $obj_etag    = '';
    $t->app->s3_put_object(
        bucket         => $s3_bucket,
        object         => $s3_object,
        signed_headers => {'Content-Type' => 'application/json; charset=utf-8'},
        payload =>
          [json => {root => {widget_label => 'socks'}, other => {damage_control => 'off'}}]
    )->then(
        sub {
            my $tx = shift;
            ok $tx->res->headers->header('x-amz-request-id'), 'request id header'
              or diag explain $tx->res->headers;

            $obj_etag = $tx->res->headers->etag;
            is $obj_etag, '"40c382963cf66a205d49b258fc2c2f06"', 'ETag header'
              or diag explain $tx->res->headers->etag;

            $obj_version = $tx->res->headers->header('x-amz-version-id');
            ok $obj_version, 'object version';
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred" or diag "Error: $err";
            ok 0;
            ok 0;
        }
    )->wait;

    $t->app->s3_get_object(bucket => $s3_bucket, object => $s3_object,)->then(
        sub {
            my $tx = shift;
            ok $tx->res->headers->header('x-amz-request-id'), 'request id header'
              or diag explain $tx->res->headers;

            is $tx->res->headers->etag, $obj_etag, 'ETag match';
            is $tx->res->json('/root/widget_label'), 'socks', 'content match';
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred" or diag "Error: $err";
            ok 0;
            ok 0;
        }
    )->wait;

    $t->app->s3_get_object_acl(bucket => $s3_bucket, object => $s3_object,)->then(
        sub {
            my $tx = shift;
            ok $tx->res->headers->header('x-amz-version-id'), 'response has version id header'
              or diag explain $tx->res->headers;
            ok $tx->res->dom->at('AccessControlPolicy > Owner > ID')->text, 'ID element found'
              or diag $tx->res->dom->to_string;
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred" or diag "Error: $err";
            ok 0;
        }
    )->wait;

    $t->app->s3_delete_object(
        bucket => $s3_bucket,
        object => $s3_object,
        query  => {VersionId => $obj_version},
    )->then(
        sub {
            my $tx = shift;
            ok $tx->res->headers->header('x-amz-version-id'), 'version id header'
              or diag explain $tx->res->headers;
            is $tx->res->headers->header('x-amz-delete-marker'), 'true', 'amz delete marker';
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred" or diag "Error: $err";
            ok 0;
        }
    )->wait;

    $t->app->s3_get_object(bucket => $s3_bucket, object => $s3_object,)->then(
        sub {
            my $tx = shift;
            ok $tx->res->headers->header('x-amz-request-id'), 'request id header'
              or diag explain $tx->res->headers;
            is $tx->res->code, '404', 'object not found';
            is $tx->res->headers->header('X-amz-delete-marker'), 'true', 'delete marker';
        }
    )->catch(
        sub {
            my $err = shift;
            ok !$err, "an error occurred" or diag "Error: $err";
            ok 0;
            ok 0;
        }
    )->wait;
}

done_testing();

__END__
<?xml version="1.0" encoding="UTF-8"?>
<AccessControlPolicy xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Owner>
    <ID>7f236a77ac8ce9b0448a1d3520e6d5365a4cf777eff5f6dce329c3da8d6d6bef</ID>
  </Owner>
  <AccessControlList>
    <Grant>
      <Grantee xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:type="CanonicalUser">
        <ID>7f236a77ac8ce9b0448a1d3520e6d5365a4cf777eff5f6dce329c3da8d6d6bef</ID>
      </Grantee>
      <Permission>FULL_CONTROL</Permission>
    </Grant>
  </AccessControlList>
</AccessControlPolicy>
