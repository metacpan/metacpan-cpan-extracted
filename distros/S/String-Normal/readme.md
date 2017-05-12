String::Normal
=====================
Transform strings into a normal form.  [![CPAN Version](https://badge.fury.io/pl/String-Normal.svg)](https://metacpan.org/pod/String::Normal) [![Build Status](https://api.travis-ci.org/jeffa/String-Normal.svg?branch=master)](https://travis-ci.org/jeffa/String-Normal)

Synopsis
--------
```
normalizer --value='Jones & Sons Bakeries'

normalizer --value='Los Angeles' --type='city'

normalizer --file=addresses.txt --type=address

```

Backend API
-----------
```perl
use String::Normal;

my $normalizer = String::Normal->new( type => 'name' );
print $normalizer->transform( 'Jones & Sons Bakeries' );     # bakeri jone son

$normalizer = String::Normal->new( type => 'address' );
print $normalizer->transform( '123 Main Street Suite A47' ); # 123 main st

$normalizer = String::Normal->new( type => 'phone' );
print $normalizer->transform( '(818) 423-7750' );            # 8184237750

$normalizer = String::Normal->new( type => 'city' );
print $normalizer->transform( 'Los Angeles' );               # los angeles

$normalizer = String::Normal->new( type => 'state' );
print $normalizer->transform( 'California' );                # ca

$normalizer = String::Normal->new( type => 'zip' );
print $normalizer->transform( '90292' );                     # 90292
```

Installation
------------
To install this module, you should use CPAN. A good starting
place is [How to install CPAN modules](http://www.cpan.org/modules/INSTALL.html).

If you truly want to install from this github repo, then
be sure and create the manifest before you test and install:
```
perl Makefile.PL
make
make manifest
make test
make install
```

Support and Documentation
-------------------------
After installing, you can find documentation for this module with the
perldoc command.
```
perldoc String::Normal
```
License and Copyright
---------------------
See [source POD](/lib/String/Normal.pm).
