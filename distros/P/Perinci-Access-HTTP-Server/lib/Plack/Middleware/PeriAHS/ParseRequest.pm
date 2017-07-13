package Plack::Middleware::PeriAHS::ParseRequest;

our $DATE = '2017-07-10'; # DATE
our $VERSION = '0.61'; # VERSION

use 5.010;
use strict;
use warnings;
use Log::ger;

use Perinci::AccessUtil qw(insert_riap_stuffs_to_res decode_args_in_riap_req);
use Perinci::Access::Base::Patch::PeriAHS;

use parent qw(Plack::Middleware);
use Plack::Request;
use Plack::Util::Accessor qw(
                                riap_uri_prefix
                                server_host
                                server_port
                                server_path

                                match_uri
                                match_uri_errmsg
                                parse_form
                                parse_reform
                                parse_path_info
                                accept_yaml

                                riap_client
                                use_tx
                                custom_tx_manager

                                php_clients_ua_re
                                deconfuse_php_clients
                        );

use Perinci::Access::Schemeless;
use Perinci::Sub::GetArgs::Array qw(get_args_from_array);
use Plack::Util::PeriAHS qw(errpage);
use Scalar::Util qw(blessed);
use URI::Escape;

# retun ($success?, $errmsg, $res)
sub __parse_json {
    require Data::Clean::FromJSON;
    require JSON::MaybeXS;

    my $str = shift;

    state $json = JSON::MaybeXS->new->allow_nonref;

    # to rid of those JSON::XS::Boolean objects which currently choke
    # Data::Sah-generated validator code. in the future Data::Sah can be
    # modified to handle those, or we use a fork of JSON::XS which doesn't
    # produce those in the first place (probably only when performance is
    # critical).
    state $cleanser = Data::Clean::FromJSON->get_cleanser;

    my $res;
    eval { $res = $json->decode($str); $cleanser->clean_in_place($res) };
    my $e = $@;
    return (!$e, $e, $res);
}

sub __parse_yaml {
    require YAML::Syck;

    my $str = shift;

    local $YAML::Syck::ImplicitTyping = 1;
    my $res;
    eval { $res = YAML::Syck::Load($str) };
    my $e = $@;
    return (!$e, $e, $res);
}

sub get_server_url {
    my ($self, $env) = @_;
    my $host = $self->{server_host};
    unless (defined $host) {
        $host = $env->{HTTP_HOST} =~ /(.+):(.+)/ ? $1 : $env->{HTTP_HOST};
    }
    my $port = $self->{server_port};
    unless (defined $port) {
        $port = $env->{HTTP_HOST} =~ /(.+):(.+)/ ? $2 :
            ($env->{HTTPS} ? 443 : 80);
    }
    join("",
         ($env->{HTTPS} ? "https" : "http"), "://",
         $host,
         $port == ($env->{HTTPS} ? 443:80) ? "" : ":$port",
         $self->{server_path},
         "/",
     );
}

sub prepare_app {
    my $self = shift;

    $self->{riap_uri_prefix}      //= '';
    $self->{server_host}          //= undef;
    $self->{server_port}          //= undef;
    $self->{server_path}          //= '/api';
    $self->{server_path} =~ s!/\z!!;
    $self->{get_http_request_url} //= sub {
        my ($self, $env, $rreq) = @_;
        my $uri = $rreq->{uri};
        return unless $uri =~ m!^/! || $uri =~ s/^pl://;
        $uri =~ s/\A\Q$self->{riap_uri_prefix}\E//;
        $uri =~ s!^/!!;
        join("",
             $self->get_server_url($env),
             $uri
         );
    };

    $self->{match_uri}         //= qr/(?<uri>[^?]*)/;
    $self->{accept_yaml}       //= 0;
    $self->{parse_form}        //= 1;
    $self->{parse_reform}      //= 0;
    $self->{parse_path_info}   //= 0;
    $self->{use_tx}            //= 0;
    $self->{custom_tx_manager} //= undef;

    $self->{riap_client}       //= Perinci::Access::Schemeless->new(
        load => 0,
        set_function_properties => {
            #timeout => 300,
        },
        use_tx            => $self->{use_tx},
        custom_tx_manager => $self->{custom_tx_manager},
    );

    $self->{php_clients_ua_re} //= qr(Phinci|/php|php/)i;
    $self->{deconfuse_php_clients} //= 1;

    log_trace("Prepared PeriAHS::ParseRequest middleware: %s", $self);
}

