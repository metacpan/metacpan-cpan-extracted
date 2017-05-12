use strict;
use warnings;
use Plack::Builder;
use Plack::App::File;
use Plack::Request;
use Plack::Util;
use Plack::Middleware::CrossOrigin;
use Socket;

# Adjust these values to test how browsers respond to the different headers
my $co_mw = Plack::Middleware::CrossOrigin->new(
    origins => '*',
    methods => '*',
    expose_headers => '*',
    max_age => 0,
);

sub alt_addr {
    my $address = shift;
    if ($address =~ /^[\d.]+$/) {
        return gethostbyaddr(inet_aton($address), AF_INET);
    }
    else {
        no warnings;
        return ( eval { inet_ntoa(inet_aton($address)) } || $address );
    }
}

builder {
    enable sub {
        my $app = shift;
        sub {
            my $env = shift;
            if ($env->{'psgi.multithread'} || $env->{'psgi.multiprocess'}) {
                return [401, ['Content-Type' => 'text/plain'], ['Unsupported server.  Please use a single threaded, single process server.']];
            }
            $app->($env);
        };
    };
    my $last_cors = '';
    mount '/last_cors' => sub {
        my $out = $last_cors;
        $last_cors = '';
        [200, ['Content-Type' => 'text/plain'], [$out]];
    };
    mount '/cors' => builder {
        my $main_app_run;
        enable sub {
            my $app = shift;
            sub {
                my $env = shift;
                my $req = Plack::Request->new($env);
                $main_app_run = undef;
                my $in_head = $req->headers;
                return Plack::Util::response_cb($app->($env), sub {
                    my $res = shift;
                    my $preflight = $req->method eq 'OPTIONS' && $in_head->header('Access-Control-Request-Method');
                    if ( $preflight ) {
                        $last_cors .= "Preflight request:\n";
                    }
                    else {
                        $last_cors .= "Actual request:\n";
                    }
                    if ( $main_app_run ) {
                        $last_cors .= "  Main Plack app run\n";
                    }

                    $last_cors .= "  Incoming:\n";
                    $last_cors .= sprintf "    Method:    %s\n", $req->method;
                    if ( defined $in_head->header('Origin') ) {
                        $last_cors .= sprintf "    Origin:    %s\n", $in_head->header('Origin');
                    }
                    $in_head->scan( sub {
                        my ($k, $v) = @_;
                        return
                            unless $k =~ /^Access-Control/i;
                        $k =~ s/\b(\w)(\w+)\b/\u$1\L$2/g;
                        $last_cors .= sprintf "    %s:    %s\n", $k, $v;
                    } );
                    $last_cors .= "  Response:\n";
                    $last_cors .= sprintf "    Status code:    %s\n", $res->[0];

                    my %out_headers = @{ $res->[1] };
                    my @cors_headers = grep { /^Access-Control/i } keys %out_headers;
                    for my $header (@cors_headers) {
                        for my $value (Plack::Util::header_get($res->[1], $header)) {
                            $last_cors .= sprintf "    %-30s: %s\n", $header, $value;
                        }
                    }
                    my $will_browser_see = !( $preflight || ( $in_head->header('Origin') && ! @cors_headers) );
                    if ($will_browser_see) {
                        $res->[2] = [$last_cors];
                        $last_cors = '';
                    }
                });
            };
        };
        enable sub { $co_mw->wrap($_[0]) };
        sub {
            $main_app_run = 1;
            [ 200, ['X-Some-Other-Header' => 1, 'Content-Type' => 'text/plain'], [ 'output' ] ]
        };
    };
    mount '/' => sub {
        my $env = shift;
        my $req = Plack::Request->new($env);

        my $cors = $req->base;
        $cors->host(alt_addr($cors->host));
        $cors->path($cors->path . 'cors');


        my $last_cors_url = $req->base;
        $last_cors_url->path($last_cors_url->path . 'last_cors');

        return [ 200, ['Content-Type' => 'text/html'], [
            sprintf <<'END_HTML', $cors->scheme, $cors->host_port, $cors->path_query, $last_cors_url ] ];
<!DOCTYPE html>
<html>
<head>
    <title>CORS Test</title>
    <style type="text/css">
        textarea, .url, .url * {
            font-family: monospace;
        }
        #standard-form {
            display: none;
        }
        iframe, textarea {
            border: 1px solid #000;
        }
    </style>
</head>
<body>
    <div>
        <form id="standard-form" target="standard-form-submit" method="post"></form>
        <form id="cors-form">
            <div>Requesting from <span class="url">%s://<input type="text" id="request-host" value="%s" />%s</span></div>
            <div>
                Request Type :
                <label><input type="radio" name="request-type" id="request-type-xhr" checked="checked" /> XMLHttpRequest</label>
                <label><input type="radio" name="request-type" id="request-type-form" /> Form</label>
            </div>
            <div>
                <label>Method :
                    <select id="request-method">
                        <option value="GET">GET</option>
                        <option value="POST">POST</option>
                        <option value="OPTIONS">OPTIONS</option>
                        <option value="PUT">PUT</option>
                        <option value="MODIFY">MODIFY</option>
                    </select>
                </label>
            </div>
            <fieldset style="width: 12em">
                <legend>Headers</legend>
                <div><label><input type="checkbox" id="x-requested-with" /> Add X-Requested-With</label></div>
                <div><label><input type="checkbox" id="x-something-else" /> Add X-Something-Else</label></div>
            </fieldset>
            <div><input type="submit" value="Send Request" id="send-request" /></div>
            <hr />
            <div>Result Status: <span id="result-status"></span></div>
            <div>Results: <div>
                <textarea cols="100" rows="20" readonly="readonly" id="results"></textarea>
                <iframe id="results-iframe" name="standard-form-submit" src="about:blank"></iframe>
            </div></div>
        </form>
    </div>
    <script type="text/javascript">
        (function(){
            var form = document.getElementById('cors-form');
            var results = document.getElementById('results');
            var resultsiframe = document.getElementById('results-iframe');
            var status = document.getElementById('result-status');
            var method = document.getElementById('request-method');
            var host = document.getElementById('request-host');
            var xrequestedwith = document.getElementById('x-requested-with');
            var xsomethingelse = document.getElementById('x-something-else');
            var rt_xhr = document.getElementById('request-type-xhr');
            var rt_form = document.getElementById('request-type-form');

            var listen;
            if (form.addEventListener) {
                listen = function(el, ev, func) {
                    el.addEventListener(ev, func, false);
                };
            }
            else if (form.attachEvent) {
                listen = function(el, ev, func) {
                    el.attachEvent('on'+ev, func);
                };
            }

            rt_xhr.checked = true;
            method.disabled = false;
            results.style.display = 'block';
            resultsiframe.style.display = 'none';

            results.value = '';
            var noheaders;
            if (typeof XMLHttpRequest != "undefined" && ("withCredentials" in ( new XMLHttpRequest() ) ) ) {}
            else if (typeof XDomainRequest != "undefined") {
                noheaders = true;
                xrequestedwith.disabled = true;
                xrequestedwith.checked = false;
                xsomethingelse.disabled = true;
                xsomethingelse.checked = false;
            }
            else {
                status.innerHTML = 'Unsupported browser';
                document.getElementById('send-request').disabled = true;
                return;
            }

            var formsubmit = function(e) {
                e = e || window.event;
                if (e.preventDefault)
                    e.preventDefault();
                e.returnValue = false;
                results.value = '';
                var request_address = "%1$s://"+host.value+"%3$s?no_cache="+(new Date()).getTime();
                if (rt_xhr.checked) {
                    var xhr = new XMLHttpRequest();
                    if ("withCredentials" in xhr){
                        xhr.open(method.value, request_address, true);
                    }
                    else if (typeof XDomainRequest != "undefined") {
                        xhr = new XDomainRequest();
                        try {
                            xhr.open(method.value, request_address);
                        }
                        catch(e) {
                            status.innerHTML = 'Unsupported method';
                            return;
                        }
                    }
                    else {
                        status.innerHTML = 'Unsupported browser';
                        return;
                    }
                    if (xrequestedwith.checked) {
                        xhr.setRequestHeader('X-Requested-With', 'XMLHttpRequest');
                    }
                    if (xsomethingelse.checked) {
                        xhr.setRequestHeader('X-Something-Else', 'something-else');
                    }

                    var complete = function() {
                        if (xhr.status == 200) {
                            status.innerHTML = 'Success';
                            results.value = xhr.responseText;
                            if (xhr.getResponseHeader) {
                                if (xhr.getResponseHeader('X-Some-Other-Header')) {
                                    results.value += "\nExtra header was exposed\n";
                                }
                                else {
                                    results.value += "\nExtra header was not exposed\n";
                                }
                            }
                            else {
                                results.value += "\nExtra headers are unsupported\n";
                            }
                        }
                        else {
                            status.innerHTML = 'Failure';
                            var xhr2 = new XMLHttpRequest();
                            xhr2.open('GET', '%4$s?no_cache='+(new Date()).getTime(), true);
                            xhr2.onreadystatechange = function() {
                                if (xhr2.readyState == 4) {
                                    results.value = xhr2.responseText;
                                }
                            };
                            xhr2.send();
                        }
                    };

                    if ('onreadystatechange' in xhr) {
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState == 4) {
                                complete();
                            }
                        };
                    }
                    // XDomainRequest uses different events and has no status property
                    else if ('onload' in xhr) {
                        xhr.onload = function() {
                            xhr.status = 200;
                            complete();
                        };
                        xhr.onerror = function() {
                            xhr.status = 500;
                            complete();
                        };
                    }
                    status.innerHTML = 'Running';
                    xhr.send();
                    return false;
                }
                else {
                    var st_form = document.getElementById("standard-form");
                    st_form.action = request_address;
                    st_form.submit();
                }
            };

            listen(form, 'submit', formsubmit);
            listen(rt_xhr, 'click', function() {
                method.disabled = false;
                results.style.display = 'block';
                resultsiframe.style.display = 'none';
                if (! noheaders) {
                    xrequestedwith.disabled = false;
                    xsomethingelse.disabled = false;
                }
            });
            listen(rt_form, 'click', function() {
                method.value = 'POST';
                method.disabled = true;
                xrequestedwith.disabled = true;
                xsomethingelse.disabled = true;
                resultsiframe.width = results.clientWidth;
                resultsiframe.height = results.clientHeight;
                results.style.display = 'none';
                resultsiframe.style.display = 'block';
            });
        })();
    </script>
</body>
</html>
END_HTML
    };
};

