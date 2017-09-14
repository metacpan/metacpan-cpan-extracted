# NAME

Plack::Middleware::QueryCounter::DBI - DBI query counter per request middleware

# SYNOPSIS

Enable this middleware using Plack::Builder.

    use MyApp;
    use Plack::Builder;

    my $app = MyApp->psgi_app;

    builder {
        enable 'QueryCounter::DBI';
        $app;
    };

You can specify HTTP header using prefix option.

    builder {
        enable 'QueryCounter::DBI', prefix => 'X-MyQueryCounter';
        $app;
    };

# DESCRIPTION

Plack::Middleware::QueryCounter::DBI is a middleware to count SQL query
per each HTTP request. Count result outputs on HTTP header.

The counted quieries classify read, write or other query.

You'll get following HTTP headers.

X-QueryCounter-DBI-Total: 20
X-QueryCounter-DBI-Read:  16
X-QueryCounter-DBI-Write:  4
X-QueryCounter-DBI-Other:  0

Then, you can write to access log using nginx.

    log_format ltsv   'host:$remote_addr\t'
                      'user:$remote_user\t'
    (snip)
                      'user_agent:$http_user_agent\t'
                      'query_total:$sent_http_x_querycounter_dbi_total\t'
                      'query_read:$sent_http_x_querycounter_dbi_read\t'
                      'query_write:$sent_http_x_querycounter_dbi_write\t'
                      'query_other:$sent_http_x_querycounter_dbi_other\t';

LTSV is Labeled Tab-separated Values, see [http://ltsv.org/](http://ltsv.org/)

Additionally, I recommend to remove these header for end-user response.

    location / {
        proxy_hide_header 'X-QueryCounter-DBI-Total';
        proxy_hide_header 'X-QueryCounter-DBI-Read';
        proxy_hide_header 'X-QueryCounter-DBI-Write';
        proxy_hide_header 'X-QueryCounter-DBI-Other';

        proxy_pass http://backend;
    }

# SEE ALSO

[Plack](https://metacpan.org/pod/Plack) [Plack::Builder](https://metacpan.org/pod/Plack::Builder)

# LICENSE

Copyright (C) Masatoshi Kawazoe (acidlemon).

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Masatoshi Kawazoe (acidlemon) <acidlemon@cpan.org>
