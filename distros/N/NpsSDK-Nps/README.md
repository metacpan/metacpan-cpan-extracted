# Perl SDK

  
## Availability
Supports Perl 5.24.1

## How to install

```
cpan install NpsSDK::Nps
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

## Environments

```perl
use NpsSDK::Nps;

$NpsSDK::Constants::PRODUCTION_ENV
$NpsSDK::Constants::STAGING_ENV
$NpsSDK::Constants::SANDBOX_ENV
```

## Error handling

You can check if something went wrong checking the type of $response. There are 3 type of errors: Timeout, Connection and Unknown. Their type of object are NpsSDK::TimeoutException, NpsSDK::ConnectionException, NpsSDK::UnknownError respectively.

The example below also work for Connection and Unknown errors.

```perl
use NpsSDK::Nps;
use warnings;
use stricts;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 timeout     => 60);

my $response = NpsSDK::Nps::pay_online_2p($params);

if (ref($response) eq "NpsSDK::TimeoutException") {
    #Your code to handle the error
};
```

## Advanced configurations

### Logging 

Nps SDK allows you to log what’s happening with you request inside of our SDK.
In order to do so you will have to create a logger with Log::Log4perl and pass it by configuration.

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 logger      => $logger);
```

### LogLevel

The INFO level will write concise information of the request and will mask sensitive data of the request. 
The DEBUG level will write information about the request to let developers debug it in a more detailed way.
You can change the level in Log4perl init method.

Simple debug screen logging example:

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

use Log::Log4perl;

Log::Log4perl->init(\<<CONFIG);
log4perl.rootLogger = INFO, screen

log4perl.appender.screen = Log::Log4perl::Appender::Screen
log4perl.appender.screen.stderr = 0
log4perl.appender.screen.layout = PatternLayout
log4perl.appender.screen.layout.ConversionPattern = %d %p %m%n

CONFIG

my $logger = Log::Log4perl::get_logger();

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 logger      => $logger);
```

You can also save the logs in a file:

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

use Log::Log4perl;

Log::Log4perl->init(\<<CONFIG);
log4perl.rootLogger = DEBUG, screen, file

log4perl.appender.screen = Log::Log4perl::Appender::Screen
log4perl.appender.screen.stderr = 0
log4perl.appender.screen.layout = PatternLayout
log4perl.appender.screen.layout.ConversionPattern = %d %p %m%n

log4perl.appender.file = Log::Log4perl::Appender::File
log4perl.appender.file.filename = YOUR_LOG_FILE.log
log4perl.appender.file.mode = append
log4perl.appender.file.layout = PatternLayout
log4perl.appender.file.layout.ConversionPattern = %d %p %m%n
CONFIG

my $logger = Log::Log4perl::get_logger();

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 logger      => $logger);
```

### Sanitize

Sanitize allows the SDK to truncate to a fixed size some fields that could make request fail, like extremely long name.

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 sanitize    => 1);
```

### Timeout

You can change the timeout of the request.

```perl
use NpsSDK::Nps;
use warnings; 
use strict;

NpsSDK::Configuration::configure(environment => $NpsSDK::Constants::SANDBOX_ENV,
                                 secret_key  => "_YOUR_SECRET_KEY_",
                                 timeout     => 60);
```

