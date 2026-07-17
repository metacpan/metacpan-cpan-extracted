use strict;
use warnings;
use Test2::V0;
use Future::AsyncAwait;
use PAGI::Request;
use PAGI::Response;
use PAGI::Test::Client;
use PAGI::StructuredParameters;

# The adapters bind the engine to a real PAGI::Request. Because reading a request
# body is asynchronous in PAGI, the terminal permitted/required are async:
#   my $clean = await $c->params->permitted(...)
# These tests drive a real app through PAGI::Test::Client so the body is parsed
# by the genuine request plumbing, not a mock.

# Build a one-route app that runs $build->($req) and returns its result as JSON.
sub app_that {
    my ($build) = @_;
    return async sub {
        my ($scope, $receive, $send) = @_;
        my $req    = PAGI::Request->new($scope, $receive);
        my $result = await $build->($req);
        await PAGI::Response->json($result)->respond($send);
    };
}

subtest 'from_body parses form-encoded body and reconstructs structure' => sub {
    my $client = PAGI::Test::Client->new(app => app_that(async sub {
        my ($req) = @_;
        return await PAGI::StructuredParameters->from_body($req)
            ->permitted('username', name => ['first', 'last'], +{ email => [] });
    }));

    my $res = $client->post('/', form => {
        username     => 'jnap',
        'name.first' => 'John',
        'name.last'  => 'Napiorkowski',
        'email[0]'   => 'a@example.com',
        'email[1]'   => 'b@example.com',
        secret       => 'drop me',
    });

    is $res->status, 200, 'request handled';
    is $res->json, {
        username => 'jnap',
        name     => { first => 'John', last => 'Napiorkowski' },
        email    => ['a@example.com', 'b@example.com'],
    }, 'body whitelisted and reconstructed';
};

subtest 'from_data parses a JSON body and keeps arrays as-is' => sub {
    my $client = PAGI::Test::Client->new(app => app_that(async sub {
        my ($req) = @_;
        return await PAGI::StructuredParameters->from_data($req)
            ->permitted('title', +{ tags => [] });
    }));

    my $res = $client->post('/', json => {
        title => 'Hello',
        tags  => ['perl', 'pagi'],
        secret => 'drop',
    });

    is $res->json, { title => 'Hello', tags => ['perl', 'pagi'] },
        'JSON body whitelisted, array untouched';
};

subtest 'from_query parses the query string' => sub {
    my $client = PAGI::Test::Client->new(app => app_that(async sub {
        my ($req) = @_;
        return await PAGI::StructuredParameters->from_query($req)
            ->permitted('q', 'page');
    }));

    my $res = $client->get('/', query => { q => 'perl', page => '2', junk => 'x' });
    is $res->json, { q => 'perl', page => '2' }, 'query whitelisted';
};

subtest 'required failure path: callback return value is thrown and sent' => sub {
    my $client = PAGI::Test::Client->new(app => async sub {
        my ($scope, $receive, $send) = @_;
        my $req = PAGI::Request->new($scope, $receive);
        my $clean = eval {
            await PAGI::StructuredParameters->from_body($req)->required(
                'title',
                sub {
                    my ($ctx, $missing) = @_;
                    return PAGI::Response->json(
                        { error => 'missing', fields => $missing }, status => 400,
                    );
                },
            );
        };
        # Nano's dispatch does this catch; here we emulate it inline.
        if (my $thrown = $@) {
            await $thrown->respond($send) if ref($thrown) && $thrown->can('respond');
            return;
        }
        await PAGI::Response->json($clean)->respond($send);
    });

    my $res = $client->post('/', form => { not_title => 'x' });
    is $res->status, 400, 'missing required -> thrown 400 response sent';
    is $res->json, { error => 'missing', fields => ['title'] }, 'callback shaped the body';
};

done_testing;
