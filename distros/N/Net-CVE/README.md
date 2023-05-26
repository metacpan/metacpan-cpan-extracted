## Net::CVE

Fetch CVE (Common Vulnerabilities and Exposures) information from cve.org

```perl
 use Net::CVE;

 my $cr = Net::CVE->new ();

 $cr->get ("CVE-2022-12345");
 my $full_report = $cr->data;
 my $summary     = $cr->summary;

 use Data::Peek;
 DDumper $cr->summary ("CVE-2022-12345");
```

### Prerequisites

perl version 5.14.2 and up. Very well possible, you will be able to use this
with a previous version, but that is not officially supported.

Network access: the default operation mode is to fetch reports directly from
[the CVE database](https://cve.org), but using downloaded reports in JSON is
undocumented supported.

### Installation

```
$ perl Makefile.PL
$ make
$ make test
$ make install
```

Recent changes can be (re)viewed in the public GIT repository at
https://github.com/Tux/Net-CVE

Feel free to clone your own copy:

```
$ git clone https://github.com/Tux/Net-CVE Net-CVE
```

or get it as a tgz:

```
$ wget --output-document=Net-CVE-git.tgz \
        https://github.com/Tux/Net-CVE/archive/main.tar.gz
```

### Contibuting

New ideas and fixes welcome. Please read [this guide](CONTRIBUTING.md)

### Author

H.Merijn Brand <hmbrand@cpan.org>
