Net::PayPal::Lite
==================

Unofficial Perl extension for PayPal's REST API (Lite version)

### Installation

    cpanm Net::PayPal


Usage
--------

```perl
    use Net::PayPal::Lite;

    my $paypal = Net::PayPal::Lite->new(
        client_id => $client_id,
        secret    => $client_secret
    );

    my $payment = $paypal->cc_payment({
        cc_number       => '4111111111111111',
        cc_type         => 'visa',
        cc_expire_month => 3,
        cc_expire_year  => 2099,
        amount          => 19.95,
    }) or die $paypal->error;

    if ($payment->{state} eq 'approved') {
        say 'Thank you for your payment!';
    }
```

Description
-----------

Net::PayPal implements PayPal's REST API. Visit
http://developer.paypal.com for further information.

To start using Net::PayPal the following actions must be completed to
gain access to API endpoints.

Please refer to the
[module's documentation online](https://metacpan.org/pod/Net::PayPal::Lite)
or, after installing it, via the command

    perldoc Net::PayPal::Lite


Credits
-------

Net::PayPal::Lite is an immediate fork of Sherzod B. Ruzmetov's excellent Net::PayPal, which sadly hasn't been updated in a while.

**Net::PayPal::Lite is NOT affiliated with PayPal nor PayPal, Inc. in any way.**

PayPal is a trademark of PayPal, Inc.


COPYRIGHT AND LICENSE
---------------------

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
