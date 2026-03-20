```
NAME
    Restish::Client - A RESTish client...in perl!

SYNOPSIS
    my $client = Restish::Client->new(
        uri_host            => 'https://vault.example.com/',
        head_params_default => { X-Vault-Token => a_token },
        agent_options       => { timeout => 5 },
        require_https       => 1,
        ssl_opts => {
            -=> 1,
            SSL_cert_file   => "/etc/ssl/certs/cert.pem",
            SSL_key_file    => "/etc/ssl/private_keys/key.pem",
        },
        cooke_jar           => 1,
    );

    $client->head_params_default({ 'X-Vault-Token' => $auth_token });
    $client->ssl_opts({ SSL_use_cert => 1 });

    $client->cookie_jar(1); # OR
    $client->cookie_jar(/path/to/cookiejar);

    $client->request( method      => 'POST',
                      uri         => 'already/escaped/path',  
                      query_params  => { param1 => value1, param2 => value2 },
                      body_params => { body_param1 => bvalue1, body_param2 => bvalue2 },
                      head_params => { X-Subject-Token => $subject_token } 
    );

    # request method shorthand
    $client->GET(
        uri => 'endpoint',
    );

DESCRIPTION
    This module provides a Perl wrapper for the REST-like API's.

  METHODS
    "new"

                Construct a new Restish::Client object. The uri_host is used
                as the base uri for each API call, and serves as a template
                if string interpolation is used (see below).

                Optionally provide any data that can be set via a mutator,
                such as head_params_default or the ssl_opts.

                Options can be passed to the user agent (currently LWP) via
                agent_options.

                If require_https is set, new() will die if uri_host is not
                an https uri.

    "head_params_default"

                Supply a hashref specifying default header parameters to be
                sent with every request using this object.

    "ssl_opts"
                Supply a hashref specifying default LWP UserAgent SSL
                options to be sent with every request using this object.

    "cookie_jar"
                Enable LWP UserAgent's cookie_jar. Optionally store the
                cookie jar to disk.

    "request"
                Send a request based off of the object's base uri_host,
                returning a Perl data structure of the parsed JSON response
                in the event of a 2xx series response code. c<method> and
                c<uri> are required.

                If the request returns a 4xx or 5xx response status code,
                the return value will be 0.

                The c<response_code>, c<response_header>, and
                c<response_body> methods can be used to retrieve more
                information about the previous request.

                The URI is specified as a string that supports
                Text::Sprintf::Named compatible string interpretation.
                Interpolated values will be escaped, but the
                non-interpolated section will not be escaped. The URI can
                begin with a slash or the slash can be omitted.

                    my $res = $client->request(
                        method      => 'GET',
                        uri         => '/%(tenant_id)s/%(other)s',
                        template_params      => { tenant_id => 'cde381ab', other => 'blah' }
                        );

                Optionally specify parameters. URI parameters will be
                escaped in the query string. Body parameters will be encoded
                as JSON. Head parameters will be sent in addition to any
                default parameters specified using the
                c<head_params_default> method.

                Invalid parameters, such as an invalid uri or not supplying
                a hashref to query_params, will result in an exception.

    "METHOD Aliases"
                $client->METHOD(params) will ship the METHOD as
                method=>$method to the request

    "thin_request"
                Send a request directly to a LWP::UserAgent request method.
                These arguments of the requst may be in the form of
                key=>value, or multiples of k1=>v1, k2=>v2. Complex
                structures are not supported.

                Usage:

                  # For GET/DELETE supply each k=>v pair as a new array element
                  $client->thin_request('GET', $URI, key1=> val1, key2 => val2);

                  # For POST/PUT if you wrap the k=>v pairs into a structure they will be sent as form data
                  $client->thin_request('PUT', $URI, {key1 => val1, key2 => val2});

                Example:

                  my $res = $client->thin_request('POST', "public/auth", { user => $user, pass => $pass });

    "is_success"
                Shortcut to the whether the last response succeeded

    "response_code"
                Returns the response code of the last request.

    "response_header"
                    my $ctype = $client->response_header('Content-Type');

                Returns the value of a selected response header of the last
                request.

    "response_body"
                Returns a string of the response body of the last request.

    "debug"     Dump information on every request(). Set to undef, {}, or a
                hashref of configuration flags.

                "undef"     The default level: don't dump anything.

                "{}"        Dump the LWP object's default header object,
                            request object, and response object.

                "{trim_tokens =" 0}>
                            Whether to trim tokens.

```
