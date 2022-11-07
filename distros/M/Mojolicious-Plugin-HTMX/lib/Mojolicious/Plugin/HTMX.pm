package Mojolicious::Plugin::HTMX;
use Mojo::Base 'Mojolicious::Plugin';

use Mojo::ByteStream;
use Mojo::JSON qw(encode_json decode_json);

our $VERSION = '1.00';

my @HX_RESWAPS = (qw[
    innerHTML
    outerHTML
    beforebegin
    afterbegin
    beforeend
    afterend
    delete
    none
]);

use constant HX_TRUE  => 'true';
use constant HX_FALSE => 'false';

use constant HTMX_STOP_POLLING => 286;
use constant HTMX_CDN_URL      => 'https://unpkg.com/htmx.org';

sub register {

    my ($self, $app) = @_;

    $app->helper('htmx.asset'      => \&_htmx_js);
    $app->helper('is_htmx_request' => sub { _header(shift, 'HX-Request', HX_TRUE) });

    $app->helper('htmx.req.boosted'                 => sub { _header(shift, 'HX-Boosted', HX_TRUE) });
    $app->helper('htmx.req.current_url'             => sub { Mojo::URL->new(_header(shift, 'HX-Current-URL')) });
    $app->helper('htmx.req.history_restore_request' => sub { _header(shift, 'HX-History-Restore-Request', HX_TRUE) });
    $app->helper('htmx.req.prompt'                  => sub { _header(shift, 'HX-Prompt') });
    $app->helper('htmx.req.request'                 => sub { _header(shift, 'HX-Request', HX_TRUE) });
    $app->helper('htmx.req.target'                  => sub { _header(shift, 'HX-Target') });
    $app->helper('htmx.req.trigger_name'            => sub { _header(shift, 'HX-Trigger-Name') });
    $app->helper('htmx.req.trigger'                 => sub { _header(shift, 'HX-Trigger') });

    $app->helper(
        'htmx.req.triggering_event' => sub {
            eval { decode_json(_header(shift, 'Triggering-Event')) } || {};
        }
    );

    $app->helper('htmx.res.location'    => \&_res_location);
    $app->helper('htmx.res.push_url'    => \&_res_push_url);
    $app->helper('htmx.res.redirect'    => \&_res_redirect);
    $app->helper('htmx.res.refresh'     => \&_res_refresh);
    $app->helper('htmx.res.replace_url' => \&_res_replace_url);
    $app->helper('htmx.res.reswap'      => \&_res_reswap);
    $app->helper('htmx.res.retarget'    => \&_res_retarget);

    $app->helper('htmx.res.trigger'              => sub { _res_trigger('default',      @_) });
    $app->helper('htmx.res.trigger_after_settle' => sub { _res_trigger('after_settle', @_) });
    $app->helper('htmx.res.trigger_after_swap'   => sub { _res_trigger('after_swap',   @_) });

}

sub _htmx_js {

    my ($self, %params) = @_;
    my $url = delete $params{url} || HTMX_CDN_URL;
    my $ext = delete $params{ext};

    if ($ext) {
        $url .= "/dist/ext/$ext.js";
    }

    return Mojo::ByteStream->new(Mojo::DOM::HTML::tag_to_html('script', 'src' => $url));

}

sub _header {

    my ($c, $header, $check) = @_;
    my $value = $c->req->headers->header($header);

    if ($value && $check) {
        return 1 if ($value eq $check);
        return 0;
    }

    return $value;

}

sub _res_location {

    my $c        = shift;
    my $location = (@_ > 1) ? {@_} : $_[0];

    return undef unless $location;

    if (ref $location eq 'HASH') {
        $location = encode_json($location);
    }

    return $c->res->headers->header('HX-Location' => $location);

}

sub _res_push_url {

    my ($c, $push_url) = @_;
    return undef unless $push_url;

    return $c->res->headers->header('HX-Push-Url' => $push_url);

}

sub _res_redirect {

    my ($c, $redirect) = @_;
    return undef unless $redirect;

    return $c->res->headers->header('HX-Redirect' => $redirect);

}

sub _res_refresh {
    my ($c) = @_;
    return $c->res->headers->header('HX-Refresh' => HX_TRUE);
}

sub _res_replace_url {

    my ($c, $replace_url) = @_;
    return undef unless $replace_url;

    return $c->res->headers->header('HX-Replace-Url' => $replace_url);

}

sub _res_reswap {

    my ($c, $reswap) = @_;
    return undef unless $reswap;

    my $is_reswap = grep {/^$reswap$/} @HX_RESWAPS;
    Carp::croak "Unknown reswap value" if (!$is_reswap);

    return $c->res->headers->header('HX-Reswap' => $reswap);

}

sub _res_retarget {

    my ($c, $retarget) = @_;
    return undef unless $retarget;

    return $c->res->headers->header('HX-Retarget' => $retarget);

}

sub _res_trigger {

    my ($type, $c) = (shift, shift);
    my $trigger = (@_ > 1) ? {@_} : $_[0];

    return undef unless $trigger;

    my $trigger_header = {after_settle => 'HX-Trigger-After-Settle', after_swap => 'HX-Trigger-After-Swap'};

    if (ref $trigger eq 'HASH') {
        $trigger = encode_json($trigger);
    }

    my $header = $trigger_header->{$type} || 'HX-Trigger';

    return $c->res->headers->header($header => $trigger);

}

1;

=encoding utf8

=head1 NAME

