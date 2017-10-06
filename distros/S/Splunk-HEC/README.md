
# Splunk::HEC [![Build Status](https://travis-ci.org/eforbus/perl-splunk-hec.svg)](https://travis-ci.org/eforbus/perl-splunk-hec)

`Splunk::HEC` is a simple client wrapper provided to interface with Splunk's HTTP Event Collector (HEC) API.

HEC is a fast and efficient way to send data to Splunk Enterprise and Splunk Cloud. Notably, HEC enables you to send data over HTTP (or HTTPS) directly to Splunk Enterprise or Splunk Cloud from your application. HEC was created with application developers in mind, so that all it takes is a few lines of code added to an app for the app to send data. Also, HEC is token-based, so you never need to hard-code your Splunk Enterprise or Splunk Cloud credentials in your app or supporting files. HTTP Event Collector provides a new way for developers to send application logging and metrics directly to Splunk Enterprise and Splunk Cloud via HTTP in a highly efficient and secure manner.

_NOTE: This library is not maintained or affiliated with Splunk._

## References
- [Introduction to Splunk HTTP Event Collector](http://dev.splunk.com/view/event-collector/SP-CAAAE6M)
- [Splunk HEC Walkthrough](http://dev.splunk.com/view/event-collector/SP-CAAAE7F)  

## Features

  * `Splunk::HEC` provides a simple means to send HEC events to Splunk
  * Events can be sent one at a time or batched

## Installation

  All you need is a one-liner, it takes less than a minute.

    $ curl -L https://cpanmin.us | perl - -M https://cpan.metacpan.org -n Splunk::HEC 

  We recommend the use of a [Perlbrew](http://perlbrew.pl) environment.

## Getting Started

  The module is very easy to use...

```perl
use Splunk::HEC; 

my $hec = Splunk::HEC->new(
  url  => 'https://splk.example.com:8088/services/collector/event',
  token => '12345678-1234-1234-1234-1234567890AB'
);

my $res = $hec->send(event => {
  message  => 'Something happened', 
  severity => 'INFO'
});

if ($res->is_success) { say $res->content }
elsif ($res->is_error) { say $res->reason }
```

## Documentation

  Take a look at our [documentation](https://metacpan.org/pod/Splunk::HEC)
