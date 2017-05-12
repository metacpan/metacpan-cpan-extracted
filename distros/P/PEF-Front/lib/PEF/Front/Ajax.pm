package PEF::Front::Ajax;

use strict;
use warnings;
use Encode;
use JSON;
use URI::Escape;
use Template::Alloy;
use Data::Dumper;
use Scalar::Util qw(blessed);
use PEF::Front::Config;
use PEF::Front::Cache;
use PEF::Front::Validator;
use PEF::Front::NLS;
use PEF::Front::Response;

sub ajax {
	my ($request, $context) = @_;
	my $form          = $request->params;
	my $cookies       = $request->cookies;
	my $logger        = $request->logger;
	my $http_response = PEF::Front::Response->new(request => $request);
	my $lang          = $context->{lang};
	my %request       = %$form;
	my $src           = $context->{src};
	$request{method} = $context->{method};
	$http_response->set_cookie(lang => {value => $lang, path => "/"});

	if (\&PEF::Front::Config::cfg_context_post_hook != \&PEF::Front::Config::std_context_post_hook) {
		cfg_context_post_hook($context);
	}
	my $vreq = eval {validate(\%request, $context)};
	my $response;
	my $json = $src eq 'ajax';
	$src = 'submit' if $src eq 'get';
	my $new_loc;

	if (!$@) {
		my $as = get_method_attrs($vreq => 'allowed_source');
		if ($as
			&& (   (!ref($as) && $as ne $src)
				|| (ref($as) eq 'ARRAY' && !grep {$_ eq $src} @$as))
			)
		{
			cfg_log_level_error
				&& $logger->({level => "error", message => "not allowed source $src"});
			$response = {result => 'INTERR', answer => 'Unallowed calling source', answer_args => []};
			goto out;
		}
		my $cache_attr = get_method_attrs($vreq => 'cache');
		my $cache_key;
		if ($cache_attr) {
			$cache_key = make_request_cache_key($vreq, $cache_attr);
			$cache_attr->{expires} = cfg_cache_method_expire unless exists $cache_attr->{expires};
			cfg_log_level_debug && $logger->({level => "debug", message => "cache key: $cache_key"});
			$response = get_cache("ajax:$cache_key");
		}
		if (not $response) {
			my $model = get_model($vreq);
			my $model_sub = get_method_attrs($vreq => 'model_sub');
			if (ref $model) {
				local $Data::Dumper::Terse = 1;
				$model = Dumper($model);
				substr($model, -1, 1, '') if substr($model, -1, 1) eq "\n";
			}
			cfg_log_level_debug
				&& $logger->({level => "debug", message => "model: $model"});
			$response = $model_sub->($vreq, $context);
			if ($@) {
				cfg_log_level_error
					&& $logger->({level => "error", message => "model: $model; error: " . Dumper($@, $vreq)});
				$response = {result => 'INTERR', answer => 'Internal error', answer_args => []};
				goto out;
			}
			if ($response->{result} eq 'OK' && $cache_attr) {
				set_cache("ajax:$cache_key", $response, $cache_attr->{expires});
			}
		}
		my $result = get_method_attrs($vreq => 'result');
		if (defined($result)) {
			my $stash = {
				response => $response,
				form     => $form,
				cookies  => $cookies,
				defaults => $context,
				context  => $context,
				request  => $vreq,
				result   => $response->{result},
			};
			my $tt = Template::Alloy->new(
				COMPILE_DIR => cfg_template_cache,
				V2EQUALS    => 0,
				ENCODING    => "UTF-8"
			);
			$stash->{uri_unescape} = sub {uri_unescape @_};
			$tt->define_vmethod(
				'text',
				session => sub {
					$context->{session} ||= PEF::Front::Session->new($request);
					if (@_) {
						return $context->{session}->data->{$_[0]};
					} else {
						return $context->{session}->data;
					}
				}
			);
			my $err;
			($new_loc, $response)
				= get_method_attrs($vreq => 'result_sub')->($response, $context, $stash, $http_response, $tt, $logger);
		}
	} else {
		cfg_log_level_error
			&& $logger->({level => "error", message => "validate error: " . Dumper($@, \%request)});
		$response = (
			ref($@) eq 'HASH'
			? $@
			: {result => 'INTERR', answer => 'Internal Error', answer_args => []}
		);
	}
	if (exists $response->{answer_headers}
		and 'ARRAY' eq ref $response->{answer_headers})
	{
		while (@{$response->{answer_headers}}) {
			if (ref($response->{answer_headers}[0])) {
				if (ref($response->{answer_headers}[0]) eq 'HASH') {
					$http_response->add_header(%{$response->{answer_headers}[0]});
				} else {
					$http_response->add_header(@{$response->{answer_headers}[0]});
				}
				shift @{$response->{answer_headers}};
			} else {
				$http_response->add_header($response->{answer_headers}[0], $response->{answer_headers}[1]);
				splice @{$response->{answer_headers}}, 0, 2;
			}
		}
	}
	if (exists $response->{answer_cookies}
		and 'ARRAY' eq ref $response->{answer_cookies})
	{
		while (@{$response->{answer_cookies}}) {
			if (ref($response->{answer_cookies}[0])) {
				if (ref($response->{answer_cookies}[0]) eq 'HASH') {
					$http_response->set_cookie(%{$response->{answer_cookies}[0]});
				} else {
					$http_response->set_cookie(@{$response->{answer_cookies}[0]});
				}
				shift @{$response->{answer_cookies}};
			} else {
				$http_response->set_cookie($response->{answer_cookies}[0], $response->{answer_cookies}[1]);
				splice @{$response->{answer_cookies}}, 0, 2;
			}
		}
	}
out:
	if ($context->{is_subrequest}) {
		return $response;
	} elsif ($json) {
		if (exists $response->{answer} and not exists $response->{answer_no_nls}) {
			my $args = exists($response->{answer_args}) ? $response->{answer_args} : [];
			$args = [$args] if 'ARRAY' ne ref $args;
			$response->{answer} = msg_get($lang, $response->{answer}, @$args)->{message};
		}
		$http_response->content_type('application/json; charset=utf-8');
		$http_response->set_body(encode_json($response));
		return $http_response->response();
	} else {
		if (exists $response->{answer_status} and $response->{answer_status} > 100) {
			$http_response->status($response->{answer_status});
			if (   $response->{answer_status} > 300
				&& $response->{answer_status} < 400
				&& (my $loc = $http_response->get_header('Location')))
			{
				$new_loc = $loc;
			}
		}
		if (!defined($new_loc) || $new_loc eq '') {
			cfg_log_level_debug
				&& $logger->({level => "debug", message => "outputting the answer"});
			my $ct = 'text/html; charset=utf-8';
			if (   exists($response->{answer_content_type})
				&& defined($response->{answer_content_type})
				&& $response->{answer_content_type})
			{
				$ct = $response->{answer_content_type};
			} elsif (defined(my $yct = $http_response->content_type)) {
				$ct = $yct;
			}
			$http_response->content_type($ct);
			if ($response->{answer} and not exists $response->{answer_no_nls} and $ct =~ /^text/) {
				my $args = [];
				$args = $response->{answer_args}
					if exists $response->{answer_args} and 'ARRAY' eq ref $response->{answer_args};
				$response->{answer} = msg_get($lang, $response->{answer}, @$args)->{message};
			}
			$http_response->set_body($response->{answer});
			return $http_response->response();
		} else {
			cfg_log_level_debug
				&& $logger->({level => "debug", message => "setting location: $new_loc"});
			$http_response->redirect($new_loc);
			return $http_response->response();
		}
	}
}

sub handler {
	my ($request, $context) = @_;
	return sub {
		my $responder = $_[0];
		my $response = ajax($request, $context);
		if (ref($response->[2]) eq 'CODE') {
			my $coderef = pop @$response;
			my $writer  = $responder->($response);
			while (my ($stream) = $coderef->($request, $context)) {
				$writer->write($stream);
			}
			$writer->close;
		} else {
			$responder->($response);
		}
	};
}

1;
