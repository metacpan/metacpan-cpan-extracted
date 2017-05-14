
package Plack::App::HipChat::WebHook;

use strict;
use warnings;

use parent qw( Plack::Component );

use Plack::Util::Accessor qw(webhooks hipchat_user_agent );
use Plack::Util;
use Plack::Request;

use JSON qw(decode_json);
use Try::Tiny;

sub call {
    my($self, $env) = @_;

    my $Req = Plack::Request->new($env);

    my $rh_webhooks = $self->webhooks;

    my $path = $Req->path_info();
    if ($rh_webhooks->{$path}) {

        ## Check headers

        my $hipchat_uagent = $self->hipchat_user_agent() // 'HipChat.com';

        if ($Req->headers()->header('User-Agent') ne $hipchat_uagent) {
#            warn "No HipChat.com User-Agent header\n";
            return $self->return_400();
        }

        if ($Req->headers()->header('Content-Type') ne 'application/json') {
#            warn "Not application/json Content-Type\n";
            return $self->return_400();
        }

        my $rh;
        try {
            $rh = decode_json($Req->content());
        } catch {
#            warn "Failed to decode JSON content\n";
        };

        if (!$rh) {
            return $self->return_400();
        }

        my $rc = $rh_webhooks->{$path};
        return Plack::Util::run_app($rc, $rh);
    }

    return $self->return_404();
}

sub return_404 {
    my $self = shift;

#    warn "Not found\n";
    return [ 404, [ 'Content-Type' => 'text/plain', 'Content-Length' => 9 ],
             ['Not found'] ];
}

sub return_400 {
    my $self = shift;
    return [ 400,  ['Content-Type' => 'text/plain', 'Content-Length' => 11 ],
            ['Bad Request'] ];
}

1;

# ABSTRACT: HipChat WebHook Plack Application

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::App::HipChat::WebHook - HipChat WebHook Plack Application

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use Plack::App::HipChat::WebHook;

  my $app = Plack::App::HipChat::WebHook->new({
      hipchat_user_agent => 'ExpectedUserAgent',  # Optional
      webhooks => {
          '/webhook_notification' => sub {
              my $rh = shift;

  #
  # Do something with $rh (decoded JSON webhook notification)
  #

              return [ 200,
                       [ 'Content-Type' => 'text/plain' ],
                       [ 'Completed' ]
                   ];
          },
      },
  })->to_app;

  # plackup <abovescript.pl>

=head1 DESCRIPTION

A Plack application to receive WebHook notifications from HipChat (see
https://www.hipchat.com/docs/apiv2/webhooks). Register webhooks
to new() with callbacks which are called with the decoded JSON payload
of a event when received from HipChat that matches the path.

The callback is passed a hashref that looks like this:

  \ {
      event             "room_notification",
      item              {
          message   {
              color            "yellow",
              date             "2015-01-17T20:29:06.018495+00:00",
              from             "Some Dude",
              id               "aaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
              mentions         [],
              message          "Message Text",
              message_format   "html",
              type             "notification"
          },
          room      {
              id      123456,
              links   {
                  participants   "https://api.hipchat.com/v2/room/123456/participant",
                  self           "https://api.hipchat.com/v2/room/123456",
                  webhooks       "https://api.hipchat.com/v2/room/123456/webhook"
              },
              name    "ChatRoom"
          }
      },
      oauth_client_id   "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee",
      webhook_id        123456
  }

Pass hipchat_user_agent to new() for checking of the 'User-Agent' in each
request. This defaults to 'HipChat.com'.

=head2 call

If the path matches a configured webhook, checks that the content-type and
user-agent are set as expected, then decode the JSON content and fire the
callback with that hashref.

=head2 return_400

Return a 400 (Bad request) error.

=head2 return_404

Return a 404 (Not found) error.

=head1 SEE ALSO

L<WebService::HipChat>

=head1 AUTHOR

Chris Hughes <chrisjh@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Chris Hughes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
