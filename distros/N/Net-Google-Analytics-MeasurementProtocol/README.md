## Net-Google-Analytics-MeasurementProtocol ##

[![Build Status](https://travis-ci.org/garu/Net-Google-Analytics-MeasurementProtocol.svg)](https://travis-ci.org/garu/Net-Google-Analytics-MeasurementProtocol)


This is a Perl interface to [Google Analytics Measurement Protocol](https://developers.google.com/analytics/devguides/collection/protocol/v1/),
allowing developers to make HTTP requests to send raw user interaction data
directly to Google Analytics servers. It can be used to tie online to offline
behaviour, sending analytics data from both the web (via JavaScript) and
from the server (via this module).

```perl
    use Net::Google::Analytics::MeasurementProtocol;

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        tid => 'UA-XXXX-Y',
    );

    # Now, instead of this JavaScript:
    # ga('send', 'pageview', {
    #     'dt': 'my new title'
    # });

    # you can do this, in Perl:
    $ga->send( 'pageview', {
        dt => 'my new title',
        dl => 'http://www.example.com/some/page',
    });
```

See [Google's complete parameter reference](https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters) for all the options you can pass.

#### Installation ####

    cpanm Net::Google::Analytics::MeasurementProtocol

or manually:

    perl Makefile.PL
    make test
    make install

Please refer to [this module's complete documentation](https://metacpan.org/pod/Net::Google::Analytics::MeasurementProtocol)
for extra information.


