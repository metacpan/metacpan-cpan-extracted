[![Release](https://img.shields.io/github/release/giterlizzi/perl-Net-Gotify.svg)](https://github.com/giterlizzi/perl-Net-Gotify/releases) [![Actions Status](https://github.com/giterlizzi/perl-Net-Gotify/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-Net-Gotify/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-Net-Gotify.svg)](https://github.com/giterlizzi/perl-Net-Gotify) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-Net-Gotify.svg)](https://github.com/giterlizzi/perl-Net-Gotify) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-Net-Gotify.svg)](https://github.com/giterlizzi/perl-Net-Gotify) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-Net-Gotify.svg)](https://github.com/giterlizzi/perl-Net-Gotify/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-Net-Gotify/badge.svg)](https://coveralls.io/github/giterlizzi/perl-Net-Gotify)

# Net::Gotify - Gotify client for Perl 

## Synopsis

```.pl
use Net::Gotify;

my $gotify = Net::Gotify->new(
    base_url     => 'http://localhost:8088',
    app_token    => '<TOKEN>',
    client_token => '<TOKEN>',
    logger       => $logger
);

$gotify->create_message(
    title    => 'Backup',
    message  => '**Backup** was successfully finished.',
    priority => 2,
    extras   => {
        'client::display' => {contentType => 'text/markdown'}
    }
);
```

## Install

Using Makefile.PL:

To install `Net::Gotify` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using App::cpanminus:

    cpanm Net::Gotify


## Documentation

 - `perldoc Net::Gotify`
 - https://metacpan.org/release/Net-Gotify
 - https://gotify.net/


## Copyright

 - Copyright 2025 © Giuseppe Di Terlizzi
