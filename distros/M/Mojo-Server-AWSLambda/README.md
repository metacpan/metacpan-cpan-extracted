# NAME

Mojo::Server::AWSLambda - Mojolicious server for AWS Lambda

# SYNOPSIS

    use Mojo::Server::AWSLambda;
    my $server = Mojo::Server::AWSLambda->new(app => $mojo_app)->run;
    $server->($payload);

# DESCRIPTION

Mojolicious server for AWS Lambda

### THIS MODULE IS EXPERIMENTAL.

# SEE ALSO

- [AWS::Lambda](https://metacpan.org/pod/AWS::Lambda) [p5-Mojo-Server-AzureFunctions](https://github.com/ytnobody/p5-Mojo-Server-AzureFunctions)

# LICENSE

Copyright (C) Prajith P.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Prajith P <me@prajith.in>

