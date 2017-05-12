# NAME

SMS::Send::Twilio - SMS::Send backend for Twilio API

# SYNOPSIS

    use SMS::Send;
    # Create an object. There are three required values:
    my $sender = SMS::Send->new('Twilio',
      _accountsid => 'ACb657bdcb16f06893fd127e099c070eca',
      _authtoken  => 'b857f7afe254fa86c689648447e04cff',
      _from       => '+15005550006',
      );
    

    # Send a message to me
    my $sent = $sender->send_sms(
      text => 'Messages have a limit of 160 chars',
      to   => '+31645742418',
      );
    

    # Did it send?
    if ( $sent ) {
      print "Sent test message\n";
    } else {
      print "Test message failed\n";
    }

# DESCRIPTION

SMS::Send::Twilio is an SMS::Send driver for the Twilio web service.

## new

    # Create a new sender using this driver
    my $sender = SMS::Send->new('Twilio',
      _accountsid => 'ACb657bdcb16f06893fd127e099c070eca',
      _authtoken  => 'b857f7afe254fa86c689648447e04cff',
      _from       => '+15005550006',
    );

The `new` constructor takes three parameters, which should be passed
through from the [SMS::Send](http://search.cpan.org/perldoc?SMS::Send) constructor.

## send\_sms

It's really easy; if it returns a true value, sending the message was OK.
If not we'd see an error message on STDERR.

    # Send a message to me
      my $sent = $sender->send_sms(
      text => 'Messages have a limit of 160 chars',
      to   => '+31645742418',
    );

# AUTHOR

Michiel Beijen <michiel.beijen@gmail.com>

# COPYRIGHT

Copyright 2013- Michiel Beijen

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[SMS::Send](http://search.cpan.org/perldoc?SMS::Send)
[WWW::Twilio::API](http://search.cpan.org/perldoc?WWW::Twilio::API)
