# Net::Payjp

[![Build Status](https://github.com/payjp/payjp-perl/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/payjp/payjp-perl/actions)
![cpan](https://img.shields.io/cpan/v/Net-Payjp)

# Perl version

5.10 or higher is required

# SYNOPSIS

In advance, you need to get a token by [Checkout](https://pay.jp/docs/checkout) or [payjp.js](https://pay.jp/docs/payjs).

```perl
# Create charge
my $payjp = Net::Payjp->new(api_key => $API_KEY);
my $res = $payjp->charge->create(
  card => 'token_id_by_Checkout_or_payjp.js',
  amount => 3500,
  currency => 'jpy',
  description => 'test charge',
);
if(my $e = $res->error){
  print "Error";
  print $e->{message}."\n";
}

# Retrieve a charge
$payjp->id($res->id); # Set id of charge
$res = $payjp->charge->retrieve; # or $payjp->charge->retrieve($res->id);
```

# DESCRIPTION

This module is a wrapper around the Pay.jp HTTP API.Methods are generally named after the object name and the acquisition method.

This method returns json objects for responses from the API.

# METHODS

Please check [API Reference](https://pay.jp/docs/api/)

## new PARAMHASH

This creates a new Payjp api object by `Net::Payjp->new()`.
The following parameters are accepted:

### api_key

Type: Str

This attribute is required.
You get this from your account settings on PAY.JP.

### max_retry

Type: Int

You can automatically retry the request when the client received HTTP 429 response caused by [Rate Limit](https://pay.jp/docs/api/#rate-limit).
By default, this is 0 (=retry disabled). To activate, set `max_retry` for 1 or more.

```perl
my $payjp = Net::Payjp->new(api_key => 'sk_live_xxx', max_retry => 2);
```

### initial_delay

Type: Int

Please check `max_retry` and [Rate Limit](https://pay.jp/docs/api/#rate-limit).
By default, this is 2 (sec).

### max_delay

Type: Int

Please check `max_retry` and [Rate Limit](https://pay.jp/docs/api/#rate-limit).
By default, this is 32 (sec).

# Contribute
## Setup

```sh
$ cmanm package
or
$ perl -MCPAN -e shell
cpan> install LWP::UserAgent
cpan> install LWP::Protocol::https
cpan> install HTTP::Request::Common
cpan> install JSON
cpan> install Test::More
cpan> install Test::Mock::LWP
```

## Test

```sh
$ perl Makefile.PL
$ make test
```

or Check GitHub Actions
