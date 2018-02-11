# nps-sdk-perl
Perl Server-side SDK

Status: Under Development

#  Perl SDK
 

## Availability
Supports Perl 5.24.1

## How to install

```
cpan install NpsSDK
```

## Configuration

It's a basic configuration of the SDK

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_");
```

Here is a simple example request:

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV, 
                                 secret_key  => "_YOUR_SECRET_KEY_");

my $params = {
    'psp_Version' => '2.2',
    'psp_MerchantId' => 'psp_test',
    'psp_TxSource' => 'WEB',
    'psp_MerchTxRef' => 'ORDER69461-3',
    'psp_MerchOrderId' => 'ORDER69461',
    'psp_Amount' => '15050',
    'psp_NumPayments' => '1',
    'psp_Currency' => '032',
    'psp_Country' => 'ARG',
    'psp_Product' => '14',
    'psp_CardNumber' => '4507990000000010',
    'psp_CardExpDate' => '1612',
    'psp_PosDateTime' => '2016-12-01 12:00:00',
    'psp_CardSecurityCode' => '123'
};

my $response = NpsSDK::Nps::pay_online_2p($params);
```

## environments

```perl
use NpsSDK::Nps;

$NpsSDK::Constants::PRODUCTION_ENV
$NpsSDK::Constants::STAGING_ENV
$NpsSDK::Constants::SANDBOX_ENV
```

## Advanced configurations

Nps SDK allows you to log what’s happening with you request inside of our SDK.
In order to do so you will have to create a logger with Log::Log4perl as DEBUG and pass it by configuration.

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 logger      => $logger);
```

The $Log::Log4perl::INFO level will write concise information of the request and will mask sensitive data of the request. 
The $Log::Log4perl::DEBUG level will write information about the request to let developers debug it in a more detailed way.

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 logger      => $logger,
                                 log_level   => $Log::Log4perl::INFO);

```

Simple Debug Example:

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);
my $logger = get_logger();
my $appender = Log::Log4perl::Appender->new("Log::Dispatch::Screen");
$logger->add_appender($appender);
my $layout = Log::Log4perl::Layout::PatternLayout->new(
                     "%d %p:");
$appender->layout($layout);

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 logger      => $logger,
                                 log_level   => $Log::Log4perl::INFO);
```

Sanitize allows the SDK to truncate to a fixed size some fields that could make request fail, like extremely long name.

```perl
use NpsSDK::Nps;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 sanitize    => 1);
```

You can change the timeout of the request.

```perl
use NpsSDK::Nps;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 timeout     => 60);
```