sub call {
    my ($self, $env) = @_;
    log_trace("=> PeriAHS::ParseRequest middleware");

    my $rreq = $env->{"riap.request"} //= {};

    # put Riap client for later phases
    $env->{"periahs.riap_client"} = $self->{riap_client};

    # first determine the default output format (fmt), so we can return error
    # page in that format
    my $acp = $env->{HTTP_ACCEPT} // "";
    my $ua  = $env->{HTTP_USER_AGENT} // "";
    my $fmt;
    if ($acp =~ m!^text/(?:x-)?yaml$!) {
        $fmt = "yaml";
    } elsif ($acp eq 'application/json') {
        $fmt = "json";
    } elsif ($acp eq 'text/plain') {
        $fmt = "text";
    } elsif ($ua =~ m!Wget/|curl/!) {
        $fmt = "text";
    } elsif ($ua =~ m!Mozilla/!) {
        $fmt = "json";
        # XXX enable json->html templating
    } else {
        $fmt = "json";
    }
    $env->{"periahs.default_fmt"} = $fmt;

    my ($decsuc, $decerr); # json/yaml decoding success status & error message

    # parse Riap request keys from HTTP headers (required by spec)
    for my $k0 (keys %$env) {
        next unless $k0 =~ /\AHTTP_X_RIAP_(.+?)(_J_)?\z/;
        my $v = $env->{$k0};
        my ($k, $encj) = (lc($1), $2);
        # already ensured by Plack
        #$k =~ /\A\w+\z/ or return errpage(
        #    $env, [400, "Invalid Riap request key syntax in HTTP header $k0"]);
        if ($encj) {
            ($decsuc, $decerr, $v) = __parse_json($v);
            return errpage(
                $env, [400, "Invalid JSON in HTTP header $k0: $decerr"])
                if !$decsuc;
        }
        $rreq->{$k} = $v;
    }

    # parse args from request body (required by spec)
    my $preq = Plack::Request->new($env);
    unless (exists $rreq->{args}) {
        {
            my $ct = $env->{CONTENT_TYPE};
            last unless $ct;
            last if $ct eq 'application/x-www-form-urlencoded';
            return errpage(
                $env, [400, "Unsupported request content type '$ct'"])
                unless $ct eq 'application/json' ||
                    $ct eq 'text/yaml' && $self->{accept_yaml};
            if ($ct eq 'application/json') {
                #$log->trace('Request body is JSON');
                ($decsuc,$decerr, $rreq->{args}) = __parse_json($preq->content);
                return errpage(
                    $env, [400, "Invalid JSON in request body: $decerr"])
                    if !$decsuc;
            #} elsif ($ct eq 'application/vnd.php.serialized') {
            #    #$log->trace('Request body is PHP serialized');
            #    request PHP::Serialization;
            #    eval { $args = PHP::Serialization::unserialize($body) };
            #    return errpage(
            #        $env, [400, "Invalid PHP serialized data in request body"])
            #        if $@;
            } elsif ($ct eq 'text/yaml') {
                ($decsuc,$decerr, $rreq->{args}) = __parse_yaml($preq->content);
                return errpage(
                    $env, [400, "Invalid YAML in request body: $decerr"])
                    if !$decsuc;
            }
        }
    }

    # special handling for php clients #1
    my $rcua = $rreq->{ua};
    if ($self->{deconfuse_php_clients} &&
            $rcua && $rcua =~ $self->{php_clients_ua_re}) {
        if (ref($rreq->{args}) eq 'ARRAY' && !@{ $rreq->{args} }) {
            $rreq->{args} = {};
        }
    }

    return errpage(
        $env, [400, "Riap request key 'args' must be hash"])
        unless !defined($rreq->{args}) || ref($rreq->{args}) eq 'HASH'; # sanity

    # get uri from 'match_uri' config
    my $mu  = $self->{match_uri};
    if ($mu && !exists($rreq->{uri})) {
        my $uri = $env->{REQUEST_URI};
        my %m;
        if (ref($mu) eq 'ARRAY') {
            $uri =~ $mu->[0] or return errpage(
                $env, [404, $self->{match_uri_errmsg} //
                           "Request does not match match_uri[0] $mu->[0]"]);
            %m = %+;
            $mu->[1]->($env, \%m);
        } else {
            $uri =~ $mu or return errpage(
                $env, [404, $self->{match_uri_errmsg} //
                           "Request does not match match_uri $mu"]);
            %m = %+;
            for (keys %m) {
                $rreq->{$_} //= $m{$_};
            }
        }
        if (defined $rreq->{uri}) {
            $rreq->{uri} =~ s!\A\Q$self->{server_path}!!;
        }
    }

    # get riap request key from form variables (optional)
    if ($self->{parse_form}) {
        my $form = $preq->parameters;
        $env->{'periahs._form_cache'} = $form;

        # special name 'callback' is for jsonp
        if (($rreq->{fmt} // $env->{"periahs.default_fmt"}) eq 'json' &&
                defined($form->{callback})) {
            return errpage(
                $env, [400, "Invalid callback syntax, please use ".
                           "a valid JS identifier"])
                unless $form->{callback} =~ /\A[A-Za-z_]\w*\z/;
            $env->{"periahs.jsonp_callback"} = $form->{callback};
            delete $form->{callback};
        }

        while (my ($k, $v) = each %$form) {
            if ($k =~ /(.+):j$/) {
                $k = $1;
                #$log->trace("CGI parameter $k (json)=$v");
                ($decsuc, $decerr, $v) = __parse_json($v);
                return errpage(
                    $env, [400, "Invalid JSON in query parameter $k: $decerr"])
                    if !$decsuc;
            } elsif ($k =~ /(.+):y$/) {
                $k = $1;
                #$log->trace("CGI parameter $k (yaml)=$v");
                return errpage($env, [400, "YAML form variable unacceptable"])
                    unless $self->{accept_yaml};
                ($decsuc, $decerr, $v) = __parse_yaml($v);
                return errpage(
                    $env, [400, "Invalid YAML in query parameter $k: $decerr"])
                    if !$decsuc;
            #} elsif ($k =~ /(.+):p$/) {
            #    $k = $1;
            #    #$log->trace("PHP serialized parameter $k (php)=$v");
            #    return errpage($env, [400, "PHP serialized form variable ".
            #                              "unacceptable"])
            #        unless $self->{accept_phps};
            #    require PHP::Serialization;
            #    eval { $v = PHP::Serialization::unserialize($v) };
            #    return errpage(
            #        $env, [400, "Invalid PHP serialized data in ".
            #                       "query parameter $k: $@") if $@;
            }
            if ($k =~ /\A-riap-([\w-]+)/) {
                my $rk = lc $1; $rk =~ s/-/_/g;
                return errpage(
                    $env, [400, "Invalid Riap request key `$rk` (from form)"])
                    unless $rk =~ /\A\w+\z/;
                $rreq->{$rk} = $v unless exists $rreq->{$rk};
            } else {
                $rreq->{args}{$k} = $v unless exists $rreq->{args}{$k};
            }
        }
    }

    if ($self->{parse_reform} && $env->{'periahs._form_cache'} &&
            $env->{'periahs._form_cache'}{'-submit'}) {
        {
            last unless $rreq->{uri};
            my $res = $env->{'periahs._meta_res_cache'} //
                $self->{riap_client}->request(meta => $rreq->{uri});
            return errpage($env, [$res->[0], $res->[1]])
                unless $res->[0] == 200;
            $env->{'periahs._meta_res_cache'} //= $res;
            my $meta = $res->[2];
            last unless $meta;
            last unless $meta->{args};

            require ReForm::HTML;
            require Perinci::Sub::To::ReForm;
            my $rf = ReForm::HTML->new(
                spec => Perinci::Sub::To::ReForm::gen_form_spec_from_rinci_meta(
                    meta => $meta,
                )
            );
            $res = $rf->get_data(psgi_env => $env);
            return errpage($env, [$res->[0], $res->[1]])
                unless $res->[0] == 200;
            $rreq->{args} = $res->[2];
        }
    }

    if ($self->{parse_path_info}) {
        {
            last unless $rreq->{uri};
            my $res = $env->{'periahs._meta_res_cache'} //
                $self->{riap_client}->request(meta => $rreq->{uri});
            return errpage($env, [$res->[0], $res->[1]])
                unless $res->[0] == 200;
            $env->{'periahs._meta_res_cache'} //= $res;
            my $meta = $res->[2];
            last unless $meta;
            last unless $meta->{args};

            my $pi = $env->{PATH_INFO} // "";
            $pi =~ s!^/+!!;
            my @pi = map {uri_unescape($_)} split m!/+!, $pi;
            $res = get_args_from_array(array=>\@pi, meta=>$meta);
            return errpage(
                $env, [500, "Bad metadata for function $rreq->{uri}: ".
                           "Can't get arguments: $res->[0] - $res->[1]"])
                unless $res->[0] == 200;
                for my $k (keys %{$res->[2]}) {
                    $rreq->{args}{$k} //= $res->[2]{$k};
                }
        }
    }

    # defaults
    $rreq->{v}      //= 1.1;
    $rreq->{fmt}    //= $env->{"periahs.default_fmt"};
    if (!$rreq->{action}) {
        if ($rreq->{uri} =~ m!/$!) {
            $rreq->{action} = 'list';
            $rreq->{detail} //= 1;
        } else {
            $rreq->{action} = 'call';
        }
    }

    # sanity: check required keys
    for (qw/uri v action/) {
        defined($rreq->{$_}) or return errpage(
            $env, [500, "Required Riap request key '$_' has not been defined"]);
    }

    # add uri prefix
    $rreq->{uri} = "$self->{riap_uri_prefix}$rreq->{uri}";

    # special handling for php clients #2
    {
        last unless $self->{deconfuse_php_clients} &&
            $rcua && $rcua =~ $self->{php_clients_ua_re};
        my $rargs = $rreq->{args};
        last unless $rargs;

        # XXX this is repetitive, must refactor
        my $res = $env->{'periahs._meta_res_cache'} //
            $self->{riap_client}->request(meta => $rreq->{uri});
        return errpage($env, [$res->[0], $res->[1]])
            unless $res->[0] == 200;
        $env->{'periahs._meta_res_cache'} //= $res;
        my $meta = $res->[2];

        if ($meta->{args}) {
            for my $arg (keys %$rargs) {
                my $argm = $meta->{args}{$arg};
                if ($argm && $argm->{schema}) {
                    # convert {} -> [] if function expects array
                    if (ref($rargs->{$arg}) eq 'HASH' &&
                            !keys(%{$rargs->{$arg}}) &&
                                $argm->{schema}[0] eq 'array') {
                        $rargs->{$arg} = [];
                    }
                    # convert [] -> {} if function expects hash
                    if (ref($rargs->{$arg}) eq 'ARRAY' &&
                            !@{$rargs->{$arg}} &&
                                $argm->{schema}[0] eq 'hash') {
                        $rargs->{$arg} = {};
                    }
                }
            }
        }
    }

    # Riap 1.2: decode base64-encoded args
    decode_args_in_riap_req($rreq);

    log_trace("Riap request: %s", $rreq);

    # expose configuration for other middlewares
    $env->{"middleware.PeriAHS.ParseRequest"} = $self;

    # continue to app
    $self->app->($env);
}

1;
# ABSTRACT: Parse Riap request from HTTP request

__END__

=pod

=encoding UTF-8

=head1 NAME

Plack::Middleware::PeriAHS::ParseRequest - Parse Riap request from HTTP request

=head1 VERSION

This document describes version 0.61 of Plack::Middleware::PeriAHS::ParseRequest (from Perl distribution Perinci-Access-HTTP-Server), released on 2017-07-10.

=head1 SYNOPSIS

 # in your app.psgi
 use Plack::Builder;

 builder {
     enable "PeriAHS::ParseRequest",
         match_uri => m!^/api(?<uri>/[^?]*)!;
 };

=head1 DESCRIPTION

This middleware's task is to parse Riap request from HTTP request (PSGI
environment) and should normally be the first middleware put in the stack.

