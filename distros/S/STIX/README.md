[![Release](https://img.shields.io/github/release/giterlizzi/perl-STIX.svg)](https://github.com/giterlizzi/perl-STIX/releases) [![Actions Status](https://github.com/giterlizzi/perl-STIX/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-STIX/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-STIX.svg)](https://github.com/giterlizzi/perl-STIX) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-STIX.svg)](https://github.com/giterlizzi/perl-STIX) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-STIX.svg)](https://github.com/giterlizzi/perl-STIX) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-STIX.svg)](https://github.com/giterlizzi/perl-STIX/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-STIX/badge.svg)](https://coveralls.io/github/giterlizzi/perl-STIX)

# STIX - Perl extension for STIX (Structured Threat Information Expression)

## Synopsis

```.pl
# Object-Oriented interface

use STIX::Indicator;
use STIX::Common::Timestamp;
use STIX::Common::Bundle;

my $bundle = STIX::Common::Bundle->new;

push @{ $bundle->objects }, STIX::Indicator->new(
    pattern_type    => 'stix',
    created         => STIX::Common::Timestamp->new('2014-05-08T09:00:00'),
    name            => 'IP Address for known C2 channel',
    description     => 'Test description C2 channel.',
    indicator_types => ['malicious-activity'],
    pattern         => "[ipv4-addr:value = '10.0.0.0']",
    valid_from      => STIX::Common::Timestamp->new('2014-05-08T09:00:00'),
);

# Functional interface

use STIX qw(:all);

my $bundle = bundle(
    objects => [
      indicator(
        pattern_type    => 'stix',
        created         => '2014-05-08T09:00:00',
        name            => 'IP Address for known C2 channel',
        description     => 'Test description C2 channel.',
        indicator_types => ['malicious-activity'],
        pattern         => "[ipv4-addr:value = '10.0.0.0']",
        valid_from      => '2014-05-08T09:00:00',
      )
    ]
);


# Validate

my @errors = $bundle->validate;

say $_ for @errors;


# Render in JSON

say $bundle;

# {
#    "id" : "bundle--eb2f23f1-8084-4847-8fe6-a5bc95cb024c",
#    "objects" : [
#       {
#          "created" : "2014-05-08T09:00:00.000Z",
#          "description" : "Test description C2 channel.",
#          "id" : "indicator--3b67f5b2-a1dc-4464-8617-d8bd371079ca",
#          "indicator_types" : [
#             "malicious-activity"
#          ],
#          "modified" : "2014-05-08T09:00:00.000Z",
#          "name" : "IP Address for known C2 channel",
#          "pattern" : "[ipv4-addr:value = '10.0.0.0']",
#          "pattern_type" : "stix",
#          "spec_version" : "2.1",
#          "type" : "indicator",
#          "valid_from" : "2014-05-08T09:00:00.000Z"
#       }
#    ],
#    "type" : "bundle"
# }

```

## Install

Using Makefile.PL:

To install `STIX` distribution, run the following commands.

    perl Makefile.PL
    make
    make test
    make install

Using `App::cpanminus`:

    cpanm STIX


## Documentation

- `perldoc STIX`
- https://metacpan.org/release/STIX
- [OASIS-Open] STIX Version 2.1 (https://docs.oasis-open.org/cti/stix/v2.1/os/stix-v2.1-os.html)

## Copyright

- Copyright 2024 © Giuseppe Di Terlizzi
