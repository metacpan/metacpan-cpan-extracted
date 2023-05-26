## Net::OSV

Perl interface to the L<< Open Source Vulnerabilities Database (OSV) | https://osv.dev/ >>, allowing developers to search and retrieve vulnerability and security advisory information from many open source projects and ecosystems.

```perl
    use Net::OSV;

    my $osv = Net::OSV->new;

    my @vulns = $osv->query( commit => '6879efc2c1596d11a6a6ad296f80063b558d5e0f' );

    @vulns = $osv->query(
        package => { ecosystem => 'Debian:10', name => 'imagemagick' },
    );

    say $vulns[0]{details};
```


#### Installation

    cpanm Net::OSV

or manually:

    perl Makefile.PL
    make test
    make install

Please refer to [this module's complete documentation](https://metacpan.org/pod/Net::OSV)
for extra information.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

This product uses data from the Open Source Vulnerabilities Database (OSV) but is not endorsed or certified by the OSV.
