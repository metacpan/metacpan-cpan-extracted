# ServiceNow::SOAP

## Description

A better Perl API for ServiceNow.

This API is simpler than ServiceNow::Simple 
and more powerful than ServiceNow's out-of-box Perl API.

Features of this module include:

* Support for both Direct and Scripted Web Services API.

* Simple API which closely mirrors
ServiceNow's Direct Web Services API documentation.

* Robust and easy to use methods for reading 
large quantities of data
based on ServiceNow's best practice recommendations.

* Specialized functions such as attachFile and getVariables.

## Installation

To install this module

    perl Makefile.PL
    make
    make test
    make install

## Dependencies

    SOAP::Lite
    LWP::UserAgent
    HTTP::Cookies
    MIME::Base64
    XML::Simple
    Time::HiRes

## License and Copyright

Copyright (C) 2015 by Giles Lewis

This is free software licensed under the terms of
the the Artistic License (2.0).