Mojolicious::Plugin::HTMX - Mojolicious Plugin for htmx

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('Mojolicious::Plugin::HTMX');

  # Mojolicious::Lite
  plugin 'Mojolicious::Plugin::HTMX';

  get '/trigger' => 'trigger';
  post '/trigger' => sub ($c) {

      state $count = 0;
      $count++;

      $c->htmx->res->trigger(showMessage => 'Here Is A Message');
      $c->render(text => "Triggered $count times");

  };

  @@ template.html.ep
  <html>
  <head>
      %= app->htmx->asset
  </head>
  <body>
      %= content
  </body>
  </html>

  @@ trigger.html.ep
  % layout 'default';
  <h1>Trigger</h1>

  <button hx-post="/trigger">Click Me</button>

  <script>
  document.body.addEventListener("showMessage", function(e){
      alert(e.detail.value);
  });
  </script>

=head1 DESCRIPTION

L<Mojolicious::Plugin::HTMX> is a L<Mojolicious> plugin to add htmx in your Mojolicious application.

=head1 HELPERS

L<Mojolicious::Plugin::HTMX> implements the following helpers.

=head2 GENERIC HELPERS

=head3 htmx->asset

  %= htmx->asset
  %= htmx->asset(src => '/assets/js/htmx.min.js')
  %= htmx->asset(ext => debug)

Generate C<script> tag for include htmx script file in your template.

=head3 htmx->is_htmx_request

  if ($c->is_htmx_request) {
    # ...
  }

Based on C<HX-Request> header.

=head2 REQUEST HELPERS

=head3 htmx->req->boosted

Indicates that the request is via an element using C<hx-boost>.

Based on C<HX-Boosted> header.

=head3 htmx->req->current_url

The current URL of the browser.

Based on C<HX-Current-URL> header.

=head3 htmx->req->history_restore_request

C<true> if the request is for history restoration after a miss in the local history cache.

Based on C<HX-History-Restore-Request> header.

=head3 htmx->req->prompt

The user response to an C<hx-prompt>.

Based on C<HX-Prompt> header.

=head3 htmx->req->request

Always C<true>.

  if ($c->is_htmx_request) {
    # ...
  }

Based on C<HX-Request> header.

=head3 htmx->req->target

The C<id> of the target element if it exists.

Based on C<HX-Target> header.

=head3 htmx->req->trigger_name

The C<name> of the triggered element if it exists.

Based on C<HX-Trigger-Name> header.

=head3 htmx->req->trigger

The C<id> of the triggered element if it exists.

Based on C<HX-Trigger> header.


=head2 RESPONSE HELPERS

=head3 htmx->res->location

Allows you to do a client-side redirect that does not do a full page reload.

Based on C<HX-Location> header.

=head3 htmx->res->push_url

Pushes a new url into the history stack.

Based on C<HX-Push-Url> header.

=head3 htmx->res->redirect

Can be used to do a client-side redirect to a new location.

Based on C<HX-Redirect> header.

=head3 htmx->res->refresh

Full refresh of the page.

Based on C<HX-Refresh> header.

=head3 htmx->res->replace_url

Replaces the current URL in the location bar.

Based on C<HX-Replace-Url> header.

=head3 htmx->res->reswap

Allows you to specify how the response will be swapped.

The possible values of this attribute are:

=over

=item C<innerHTML> The default, replace the inner html of the target element

=item C<outerHTML> Replace the entire target element with the response

=item C<beforebegin> Insert the response before the target element

=item C<afterbegin> Insert the response before the first child of the target element

=item C<beforeend> Insert the response after the last child of the target element

=item C<afterend> Insert the response after the target element

=item C<delete> Deletes the target element regardless of the response

=item C<none> Does not append content from response (out of band items will still be processed).

=back

Based on C<HX-Reswap> header.

=head3 htmx->res->retarget

A CSS selector that updates the target of the content update to a different element on the page.

Based on C<HX-Retarget> header.

=head3 htmx->res->trigger

Allows you to trigger client side events, see L<https://htmx.org/headers/hx-trigger> for more info.

To trigger a single event with no additional details you can simply send the event name like so:

  if ($c->is_htmx_request) {
    $c->htmx->res->trigger('myEvent');
  }

If you want to pass details along with the event, you can use HASH for the value of the trigger:

  if ($c->is_htmx_request) {
    $c->htmx->res->trigger( showMessage => 'Here Is A Message' );
  }

  if ($c->is_htmx_request) {
    $c->htmx->res->trigger(
      showMessage => {
        level   => 'info',
        message => 'Here Is A Message'
      }
    );
  }

If you wish to invoke multiple events, you can simply add additional keys to the HASH:

  if ($c->is_htmx_request) {
    $c->htmx->res->trigger(
        event1 => 'A message',
        event2 => 'Another message'
    );
  }

Based on C<HX-Trigger> header.

=head3 htmx->res->trigger_after_settle

Allows you to trigger client side events, see L<https://htmx.org/headers/hx-trigger> for more info.

Based on C<HX-Trigger-After-Settle> header.

=head3 htmx->res->trigger_after_swap

Allows you to trigger client side events, see L<https://htmx.org/headers/hx-trigger> for more info.

Based on C<HX-Trigger-After-Swap> header.


=head1 METHODS

L<Mojolicious::Plugin::HTMX> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 register

  $plugin->register(Mojolicious->new);

Register plugin in L<Mojolicious> application.


=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<https://mojolicious.org>.


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX>

    git clone https://github.com/giterlizzi/perl-Mojolicious-Plugin-HTMX.git


=head1 AUTHORS

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 COPYRIGHT AND LICENSE

Copyright (c) 2022, Giuseppe Di Terlizzi

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

