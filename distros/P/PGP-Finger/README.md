# NAME

pgpfinger - a tool to retrieve PGP keys

# VERSION

version 1.1

# SYNOPSIS


```
  usage: pgpfinger [-?fioq] [long options...] <uid> <more uids ...>
        -? --usage --help  Prints this usage information.
        -f --format        format of input (armored or binary)
        -i --input         path or - for stdin
        -q --query         sources to query (default: dns,keyserver,gpg,file)
        -o --output        output format: armored,rfc or generic (default:
                           armored)
```
# OPTIONS

-q --query <method,method,...> (default: keyserver)
:   Select sources to query for PGP keys. Values must be comma seperated.
Currently supported: dns, keyserver, gpg, file
-o --output <format> (default: armored)
:   Select format of output.
Supported formats: armored, binary, generic, rfc
-i --input <file> (default: -)
:   Input used for file query method. (-q file)
Path of a file or - for reading from stdin.
-f --format <format> (default: armored)
:   Format of file input.
Supported formats: armored, binary

# EXAMPLE

Query keyserver:


```
  $ pgpfinger -q keyserver ich@markusbenning.de
  # source: keyserver
  # keyid: C0C64210F4E3359A09A508B102585839DD0AAA62
  # url: http://a.keyserver.pki.scientia.net/pks/lookup
  -----BEGIN PGP PUBLIC KEY BLOCK-----
  Version: pgpfinger (head)
  
  mQENBFKVnLsBCADZVXXPLaVRUVaaGBxtmBNWAlHSiJPhdC8SPgSB/idpX5XBUKD3
  ---<cut>---
  B9acDiKsTxFCoSGAqYjEfNDunePwS6Lb4UNoVmixWoPImNc=
  =8+MQ
  -----END PGP PUBLIC KEY BLOCK-----
```
Output the key in generic DNS record format:


```
  $ pgpfinger -q keyserver -o generic ich@markusbenning.de
  243180e319b0d0752f8903f25dde3d9c99b7623d6b6358a21ab08bd0._openpgpkey.markusbenning.de. IN TYPE65280 \# 1475 99010d0452959cbb010800d95575cf2da55151569a181c6d9813560251d28893...
```
or in RFC DNS record format:


```
  $ pgpfinger -q keyserver -o rfc ich@markusbenning.de
  243180e319b0d0752f8903f25dde3d9c99b7623d6b6358a21ab08bd0._openpgpkey.markusbenning.de. IN OPENPGPKEY  mQENBFKVnLsBCADZVXXPLaVRUVaaGBxtmBNWAlHSiJPhdC8SPgSB/idpX5XBUKD31IBO6oisixb3tLaQsSsz/tP+8x+ynzS3Gi9NyHXassy+8k5eqxiyzn9aXqAOIT2yIaDyVQb9F37z2j...
```
Query DNS for armored key:


```
  $ pgpfinger -q DNS ich@markusbenning.de
  # source: DNS
  # domain: markusbenning.de
  # dnssec: ok
  -----BEGIN PGP PUBLIC KEY BLOCK-----
  Version: pgpfinger (head)
  
  mQENBFKVnLsBCADZVXXPLaVRUVaaGBxtmBNWAlHSiJPhdC8SPgSB/idpX5XBUKD3
  ----<cut>----
  sAfWnA4irE8RQqEhgKmIxHzQ7p3j8Eui2+FDaFZosVqDyJjX
  =MbDW
  -----END PGP PUBLIC KEY BLOCK-----
```
# AUTHOR

Markus Benning <ich@markusbenning.de>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Markus Benning.

This is free software, licensed under:


```
  The GNU General Public License, Version 2 or later
```
