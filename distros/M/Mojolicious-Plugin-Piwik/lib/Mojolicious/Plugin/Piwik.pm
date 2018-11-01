package Mojolicious::Plugin::Piwik;
use Mojo::Base 'Mojolicious::Plugin';
use Mojo::Util qw/deprecated/;
use Mojo::ByteStream 'b';
use Mojo::UserAgent;
use Mojo::IOLoop;

our $VERSION = '0.22';

# Todo:
# - Better test tracking API support
#   See http://piwik.org/docs/javascript-tracking/
#   http://piwik.org/docs/tracking-api/reference/
# - Support custom values in tracking api.
# - Add eCommerce support
#   http://piwik.org/docs/ecommerce-analytics/
# - Improve error handling.
# - Introduce piwik_widget helper


# Register plugin
sub register {
  my ($plugin, $mojo, $plugin_param) = @_;

  $plugin_param ||= {};

  # Load parameter from Config file
  if (my $config_param = $mojo->config('Piwik')) {
    $plugin_param = { %$plugin_param, %$config_param };
  };

  # Embed tag
  my $embed = $plugin_param->{embed} //
    ($mojo->mode eq 'production' ? 1 : 0);

  # Add 'piwik_tag' helper
  $mojo->helper(
    piwik_tag => sub {

      # Do not embed
      return '' unless $embed;

      # Controller
      my $c = shift;

      # Use opt-out tag
      my %opt;
      if ($_[0] && index(lc $_[0], 'opt-out') == 0) {
        my $opt_out = shift;

        # Get iframe content
        my $cb = ref $_[-1] eq 'CODE' ? pop : 0;

        # Accept parameters
        %opt = @_;
        $opt{out} = $opt_out;
        $opt{cb}  = $cb;

        # Empty arguments
        @_ = ();
      };

      my $site_id = shift || $plugin_param->{site_id} || 1;
      my $url     = shift || $plugin_param->{url};

      # No piwik url
      return b('<!-- No Piwik-URL given -->') unless $url;

      my $prot = 'http';

      # Clear url
      for ($url) {
        if (s{^http(s?):/*}{}i) {
          $prot = 'https' if $1;
        };
        s{piwik\.(?:php|js)$}{}i;
        s{(?<!/)$}{/};
      };

      # Render opt-out tag
      if (my $opt_out = delete $opt{out}) {

        # Upgrade protocol if embedded in https page
        if ($prot ne 'https') {
          my $req_url = $c->req->url;
          $prot = $req_url->scheme ? lc $req_url->scheme : 'http';
        };

        my $cb = delete $opt{cb};
        my $oo_url = "${prot}://${url}index.php?module=CoreAdminHome&action=optOut";

        if ($opt_out eq 'opt-out-link') {
          $opt{href} = $oo_url;
          $opt{rel} //= 'nofollow';
          return $c->tag('a', %opt, ($cb || sub { 'Piwik Opt-Out' }));
        };

        $opt{src} = $oo_url;
        $opt{width}  ||= '600px';
        $opt{height} ||= '200px';
        $opt{frameborder} ||= 'no';

        return $c->tag('iframe', %opt, ($cb || sub { '' }));
      };

      # Create piwik tag
      b(<<"SCRIPTTAG");
<script type="text/javascript">var _paq=_paq||[];(function(){var
u='http'+((document.location.protocol=='https:')?'s':'')+'://$url';
with(_paq){push(['setSiteId',$site_id]);push(['setTrackerUrl',u+'piwik.php']);
push(['trackPageView'])};var
d=document,g=d.createElement('script'),s=d.getElementsByTagName('script')[0];
if(!s){s=d.getElementsByTagName('head')[0].firstChild};
with(g){type='text/javascript';defer=async=true;
src=u+'piwik.js';s.parentNode.insertBefore(g,s)}})();</script>
<noscript><img src="${prot}://${url}piwik.php?idSite=${site_id}&amp;rec=1" alt=""
style="border:0" /></noscript>
SCRIPTTAG
    });


  # Add 'piwik->api' helper
  $mojo->helper(
    'piwik.api' => sub {
      my ($c, $method, $param, $cb) = @_;

      # Get api_test parameter
      my $api_test = delete $param->{api_test};

      # Get piwik url
      my $url = delete($param->{url}) || $plugin_param->{url};

      if ($url =~ s{^(?:http(s)?:)?//}{}i && $1) {
        $param->{secure} = 1;
      };
      $url = ($param->{secure} ? 'https' : 'http') . '://' . $url;

      # Create request URL
      $url = Mojo::URL->new($url);

      # Site id
      my $site_id = $param->{site_id} ||
        $param->{idSite}  ||
        $param->{idsite}  ||
        $plugin_param->{site_id} || 1;

      # delete unused parameters
      delete @{$param}{qw/site_id idSite idsite format module method/};

      # Token Auth
      my $token_auth = delete $param->{token_auth} ||
        $plugin_param->{token_auth} || 'anonymous';

      # Tracking API
      if (lc $method eq 'track') {

        $url->path('piwik.php');

        # Request Headers
        my $header = $c->req->headers;

        # Respect do not track
        return if $header->dnt;

        # Set default values
        for ($param)  {
          $_->{ua}     //= $header->user_agent if $header->user_agent;
          $_->{urlref} //= $header->referrer   if $header->referrer;
          $_->{rand}     = int(rand(10_000));
          $_->{rec}      = 1;
          $_->{apiv}     = 1;
          $_->{url}      = delete $_->{action_url} || $c->url_for->to_abs;

          # Todo: maybe make optional with parameter
          # $_->{_id} = rand ...
        };

        # Resolution
        if ($param->{res} && ref $param->{res}) {
          $param->{res} = join 'x', @{$param->{res}}[0, 1];
        };

        $url->query(
          idsite => ref $site_id ? $site_id->[0] : $site_id,
          format => 'JSON'
        );

        $url->query({token_auth => $token_auth}) if $token_auth;
      }

      # Analysis API
      else {

        # Create request method
        $url->query(
          module => 'API',
          method => $method,
          format => 'JSON',
          idSite => ref $site_id ? join(',', @$site_id) : $site_id,
          token_auth => $token_auth
        );

        # Urls
        if ($param->{urls}) {

          # Urls is arrayref
          if (ref $param->{urls}) {
            my $i = 0;
            foreach (@{$param->{urls}}) {
              $url->query({ 'urls[' . $i++ . ']' => $_ });
            };
          }

          # Urls as string
          else {
            $url->query({urls => $param->{urls}});
          };
          delete $param->{urls};
        };

        # Range with periods
        if ($param->{period}) {

          # Delete period
          my $period = lc delete $param->{period};

          # Delete date
          my $date = delete $param->{date};

          # Get range
          if ($period eq 'range') {
            $date = ref $date ? join(',', @$date) : $date;
          };

          if ($period =~ m/^(?:day|week|month|year|range)$/) {
            $url->query({
              period => $period,
              date   => $date
            });
          };
        };
      };

      # Todo: Handle Filter

      # Merge query
      $url->query($param);

      # Return string for api testing
      return $url if $api_test;

      # Create Mojo::UserAgent
      my $ua = Mojo::UserAgent->new(max_redirects => 2);

      # Todo: Handle json errors!

      # Blocking
      unless ($cb) {
        my $tx = $ua->get($url);

        # Return prepared response
        return _prepare_response($tx->res) unless $tx->error;

        return;
      }

      # Non-Blocking
      else {

        # Create delay object
        my $delay = Mojo::IOLoop->delay(
          sub {
            # Return prepared response
            my $res = pop->success;

            # Release callback with json object
            $cb->( $res ? _prepare_response($res) : {} );
          }
        );

        # Get resource non-blocking
        $ua->get($url => $delay->begin);

        # Start IOLoop if not started already
        $delay->wait unless Mojo::IOLoop->is_running;
      };
    });

  # Establish 'piwik.api_url' helper
  $mojo->helper(
    'piwik.api_url' => sub {
      my ($c, $method, $param) = @_;

      # Set api_test to true
      $param->{api_test} = 1;
      return $c->piwik->api($method => $param);
    }
  );

  # Add legacy 'piwik_api' helper
  $mojo->helper(
    'piwik_api' => sub {
      my $c = shift;
      deprecated 'Deprecated in favor of piwik->api';
      return $c->piwik->api(@_);
    }
  );

  # Establish 'piwik_api_url' helper
  $mojo->helper(
    piwik_api_url => sub {
      my $c = shift;
      deprecated 'Deprecated in favor of piwik->api_url';
      return $c->piwik->api_url(@_);
    }
  );
};


# Treat response different
sub _prepare_response {
  my $res = shift;
  my $ct = $res->headers->content_type;

  # Return json response
  if (index($ct, 'json') >= 0) {
    return $res->json;
  }

  # Prepare erroneous html response
  elsif (index($ct, 'html') >= 0) {

    # Find error message in html
    my $found = $res->dom->at('#contentsimple > p');

    # Return unknown error
    return { error => 'unknown' } unless $found;

    # Return error message as json
    return { error => $found->all_text };
  }

  # Prepare image responses
  elsif ($ct =~ m{^image/(gif|jpe?g)}) {
    return {
      image => 'data:image/' . $1 . ';base64,' . b($res->body)->b64_encode
    };
  };

  # Return unknown response type
  return {
    error => 'Unknown response type',
    body  => $res->body
  };
};


1;


__END__

=pod

=encoding utf8

=head1 NAME

Mojolicious::Plugin::Piwik - Use Matomo (Piwik) in Mojolicious


=head1 SYNOPSIS

  # On startup
  plugin 'Piwik' => {
    url => 'piwik.khm.li',
    site_id => 1
  };

  # In Template
  %= piwik_tag

  # In controller
  my $json = $c->piwik->api('API.getPiwikVersion');


=head1 DESCRIPTION

L<Mojolicious::Plugin::Piwik> is a simple plugin for embedding
L<Matomo (Piwik)|https://matomo.org/> Analysis in your Mojolicious app.
Please respect the privacy of your visitors and do not track
more information than necessary!


=head1 METHODS

L<Mojolicious::Plugin::Piwik> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.


=head2 register

  # Mojolicious
  $app->plugin(Piwik => {
    url => 'piwik.khm.li',
    site_id => 1
  });

  # Mojolicious::Lite
  plugin 'Piwik' => {
    url => 'piwik.khm.li',
    site_id => 1
  };

  # Or in your config file
  {
    Piwik => {
      url => 'piwik.khm.li',
      site_id => 1
    }
  }


Called when registering the plugin.
Accepts the following parameters:

=over 2

=item

C<url> - URL of your Matomo (Piwik) instance.

=item

C<site_id> - The id of the site to monitor. Defaults to 1.

=item

C<embed> - Activates or deactivates the embedding of the script tag.
Defaults to a C<true> value if Mojolicious is in production mode,
defaults to a C<false> value otherwise.

=item

C<token_auth> - Token for authentication.
Used only for the Piwik API.

=back

All parameters can be set either as part of the configuration
file with the key C<Piwik> or on registration
(that can be overwritten by configuration).


=head1 HELPERS

=head2 piwik_tag

  %= piwik_tag
  %= piwik_tag 1
  %= piwik_tag 1, 'piwik.khm.li'
  %= piwik_tag 1, 'https://piwik.khm.li'

Renders a script tag that asynchronously loads the Piwik
javascript file from your Piwik instance.
Accepts optionally a site id and the url of your Piwik
instance. Defaults to the site id and the url given when the plugin
was registered.

This tag should be included at the bottom
of the body tag of each website you want to analyse.

The special C<opt-out> tag renders an
L<iframe|https://matomo.org/faq/general/faq_20000/>
helping your visitors to disallow tracking via javascript.

  %= piwik_tag 'opt-out', width => 400

See the L<default tag helper|Mojolicious::Plugin::TagHelpers/tag>
for explanation of usage.

The special C<opt-out-link> renders an anchor link
to the opt-out page to be used if the visitor does
not allow third party cookies.

  <%= piwik_tag 'opt-out-link', begin %>Opt Out<% end %>
  # <a href="..." rel="nofollow">Opt Out</a>

See the L<default tag helper|Mojolicious::Plugin::TagHelpers/tag>
for explanation of usage.


=head2 piwik.api

  # In Controller - blocking ...
  my $json = $c->piwik->api(
    'Actions.getPageUrl' => {
      token_auth => 'MyToken',
      idSite => [4,7],
      period => 'day',
      date   => 'today'
    }
  );

  # ... or async
  $c->piwik->api(
    'Actions.getPageUrl' => {
      token_auth => 'MyToken',
      idSite => [4,7],
      period => 'day',
      date   => 'today'
    } => sub {
      my $json = shift;
      # ...
    }
  );

Sends an API request and returns the response as a hash
or array reference (the decoded JSON response).
Accepts the API method, a hash reference
with request parameters as described in the
L<Piwik API|https://matomo.org/docs/analytics-api/>, and
optionally a callback, if the request is meant to be non-blocking.

The L<Tracking API|https://matomo.org/docs/tracking-api/reference/>
uses the method name C<Track> and will forward user agent and
referrer information based on the controller request as well as the
url of the requested resource, unless
L<Do-Not-Track|https://www.eff.org/issues/do-not-track>
is activated.
The ip address is not forwarded.

  $c->piwik->api(
    Track => {
      idsite => '4',
      res    => [1024, 768],
      action_url  => 'http://khm.li/12',
      action_name => 'Märchen/Rapunzel'
    });

As the C<url> parameter is used to define the Piwik instance,
the url of the requested resource has to be named C<action_url>.

Please remember that cookie-based opt-out can't be supported
for the non-javascript Tracking API.

In addition to the parameters of the API references, the following
parameters are allowed:

=over 2

=item

C<url> - The url of your Piwik instance.
Defaults to the url given when the plugin was registered.

=item

C<secure> - Boolean value that indicates a request using the C<https> scheme.
Defaults to false, in case the C<url> is given without or
with a C<http> scheme.

=back

C<idSite> is an alias of C<site_id> and C<idsite> and defaults to the id
of the plugin registration.
Some parameters are allowed to be array references instead of string values,
for example C<idSite> (for analysis), C<date> (for ranges) and C<res> (for tracking).

  my $json = $c->piwik->api(
    'API.get' => {
      site_id => [4,5],
      period  => 'range',
      date    => ['2012-11-01', '2012-12-01'],
      secure  => 1
    });

In case of an error, C<piwik.api> tries to response with a meaningsful
description in the hash value of C<error>.
If an image is expected instead of a JSON object
(as for the Tracking or the C<ImageGraph> API), the image is base64
encoded and mime-type prefixed in the hash value of C<image>,
ready to be embedded as the C<src> of an C<E<lt>img /E<gt>> tag.


=head2 piwik.api_url

  my $src_url = $c->piwik->api_url(
    'ImageGraph.get' => {
      apiModule => 'VisitsSummary',
      apiAction => 'get',
      graphType => 'evolution',
      period => 'day',
      date   => 'last30',
      width  => 500,
      height => 250
  });

  # In template
  <img src="<%= $src_url %>" alt="Piwik analysis" />

Creates the URL of an API request and returns the L<Mojo::URL> object.
Accepts the same parameters as the L<piwik.api|/piwik.api> helper,
excluding the callback.

B<This helper is EXPERIMENTAL and may change without warnings!>


=head1 LIMITATIONS

The plugin currently lacks support for eCommerce tracking.


=head1 TESTING

To test the plugin against your Piwik instance, create a configuration
file with the necessary information as a perl data structure in C<t/auth.pl>
and run C<make test>, for example:

  {
    token_auth => '123456abcdefghijklmnopqrstuvwxyz',
    url => 'https://piwik.khm.li/',
    site_id => 1,
    action_url => 'http://khm.li/Test',
    action_name => 'Märchen/Test'
  };

The user agent to be ignored in your Piwik instance is called C<Mojo-Test>.


=head1 DEPENDENCIES

L<Mojolicious>.


=head1 AVAILABILITY

  https://github.com/Akron/Mojolicious-Plugin-Piwik


=head1 PRIVACY NOTE

Please make sure you are using Matomo (Piwik) in compliance to the law.
For german users,
L<this information|https://www.datenschutzzentrum.de/uploads/projekte/verbraucherdatenschutz/20110315-webanalyse-piwik.pdf>
(last accessed on 2018-02-27)
may help you to design your service correctly.
You may need to inform your users about your usage of
Piwik, especially if you are located in the European Union.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2018, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it and/or
modify it under the terms of the Artistic License version 2.0.

This plugin was developed for
L<khm.li - Kinder- und Hausmärchen der Brüder Grimm|https://khm.li/>.

=cut
