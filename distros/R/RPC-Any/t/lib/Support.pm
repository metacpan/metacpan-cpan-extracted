package Support;
use strict;
use base qw(Exporter);
use Carp;
use Data::Dumper qw(Dumper);
use File::Spec;
use HTTP::Request;
use HTTP::Response;
use IO::File;
use MIME::Base64;
use JSON;
use JSON::RPC::Common::Marshal::Text;
use JSON::RPC::Common::Procedure::Call;
use RPC::Any::Exception;
use RPC::XML;
use Scalar::Util qw(tainted);
use Storable qw(dclone);
use Taint::Util qw(taint);
use Test::More;
use Test::Exception;
use WSTest;

our @EXPORT_OK = qw(
    all_modules
    extract_versioned_tests
    test_jsonrpc
    test_xmlrpc
);

# Really, this is high iso-8859-1.
use constant HIGH_ASCII    => "\x{00A9}\x{00C5}\x{00DF}"; # ©Åß
use constant UNICODE_THREE => "\x{0100}\x{010A}\x{0114}"; # ĀĊĔ
use constant UNICODE_FOUR  => "\x{1000}\x{1001}\x{1002}"; # ကခဂ
use constant UNICODE_FIVE  => "\x{10008}\x{10009}\x{1000A}"; # 𐀈𐀉𐀊

