# Mojolicious::Plugin::AWS::SNS - Publish to AWS SNS topic

## SYNOPSIS

```perl
# Mojolicious
$self->plugin('Mojolicious::Plugin::AWS::SNS');

# Mojolicious::Lite
plugin 'Mojolicious::Plugin::AWS::SNS';

# in a controller
$c->sns_publish(
    region     => 'us-east-2',
    topic      => $topic_arn,
    subject    => 'my subject',
    message    => {default => 'my message'},
    access_key => $access_key,
    secret     => $secret_key
)->then(
  sub {
      my $tx = shift;
      say $tx->res->json('/PublishResponse/PublishResult/MessageId');
  }
);
```

## DESCRIPTION

Mojolicious::Plugin::AWS::SNS is a Mojolicious plugin for publishing to Amazon Web Service's Simple Notification Service.

## CAVEAT

This module is alpha quality. This means that its interface will likely change in backward-incompatible ways, that its performance is unreliable, and that the code quality is only meant as a proof-of-concept. Its use is discouraged except for experimental, non-production deployments.

## AUTHOR

Scott Wiersdorf, <scott@perlcode.org>

## SPONSORS

* AdvanStaff HR <https://www.advanstaff.com/>

## COPYRIGHT AND LICENSE

Copyright (C) 2019, Scott Wiersdorf.

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.
