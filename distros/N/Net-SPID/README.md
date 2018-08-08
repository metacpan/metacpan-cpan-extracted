# Net::SPID
Perl module for SPID authentication

[![Join the #spid-perl channel](https://img.shields.io/badge/Slack%20channel-%23spid--perl-blue.svg?logo=slack)](https://developersitalia.slack.com/messages/C7ESTMQDQ)
[![Get invited](https://slack.developers.italia.it/badge.svg)](https://slack.developers.italia.it/)
[![SPID on forum.italia.it](https://img.shields.io/badge/Forum-SPID-blue.svg)](https://forum.italia.it/c/spid) [![Build Status](https://travis-ci.org/italia/spid-perl.svg?branch=master)](https://travis-ci.org/italia/spid-perl) [![MetaCPAN Release](https://badge.fury.io/pl/Net-SPID.svg)](https://metacpan.org/pod/Net::SPID)

This Perl module is aimed at implementing SPID Service Providers and Attribute Authorities. [SPID](https://www.spid.gov.it/) is the Italian digital identity system, which enables citizens to access all public services with single set of credentials. This module provides a layer of abstraction over the SAML protocol by exposing just the subset required in order to implement SPID authentication in a web application. In addition, it will be able to generate the HTML code of the SPID login button and enable developers to implement an Attribute Authority.

This module is not bound to any particular web framework, so you'll have to do some plumbing yourself in order to route protocol messages over HTTP (see the [example/](example/) directory for a full working example).

On top of this module, plugins for web frameworks can be developed in order to achieve even more API abstraction. See [Dancer2::Plugin::SPID](https://github.com/italia/spid-perl-dancer2) for the well-known [Dancer2](http://perldancer.org) framework. A plugin for Mojolicious is in the works.

## Features

|<img src="https://github.com/italia/spid-graphics/blob/master/spid-logos/spid-logo-c-lb.png?raw=true" width="100" /><br />_Compliance with [SPID regulations](http://www.agid.gov.it/sites/default/files/circolari/spid-regole_tecniche_v1.pdf) (for Service Providers)_||
|:---|:---|
|**Metadata:**||
|parsing of IdP XML metadata (1.2.2.4)|✓|
|parsing of AA XML metadata (2.2.4)||
|SP XML metadata generation (1.3.2)|✓|
|**AuthnRequest generation (1.2.2.1):**||
|generation of AuthnRequest XML|✓|
|HTTP-Redirect binding|✓|
|HTTP-POST binding|✓|
|`AssertionConsumerServiceURL` customization|✓|
|`AssertionConsumerServiceIndex` customization|✓|
|`AttributeConsumingServiceIndex` customization|✓|
|`AuthnContextClassRef` (SPID level) customization|✓|
|`RequestedAuthnContext/@Comparison` customization|✓|
|`RelayState` customization (1.2.2)|✓|
|**Response/Assertion parsing**||
|verification of `Signature` value (if any)|✓|
|verification of `Signature` certificate (if any) against IdP/AA metadata|✓|
|verification of `Assertion/Signature` value|✓|
|verification of `Assertion/Signature` certificate against IdP/AA metadata|✓|
|verification of `SubjectConfirmationData/@Recipient`|✓|
|verification of `SubjectConfirmationData/@NotOnOrAfter`|✓|
|verification of `SubjectConfirmationData/@InResponseTo`|✓|
|verification of `Issuer`|✓|
|verification of `Assertion/Issuer`|✓|
|verification of `Destination`|✓|
|verification of `Conditions/@NotBefore`|✓|
|verification of `Conditions/@NotOnOrAfter`|✓|
|verification of `Audience`|✓|
|parsing of Response with no `Assertion` (authentication/query failure)|✓|
|parsing of failure `StatusCode` (Requester/Responder)|✓|
|**Response/Assertion parsing for SSO (1.2.1, 1.2.2.2, 1.3.1):**||
|parsing of `NameID`|✓|
|parsing of `AuthnContextClassRef` (SPID level)|✓|
|parsing of attributes|✓|
|**Response/Assertion parsing for attribute query (2.2.2.2, 2.3.1):**||
|parsing of attributes| |
|**LogoutRequest generation (for SP-initiated logout):**||
|generation of LogoutRequest XML|✓|
|HTTP-Redirect binding|✓|
|HTTP-POST binding|✓|
|**LogoutResponse parsing (for SP-initiated logout):**||
|parsing of LogoutResponse XML|✓|
|verification of `Response/Signature` value (if any)|✓|
|verification of `Response/Signature` certificate (if any) against IdP metadata|✓|
|verification of `Issuer`|✓|
|verification of `Destination`|✓|
|PartialLogout detection|✓|
|**LogoutRequest parsing (for third-party-initiated logout):**||
|parsing of LogoutRequest XML|✓|
|verification of `Response/Signature` value (if any)|✓|
|verification of `Response/Signature` certificate (if any) against IdP metadata|✓|
|verification of `Issuer`|✓|
|verification of `Destination`|✓|
|parsing of `NameID`|✓|
|**LogoutResponse generation (for third-party-initiated logout):**||
|generation of LogoutResponse XML|✓|
|HTTP-Redirect binding|✓|
|HTTP-POST binding|✓|
|PartialLogout customization|✓|
|**AttributeQuery generation (2.2.2.1):**||
|generation of AttributeQuery XML| |
|SOAP binding (client)| |

|<img src="https://github.com/italia/spid-graphics/blob/master/spid-logos/spid-logo-c-lb.png?raw=true" width="100" /><br />_Compliance with [SPID regulations](http://www.agid.gov.it/sites/default/files/circolari/spid-regole_tecniche_v1.pdf) (for Attribute Authorities)_||
|:---|:---|
|**Metadata:**||
|parsing of SP XML metadata (1.3.2)| |
|AA XML metadata generation (2.2.4)| |
|**AttributeQuery parsing (2.2.2.1):**||
|parsing of AttributeQuery XML| |
|verification of `Signature` value| |
|verification of `Signature` certificate against SP metadata| |
|verification of `Issuer`| |
|verification of `Destination`| |
|parsing of `Subject/NameID`| |
|parsing of requested attributes| |
|**Response/Assertion generation (2.2.2.2):**||
|generation of `Response/Assertion` XML| |
|Signature| |

### More features

* [ ] Generation of SPID button markup

## Repository layout

* [example/](example/) contains a demo application based on Dancer2
* [lib/Net/SPID.pm](lib/Net/SPID.pm) contains the source code of the Net::SPID module, which is just a wrapper around Net::SPID::SAML and Net::SPID::OpenID
* [t/](t/) contains the test suite

## Prerequisites & installation

This module should be compatible with Perl 5.10+.
Just install it with cpanm and all dependencies will be retrieved automatically:

```
cpanm Net::SPID
```

Or, if you want the latest version from git, use:

```
cpanm https://github.com/italia/spid-perl/archive/master.tar.gz
```

## Documentation

See the POD documentation in [Net::SPID](lib/Net/SPID.pm) and the other .pm files or browse it on [MetaCPAN](https://metacpan.org/release/Net-SPID).

## See also

* [SPID page](https://developers.italia.it/it/spid) on Developers Italia

## Authors

* [Alessandro Ranellucci](https://github.com/alexrj) (maintainer) - [Team per la Trasformazione Digitale](https://teamdigitale.governo.it/) - Presidenza del Consiglio dei Ministri
    * [alranel@teamdigitale.governo.it](alranel@teamdigitale.governo.it)