use constant SERVER_TESTS => (
    hello => {
        method  => 'hello',
        returns => 'Hello!',
        return_type => 'string',
    },
    hello_fh => {
        method  => 'hello',
        returns => 'Hello!',
        return_type => 'string',
        use_fh  => 1,
    },
    struct => {
        method  => 'struct',
        returns => WSTest::RETURN_STRUCT,
        return_type => 'struct',
    },
    array => {
        method  => 'array',
        returns => WSTest::RETURN_ARRAY,
        return_type => 'array',
    },
    return_array => {
        method  => 'return_this',
        params  => WSTest::RETURN_ARRAY,
        returns => WSTest::RETURN_ARRAY,
        return_type => 'array',
    },
    return_struct => {
        method  => 'return_this',
        params  => WSTest::RETURN_STRUCT,
        returns => WSTest::RETURN_STRUCT,
        return_type => 'struct',
    },
    return_string => {
        method  => 'return_this',
        params  => 'A string',
        returns => 'A string',
        return_type => 'string',
    },
    return_int => {
        method  => 'return_this',
        params  => 123,
        returns => 123,
        return_type => 'int',
    },
    return_double => {
        method  => 'return_this',
        params  => 2.2,
        returns => 2.2,
        return_type => 'double',
    },
    return_nil => {
        method  => 'return_this',
        params  => undef,
        returns => undef,
        return_type => 'nil',
    },
    allow_constants => {
        method  => 'RETURN_ARRAY',
        returns => WSTest::RETURN_ARRAY,
        return_type => 'array',
        allow_constants => 1,
    },
    is_tainted => {
        method  => 'is_tainted',
        returns => 1,
        params  => $0,
        return_type => 'int',
    },
    is_not_tainted => {
        method  => 'is_tainted',
        returns => 0,
        params  => 'foo',
        return_type => 'int',
    },
    
    #################
    # Unicode Tests #
    #################

    no_params_unicode_output => {
        method  => 'always_utf8',
        returns => WSTest::UNICODE_STRING,
        return_type => 'string',
    },
    high_ascii => {
        method => 'return_utf8',
        params  => HIGH_ASCII,
        returns => { 1 => HIGH_ASCII },
        return_type => 'struct',
    },
    unicode_3 => {
        method  => 'return_utf8',
        params  => UNICODE_THREE,
        returns => { 1 => UNICODE_THREE },
        return_type => 'struct',
    },
    unicode_4 => {
        method => 'return_utf8',
        params => UNICODE_FOUR,
        returns => { 1 => UNICODE_FOUR },
        return_type => 'struct',
    },
    unicode_5 => {
        method  => 'return_utf8',
        params  => UNICODE_FIVE,
        returns => { 1 => UNICODE_FIVE },
        return_type => 'struct',
    },
    high_ascii_string => {
        method => 'return_this',
        params  => HIGH_ASCII,
        returns => HIGH_ASCII,
        return_type => 'string',
        # RPC::Any tends to convert this ISO-8859-1 string into an identical
        # UTF-8 string, with the same exact numerical character values.
        # Although this is technically an alteration of the string, there
        # is no data loss involved, so I don't consider it a bug.
        skip_utf8_test => 1,
    },
    unicode_3_string => {
        method  => 'return_this',
        params  => UNICODE_THREE,
        returns => UNICODE_THREE,
        return_type => 'string',
    },
    unicode_4_string => {
        method => 'return_this',
        params => UNICODE_FOUR,
        returns => UNICODE_FOUR,
        return_type => 'string',
    },
    unicode_5_string => {
        method  => 'return_this',
        params  => UNICODE_FIVE,
        returns => UNICODE_FIVE,
        return_type => 'string',
    },

    ##############
    # Type Tests #
    ##############
    
    type_int => {
        method  => 'type_this',
        params  => ['int', '001'],
        returns => 1,
        return_type => 'int',
        expand_params => 1,
    },
    type_double => {
        method  => 'type_this',
        params  => ['double', '02.10'],
        returns => 2.1,
        return_type => 'double',
        expand_params => 1,
    },
    type_nil_string => {
        method  => 'type_this',
        params  => ['string', undef],
        returns => undef,
        return_type   => 'nil',
        expand_params => 1,
    },
    type_nil_explicit => {
        method  => 'type_this',
        params  => ['nil', 'A string'],
        returns => undef,
        return_type   => 'nil',
        expand_params => 1,
    },
    type_string => {
        method  => 'type_this',
        params  => ['string', '01234'],
        returns => '01234',
        return_type   => 'string',
        expand_params => 1,
    },
    type_string_from_int => {
        method  => 'type_this',
        params  => ['string', 1234],
        returns => '1234',
        return_type   => 'string',
        expand_params => 1,
    },
    type_base64 => {
        method => 'type_this',
        params => ['base64', 'foo bar'],
        returns => 'foo bar',
        return_type   => 'base64',
        expand_params => 1,
    },
    type_datetime => {
        method  => 'type_this',
        params  => ['dateTime', '1970-01-01T00:00:00Z'],
        returns => '1970-01-01T00:00:00Z',
        return_type   => 'dateTime',
        expand_params => 1,
    },
    type_boolean_true => {
        method  => 'type_this',
        params  => ['boolean', 1],
        returns => 1,
        return_type => 'boolean',
        expand_params => 1,
    },
    type_boolean_false => {
        method  => 'type_this',
        params  => ['boolean', 0],
        returns => 0,
        return_type => 'boolean',
        expand_params => 1,
    },
    
    #################
    # Failing calls #
    #################
    
    die_this => {
        method => 'die_this',
        params => 'Lorem ipsum dolor sit amet',
        return_type  => 'fault',
        exception    => 'PerlError',
        exception_re => qr/Lorem ipsum dolor sit amet/,
    },
    exception_this => {
        method => 'exception_this',
        params => 'Lorem ipsum dolor sit amet',
        return_type  => 'fault',
        exception    => 'WSTest',
        exception_re => qr/^Lorem ipsum dolor sit amet$/,
    },
    no_method => {
        method => '',
        return_type => 'fault',
        exception   => 'NoSuchMethod',
        exception_re => qr/contain a package name, followed/,
    },
    no_package => {
        full_method => 'hello',
        return_type => 'fault',
        exception   => 'NoSuchMethod',
        exception_re => qr/contain a package name, followed/,
    },
    package_only => {
        full_method => 'WSTest',
        return_type => 'fault',
        exception   => 'NoSuchMethod',
        exception_re => qr/contain a package name, followed/,
    },
    private_method => {
        method => '_private',
        return_type  => 'fault',
        exception    => 'NoSuchMethod',
        exception_re => qr/underscore are considered private/,
    },
    constant_method => {
        method => 'RETURN_ARRAY',
        return_type  => 'fault',
        exception    => 'NoSuchMethod',
        exception_re => qr/considered to be private constants/,
    },
    method_bad_identifier => {
        method => '*this_is_a_method',
        return_type => 'fault',
        exception => 'NoSuchMethod',
        exception_re => qr/because it is not a valid Perl identifier\.$/
    },
    bad_package => {
        full_method  => 'Support.all_modules',
        return_type  => 'fault',
        exception    => 'NoSuchMethod',
        exception_re => qr/There is no method package named/,
    },
    no_such_method => {
        method       => 'no_such_method',
        return_type  => 'fault',
        exception    => 'NoSuchMethod',
        exception_re => qr/There is no method named/,
    },
    bad_dispatch => {
        full_method  => 'BadPackage.hello',
        dispatch     => { 'BadPackage' => 'BadPackage' },
        return_type  => 'fault',
        exception    => 'PerlError',
        exception_re => qr/BadPackage\.pm/,
    },
);

