# NAME

Test::Deep::JWT - JWT comparison with Test:Deep functionality

# SYNOPSIS

    use Test::Deep;
    use Test::Deep::JWT;

    cmp_deeply 'eyJhbGciOiJub25lIn0.eyJzdWIiOiIxMDAiLCJhdWQiOiIxMjMifQ.', jwt(+{
        sub => '100',
        aud => ignore()
    }, +{
        alg => 'none'
    });

# DESCRIPTION

Test::Deep::JWT is the helper module for comparing JWT string with Test::Deep functionality.
This module will export a function called 'jwt'.

## jwt(\\%claims, \\%header)

\\%claims is the expected claims part of JWT.

\\%header is the expected header part of JWT (Optional).

# LICENSE

Copyright (C) Yuuki Furuyama.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Yuuki Furuyama <addsict@gmail.com>

# THANKS

This module is highly inspired from [Test::Deep::JSON](https://metacpan.org/pod/Test::Deep::JSON).
The most part of implementation is borrowed from that module.

# SEE ALSO

[Test::Deep](https://metacpan.org/pod/Test::Deep)

[Test::Deep::JSON](https://metacpan.org/pod/Test::Deep::JSON)
