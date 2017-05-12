# NAME
Net::Payjp

# VERSION
version 0.1.4

# SYNOPSIS
```
# Create charge
my $payjp = Net::Payjp->new(api_key => $API_KEY);
my $card = {
  number => '4242424242424242',
  exp_month => '02',
  exp_year => '2020',
  address_zip => '2020014'
};
my $res = $payjp->charge->create(
  card => $card,
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
## new PARAMHASH
This creates a new Payjp api object. The following parameters are accepted:

###api_key
This is required. You get this from your account settings on PAY.JP.

## ATTRIBUTES
### api_key
Reader: api_key

Type: Str

This attribute is required.

# Charge Methods
## create
Create a new charge

http://docs.pay.jp/docs/charge-create

```
my $card = {
  number => '4242424242424242',
  exp_month => '02',
  exp_year => '2020',
  address_zip => '2020014'
};
$payjp->charge->create(
  card => $card,
  amount => 3500,
  currency => 'jpy',
  description => 'yakiimo',
);
```

## retrieve
Retrieve a charge

http://docs.pay.jp/docs/charge-retrieve

```
$payjp->charge->retrieve('ch_fa990a4c10672a93053a774730b0a');
```

## save
Update a charge

http://docs.pay.jp/docs/charge-update

```
$payjp->id('ch_fa990a4c10672a93053a774730b0a');
$payjp->charge->save(description => 'update description.');
```

## refund
Refund a charge

http://docs.pay.jp/docs/charge-refund

```
$payjp->id('ch_fa990a4c10672a93053a774730b0a');
$payjp->charge->refund(amount => 1000, refund_reason => 'test.');
```

## capture
Capture a charge

http://docs.pay.jp/docs/charge-capture

```
$payjp->id('ch_fa990a4c10672a93053a774730b0a');
$payjp->charge->capture(amount => 2000);
```

## all
Returns the charge list

http://docs.pay.jp/docs/charge-list

```
$payjp->charge->all("limit" => 2, "offset" => 1);
```

# Customer Methods
## create
Create a cumtomer

http://docs.pay.jp/docs/customer-create

```
$payjp->customer->create(
  "description" => "test",
);
```

## retrieve
Retrieve a customer

http://docs.pay.jp/docs/customer-retrieve

```
$payjp->customer->retrieve('cus_121673955bd7aa144de5a8f6c262');
```

## save
Update a customer

http://docs.pay.jp/docs/customer-update

```
$payjp->id('cus_121673955bd7aa144de5a8f6c262');
$payjp->customer->save(email => 'test@test.jp');
```

## delete
Delete a customer

http://docs.pay.jp/docs/customer-delete

```
$payjp->id('cus_121673955bd7aa144de5a8f6c262');
$payjp->customer->delete;
```

## all
Returns the customer list

http://docs.pay.jp/docs/customer-list

```
$res = $payjp->customer->all(limit => 2, offset => 1);
```

# Cutomer card Methods
Returns a customer's card object

```
my $card = $payjp->customer->card('cus_4df4b5ed720933f4fb9e28857517');
```

## create
Create a customer's card

http://docs.pay.jp/docs/customer-card-create

```
$card->create(
  number => '4242424242424242',
  exp_year => '2020',
  exp_month => '02'
);
```

## retrieve
Retrieve a customer's card

http://docs.pay.jp/docs/customer-card-retrieve

```
$card->retrieve('car_f7d9fa98594dc7c2e42bfcd641ff');
```

## save
Update a customer's card

http://docs.pay.jp/docs/customer-card-update

```
$card->id('car_f7d9fa98594dc7c2e42bfcd641ff');
$card->save(exp_year => "2026", exp_month => "05", name => 'test');
```

## delete
Delete a customer's card

http://docs.pay.jp/docs/customer-card-delete

```
$card->id('car_f7d9fa98594dc7c2e42bfcd641ff');
$card->delete;
```

## all
Returns the customer's card list

http://docs.pay.jp/docs/customer-card-list

```
$card->all(limit => 2, offset => 0);
```

# Customer subscription Methods
Returns a customer's subscription object

```
my $subscription = $payjp->customer->subscription('sub_567a1e44562932ec1a7682d746e0');
```

## retrieve
Retrieve a customer's subscription

http://docs.pay.jp/docs/customer-subscription-retrieve

```
$subscription->retrieve('sub_567a1e44562932ec1a7682d746e0');
```

## all
Returns the customer's subscription list

http://docs.pay.jp/docs/customer-subscription-list

```
$subscription->all(limit => 1, offset => 0);
```

# Plan Methods
## create
Create a plan

http://docs.pay.jp/docs/plan

```
$payjp->plan->create(
  amount => 500,
  currency => "jpy",
  interval => "month",
  trial_days => 30,
  name => 'test_plan'
);
```

## retrieve
Retrieve a plan

http://docs.pay.jp/docs/plan-retrieve

```
$payjp->plan->retrieve('pln_45dd3268a18b2837d52861716260');
```

## save
Update a plan

http://docs.pay.jp/docs/plan-update

```
$payjp->id('pln_45dd3268a18b2837d52861716260');
$payjp->plan->save(name => 'NewPlan');
```

## delete
Delete a plan

http://docs.pay.jp/docs/plan-delete

```
$payjp->id('pln_45dd3268a18b2837d52861716260');
$payjp->plan->delete;
```

## all
Returns the plan list

http://docs.pay.jp/docs/plan-list

```
$payjp->plan->all("limit" => 5, "offset" => 0);
```

# Subscription Methods
## create
Create a subscription

http://docs.pay.jp/docs/subscription-create

```
$payjp->subscription->create(
  customer => 'cus_4df4b5ed720933f4fb9e28857517',
  plan => 'pln_9589006d14aad86aafeceac06b60'
);
```

## retrieve
Retrieve a subscription

http://docs.pay.jp/docs/subscription-retrieve

```
$payjp->subscription->retrieve('sub_567a1e44562932ec1a7682d746e0');
```

## save
Update a subscription

http://docs.pay.jp/docs/subscription-update

```
$payjp->id('sub_567a1e44562932ec1a7682d746e0');
$payjp->subscription->save(trial_end => 1473911903);
```

## pause
Pause a subscription

http://docs.pay.jp/docs/subscription-pause

```
$payjp->id('sub_567a1e44562932ec1a7682d746e0');
$payjp->subscription->pause;
```

## resume
Resume a subscription

http://docs.pay.jp/docs/subscription-resume

```
$payjp->id('sub_567a1e44562932ec1a7682d746e0');
$payjp->subscription->resume;
```

## cancel
Cancel a subscription

http://docs.pay.jp/docs/subscription-cancel

```
$payjp->id('sub_567a1e44562932ec1a7682d746e0');
$payjp->subscription->cancel;
```

## delete
Delete a subscription

http://docs.pay.jp/docs/subscription-delete

```
$payjp->id('sub_567a1e44562932ec1a7682d746e0');
$payjp->subscription->delete;
```

## all
Returns the subscription list

http://docs.pay.jp/docs/subscription-list

```
$payjp->subscription->all(limit => 3, offset => 0);
```

# Token Methods
## create
Create a token

http://docs.pay.jp/docs/token-create

```
my $card = {
  number => '4242424242424242',
  cvc => "1234",
  exp_month => "02",
  exp_year =>"2020"
};
$payjp->token->create(
  card => $card,
);
```

## retrieve
Retrieve a token

http://docs.pay.jp/docs/token-retrieve

```
$payjp->token->retrieve('tok_eff34b780cbebd61e87f09ecc9c6');
```

# Transfer Methods
## retrieve
Retrieve a transfer

http://docs.pay.jp/docs/transfer-retrieve

```
$payjp->transfer->retrieve('tr_8f0c0fe2c9f8a47f9d18f03959ba1');
```

## all
Returns the transfer list

http://docs.pay.jp/docs/transfer-list

```
$res = $payjp->transfer->all("limit" => 3, offset => 0);
```

# charges
Returns the charge list

http://docs.pay.jp/docs/transfer-charge-list

```
$payjp->transfer->charges(
  limit => 3,
  offset => 0
);
```

# Event Methods
## retrieve
Retrieve a event

http://docs.pay.jp/docs/retrieve-event

```
$res = $payjp->event->retrieve('evnt_2f7436fe0017098bc8d22221d1e');
```

## all
Returns the event list

http://docs.pay.jp/docs/event-list

```
$payjp->event->all(limit => 10, offset => 0);
```

# Account Methods
## retrieve
Retrieve a account

http://docs.pay.jp/docs/account-retrieve

```
$payjp->account->retrieve;
```

# use package
## need to install the following package
```
$ cmanm package
or
$ perl -MCPAN -e shell
cpan> install package
```

- LWP::UserAgent
- LWP::Protocol::https
- HTTP::Request::Common
- JSON
- Test::More

# Perl version
ver.10 or higher is required

# SEE ALSO
- http://docs.pay.jp
- https://github.com/payjp/user-docs

# AUTHORS
BASE, Inc.

# COPYRIGHT AND LICENSE
This software is copyright (c) 2015 by BASE, Inc.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.