use constant HTTP_TESTS => (
    get_disallowed => {
        method  => 'hello',
        return_type  => 'fault',
        exception    => 'HTTPError',
        exception_re => qr/^HTTP GET not allowed\.$/,
        version      => '2.0',
        content_type => 'application/json-rpc',
        headers => { GET => "/" },
    },
);

use constant JSON_TESTS => (
    return_bool => {
        method => 'return_this',
        params  => JSON::true,
        returns => JSON::true,
        return_type => 'boolean',
    },
    'json_no_id 2.0' => {
        input_json  => '{"jsonrpc":"2.0","method":"WSTest.hello"}',
        version     => '2.0',
        returns     => 'Hello!',
        return_type => 'string',
    },
    'json_no_id 1.1' => {
        input_json  => '{"version":"1.1","method":"WSTest.hello"}',
        version     => '1.1',
        returns     => 'Hello!',
        return_type => 'string',
    },
    
    normal_ascii => {
        method  => 'return_utf8',
        params  => ' foo bar ',
        returns => { 0 => ' foo bar ' },
        return_type => 'struct',
    },
    
    #################
    # Failing Tests #
    #################
    
    'json_no_id 1.0' => {
        input_json  => '{"method":"WSTest.hello"}',
        version     => '2.0', # Error response will be 2.0.
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/^Error while parsing JSON/,
    },
    json_blank => {
        input_json   => '',
        version      => '2.0',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/^You did not supply any JSON/,
    },
    json_no_json => {
        input_json => 'blah',
        version    => '2.0',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/^Error while parsing JSON/,
    },
    json_only_int => {
        input_json => 1,
        version    => '2.0',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/^Error while parsing JSON/,
    },
    json_empty => {
        input_json => '{}',
        version    => '2.0',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/^Error while parsing JSON/,
    },
);

