package Net::MQTT::Simple::One_Shot_Loader;
use strict;
use warnings;
require Net::MQTT::Simple; #skip import

our $VERSION = '0.02';

=head1 NAME

Net::MQTT::Simple::One_Shot_Loader - Perl package to add one_shot method to Net::MQTT::Simple

=head1 SYNOPSIS

  require Net::MQTT::Simple::One_Shot_Loader;
  use Net::MQTT::Simple; #or Net::MQTT::Simple::SSL
  my $mqtt  = Net::MQTT::Simple->new($host);
  my $obj   = $mqtt->one_shot($topic_sub, $topic_pub, $message_pub, $timeout_seconds); #isa Net::MQTT::Simple::One_Shot_Loader::Response
  my $value = $obj->message;

=head1 DESCRIPTION

This package loads the C<one_shot> method into the L<Net::MQTT::Simple> name space to provide a well tested remote procedure call (RPC) via MQTT.  Many IoT devices only support MQTT as a protocol so, in order to query state or settings these properties need to be requested by sending a message on one queue and receiving a response on another queue.

Due to the way L<Net::MQTT::Simple::SSL> was implemented as a super class of L<Net::MQTT::Simple> and since the author of L<Net::MQTT::Simple> did not want to implement this method in his package (ref L<GitHub|https://github.com/Juerd/Net-MQTT-Simple/pull/22#pullrequestreview-1340685240>), we implemented this method in a method loader package.

=head1 METHODS

=head2 one_shot

Returns an object representing the first message that matches the subscription topic after publishing the message on the message topic.  Returns an object with the error set to a true value on error like timeout.

  my $response = $mqtt->one_shot($topic_sub, $topic_pub, $message_pub, $timeout_seconds);

  if (not $response->error) {
    my $message  = $response->message;
  }

=cut

{
  package Net::MQTT::Simple::One_Shot_Loader::Response;
  use strict;
  use warnings;
  sub error   {shift->{'error'}};
  sub topic   {shift->{'topic'}};
  sub message {shift->{'message'}};
  sub time    {shift->{'time'}};
}

{
  package Net::MQTT::Simple;
  use strict;
  use warnings;
  use Time::HiRes qw{};

  sub one_shot {
    my $self        = shift; #isa Net::MQTT::Simple or Net::MQTT::Simple::SSL
    my $topic_sub   = shift or die('Error: subscribe topic is required');
    my $topic_pub   = shift or die('Error: publish topic is required');
    my $message     = shift;
    $message        = '' unless defined $message; #default '', allow 0 and support perl 5.8
    my $timeout     = shift || 1.5; #seconds

    my $found       = 0; #anonymous sub updates these variables
    my $topic_out   = $topic_sub;
    my $message_out = '';

    $self->subscribe($topic_sub => sub {
                                        unless ($found) { #stop after first found but we get multiple calls per tick
                                          $found       = 1;
                                          $topic_out   = shift;
                                          $message_out = shift;
                                        }
                                       }
    );

    my $timer       = Time::HiRes::time();
    $self->publish($topic_pub => $message);

    my $future      = Time::HiRes::time() + $timeout;
    while (Time::HiRes::time() < $future) {
      $self->tick($timeout); #it takes a few ticks to clear out LWT
      last if $found;
    }
    $timer          = Time::HiRes::time() - $timer;
    my $error       = $found ? '' : sprintf('subscribe timeout (%0.1f s)', $timer);

    $self->unsubscribe($topic_sub); #must unsubscribe to do one_shot back to back
    return bless {
                  error   => $error,
                  topic   => $topic_out,
                  message => $message_out,
                  time    => $timer,
                 }, 'Net::MQTT::Simple::One_Shot_Loader::Response';
  }
}

=head1 SEE ALSO

L<Net::MQTT::Simple>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

MIT License

Copyright (c) 2023 Michael R. Davis

=cut

1;
