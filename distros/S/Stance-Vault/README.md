Stance::Vault - a Perl Interface to Hashicorp Vault
===================================================

This code is part of **The Stance Project**, an attempt to build a
small toolkit of modern API clients for rapidly building
proof-of-concept application ideas, using Perl.

This library in particular provides access to the `kv` backend to
Hashicorp Vault, a mature and secure credentials storage solution.

Usage
-----

This is an object-oriented library; you create a Vault object:

    use Stance::Vault;

    my $vault = Stance::Vault->new($ENV{VAULT_ADDR});

Then, you'll need to authenticate.  Currently, only root-token
authentication is supported, but I'll be adding more
authentication methods in eventually.

    $vault->authenticate(token => $ENV{VAULT_TOKEN});

After that, you can use the `kv_set($path, $data)` and
`kv_get($path)` methods of the Vault object to interact with the
key-value v2 backend.

    $vault->kv_set('secret/handshake', { knock => 'knock' })
      or die "set failed: " . $vault->last_error;

    my $data = $vault->kv_get('secret/handshake')
      or die "get failed: " . $vault->last_error;

    print "KNOCK: ".$data->{data}{data}{knock};

Contributing
------------

This code is licensed MIT.  Enjoy.

If you find a bug, please raise a [GitHub Issue][issues] first,
before submitting a PR.

Happy Hacking!

[issues]: https://github.com/jhunt/perl-Stance-Vault/issues