use constant XML_TESTS => (
    return_undef_string => {
        method => 'return_this',
        params  => undef,
        returns => '',
        return_type => 'string',
    },
    nil_in_array => {
        method  => 'return_this',
        params  => [undef],
        returns => [''],
        return_type => 'array',
    },
    nil_in_struct => {
        method  => 'return_this',
        params  => { this => undef },
        returns => { this => '' },
        return_type => 'struct',
    },
    nil_type_to_string => {
        method  => 'type_this',
        params  => ['nil', undef],
        returns => '',
        return_type   => 'string',
        expand_params => 1,
    },
    xml_params_blank => {
        input_xml => '<?xml version="1.0" encoding="UTF-8"?><methodCall>
                      <methodName>WSTest.hello</methodName><params />
                      </methodCall>',
        returns => 'Hello!',
        return_type => 'string',        
    },
    # This probably should throw an error, but RPC-XML accepts it.
    xml_no_params => {
        input_xml => '<?xml version="1.0" encoding="UTF-8"?><methodCall>
                      <methodName>WSTest.hello</methodName></methodCall>',
        returns => 'Hello!',
        return_type => 'string',
    },
    # Same here.
    xml_no_decl => {
        input_xml => '<methodCall><methodName>WSTest.hello</methodName>
                      <params /></methodCall>',
        returns => 'Hello!',
        return_type => 'string',        
    },
    
    #################
    # Failing Tests #
    #################
    
    xml_blank => {
        input_xml    => '',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/You did not supply/,
    },
    xml_no_xml => {
        input_xml => 'foo',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/Error while parsing XML-RPC request/,
    },
    xml_empty_methodcall => {
        input_xml => '<?xml version="1.0" encoding="UTF-8"?>
                      <methodCall></methodCall>',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/Error while parsing XML-RPC request.+methodName/,
    },
    xml_empty_methodname => {
        input_xml => '<?xml version="1.0" encoding="UTF-8"?>
                      <methodCall><methodName></methodName></methodCall>',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/Error while parsing XML-RPC request.+methodName/,
    },
    xml_empty_param => {
        input_xml => '<?xml version="1.0" encoding="UTF-8"?><methodCall>
                      <methodName>WSTest.hello</methodName>
                      <params><param></param></params></methodCall>',
        return_type  => 'fault',
        exception    => 'ParseError',
        exception_re => qr/Error while parsing XML-RPC request.+<value>/,
    },    
);

use constant DISPATCH => {
    'WSTest' => 'WSTest',
};

sub extract_versioned_tests {
    my ($tests) = @_;
    
    my @versioned_names = grep { $tests->{$_}->{version} } (keys %$tests);
    my %versioned;
    foreach my $name (@versioned_names) {
        $versioned{$name} = delete $tests->{$name};
    }
    return \%versioned;
}

# FIXME NEED GET TESTS

sub test_jsonrpc {
    my ($server, $test, $name) = @_;

    return if $test->{use_fh} and $test->{http_request};

    my $method  = $test->{method} || '';
    my $params  = $test->{params};
    my $version = $test->{version};
    my $full_method = $test->{full_method};
    my $return_type  = $test->{return_type};
    my $input_json   = $test->{input_json};
    
    local $SIG{__DIE__} = \&Carp::confess;
    SKIP: {
        my $skip_count = $test->{headers} ? 13 : 8;
        $skip_count++ if $server->does('RPC::Any::Interface::CGI');
        skip("$name: Taint not enabled", $skip_count)
            if $name =~ /taint/ && !${^TAINT};
        $skip_count--;
        my $skip_use_fh = _skip_use_fh($test);
        skip("$name: $skip_use_fh", $skip_count) if $skip_use_fh;

    _init_server($test, $server);

    my $m = JSON::RPC::Common::Marshal::Text->new;
    $m->json->utf8(utf8::is_utf8($params) ? 0 : 1);

    if (!defined $input_json) {
        $full_method = "WSTest.$method" if !defined $full_method;
        my %call_params = (version => $version, method => $full_method,
                           id => 'RPC::Any::Test');
        my $tainted;
        if (exists $test->{params}) {
            $tainted = tainted($params);
            if ((!$test->{expand_params} and ref $params eq 'ARRAY')
                or ($version eq '1.0' and ref $params ne 'ARRAY')
                or !ref $params or JSON::is_bool($params))
            {
                $params = [$params];
            }
            $call_params{params} = $params;
        }
        elsif ($version eq '1.0') {
            $call_params{params} = [];
        }
        my $call = JSON::RPC::Common::Procedure::Call->inflate(\%call_params);
        $input_json = $m->call_to_json($call);
        taint($input_json) if $tainted;
    }
    
    my $text_result = _test_server_call($test, $name, $server, $input_json);
    my $http_code = $return_type eq 'fault' ? 500 : 200;
    $text_result = _test_http_response($test, $name, $server, $text_result,
                                       $http_code, $test->{content_type});
    

    my $parsed_response;
    $m->json->utf8(1) if $test->{headers}; # HTTP Responses are never utf8. # FIXME?
    lives_ok { $parsed_response = $m->json_to_return($text_result) }
             "$name: response can be parsed"
        or diag $text_result;
    isa_ok($parsed_response, 'JSON::RPC::Common::Procedure::Return',
           "$name: server response") or diag explain $parsed_response;

    is($parsed_response->version, $version,
       "$name: response is version $version");
    
    _test_is_fault($test, $name, $parsed_response->error, $parsed_response);

    if ($return_type eq 'fault') {
        my $error = $parsed_response->error;
        _test_fault($test, $name, $error->message, $error->code,
                    $parsed_response);
    }
    else {
        my $response_value = $parsed_response->result;
        
        my $type_test = "$name: return value is the right type";
        if ($return_type eq 'array') {
            is(ref $response_value, 'ARRAY', $type_test);
        }
        elsif ($return_type eq 'struct') {
            is(ref $response_value, 'HASH', $type_test);
        }
        elsif ($return_type eq 'boolean') {
            ok(JSON::is_bool($response_value), $type_test);
        }
        elsif ($return_type eq 'nil') {
            is($response_value, JSON::null, $type_test);
        }
        elsif ($return_type eq 'int' or $return_type eq 'double') {
            my $pm = '(\+|\-)?';
            like($text_result, qr/"result":$pm\d/,
                 "$name: numeric return value lacks quotes");
            my $re = $return_type eq 'int' ? qr/^$pm\d+$/ : qr/^$pm[\d\.]+$/;
            like($response_value, $re, $type_test);
        }
        elsif ($return_type eq 'base64') {
            lives_ok { $response_value = decode_base64($response_value) }
                     "$name: base64 decodes properly";
        }
        
        _test_return_value($test, $name, $response_value);
    }
    } # SKIP
}



