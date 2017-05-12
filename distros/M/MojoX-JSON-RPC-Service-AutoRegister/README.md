[![Build Status](https://travis-ci.org/IntelliHome/MojoX-JSON-RPC-Service-AutoRegister.png?branch=master)](https://travis-ci.org/IntelliHome/MojoX-JSON-RPC-Service-AutoRegister)
# NAME

MojoX::JSON::RPC::Service::AutoRegister - Base class for RPC Services

# DESCRIPTION

This object represent a base class for RPC Services.
It only ovverides the `new` to inject `'with_mojo_tx'=1`, `'with_svc_obj'=1` and `'with_self'=1`  options by default.
For more information on how services work, have a look at
[MojoX::JSON::RPC::Service](https://metacpan.org/pod/MojoX::JSON::RPC::Service).

Every function that starts with `rpc_` it's automatically registered as an
rpc service, this means that on your service file you must only add

    __PACKAGE__->register_rpc;

at the bottom of the code.
You can also defines your suffix or your regex to match the functions to being automatically registered.

# METHODS

Inherits all methods from [MojoX::JSON::RPC::Service](https://metacpan.org/pod/MojoX::JSON::RPC::Service) and adds the following new ones:

## register\_rpc

witouth arguments, register all the methods of the class that starts with "rpc\_" as a RPC services

## register\_rpc\_suffix

    __PACKAGE__->register_rpc_suffix("somesuffix");

Accept  an argument, the suffix name. Register all the methods of the class that starts with the given suffix as a RPC services (e.g. somesuffix\_edit, somesuffix\_lay )

## register\_rpc\_regex

    __PACKAGE__->register_rpc_regex(qr//);

Accept  an argument, a regex. Register all the methods of the class that matches the given regex as a RPC services

# AUTHOR

mudler <mudler@dark-lab.net>, vytas <vytas@cpan.org>

# COPYRIGHT

Copyright 2014- mudler, vytas

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[MojoX::JSON::RPC::Service](https://metacpan.org/pod/MojoX::JSON::RPC::Service)
