Here are some notes on how to upgrade from Net::STOMP::Client 1.x to 2.x.

Net::STOMP::Client 2.0 is mostly backward compatible with versions 1.x
but some changes might be needed for code using some specific features.
These are documented below.


Compatible Changes
==================

The following things have been changed in Net::STOMP::Client but version 2.0
provides backward compatibility for them. However, since this compatibility
will disappear at some point in future 2.x versions, it is recommended to
change your code after you have upgraded to Net::STOMP::Client 2.0.

Frame Checking
--------------

The frame checking code in Net::STOMP::Client::Frame has been removed. The
check() method is currently still present but it does nothing. You should
stop using it.

If needed, this functionality may come back as a separate optional  module.

demessagify()
-------------

The demessagify() class method is now a function. You should replace calls
like:

  $frame = Net::STOMP::Client::Frame->demessagify($message);

by:

  $frame = Net::STOMP::Client::Frame::demessagify($message);

Timeout parameter
-----------------

All the methods from the low-level API that had a timeout parameter:

  $stomp->send_frame(FRAME, TIMEOUT)
  $stomp->send_data(TIMEOUT)
  $stomp->receive_frame(TIMEOUT)
  $stomp->receive_data(TIMEOUT)

now instead have keyed options:

  $stomp->send_frame(FRAME, [OPTIONS])
  $stomp->send_data([OPTIONS])
  $stomp->receive_frame([OPTIONS])
  $stomp->receive_data([OPTIONS])

If you did not supply the timeout parameter (i.e. relying on it being undef),
you do not need to change anything. Otherwise, you should replace calls like:

  $stomp->send_frame($frame, $timeout);

by:

  $stomp->send_frame($frame, timeout => $timeout);


Incompatible Changes
====================

The following things have been changed and, if you use these features, you
must change your code before upgrading to Net::STOMP::Client 2.0.

Error Handling
--------------

Net::STOMP::Client 1.x used its own module to handle errors. Now, the more
standard No::Worries::Die module is used.

If you never modified $Net::STOMP::Client::Error::Die then nothing changes:
a fatal error will be reported by Perl's die().

Otherwise, you will have to use eval() and replace code like:

  local $Net::STOMP::Client::Error::Die = 0;
  $success = ... some Net::STOMP::Client code ...
  unless ($success) {
      ... error handling here ...
  }

by:

  eval { ... some Net::STOMP::Client code ... };
  if ($@) {
      ... error handling here ...
  }

Debugging
---------

Net::STOMP::Client 1.x used its own module to handle debugging. Now, the
more standard No::Worries::Log module is used.

If you never modified $Net::STOMP::Client::Debug::Flags then nothing
changes: debugging is still disabled by default.

Otherwise, you will have to enable debugging with something like:

  log_filter("debug");

or, to enable logging only from Net::STOMP::Client modules:

  log_filter("debug caller=~^Net::STOMP::Client");

See the No::Worries::Log documentation for more information.

Net::STOMP::Client 1.x used a bit-field to select what to debug. Version
2.0 uses a string, here is the mapping:

    Flags        String
    -----        ------
     API=1       api
   FRAME=2       command
  HEADER=4       header
    BODY=8       body
      IO=16      io
         -1      all

See the DEBUGGING section of the Net::STOMP::Client documentation for
more information.