sub test_xmlrpc {
    my ($server, $test, $name) = @_;
    
    return if $test->{use_fh} and $test->{http_request};
    
    local $SIG{__DIE__} = \&Carp::confess;
    SKIP: {
        my $skip_count = $test->{headers} ? 10 : 5;
        $skip_count++ if $server->does('RPC::Any::Interface::CGI');
        skip("$name: Taint not enabled", $skip_count)
            if ($name =~ /taint/ && !${^TAINT});
        $skip_count++;
        my $skip_use_fh = _skip_use_fh($test);
        skip("$name: $skip_use_fh", $skip_count) if $skip_use_fh;
        
    my $method  = $test->{method} || '';
    my $params  = $test->{params};
    my $full_method = $test->{full_method};
    my $return_type  = $test->{return_type};
    my $input_xml    = $test->{input_xml};

    _init_server($test, $server);
    
    $server->send_nil($return_type eq 'nil' ? 1 : 0);
    local $RPC::XML::ALLOW_NIL = $server->send_nil;
    
    if (!defined $input_xml) {
        local $RPC::XML::ENCODING = 'UTF-8';
        $full_method = "WSTest.$method" if !defined $full_method;
        my @request_params = ($full_method);
        my $tainted;
        if ($params) {
            $tainted = tainted($params);
            if ($test->{expand_params}) {
                push(@request_params, @$params);
            }
            else {
                push(@request_params, $params);
            }
        }
        my $request = RPC::XML::request->new(@request_params);
        $input_xml = $request->as_string;
        taint($input_xml) if $tainted;
    }
    
    my $text_result = _test_server_call($test, $name, $server, $input_xml);
    $text_result = _test_http_response($test, $name, $server, $text_result);
    
    my $parsed_response = $server->parser->parse($text_result);
    isa_ok($parsed_response, 'RPC::XML::response', "$name: server response")
        or diag explain $parsed_response;

    _test_is_fault($test, $name, $parsed_response->is_fault, $parsed_response);
    
    my $returned = $parsed_response->value;

    my $type = $returned->type;
    $type = 'dateTime' if $type eq 'dateTime.iso8601';
    _test_return_type($test, $name, $type, $returned);
    
    if ($return_type eq 'fault') {
        _test_fault($test, $name, $returned->string, $returned->code,
                    $returned);
    }
    else {
        my $response_value = $returned->value;
        _test_return_value($test, $name, $response_value);
    }
    } # SKIP
}



