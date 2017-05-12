[![Build Status](https://travis-ci.org/dex4er/perl-Plack-Middleware-TrafficLog.png?branch=master)](https://travis-ci.org/dex4er/perl-Plack-Middleware-TrafficLog)

# NAME

Plack::Middleware::TrafficLog - Log headers and body of HTTP traffic

# SYNOPSIS

    # In app.psgi
    use Plack::Builder;

    builder {
        enable "TrafficLog", with_body => 1;
    };

# DESCRIPTION

This middleware logs the request and response messages with detailed
information about headers and body.

The example log:

    [08/Aug/2012:16:59:47 +0200] [164836368] [127.0.0.1 -> 0:5000] [Request ]
    |GET / HTTP/1.1|Connection: TE, close|Host: localhost:5000|TE: deflate,gzi
    p;q=0.3|User-Agent: lwp-request/6.03 libwww-perl/6.03||
    [08/Aug/2012:16:59:47 +0200] [164836368] [127.0.0.1 <- 0:5000] [Response]
    |HTTP/1.0 200 OK|Content-Type: text/plain||Hello World

This module works also with applications which have delayed response. In that
case each chunk is logged separately and shares the same unique ID number and
headers.

The body of request and response is not logged by default. For streaming
responses only first chunk is logged by default.

# CONFIGURATION

- logger

        # traffic.l4p
        log4perl.logger.traffic = DEBUG, LogfileTraffic
        log4perl.appender.LogfileTraffic = Log::Log4perl::Appender::File
        log4perl.appender.LogfileTraffic.filename = traffic.log
        log4perl.appender.LogfileTraffic.layout = PatternLayout
        log4perl.appender.LogfileTraffic.layout.ConversionPattern = %m{chomp}%n

        # app.psgi
        use Log::Log4perl qw(:levels get_logger);
        Log::Log4perl->init('traffic.l4p');
        my $logger = get_logger('traffic');

        enable "Plack::Middleware::TrafficLog",
            logger => sub { $logger->log($INFO, join '', @_) };

    Sets a callback to print log message to. It prints to `psgi.errors` output
    stream by default.

- with\_request

    The false value disables logging of request message.

- with\_response

    The false value disables logging of response message.

- with\_date

    The false value disables logging of current date.

- with\_body

    The true value enables logging of message's body.

- with\_all\_chunks

    The true value enables logging of every chunk for streaming responses.

- eol

    Sets the line separator for message's headers and body. The default value is
    the pipe character `|`.

- body\_eol

    Sets the line separator for message's body only. The default is the space
    character ` `. The default value is used only if **eol** is also undefined.

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack), [Plack::Middleware::AccessLog](https://metacpan.org/pod/Plack::Middleware::AccessLog).

# BUGS

This module has unstable API and it can be changed in future.

The log file can contain the binary data if the PSGI server provides binary
files.

If you find the bug or want to implement new features, please report it at
[http://github.com/dex4er/perl-Plack-Middleware-TrafficLog/issues](http://github.com/dex4er/perl-Plack-Middleware-TrafficLog/issues)

The code repository is available at
[http://github.com/dex4er/perl-Plack-Middleware-TrafficLog](http://github.com/dex4er/perl-Plack-Middleware-TrafficLog)

# AUTHOR

Piotr Roszatycki <dexter@cpan.org>

# LICENSE

Copyright (c) 2012, 2014-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See [http://dev.perl.org/licenses/artistic.html](http://dev.perl.org/licenses/artistic.html)
