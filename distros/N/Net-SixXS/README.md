# NAME

Net::SixXS - interface to the SixXS.org services

# SYNOPSIS

    use Net::SixXS::TIC::Client;

    my $tic = Net::SixXS::TIC::Client->new(username = 'me', password = 'none');
    $tic->connect;
    say for sort map $_->name, values %{$tic->tunnels};

# DESCRIPTION

The `Net::SixXS` suite contains helper classes to connect to the various
IPv6 tunnel services provided by SixXS ([http://www.sixxs.net/](http://www.sixxs.net/)).

This implementation includes a simple TIC client (`Net::SixXS::TIC::Client`),
a couple of trivial TIC servers (see `Net::SixXS::TIC::Server` for a list),
and some data structures to facilitate their use.

The `Net::SixXS` module itself only serves as a common repository for
subroutines and data used by all the modules in the hierarchy.

# FUNCTIONS

The `Net::SixXS` module currently only defines a single function:

- **diag (\[object\])**

    Get or set the object that will be used to output diagnostic information
    by all the modules in the `Net::SixXS` hierarchy.  The parameter, if
    supplied, must implement the [Net::SixXS::Diag](https://metacpan.org/pod/Net::SixXS::Diag) role.

    By default this is set to a [Net::SixXS::Diag::None](https://metacpan.org/pod/Net::SixXS::Diag::None) instance; thus,
    unless a program overrides it, any diagnostic output from classes in
    the `Net::SixXS` hierarchy will be ignored.

# SEE ALSO

The TIC client class: [Net::SixXS::TIC::Client](https://metacpan.org/pod/Net::SixXS::TIC::Client)

The TIC server class: [Net::SixXS::TIC::Server](https://metacpan.org/pod/Net::SixXS::TIC::Server)

Diagnostics: [Net::SixXS::Diag](https://metacpan.org/pod/Net::SixXS::Diag), [Net::SixXS::Diag::None](https://metacpan.org/pod/Net::SixXS::Diag::None),
[Net::SixXS::Diag::MainDebug](https://metacpan.org/pod/Net::SixXS::Diag::MainDebug)

# LICENSE

Copyright (C) 2015  Peter Pentchev &lt;roam@ringlet.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Peter Pentchev &lt;roam@ringlet.net>
