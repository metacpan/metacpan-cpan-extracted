use strict;
use warnings;

use String::Random qw/random_string/;
use Test::Most;
use Test::Mojo;
use Mojolicious::Quick;

subtest 'Any verb' => sub {
    my $app = Mojolicious::Quick->new(
        [   '/thing'       => { 'text' => 'You did a thing!' },
            '/other/thing' => { 'json' => { 'response' => 'You did a thing!' } }
        ]
    );

    my $t = Test::Mojo->new($app);
    $t->get_ok('/thing')->status_is(200)->content_is('You did a thing!');
    $t->get_ok('/other/thing')->status_is(200)->json_is( { 'response' => 'You did a thing!' } );
};

subtest 'Specific verbs' => sub {
    my $app = Mojolicious::Quick->new(
        [   'GET' => [
                '/thing'       => { 'text' => 'You got a thing!' },
                '/other/thing' => { 'json' => { response => 'You got a thing!' } },
            ],
            'POST' => [
                '/thing'       => { 'text' => 'You posted a thing!' },
                '/other/thing' => { 'json' => { response => 'You posted a thing!' } },
            ],
            'PUT' => [
                '/thing'       => { 'text' => 'You did put a thing!' },
                '/other/thing' => { 'json' => { response => 'You did put a thing!' } },
            ],
            'DELETE' => [
                '/thing'       => { 'text' => 'You deleted a thing!' },
                '/other/thing' => { 'json' => { response => 'You deleted a thing!' } },
            ],
            'OPTIONS' => [
                '/thing'       => { 'text' => 'You optioned or something a thing!' },
                '/other/thing' => { 'json' => { response => 'You optioned or something a thing!' } },
            ],
            'PATCH' => [
                '/thing'       => { 'text' => 'You patched a thing!' },
                '/other/thing' => { 'json' => { response => 'You patched a thing!' } },
            ],
        ],
    );
    my $t = Test::Mojo->new($app);
    for my $verb (qw/get post put patch delete options/) {
        my $past_tense =
              $verb eq 'get'     ? 'got'
            : $verb eq 'put'     ? 'did put'
            : $verb eq 'delete'  ? 'deleted'
            : $verb eq 'options' ? 'optioned or something'
            :                      qq{${verb}ed};
        my $method = qq{${verb}_ok};
        $t->$method('/thing')->status_is(200)->content_is(qq{You $past_tense a thing!});
        $t->$method('/other/thing')->status_is(200)->json_is( { 'response' => qq{You $past_tense a thing!} } );
    }
        
};
done_testing;
