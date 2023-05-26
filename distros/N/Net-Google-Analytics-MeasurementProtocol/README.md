## Net-Google-Analytics-MeasurementProtocol ##

This is a Perl interface to [Google Analytics Measurement Protocol](https://developers.google.com/analytics/devguides/collection/protocol/ga4),
allowing developers to make HTTP requests to send raw user interaction data
directly to Google Analytics 4 (GA4) servers. It can be used to tie online
to offline behaviour, sending analytics data from both the web
(via JavaScript) and from the server (via this module).

```perl
    use Net::Google::Analytics::MeasurementProtocol;

    my $ga = Net::Google::Analytics::MeasurementProtocol->new(
        api_secret     => '...',
        measurement_id => '...',
    );

    $ga->send( level_up => { character => 'Alma', level => 99 } );

    $ga->send_multiple([
        {
            purchase => {
                transaction_id => 'T-1234',
                currency       => 'USD',
                value          => 14.99,
                coupon         => 'SPECIALPROMO',
                shipping       => 2.99,
                tax            => 0.37,
                items          => [
                    { item_id => 'X-1234', item_name => 'Amazing Tee' },
                    { item_id => 'Y-4321', item_name => 'Cool Shades' },
                ],
            },
        },
        {
            earn_virtual_currency => {
                virtual_currency_name => 'StoreCash',
                value => 999,
            },
        },
    ]);
```

See [Google's complete parameter reference](https://developers.google.com/analytics/devguides/collection/protocol/ga4/reference?client_type=gtag) for all the events and parameters you can pass.

#### Installation ####

    cpanm Net::Google::Analytics::MeasurementProtocol

or manually:

    perl Makefile.PL
    make test
    make install

Please refer to [this module's complete documentation](https://metacpan.org/pod/Net::Google::Analytics::MeasurementProtocol)
for extra information.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>.

Google and Google Analytics are trademarks of Google LLC.

This software is not endorsed by or affiliated with Google in any way.
