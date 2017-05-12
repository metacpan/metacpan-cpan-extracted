# NAME

Plack::Middleware::SetLocalEnv - Set localized environment variables from the value of PSGI environment.

# SYNOPSIS

    use Plack::Builder;
    builder {
        enable 'SetLocalEnv' =>
            REQUEST_ID       => "HTTP_X_REQUEST_ID",
            URL_SCHEME       => "psgi.url_scheme",
        #   "local %ENV key" => "psgi env key",
        ;
        $app;
    };

# DESCRIPTION

Plack::Middleware::SetLocalEnv - Set localized environment variables(Perl's %ENV) from the value of PSGI environment.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
