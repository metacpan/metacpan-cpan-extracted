[![Release](https://img.shields.io/github/release/giterlizzi/perl-Net-OpenVAS.svg)](https://github.com/giterlizzi/perl-Net-OpenVAS/releases) [![Build Status](https://travis-ci.org/giterlizzi/perl-Net-OpenVAS.svg)](https://travis-ci.org/giterlizzi/perl-Net-OpenVAS) [![License](https://img.shields.io/github/license/giterlizzi/perl-Net-OpenVAS.svg)](https://github.com/giterlizzi/perl-Net-OpenVAS) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Net-OpenVAS.svg)](https://github.com/giterlizzi/perl-Net-OpenVAS) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Net-OpenVAS.svg)](https://github.com/giterlizzi/perl-Net-OpenVAS) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Net-OpenVAS.svg)](https://github.com/giterlizzi/perl-Net-OpenVAS/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Net-OpenVAS/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Net-OpenVAS)

# Net::OpenVAS - Perl interface to OpenVAS - Open Vulnerability Assessment Scanner

This module provides Perl scripts easy way to interface the OMP (OpenVAS Management Protocol) of OpenVAS.

For more information about the OPM follow the online documentation:

https://docs.greenbone.net/API/OMP/omp.html


## Synopsis

```.pl
use Net::OpenVAS;

my $openvas = Net::OpenVAS->new(
    host     => 'localhost:9390',
    username => 'admin',
    password => 's3cr3t'
) or die "ERROR: $@";

my $task = $openvas->create_task(
    name   => [ 'Scan created via Net::OpenVAS' ],
    target => { id => 'a800d5c7-3493-4f73-8401-c42e5f2bfc9c' },
    config => { id => 'daba56c8-73ec-11df-a475-002264764cea' }
);

if ( $task->is_created ) {

    my $task_id = $task->result->{id};

    say "Created task $task_id";

    my $task_start = $openvas->start_task( task_id => $task_id );

    say "Task $task_id started (" . $task_start->status_text . ')' if ( $task_start->is_accepted );

}

if ( $openvas->error ) {
    say "ERROR: " . $openvas->error;
}
```

## Install

To install `Net::OpenVAS` distribution, run the following commands:

    perl Makefile.PL
    make
    make test
    make install

## Copyright

 - Copyright 2020 © Giuseppe Di Terlizzi