=head2 Parsing result

The result of parsing will be put in C<< $env->{"riap.request"} >> hashref.

Aside from that, this middleware also sets these for convenience of later
middlewares:

=over 4

=item * $env->{'periahs.default_fmt'} => STR

Default output format, will be used for response if C<fmt> is not specified in
Rinci request. Determined using some simple heuristics, i.e. graphical browser
like Firefox or Chrome will get 'HTML', command-line browser like Wget or Curl
will get 'Text', others will get 'json'.

=item * $env->{'periahs.jsonp_callback'} => STR

From form variable C<callback>.

=item * $env->{'periahs.riap_client'} => OBJ

Store the Riap client (by default instance of L<Perinci::Access::Schemeless>).

=back

=head2 Parsing process

B<From HTTP header and request body>. First parsing is done as per L<Riap::HTTP>
specification's requirement. All C<X-Riap-*> request headers are parsed for Riap
request key. When an unknown header is found, HTTP 400 error is returned. Then,
request body is read for C<args>. C<application/json> document type is accepted,
and also C<text/yaml> (if C<accept_yaml> configuration is enabled).

Additionally, the following are also done:

B<From URI>. Request URI is checked against B<match_uri> configuration (This
step will be skipped if B<match_uri> configuration is not set or empty). If URI
doesn't match this regex, a 404 error response is returned. It is a convenient
way to check for valid URLs as well as set Riap request keys, like:

 qr!^/api/(?<fmt>json|yaml)/!;

