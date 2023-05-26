## Net::NVD

Perl interface to [NIST's National Vulnerability Database (NVD)](https://nvd.nist.gov/), allowing developers to search and retrieve [CVE (Common Vulnerabilities and Exposures)](https://cve.mitre.org/) information.

```perl
    use Net::NVD;
    my $nvd = Net::NVD->new;

    # fetch a single CVE, by name.
    my $cve = $nvd->get( 'CVE-2019-1010218' );

    # search multiple CVE:
    my @cves = $nvd->search(
        keyword_search      => 'perl cpan',
        last_mod_start_date => '2023-01-15T13:00:00.000-03:00',
        no_rejected         => 1,
    );
```


#### Installation

    cpanm Net::NVD

or manually:

    perl Makefile.PL
    make test
    make install

Please refer to [this module's complete documentation](https://metacpan.org/pod/Net::NVD)
for extra information.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See [perlartistic](http://dev.perl.org/licenses/).

This product uses data from the NVD API but is not endorsed or certified by the NVD.
