#!/usr/bin/env perl
use strict;
use warnings;
use Dancer;
use Net::OAuth::Client;
use HTML::Entities;

sub client {
	my $site_id = shift;
	Net::OAuth::Client->new(
		config->{sites}{$site_id}{client_id},
		config->{sites}{$site_id}{client_secret},
		site => config->{sites}{$site_id}{site},
		request_token_path => config->{sites}{$site_id}{request_token_path},
		authorize_path => config->{sites}{$site_id}{authorize_path},
		access_token_path => config->{sites}{$site_id}{access_token_path},
		callback => fix_uri(uri_for("/got/$site_id")),
		session => \&session,
		debug => 1,
	);
}

get '/get/:site_id' => sub {
	redirect client(params->{site_id})->authorize_url;
};

get '/got/:site_id' => sub {
	return wrap("Error: Missing access code") if (!defined params->{oauth_verifier});
	my $access_token =  client(params->{site_id})->get_access_token(params->{oauth_token}, params->{oauth_verifier});
	return wrap("Error: " . $access_token->to_string) if ($access_token->{error});
	my $content = '<h2>Access token retrieved successfully!</h2>'.
	'<p>Token: ' . encode_entities($access_token->token) . '</p>'.
	'<p>Secret: ' . encode_entities($access_token->token_secret) . '</p>';
	my $response = $access_token->get(config->{sites}{params->{site_id}}{protected_resource_path});
	if ($response->is_success) {
		$content .= '<h2>Protected resource retrieved successfully!</h2><textarea>' . encode_entities($response->decoded_content) . '</textarea>';
	}
	else {
		$content .= '<p>Error: ' . $response->status_line . '</p>';
	}
	$content =~ s[\n][<br/>\n]g;
	return wrap($content);
};

sub fix_uri {
	(my $uri = shift) =~ s[/dispatch\.cgi][];
	return $uri;
}

sub wrap {
	my $content = shift;
	return <<EOT;
	<html>
	<head>
		<title>OAuth Test</title>
		<style>
		h1 a {color: black; text-decoration:none}
		textarea {width:50%;height:300px}
		</style>
	</head>
	<body>
	<h1><a href='/'>OAuth Test</a></h1>
	$content
	</body>
	</html>
EOT
}

get '/' => sub {
	my $content='';
	while (my ($k,$v) = each %{config->{sites}}) {
		if (defined $v->{client_id} and length $v->{client_id} 
				and defined $v->{client_secret} and length $v->{client_secret}) {
			$content .= "<p>" . $v->{name} . ": <a href='/get/$k'>/get/$k</a></p>\n";
		}
	}
	$content = "You haven't configured any sites yet.  Edit your config.yml file!" unless $content;
	return wrap($content);
};

dance;

