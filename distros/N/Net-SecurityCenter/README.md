[![Release](https://img.shields.io/github/release/LotarProject/perl-Net-SecurityCenter.svg)](https://github.com/LotarProject/perl-Net-SecurityCenter/releases) [![Build Status](https://travis-ci.org/LotarProject/perl-Net-SecurityCenter.svg)](https://travis-ci.org/LotarProject/perl-Net-SecurityCenter) [![License](https://img.shields.io/github/license/LotarProject/perl-Net-SecurityCenter.svg)](https://github.com/LotarProject/perl-Net-SecurityCenter) [![Starts](https://img.shields.io/github/stars/LotarProject/perl-Net-SecurityCenter.svg)](https://github.com/LotarProject/perl-Net-SecurityCenter) [![Forks](https://img.shields.io/github/forks/LotarProject/perl-Net-SecurityCenter.svg)](https://github.com/LotarProject/perl-Net-SecurityCenter) [![Issues](https://img.shields.io/github/issues/LotarProject/perl-Net-SecurityCenter.svg)](https://github.com/LotarProject/perl-Net-SecurityCenter/issues)

# Net::SecurityCenter - Perl interface to Tenable.sc (SecurityCenter) REST API

## Synopsis

```.pl
    use Net::SecurityCenter;
    my $sc = Net::SecurityCenter('sc.example.org') or die "Error: $@";

    $sc->login('secman', 'password');

    if ($sc->error) {
      print "Failed login: " . $sc->error;
      exit 0;
    }

    my $running_scans = $sc->scan_result->list_running;

    if ($sc->scan_result->get_status( id => 1337 ) eq 'completed') {
        $sc->scan_result->download( id       => 1337,
                                    filename => '/tmp/1337.nessus' );

    }

    $sc->logout();
```

## Install

To install `Net::SecurityCenter` distribution, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Copyright

 - Copyright 2018-2019 © Giuseppe Di Terlizzi
 - Nessus®, Tenable.sc® and SecurityCenter® is a Registered Trademark of Tenable®, Inc.
