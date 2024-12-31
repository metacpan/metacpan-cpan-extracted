# NAME

SMS::Send::Adapter::Node::Red - SMS::Send Adapter to Node-RED JSON HTTP request

# SYNOPSIS

CGI Application

    use SMS::Send::Adapter::Node::Red;
    my $service = SMS::Send::Adapter::Node::Red->new(content => join('', <>));
    $service->cgi_response;

PSGI Application

    use SMS::Send::Adapter::Node::Red;
    SMS::Send::Adapter::Node::Red->psgi_app

PSGI Plack Mount

    use SMS::Send::Adapter::Node::Red;
    use Plack::Builder qw{builder mount};
    builder {
      mount '/sms' => SMS::Send::Adapter::Node::Red->psgi_app;
      mount '/'    => sub {[404=> [], []]};
    }

# DESCRIPTION

This Perl package provides an adapter from Node-RED HTTP request object with a JSON payload to the SMS::Send infrastructure using either a PSGI or a CGI script.  The architecture works easiest with SMS::Send drivers based on the [SMS::Send::Driver::WebService](https://metacpan.org/pod/SMS::Send::Driver::WebService) base object since common settings can be stored in the configuration file.

# CONSTRUCTOR

## new

    my $object = SMS::Send::Adapter::Node::Red->new(content=>$string_of_json_object);

# PROPERTIES

## content

JSON string payload of the HTTP post request.

Example Payload:

    {
      "to"      : "7035551212",
      "text"    : "My Text Message",
      "driver"  : "VoIP::MS",
      "options" : {}
    }

The Perl logic is based on this one-liner with lots of error trapping

    my $sent = SMS::Send->new($driver, %$options)->send_sms(to=>$to, text=>$text);

I use a Node-RED function like this to format the JSON payload.

    my_text     = msg.payload;
    msg.payload = {
                   "driver"  : "VoIP::MS",
                   "text"    : my_text,
                   "to"      : "7035551212",
                   "options" : {"key" : "value"},
                  };
    return msg;

# METHODS (STATE)

## input

JSON Object from input that is passed to output.

## status

HTTP Status Code returned to Node-RED is one of 200, 400, 500 or 502. Typically, a 200 means the SMS message was successfully sent to the provider, a 400 means the input is malformed, a 500 means the server is misconfigured (verify installation), and a 502 means that the remote service has issues or is unreachable.

## status\_string

Format HTTP Status Code as string for web response

## error

Error string passed in the JSON return object.

## set\_status\_error

Method to set the HTTP status and error with one function call.

# METHODS (ACTIONS)

## send\_sms

Wrapper around the SMS::Send->send\_sms call.

## cgi\_response

Formatted CGI response

## psgi\_app

Returns a PSGI application

# OBJECT ACCESSORS

## CGI

Returns a [CGI](https://metacpan.org/pod/CGI) object for use in this package.

## SMS

Returns a [SMS::Send](https://metacpan.org/pod/SMS::Send) object for use in this package.

# SEE ALSO

[SMS::Send](https://metacpan.org/pod/SMS::Send), [CGI](https://metacpan.org/pod/CGI), [JSON](https://metacpan.org/pod/JSON)

# AUTHOR

Michael R. Davis

# COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2020 Michael R. Davis

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
