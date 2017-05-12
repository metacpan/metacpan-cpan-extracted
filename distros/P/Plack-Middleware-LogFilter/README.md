# NAME

Plack::Middleware::LogFilter - modify log output.

# SYNOPSIS

    use Plack::Builder;

    builder {
        enable 'LogFilter', filter => sub {
            my ($env, $output) = @_;

            # ignore static file log
            if ($output =~ /\/static\/(js|css|images)/) {
                return 0;
            }

            return 1;
        };
        $app
    };

# DESCRIPTION

This middleware allows the modification of log output.

# LICENSE

Copyright (C) Uchiko.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Uchiko <memememomo@gmail.com>