The default C<match_uri> is qr/(?<uri>[^?]*)/.

B<From form variables>. If B<parse_form> configuration is enabled, C<args>
request key will be set (or added) from GET/POST request variables, for example:
http://host/api/foo/bar?a=1&b:j=[2] will set arguments C<a> and C<b> (":j"
suffix means value is JSON-encoded; ":y" is also accepted if the C<accept_yaml>
configurations are enabled). In addition, request variables C<-riap-*> are also
accepted for setting other Riap request keys. Unknown Riap request key or
encoding suffix will result in 400 error.

If request format is JSON and form variable C<callback> is defined, then it is
assumed to specify callback for JSONP instead part of C<args>. "callback(json)"
will be returned instead of just "json".

B<From form variables (2, ReForm)>. PeriAHS has support for L<ReForm>. If
B<parse_reform> configuration is set to true and form variable C<-submit> is
also set to true, then the resulting C<args> from previous step will be further
fed to ReForm object. See the "parse_reform" in the configuration documentation.

C<From URI (2, path info)>. If C<parse_path_info> configuration is enabled, and
C<uri> Riap request key has been set (so metadata can be retrieved), C<args>
will be set (or added) from URI path info. See "parse_path_info" in the
configuration documentation.

 http://host/api/v1/Module::Sub/func/a1/a2/a3

