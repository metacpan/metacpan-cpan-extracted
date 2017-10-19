# NAME

ParseUtil::Domain - Domain parser and puny encoder/decoder.

[![Build Status](https://travis-ci.org/heytrav/ParseUtil-Domain.svg?branch=remove-utf8)](https://travis-ci.org/heytrav/ParseUtil-Domain)

# SYNOPSIS

    use ParseUtil::Domain ':parse';

      my $processed = parse_domain("somedomain.com");
      #$processed:
      #{
          #domain => 'somedomain',
          #domain_ace => 'somedomain',
          #zone => 'com',
          #zone_ace => 'com'
      #}

# DESCRIPTION

This purpose of this module is to parse a domain name into its respective name and tld. Note that
the _tld_ may actually refer to a second- or third-level domain, e.g. co.uk or
plc.co.im.  It also provides respective puny encoded and decoded versions of
the parsed domain.

This module uses TLD data from the [Public Suffix List](http://publicsuffix.org/list/) which is included with this
distribution.

# INTERFACE

## parse\_domain

-
parse\_domain(string)
    -
    Examples:

             1. parse_domain('somedomain.com');

              Result:
              {
                  domain     => 'somedomain',
                  zone       => 'com',
                  domain_ace => 'somedomain',
                  zone_ace   => 'com'
              }

            2. parse_domain('test.xn--o3cw4h');

              Result:
              {
                  domain     => 'test',
                  zone       => 'ไทย',
                  domain_ace => 'test',
                  zone_ace   => 'xn--o3cw4h'
              }

            3. parse_domain('bloß.co.at');

              Result:
              {
                  domain     => 'bloss',
                  zone       => 'co.at',
                  domain_ace => 'bloss',
                  zone_ace   => 'co.at'
              }

            4. parse_domain('bloß.de');

              Result:
              {
                  domain     => 'bloß',
                  zone       => 'de',
                  domain_ace => 'xn--blo-7ka',
                  zone_ace   => 'de'
              }

            5. parse_domain('www.whatever.com');

             Result:
              {
                  domain     => 'www.whatever',
                  zone       => 'com',
                  domain_ace => 'www.whatever',
                  zone_ace   => 'com',
                  name       => 'whatever',
                  name_ace   => 'whatever',
                  prefix     => 'www',
                  prefix_ace => 'www'
              }

## puny\_convert

Toggles a domain between puny encoded and decoded versions.

    use ParseUtil::Domain ':simple';

    my $result = puny_convert('bloß.de');
    # $result: xn--blo-7ka.de

    my $reverse = puny_convert('xn--blo-7ka.de');
    # $reverse: bloß.de

# DEPENDENCIES

-
[Net::IDN::Encode](https://metacpan.org/pod/Net::IDN::Encode)
-
[Net::IDN::Punycode](https://metacpan.org/pod/Net::IDN::Punycode)
-
[Regexp::Assemble::Compressed](https://metacpan.org/pod/Regexp::Assemble::Compressed)
-
The [Public Suffix List](http://publicsuffix.org/list/).

