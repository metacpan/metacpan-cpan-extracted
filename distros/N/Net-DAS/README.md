### Net::DAS
Simple DAS (Domain Availability Service) Client for Perl

Supported TLDs: be eu gent it lt no nu  ro se si uk

* * *
#### Installation
``` shell
perl Makefile.PL
make
make test
make install
```

#### Usage
``` shell
Usage: das [switch] [timeout] domain.tld [domain2.tld] ...
Switches:
-h help
-v print version
-e exit code only (only works when quering a single domain)
-r use registrar das servers where available (normally requires signup/ip whitelist)
Examples:
das test1.eu test2.be test3.no
das -er 3 test.eu
```

