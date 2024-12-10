# SmsAero API Client for Perl

## Installation:

```bash
cpanm SmsAero
```

## Usage example:

Get credentials from account settings page: https://smsaero.ru/cabinet/settings/apikey/

```perl
use strict;
use warnings;
use SmsAero;

my $SMSAERO_EMAIL = 'your email';
my $SMSAERO_API_KEY = 'your api key';

my $sms = SmsAero->new(
    email => $SMSAERO_EMAIL,
    api_key => $SMSAERO_API_KEY
);

eval {
    my $response = $sms->send_sms(
        number => '70000000000',
        text => 'Hello, World!'
    );
    use Data::Dumper;
    print "API Response:\n", Dumper($response);
};
if ($@) {
    print "An error occurred: $@\n";
}
```

#### Exceptions:

* `SmsAeroException` - base exception class for all exceptions raised by the library
* `SmsAeroConnectionException` - exception raised when there is a connection error
* `SmsAeroNoMoneyException` - exception raised when there is not enough money in the account

## Run on Docker:

```bash
docker pull 'smsaero/smsaero_perl:latest'
docker run -it --rm 'smsaero/smsaero_perl:latest' smsaero_send --email "your email" --api_key "your api key" --phone 70000000000 --message 'Hello, World!'
```

## License:

```
MIT License
```
