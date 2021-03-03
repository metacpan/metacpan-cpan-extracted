[![Release](https://img.shields.io/github/release/giterlizzi/perl-Net-SecurityCenter.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter/releases) [![Actions Status](https://github.com/giterlizzi/perl-Net-SecurityCenter/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter/actions) [![Actions Status](https://github.com/giterlizzi/perl-Net-SecurityCenter/workflows/macos/badge.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-Net-SecurityCenter.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Net-SecurityCenter.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Net-SecurityCenter.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Net-SecurityCenter.svg)](https://github.com/giterlizzi/perl-Net-SecurityCenter/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Net-SecurityCenter/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Net-SecurityCenter)

# Net::SecurityCenter - Perl interface to Tenable.sc (SecurityCenter) REST API

## Synopsis

```.pl
use Net::SecurityCenter;
my $sc = Net::SecurityCenter('sc.example.org') or die "Error: $@";

$sc->login(username => 'secman', password => 's3cr3t');

if ($sc->error) {
  print "Failed login: " . $sc->error;
  exit 0;
}

my $running_scans = $sc->scan_result->list_running;

if ($sc->scan_result->status( id => 1337 ) eq 'completed') {
    $sc->scan_result->download( id       => 1337,
                                filename => '/tmp/1337.nessus' );

}

$sc->logout();
```

## Install

Using Makefile.PL:

To install `Net::SecurityCenter` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm Net::SecurityCenter


## Documentation

 - `perldoc Net::SecurityCenter`
 - https://metacpan.org/release/Net-SecurityCenter
 - https://giterlizzi.github.io/perl-Net-SecurityCenter


## Copyright

 - Copyright 2018-2021 © Giuseppe Di Terlizzi
 - Nessus®, Tenable.sc® and SecurityCenter® is a Registered Trademark of Tenable®, Inc.
