# Selenium::Client

WC3 Standard selenium client

Automatically spins up/down drivers when pointing at localhost and nothing is already listening on the provided port

Working Drivers:

* Gecko
* Chrome
* MicrosoftEdge
* Safari

Also can auto-fetch the SeleniumHQ JAR file and run it.
This feature is only tested with the Selenium 4.0 or better JARs.

Also contains:

- Selenium::Specification

Module to turn the Online specification documents for Selenium into JSON specifications for use by API clients

Soon to come:

- BrowserMob Proxy integration

- Selenium::Server

Pure perl selenium server (that proxies commands to browser drivers, much like the SeleniumHQ Jar)

- Selenium::Grid

Pure perl selenium grid API server

- Selenium::Driver::Playwright

Selenium implemented in playwright (so that it no longer is crippled by inability to access some attrs/props)

- Selenium::Client::SRD

Drop-in replacement for Selenium::Remote::Driver

## Care and feeding

This module stores a number of things in your homedirectory's .selenium folder.
You may want to clear this out periodically, as various log files and configuration data becomes stale.

## BUILDING

This is a Dist::Zilla CPAN module.  To build this project, do the following:

* Install Dist::Zilla either via cpan or your favorite package manager

* `dzil authordeps --missing | sudo cpanm`
* `dzil listdeps   --missing | sudo cpanm`
* `dzil build`

## TESTING

To check how this works with your setup, install Selenium::Client from CPAN (or just clone this repo), and then run:

`prove -vm -Ilib at/sanity.test`

If you encounter problems, you can get extra debugging output (which would be very much appreciated in any issues you file):

`NO_HEADLESS=1 DEBUG=1 prove -vm -Ilib at/sanity.test`

This runs through 100% of the WC3 selenium API.
At release it passed on all of the supported browsers on:

* Windows 10
* OSX 10.13
* Ubuntu Linux (focal)

Please file a bug report on this repository's tracker if you get a NOT OK that isn't already in a SKIP or TODO block.

## LICENSE

This software is Copyright (c) 2021 by George S. Baugh.

This is free software, licensed under:

  The MIT (X11) License

The MIT License

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to
whom the Software is furnished to do so, subject to the
following conditions:

The above copyright notice and this permission notice shall
be included in all copies or substantial portions of the
Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT
WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT
SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
