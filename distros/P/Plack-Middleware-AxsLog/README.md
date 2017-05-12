# NAME

Plack::Middleware::AxsLog - Yet another AccessLog Middleware

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'AxsLog',
          combined => 1,
          response_time => 1,
          error_only => 1,
        $app
    };

# DESCRIPTION

Alternative implementation of Plack::Middleware::AccessLog. 
This middleware supports response\_time and content\_length calculation 
AxsLog also can set condition to display logs by response\_time and status code.

Originally, AxsLog was faster AccessLog implementation. But PM::AccessLog became 
to using same access-log generator module [Apache::LogFormat::Compiler](http://search.cpan.org/perldoc?Apache::LogFormat::Compiler). 
Two middlewares have almost same performance now.

# ARGUMENTS

- combined: Bool

    log format. if disabled, "common" format used. default: 1 (combined format used)

    common (Common Log Format) format is

        %h %l %u %t \"%r\" %>s %b
        

        => 127.0.0.1 - - [23/Aug/2012:00:52:15 +0900] "GET / HTTP/1.0" 200 645

    combined (NCSA extended/combined log format) format is

        %h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"
        

        => 127.0.0.1 - - [23/Aug/2012:00:52:15 +0900] "GET / HTTP/1.1" 200 645 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.79 Safari/537.1"



- ltsv: Bool

    use ltsv log format. default: 0

    LTSV (Labeled Tab-separated Values) format is

        host:%h<TAB>user:%u<TAB>time:%t<TAB>req:%r<TAB>status:%>s<TAB>size:%b<TAB>referer:%{Referer}i<TAB>ua:%{User-agent}i
        

        => host:127.0.0.1<TAB>user:-<TAB>time:[23/Aug/2012:00:52:15 +0900]<TAB>req:GET / HTTP/1.1<TAB>status:200<TAB>size:645<TAB>"referer:-<TAB>ua:Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/21.0.1180.79 Safari/537.1

    See also [http://ltsv.org/](http://ltsv.org/)

- format: String

    A format string.

        builder {
            enable 'AxsLog', 
                format => '%h %l %u %t "%r" %>s %b "%{Referer}i" "%{User-agent}i" %D';
            $app
        };

    See details on perldoc [Apache::LogFormat::Compiler](http://search.cpan.org/perldoc?Apache::LogFormat::Compiler)

- format\_options

    This variable is passed to [Apache::LogFormat::Compiler](http://search.cpan.org/perldoc?Apache::LogFormat::Compiler). You can add char\_handlers
    and block\_handlers with this middleware.

        enable 'AxsLog', 
            format => '%z %{X_MYAPP_VARIABLE}Z', 
            format_options => +{
                char_handlers => +{
                    'z' => sub { 'z' },
                },
                block_handlers => +{
                    'Z' => sub { 'Z' },
                },
            };

- response\_time: Bool

    Adds time taken to serve the request. default: 0. This args effect to common, combined and ltsv format.

- error\_only: Bool

    Display logs if response status is error (4xx or 5xx). default: 0

- long\_response\_time: Int (microseconds)

    Display log if time taken to serve the request is above long\_response\_time. default: 0 (all request logged)

- logger: Coderef

    Callback to print logs. default:none ( output to psgi.errors )

        use File::RotateLogs;
        my $logger = File::RotateLogs->new();

        builder {
            enable 'AxsLog',
              logger => sub { $logger->print(@_) }
            $app
        };

# AUTHOR

Masahiro Nagano <kazeburo {at} gmail.com>

# SEE ALSO

[Plack::Middleware::AccessLog](http://search.cpan.org/perldoc?Plack::Middleware::AccessLog)

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
