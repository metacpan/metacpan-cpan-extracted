#!/usr/bin/env perl
#
# This plack demo shows the logic which your website needs to facilitate
# third-party OAuth2 authorization.

# This code only works when you plack server runs in a single process:
# otherwise you will need to keep the session information in some
# shared store, for instance a database.  That makes life considerable
# harder.

use strict;
use warnings;

use Dancer;
use Net::OAuth2::Client;
use HTML::Entities;

get '/get/:site_id' => sub {
    redirect client(params->{site_id})->authorize;
};

get '/got/:site_id' => sub {
    defined params->{code}
        or return html_page("Error: Missing access code");

    my $site_id      = params->{site_id};
    my $access_token = client($site_id)->get_access_token(params->{code});
    return html_page("Error: " . $access_token->to_string)
        if $access_token->{error};

    my $content = "<h2>Access token retrieved successfully!</h2>\n"
                . '<p>'.encode_entities($access_token->to_string)."</p>\n";
    $content   .= "<h2>State passthru</h2>" . encode_entities(params->{state})
        if params->{state};

    my $this_site = config->{sites}{$site_id};
    my $response  = $access_token->get($this_site->{protected_resource_url}
                 || $this_site->{protected_resource_path});

    if ($response->is_success)
    {   $content .= "<h2>Protected resource retrieved successfully!</h2>\n"
                 .  '<p>'.encode_entities($response->decoded_content).'</p>';
    }
    else {
        $content .= '<p>Error: '. $response->status_line."</p>\n";
    }
    $content =~ s[\n][<br/>\n]g;
    html_page($content);
};

get '/' => sub {
    my $content = '';
    while (my ($k,$v) = each %{config->{sites}}) {
        $content .= qq{<p>$v->{name}: <a href="/get/$k">/get/$k</a></p>\n}
            if $v->{client_id} && $v->{client_secret};
    }
    $content ||= "<p>You haven't configured any sites yet.<br>\n"
               . "Edit your config.yml file!</p>\n";
    html_page($content);
};

dance;

exit 0;

### Helpers

sub html_page($) {
    my $content = shift;
    return <<EOT;
<html>
<head>
    <title>OAuth 2 Test</title>
    <style>
    h1 a {color: black; text-decoration:none}
    </style>
</head>
<body>
<h1><a href="/">OAuth 2 Test</a></h1>
$content
</body>
</html>
EOT
}

sub client($)
{   my $site_id     = shift;
    my $site_config = config->{sites}{$site_id} || {};

    my $redirect    = uri_for("/got/$site_id");
    $redirect       =~ s,/dispatch\.cgi,,;

    Net::OAuth2::Profile::WebServer->new
      ( %$site_config
      , redirect_uri => $redirect
      );
}

