# p5-net-freeipa
Perl5 NET::FreeIPA (FreeIPA 4.2+ JSON API)

# Example usage

`ipa user-find` equivalent using API call and basic result postprocessing.
The connection in this example will (try to) use kerberos authentication.
(See `Net::FreeIPA::RPC::new_client` for authentication details.)

```perl
use Net::FreeIPA;

my $fi = Net::FreeIPA->new("host.example.com");
die("Failed to initialise the rest client") if ! $fi->{rc};
if ($fi->api_user_find("")) {
    print "Found ", scalar @{$fi->{result}}, " users\n";
} else {
    print "Something went wrong\n";
}
```

# IPA API

All API commands are retrieve using `gen_api.pl` script from the JSON API.

# Tests

Run tests with `prove -Ilib -r t` (or `prove -Ilib -t/name_of_test.t` for single unittest)

# References

* [perl example][api_perl_example]
* [bash/curl example][bokovoy_blog_json_rpc]

[bokovoy_blog_json_rpc]: https://vda.li/en/posts/2015/05/28/talking-to-freeipa-api-with-sessions/
[api_perl_example]: https://www.redhat.com/archives/freeipa-users/2015-November/msg00132.html

# License

Apache 2.0 (license is added to the release via `Dist-Zilla`).
