Perl bindings for Upwork API (OAuth2)
============

[![License](http://img.shields.io/packagist/l/upwork/php-upwork.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CPAN](https://img.shields.io/cpan/v/Net-Upwork-API.svg)](https://metacpan.org/pod/Net::Upwork::API)
[![GitHub release](https://img.shields.io/github/release/upwork/perl-upwork.svg)](https://github.com/upwork/perl-upwork/releases)
[![Build Status](https://github.com/upwork/perl-upwork-oauth2/workflows/build/badge.svg)](https://github.com/upwork/perl-upwork-oauth2/actions)

# Introduction
This project provides a set of resources of Upwork API from http://developers.upwork.com
 based on OAuth 2.0.

# Features
The library supports all GraphQL calls, which are publicly shared at Upwork

# License

Copyright 2015 Upwork Corporation. All Rights Reserved.

perl-upwork is licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

## SLA
The usage of this API is ruled by the Terms of Use at:

    https://developers.upwork.com/api-tos.html

# Application Integration
To integrate this library you need to have:

* Perl >= 5.008003
* CPAN

## Example
In addition to this, a full example is available in the `example` directory. 
This includes `example.pl` that gets an access token and requests the data
for applications that are not web-based applications.

## Installation
1.
Start `cpan`

2.
Run the following command to install API:
```
cpan> install Net::Upwork::API
```

3.
open `example.pl` and type the clientId (a.k.a. consumer key), clientSecret (a.k.a. client secret) and `redirectUri` that you previously got from the API Center
***That's all. Run your app as `perl example.pl` and have fun.***