sub _skip_use_fh {
    my $test = shift;
    return 0 if !$test->{use_fh};
    return "Env" if $ENV{RPC_ANY_SKIP_FH_TEST};
    my $tmpfile = IO::File->new_tmpfile;
    return $! if !$tmpfile;
    $tmpfile->clearerr;
    print $tmpfile "test";
    return $! if $tmpfile->error;
    return 0;
}

sub _init_server {
    my ($test, $server) = @_;
    $server->dispatch($test->{dispatch} || DISPATCH);
    $server->allow_constants($test->{allow_constants});    
}

sub _test_server_call {
    my ($test, $name, $server, $input) = @_;
    my $method  = $test->{method} || '';
    my $headers = $test->{headers};

    if ($headers) {
        $headers = dclone($headers);
        my ($method_line, @header_strings);
        foreach my $name (keys %$headers) {
            my $string;
            if ($name =~ /^(GET|POST)$/) {
                $method_line = "$name $headers->{$name}";
            }
            else {
                push(@header_strings, "$name: $headers->{$name}")
            }
        }
        
        my ($http_method, $url, $protocol) = split(/\s+/, $method_line);
        delete $headers->{$http_method};
        if ($test->{http_request}) {
            my $request = HTTP::Request->new();
            $request->method($http_method);
            $request->uri($url);
            $request->protocol($protocol);
            $request->header(%{ $test->{headers} }) if %{ $test->{headers} };
            utf8::encode($input) if utf8::is_utf8($input);
            $request->content($input);
            $input = $request;
        }
        elsif ($server->does('RPC::Any::Interface::CGI')) {
            $ENV{'REQUEST_METHOD'} = $http_method;
            $ENV{'REQUEST_URI'} = $url;
            $ENV{'SERVER_PROTOCOL'} = $protocol;
            foreach my $name (keys %{ $headers || {} }) {
                my $env_key = uc($name);
                $env_key =~ s/-/_/g;
                $ENV{"HTTP_$env_key"} = $headers->{$name};
            }
        }
        else {
            unshift(@header_strings, $method_line);
            my $head = join("\015\012", @header_strings);
            $input = "$head\015\012\015\012$input";
        }
    }
    
    if ($test->{use_fh}) {
        my $fh = IO::File->new_tmpfile;
        $fh->autoflush(1);
        print $fh $input;
        $fh->seek(0, 0);
        $input = $fh;
    }
    
    my $result;
    lives_ok { $result = $server->handle_input($input) }
             "$name: calling the $method method"
        or diag $input;
        
    if ($server->does('RPC::Any::Interface::CGI')) {
        delete $ENV{'REQUEST_METHOD'};
        delete $ENV{'REQUEST_URI'};
        delete $ENV{'SERVER_PROTOCOL'};
        foreach my $name (keys %{ $headers || {} }) {
            $name = uc($name);
            $name =~ s/-/_/g;
            delete $ENV{"HTTP_$name"};
        }
    }
    
    return $result;
}

