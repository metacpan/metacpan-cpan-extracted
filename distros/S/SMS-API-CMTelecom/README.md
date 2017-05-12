# SMS::API::CMTelecom

[![Build Status](https://travis-ci.org/sonntagd/SMS-API-CMTelecom.svg?branch=master)](https://travis-ci.org/sonntagd/SMS-API-CMTelecom)

This module provides a basic implementation of the cmtelecom.com SMS API:

+ send SMS messages
+ validate phone numbers and get other details about a number (like provider, region, timezone)

It also contains a SMS::Send:: module to provide SMS sending via this standard interface. As SMS::Send only allows sending SMS, you must use SMS::API::CMTelecom if you want to use the additional features.

## INSTALLATION

To install this module, easily run the following command:

    cpanm SMS::API::CMTelecom

## BUGS AND SUPPORT

Please report any bugs or feature requests on [Github](https://github.com/sonntagd/SMS-API-CMTelecom/issues)


## LICENSE AND COPYRIGHT

Copyright 2017 Dominic Sonntag.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

http://www.perlfoundation.org/artistic_license_2_0

