[![Build Status](https://travis-ci.com/Hypernova-Oy/SMS-Send-BudgetSMS.svg?branch=master)](https://travis-ci.com/Hypernova-Oy/SMS-Send-BudgetSMS)

# SMS-Send-BudgetSMS

SMS::Send::BudgetSMS - SMS::Send driver to send messages via BudgetSMS, https://www.budgetsms.net/

## VERSION

version 0.04

## SYNOPSIS

```
  use SMS::Send;

  # Create a sender
  my $sender = SMS::Send->new(
      'BudgetSMS',
      _login    => 'budgetsms_username',
      _userid   => 'budgetsms_userid',
      _password => 'budgetsms_handle',
  );

  # Send a message
  my $sent = $sender->send_sms(
      text => 'This is a test message',
      to   => '+61 (4) 1234 5678',
  );

  if ($sent) {
      print "Message sent ok\n";
  }
  else {
      print "Failed to send message\n";
  }
```

## DESCRIPTION

SMS::Send driver for BudgetSMS - https://www.budgetsms.net/

This is not intended to be used directly, but instead called by SMS::Send (see
synopsis above for a basic illustration, and see SMS::Send's documentation for
further information).

The driver uses the BudgetSMS HTTP API mechanism.  This is documented at
https://www.budgetsms.net/sms-http-api/send-sms/

## METHODS

### new

Constructor, takes argument pairs passed by SMS::Send, returns an
SMS::Send::BudgetSMS object.  See usage synopsis for example, and see SMS::Send
documentation for further info on using SMS::Send drivers.

Additional arguments that may be passed include:-

#### _userid

BudgetSMS userid

#### _endpoint

The HTTP API endpoint. Defaults to
https://api.budgetsms.net/sendsms/

For development purposes, you may also use test API
https://api.budgetsms.net/testsms/

#### _timeout

The timeout in seconds for HTTP operations. Defaults to 20 seconds.

### send_sms

Send the message - see SMS::Send for details.  Additionally the following
options can be given - these have the same meaning as they do in the C<new>
method:-

#### _from

Alphanumeric or Numeric senderid (shown as the sender of SMS)

## INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

## BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through GitHub
 at https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS/issues

## AVAILABILITY

The project homepage is https://github.com/Hypernova-Oy/SMS-Send-BudgetSMS

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit http://www.perl.com/CPAN/ to find a CPAN
site near you, or see https://metacpan.org/module/SMS::Send::BudgetSMS/

## AUTHOR

Lari Taskula <lari.taskula@hypernova.fi>
Hypernova Oy, https://www.hypernova.fi

## COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Hypernova Oy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