sub _test_http_response {
    my ($test, $name, $server, $text, $expected_code, $content_type) = @_;
    return $text if !$test->{headers};
    
    if ($server->does('RPC::Any::Interface::CGI')) {
        like($text, qr/^Status: /s,
             "$name: response starts with the Status header");
        $text =~ s{^Status:\s+(\d+)\s(\S+)}{HTTP/1.1 $1 $2};
    }
    
    $expected_code ||= 200;
    $content_type  ||= 'text/xml';
    my $http_response;
    lives_ok { $http_response = HTTP::Response->parse($text) }
             "$name: can parse http response"
        or diag $text;
    cmp_ok($http_response->code, '==', $expected_code,
           "$name: http response has code $expected_code");
    is($http_response->content_type, $content_type,
       "$name: response is $content_type");
    
    my $content = $http_response->content;
    ok($http_response->content_length,
       "$name: http response has a Content-Length");
    chomp($content);
    cmp_ok($http_response->content_length, '==', length $content,
           "$name: response has the right content length");
    return $content;
}

sub _test_is_fault {
    my ($test, $name, $is_fault, $object) = @_;
    
    if ($test->{return_type} eq 'fault') {
        ok($is_fault, "$name: response is a fault") or diag explain $object;
    }
    else {
        ok(!$is_fault, "$name: response is not a fault")
            or diag explain $object;
    }
}

sub _test_return_type {
    my ($test, $name, $type, $object) = @_;
    is($type, $test->{return_type}, "$name: return type is correct")
        or diag explain $object;
}

sub _test_fault {
    my ($test, $name, $message, $code, $object) = @_;
    my $exception    = $test->{exception};
    my $exception_re = $test->{exception_re};
    return if !$exception;
    
    my $exception_class = "RPC::Any::Exception::$exception";
    my $expected_code = $exception_class->new(message => '')->code;
    cmp_ok($code, '==', $expected_code,
           "$name: Return code is right for $exception")
        or diag explain $object;
    like($message, $exception_re, "$name: Return message is correct")
        or diag explain $object;
}

sub _test_return_value {
    my ($test, $name, $got) = @_;

    my $expected    = $test->{returns};
    my $return_type = $test->{return_type};
    my $return_numeric = ($return_type eq 'int' or $return_type eq 'double')
                         ? 1 : 0;

    if ($return_type eq 'string' and !$test->{skip_utf8_test}) {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        my $got_rep = Dumper($got);
        my $expected_rep = Dumper($expected);
        is($got_rep, $expected_rep,
           "$name: return strings have the same representation");
    }
    
    my $response_test = "$name: return value is correct";
    if ($return_type eq 'boolean') {
        if ($expected) {
            ok($got, $response_test);
        }
        else {
            ok(!$got, $response_test);
        }
    }
    elsif ($return_numeric) {
        cmp_ok($got, '==', $expected, $response_test);
    }
    elsif ($return_type eq 'nil') {
        ok(!defined $got, $response_test);
    }
    else {
        is_deeply($got, $expected, $response_test)
            or diag explain $got;
    }
}
 
# Stolen from Test::Pod::Coverage
sub all_modules {
    my @starters = @_ ? @_ : _starting_points();
    my %starters = map {$_,1} @starters;

    my @queue = @starters;

    my @modules;
    while ( @queue ) {
        my $file = shift @queue;
        if ( -d $file ) {
            local *DH;
            opendir DH, $file or next;
            my @newfiles = readdir DH;
            closedir DH;

            @newfiles = File::Spec->no_upwards( @newfiles );
            @newfiles = grep { $_ ne "CVS" && $_ ne ".svn" && $_ ne '.bzr' }
                             @newfiles;

            push @queue, map "$file/$_", @newfiles;
        }
        if ( -f $file ) {
            next unless $file =~ /\.pm$/;

            my @parts = File::Spec->splitdir( $file );
            shift @parts if @parts && exists $starters{$parts[0]};
            shift @parts if @parts && $parts[0] eq "lib";
            $parts[-1] =~ s/\.pm$// if @parts;

            # Untaint the parts
            for ( @parts ) {
                if ( /^([a-zA-Z0-9_\.\-]+)$/ && ($_ eq $1) ) {
                    $_ = $1;  # Untaint the original
                }
                else {
                    die qq{Invalid and untaintable filename "$file"!};
                }
            }
            my $module = join( "::", @parts );
            push( @modules, $module );
        }
    } # while

    return @modules;
}
