#!/usr/bin/perl
use strict;
use warnings;
use SMS::Send::Adapter::Node::Red;

SMS::Send::Adapter::Node::Red->psgi_app; #class function

__END__

=head1 NAME

perl-SMS-Send-Adapter-Node-Red.psgi - SMS::Send Adapter to Node-RED JSON HTTP request PSGI Script

=head1 DESCRIPTION

A PSGI application to control SMS::Send with a web service.

=head1 API

The script is called over HTTP with a JSON Object payload.

  POST http://127.0.0.1:5000/

  {
   "driver"  : "VoIP::MS",
   "to"      : "7035551212",
   "text"    : "Text Message",
   "options" : { "this" : "or", "that" : "and" }
  }

There are many SMS::Send drivers available on CPAN.  I use L<VoIP::MS|SMS::Send::VoIP::MS> in examples since that is the provider that I use for my home automation notifications.  My other notiable drivers are L<Kannel::SMSbox|SMS::Send::Kannel::SMSbox> and L<NANP::Twilio|SMS::Send::NANP::Twilio>.

Return is a JSON Object.

  200 OK

  {
   "sent"  : true,
   "input" : {...},
  }

Return on error.

  400|500|502 ...

  {
    "sent": false,
    "input": {...},
    "error": "error string to help point you in the correct direction"
  }

=head1 Node-Red Integration

Use four nodes: inject, function, http request, and debug.

=over

=item * In the function node

=over

=item * Set the "payload" to a JSON Object with the keys "driver", "to" and "text" and any extra "options" needed for SMS::Send objects not built on L<SMS::Send::Driver::WebService>.

  my_text     = msg.payload;
  msg.payload = {
                 "driver"  : "VoIP::MS",
                 "text"    : my_text,
                 "to"      : "7035551212",
                 "options" : {"key" : "value"},
                };
  return msg;

=back

=item * In the http request node

=over

=item * Set the "Method" to POST

=item * Set the "URL" to http://127.0.0.1:5000/

=item * Set the "Return" to a parsed JSON Object

=back

=item * In the debug node

=over

=item * Set the "Output" to msg.payload.sent which returns boolean true or false

=back

=back

=head2 Node Red Example

  [{"id":"3313f548.d53dba","type":"inject","z":"bbbcee28.8891c","name":"Inject","topic":"","payload":"My SMS Text","payloadType":"str","repeat":"","crontab":"","once":false,"onceDelay":0.1,"x":90,"y":1540,"wires":[["5cb3e4eb.f6d34c"]]},{"id":"3a6aed54.d74342","type":"debug","z":"bbbcee28.8891c","name":"","active":true,"tosidebar":true,"console":false,"tostatus":false,"complete":"payload.sent","targetType":"msg","x":710,"y":1540,"wires":[]},{"id":"a9dfd541.a3b3f8","type":"http request","z":"bbbcee28.8891c","name":"SMS::Send","method":"POST","ret":"obj","paytoqs":false,"url":"http://127.0.0.1:5000/","tls":"","persist":false,"proxy":"","authType":"","x":490,"y":1540,"wires":[["3a6aed54.d74342","aec87ffa.ec17f"]]},{"id":"aec87ffa.ec17f","type":"debug","z":"bbbcee28.8891c","name":"","active":true,"tosidebar":true,"console":false,"tostatus":false,"complete":"statusCode","targetType":"msg","x":700,"y":1500,"wires":[]},{"id":"707cfb7e.11b714","type":"debug","z":"bbbcee28.8891c","name":"","active":true,"tosidebar":true,"console":false,"tostatus":false,"complete":"payload","targetType":"msg","x":490,"y":1500,"wires":[]},{"id":"5cb3e4eb.f6d34c","type":"function","z":"bbbcee28.8891c","name":"payload formatter","func":"my_text     = msg.payload;\nmsg.payload = {\n               \"driver\"  : \"VoIP::MS\",\n               \"text\"    : my_text,\n               \"to\"      : \"7035551212\",\n               \"options\" : {\"key\" : \"value\"},\n              };\nreturn msg;","outputs":1,"noerr":0,"x":270,"y":1540,"wires":[["707cfb7e.11b714","a9dfd541.a3b3f8"]]}]

=cut
