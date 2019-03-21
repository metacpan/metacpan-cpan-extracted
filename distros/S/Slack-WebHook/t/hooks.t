#!/usr/bin/env perl

use strict;
use warnings;

use Test2::Bundle::Extended;
use Test2::Tools::Explain;
use Test2::Plugin::NoWarnings;

use Test::MockModule ();

use Slack::WebHook ();

our $last_http_post_form;

my $mock_http = Test::MockModule->new('HTTP::Tiny');
$mock_http->redefine(
    post_form => sub {
        my ( $self, @args ) = @_;
        note "calling HTTP::Tiny post_form mocked method";
        $last_http_post_form = \@args;
    }
);

like(
    dies { Slack::WebHook->new()->post("no URL...") },
    qr/\QMissing URL, please set it using Slack::WebHook->new( url => ... )\E/,
    "Dies when missing URL"
);

ok !$last_http_post_form, "post_form was not called";

my $URL = 'http://127.0.0.1';
my $hook = Slack::WebHook->new( url => $URL );

$hook->post('a raw message');
http_post_was_called_with( { text => 'a raw message' }, 'a raw message using post' );

$hook->post( { text => 'my custom message', custom => 'field' } );
http_post_was_called_with( 
{
  'custom' => 'field',
  'text' => 'my custom message'
}
, 'a custom hash using post' );

{
    note "post_ok";

    $hook->post_ok('posting a simple "ok" text');
    http_post_was_called_with(
        {   'attachments' => [
                {   'color'     => Slack::WebHook::SLACK_COLOR_OK,
                    'mrkdwn_in' => [
                        'text',
                        'title'
                    ],
                    'text' => 'posting a simple "ok" text'
                }
            ]
        },
        'post_ok( msg )'
    );

    $hook->post_ok(
        title => 'My Title',
        body  => qq[This is a message\nwith another line]
    );
    http_post_was_called_with(
        {   'attachments' => [
                {   'color'     => Slack::WebHook::SLACK_COLOR_OK,
                    'mrkdwn_in' => [
                        'text',
                        'title'
                    ],
                    'text'  => "This is a message\nwith another line",
                    'title' => 'My Title'
                }
            ]
        },
        'post_ok( @list )'
    );

}

{
    note "post_warning";

    $hook->post_warning('posting a simple "warning" text');
    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#f5ca46',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 'posting a simple "warning" text'
            }
          ]
        },
        'post_warning( txt )'
    );

    $hook->post_warning(
        title => ':warning: Warning Title',
        text  => 'this is the _warning_ message'
    );

    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#f5ca46',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 'this is the _warning_ message',
              'title' => ':warning: Warning Title'
            }
          ]
        },
        'post_warning( @list )'
    );

}

{
    note "post_error";

    $hook->post_error('posting a simple *"error"* message');
    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#cc0000',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 'posting a simple *"error"* message'
            }
          ]
        },
        'post_error( txt )'
    );

    $hook->post_error(
        title => ':criticalfail: Error Title',
        text  => 'this is the _error_ message'
    );

    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#cc0000',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 'this is the _error_ message',
              'title' => ':criticalfail: Error Title'
            }
          ]
        },
        'post_error( @list )'
    );


}

{
    note "start / stop";

    $hook->post_start('starting some task');

    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#2b3bd9',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 'starting some task'
            }
          ]
        },
        'post_start( txt )'
    );
    
    $hook->_started_at( time() - ( 1 * 3600 + 12 * 60 + 45 ) );
    $hook->post_end('task is now finished');

    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#2eb886',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 
              "task is now finished\n"
              . "_run time: 1 hour 12 minutes 45 seconds_"
            }
          ]
        },
        'post_end( txt ) - 1 hour 12 minutes 45 seconds'
    );

    # ----

    $hook->post_start( title => "Starting Task 42", text => "description..." );

    http_post_was_called_with(
        {   
          'attachments' => [
            {
              'color' => '#2b3bd9',
              'mrkdwn_in' => [
                'text',
                'title'
              ],
              'text' => 'description...',
              'title' => 'Starting Task 42'
            }
          ]
        },
        'post_start( @list )'
    );

    $hook->_started_at( time() - 18 );
    $hook->post_end(
        title => "Task 42 is now finished", color => "#000",
        text  => 'task is now finished'
    );

    http_post_was_called_with(
        {   
          'attachments' => [
                {
                  'color' => '#000',
                  'mrkdwn_in' => [
                    'text',
                    'title'
                  ],
                  'text' => "task is now finished\n"
                        . '_run time: 18 seconds_',
                  'title' => 'Task 42 is now finished'
                }
          ]
        },
        'post_end( @list ) with custom color'
    );
}

## final santiy check
note "final santiy check";
is $last_http_post_form, undef, "all called were check"
    or diag explain $last_http_post_form;

done_testing;
exit;

sub http_post_was_called_with {
    my ( $expect, $msg ) = @_;

    $msg //= 'http_post_was_called_with';

    is $last_http_post_form, [
        $URL,
        { payload => D() }
        ],
        "last_http_post_form called"
        or die;

    my $content = eval {
        JSON::MaybeXS::decode_json( $last_http_post_form->[1]->{payload} );
    };
    is $content => $expect, $msg or diag explain $content;

    undef $last_http_post_form;    # reset;

    return;
}

done_testing;
