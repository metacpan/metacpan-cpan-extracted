# NAME

Plack::Middleware::JSONParser - It's new $module

# SYNOPSIS

    use Plack::Middleware::JSONParser;

# DESCRIPTION

JSONParser parses json to hash multivalue object. it substitute the multivalue object for "plack.request.body" when content-type is 'application/json' and request body has JSON.

# LICENSE

Copyright (C) Yosuke Furukawa.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yosuke Furukawa <yosuke.furukawa@gmail.com>