will result in ['a1', 'a2', 'a3'] being fed into
L<Perinci::Sub::GetArgs::Array>. An unsuccessful parsing will result in HTTP 400
error.

=for Pod::Coverage .*

=head1 CONFIGURATIONS

=over 4

=item * riap_uri_prefix => STR (default: '')

If set, Riap request C<uri> will be prefixed by this. For example, you are
exposing Perl modules at C<YourApp::API::*> (e.g. C<YourApp::API::Module1>. You
want to access this module via Riap request uri C</Module1/func> instead of
C</YourApp/API/Module1/func>. In that case, you can set B<riap_uri_prefix> to
C</YourApp/API/> (notice the ending slash).

=item * server_host => STR

Set server host. Used by B<get_http_request_url>. The default will be retrieved
from PSGI environment C<HTTP_HOST>.

=item * server_port => STR

Set server port. Used by B<get_http_request_url>. The default will be retrieved
from PSGI environment C<HTTP_HOST>.

=item * server_path => STR (default: '/api')

Set server URI path. Used by C<get_http_request_url>.

=item * get_http_request_url => CODE (default: code)

Should be set to code that returns HTTP request URL. Code will be passed
C<($self, $env, $rreq)>, where C<$rreq> is the Riap request hash. The default
code will return something like:

 http(s)://<SERVER_HOST>:<SERVER_PORT><SERVER_PATH><RIAP_REQUEST_URI>

for example:

 https://cpanlists.org/api/get_list

This code is currently used by the B<PeriAHS::Respond> middleware to print
text hints.

Usually you do not need to customize this, you can already do some customization
by setting B<server_path> or B<riap_uri_prefix>, unless you have a more custom
URL scheme.

=item * match_uri => REGEX or [REGEX, CODE] (default qr/.?/)

This provides an easy way to extract Riap request keys (typically C<uri>) from
HTTP request's URI. Put named captures inside the regex and it will set the
corresponding Riap request keys, e.g.:

 qr!^/api(?<uri>/[^?]*)!

If you need to do some processing, you can also specify a 2-element array
containing regex and code. When supplied this, the middleware will NOT
automatically set Riap request keys with the named captures; instead, your code
should do it. Code will be supplied ($env, \%match) and should set
$env->{'riap.request'} as needed. An example:

 match_uri => [
     qr!^/api
        (?: /(?<module>[\w.]+)?
          (?: /(?<func>[\w+]+) )?
        )?!x,
     sub {
         my ($env, $match) = @_;
         if (defined $match->{module}) {
             $match->{module} =~ s!\.!/!g;
             $env->{'riap.request'}{uri} = "/$match->{module}/" .
                 ($match->{func} // "");
         }
     }];

Given URI C</api/Foo.Bar/baz>, C<uri> Riap request key will be set to
C</Foo/Bar/baz>.

=item * match_uri_errmsg => STR

Show custom error message when URI does not match C<match_uri>.

=item * accept_yaml => BOOL (default 0)

Whether to accept YAML-encoded data in HTTP request body and form for C<args>
Riap request key. If you only want to deal with JSON, keep this off.

=item * parse_form => BOOL (default 1)

Whether to parse C<args> keys and Riap request keys from form (GET/POST)
variable of the name C<-x-riap-*> (notice the prefix dash). If an argument is
already defined (e.g. from request body) or request key is already defined (e.g.
from C<X-Riap-*> HTTP request header), it will be skipped.

=item * parse_reform => BOOL (default 0)

Whether to parse arguments in C<args> request key using L<ReForm>. Even if
enabled, will only be done if C<-submit> form variable is set to true.

This configuration is used only if you render forms using ReForm and want to
process the submitted form.

Form specification will be created (converted) from C<args> property in function
metadata, which means that a C<meta> Riap request to the backend will be
performed first to get this metadata.

=item * parse_path_info => BOOL (default 0)

Whether to parse arguments from $env->{PATH_INFO}. Note that this will require a
Riap C<meta> request to the backend, to get the specification for function
arguments. You'll also most of the time need to prepare the PATH_INFO first.
Example:

 parse_path_info => 1,
 match_uri => [
     qr!^/ga/(?<mod>[^?/]+)(?:
            /?(?:
                (?<func>[^?/]+)?:
                (<pi>/?[^?]*)
            )
        )!x,
     sub {
         my ($env, $m) = @_;
         $m->{mod} =~ s!::!/!g;
         $m->{func} //= "";
         $env->{'riap.request'}{uri} = "/$m->{mod}/$m->{func}";
         $env->{PATH_INFO} = $m->{pi};
     },
 ]

=item * riap_client => OBJ

By default, a L<Perinci::Access::Schemeless> object will be instantiated (and
later put into C<$env->{'periahs.riap_client'}> for the next middlewares) to
perform Riap requests. You can supply a custom object here, for example the more
general L<Perinci::Access> object to allow requesting from remote URLs.

=item * use_tx => BOOL (default 0)

Will be passed to L<Perinci::Access::Schemeless> constructor.

=item * custom_tx_manager => STR|CODE

Will be passed to L<Perinci::Access::Schemeless> constructor.

=item * php_clients_ua_re => REGEX (default: qr(Phinci|/php|php/)i)

What regex should be used to identify PHP Riap clients. Riap clients often
(should) send C<ua> key identifying itself, e.g. C<Phinci/20130308.1>,
C<Perinci/0.12>, etc.

=item * deconfuse_php_clients => BOOL (default: 1)

Whether to do special handling for PHP Riap clients (identified by
C<php_clients_ua_re>). PHP clients often confuse empty array C<[]> with empty
hash C<{}>, since both are C<Array()> in PHP. If this setting is turned on, the
server makes sure C<args> becomes C<{}> when client sends C<[]>, and C<{}>
arguments become C<[]> or vice versa according to hint provided by function
metadata.

=back

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Perinci-Access-HTTP-Server>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Perinci-Access-HTTP-Server>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Perinci-Access-HTTP-Server>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Perinci::Access::HTTP::Server>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017, 2015, 2014, 2013, 2012, 2011 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
