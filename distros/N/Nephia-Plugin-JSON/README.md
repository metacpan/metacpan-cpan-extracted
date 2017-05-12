# NAME

Nephia::Plugin::JSON - A plugin for Nephia that provides JSON Response DSL

# SYNOPSIS

    use Nephia plugins => ['JSON'];
    app {
        json_res +{ 
            name  => 'ytnobody',
            birth => '1980-11-11',
        };
    };

# DESCRIPTION

Nephia::Plugin::JSON provides three DSL that is about JSON.

# CONFIG

## enable\_api\_status\_header

If you define it as true, json\_res returns with 'X-API-Status' header.

    use Nephia plugins => ['JSON' => {enable_api_status_header => 1}];
    ...



# DSL

## json\_res $hashref

Returns a Nephia::Response that contains application/json contents.

## encode\_json $hashref

Returns JSON string of encoded hashref.

## decode\_json $json\_str

Returns hashref of decoded JSON.

# LICENSE

Copyright (C) ytnobody.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

ytnobody <ytnobody@gmail.com>
