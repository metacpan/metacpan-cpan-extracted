package PubNub::PubSub;

use strict;
use v5.10;
our $VERSION = '1.1.0';

use Carp;
use Mojo::JSON qw/encode_json/;
use Mojo::UserAgent;
use Mojo::Util qw/url_escape/;

use PubNub::PubSub::Message;

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    $args{host} ||= 'pubsub.pubnub.com';
    $args{port} ||= 80;
    $args{timeout} ||= 60; # for ua timeout
    $args{publish_queue} ||= [];

    my $proto = ($args{port} == 443) ? 'https://' : 'http://';
    $args{web_host} ||= $proto . $args{host};

    return bless \%args, $class;
}

sub __ua {
    my $self = shift;

    return $self->{ua} if exists $self->{ua};

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);
    $ua->inactivity_timeout($self->{timeout});
    $ua->proxy->detect; # env proxy
    $ua->cookie_jar(0);
    $ua->max_connections(100);
    $self->{ua} = $ua;

    return $ua;
}

sub publish {
    my $self = shift;

    my %params = @_ % 2 ? %{$_[0]} : @_;
    my $callback = $params{callback} || $self->{publish_callback};

    my $ua = $self->__ua;

    my @steps = map {
             my $ref = $_;
             my $url = $ref->{url};
             sub {
                 my $delay = shift;
                 my $end = $delay->begin;
                 $ua->get($url => sub {
                    $callback->($_[1]->res, $ref->{message}) if $callback;
                    $end->();
                  });
             }
    } $self->__construct_publish_urls(%params);

    Mojo::IOLoop->delay(@steps)->wait;
}

sub __construct_publish_urls {
    my ($self, %params) = @_;

    my $pub_key = $params{pub_key} || $self->{pub_key};
    $pub_key or croak "pub_key is required.";
    my $sub_key = $params{sub_key} || $self->{sub_key};
    $sub_key or croak "sub_key is required.";
    my $channel = $params{channel} || $self->{channel};
    $channel or croak "channel is required.";
    $params{messages} or croak "messages is required.";

    return map {
        my $json = $_->json;
        my $uri = Mojo::URL->new( $self->{web_host} . qq~/publish/$pub_key/$sub_key/0/$channel/0/~ . url_escape($json) );
        $uri->query($_->query_params(\%params));
        { url => $uri->to_string, message => $_ };
    } map { PubNub::PubSub::Message->new($_) } @{$params{messages}};
}

sub subscribe {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;

    my $sub_key = $params{sub_key} || $self->{sub_key};
    $sub_key or croak "sub_key is required.";
    my $channel = $params{channel} || $self->{channel};
    $channel or croak "channel is required.";

    my $callback = $params{callback} or croak "callback is required.";
    my $timetoken = $params{timetoken} || '0';

    my $ua = $self->__ua;

    my $tx = $ua->get($self->{web_host} . "/subscribe/$sub_key/$channel/0/$timetoken");
    unless ($tx->success) {
        # for example $tx->error->{message} =~ /Inactivity timeout/

        # This is not a traditional goto. Instead it exits this function 
        # and re-enters with @ as params.
        #
        # see goto docs, this is basically a method call which exits the current
        # function first.  So no extra call stack depth.
        sleep 1;
        @_ = ($self, %params, timetoken => $timetoken);
        goto &subscribe;
    }
    my $json = $tx->res->json;
    my @cb_args = $params{raw_msg}? ($json) : (@{$json->[0]});

    my $rtn = $callback ? $callback->(@cb_args) : 1;
    return unless $rtn;

    $timetoken = $json->[1];
    return $self->subscribe(%params, timetoken => $timetoken);
}

sub subscribe_multi {
    my $self = shift;
    my %params = @_ % 2 ? %{$_[0]} : @_;
    croak 'channels must be an arrayref'
         unless ref($params{channels}) =~ /ARRAY/;
    croak 'callback must be a hashref or coderef'
         unless ref($params{callback}) =~ /(HASH|CODE)/;

    my $callback;
    if (ref($params{callback}) =~ /HASH/){
       for (keys %{$params{callback}}) {
           croak "Non-coderef value found for callback key $_" 
                unless ref($params{callback}->{$_}) =~ /CODE/;
       }
       $callback = sub {
           my ($obj) = @_;
           my ($msg, $timetoken, $channel) = @$obj;
           my $cb_dispatch = $params{callback};
           unless ($channel) { # on connect messages
              goto $cb_dispatch->{on_connect} 
                   if exists $cb_dispatch->{on_connect};
              return 1;
           }
           if (exists $cb_dispatch->{$channel}){

              # these are verified coderefs, so replacing the current stack 
              # frame with a call to the function.  They will *not* jump to 
              # a label or other points.  Basically this just lets us pretend
              # that this was called directly by subscribe above.
              goto $cb_dispatch->{$channel};
           } elsif (exists $cb_dispatch->{'_default'}){
              goto $cb_dispatch->{_default};
           } else {
              warn 'Using callback dispatch table, cannot find channel callback'
                   . ' and _default callback not specified';
              return;
           }
       };
    }
    $callback = $params{callback} unless ref $callback;

    my $channel_string = join ',', @{$params{channels}};
    return $self->subscribe(channel => $channel_string, callback => $callback,
                           raw_msg => 1);
}

sub history {
    my $self = shift;

    if (scalar(@_) == 1 and ref($_[0]) ne 'HASH' and $_[0] =~ /^\d+$/) {
        @_ = (count => $_[0]);
        warn "->history(\$num) is deprecated and will be removed in next few releases.\n";
    }

    my %params = @_ % 2 ? %{$_[0]} : @_;

    my $sub_key = delete $params{sub_key} || $self->{sub_key};
    $sub_key or croak "sub_key is required.";
    my $channel = delete $params{channel} || $self->{channel};
    $channel or croak "channel is required.";

    my $ua = $self->__ua;

    my $tx = $ua->get($self->{web_host} . "/v2/history/sub-key/$sub_key/channel/$channel" => form => \%params);
    return [$tx->error->{message}] unless $tx->success;
    return $tx->res->json;
}

1;
__END__

=encoding utf-8

=head1 NAME

PubNub::PubSub - Perl library for rapid publishing of messages on PubNub.com

=head1 SYNOPSIS

    use PubNub::PubSub;
    use 5.010;
    use Data::Dumper;

    my $pubnub = PubNub::PubSub->new(
        pub_key => 'demo', # only required for publish
        sub_key => 'demo',
        channel => 'sandbox',
    );

    # publish
    $pubnub->publish({
        messages => ['message1', 'message2'],
        callback => sub {
            my ($res) = @_;

            # $res is a L<Mojo::Message::Response>
            say $res->code; # 200
            say Dumper(\$res->json); # [1,"Sent","14108733777591385"]
        }
    });
    $pubnub->publish({
        channel  => 'sandbox2', # optional, if not applied, the one in ->new will be used.
        messages => ['message3', 'message4']
    });

    # subscribe
    $pubnub->subscribe({
        callback => sub {
            my (@messages) = @_;
            foreach my $msg (@messages) {
                print "# Got message: $msg\n";
            }
            return 1; # 1 to continue, 0 to stop
        }
    });


=head1 DESCRIPTION

PubNub::PubSub is Perl library for rapid publishing of messages on PubNub.com based on L<Mojo::UserAgent>

perl clone of L<https://gist.github.com/stephenlb/9496723#pubnub-http-pipelining>

For a rough test:

=over 4

=item * run perl examples/subscribe.pl in one terminal (or luanch may terminals with subscribe.pl)

=item * run perl examples/publish.pl in another terminal (you'll see all subscribe terminals will get messages.)

=back

=head1 METHOD

=head2 new

=over 4

=item * pub_key

optional, default pub_key for publish

=item * sub_key

optional, default sub_key for all methods

=item * channel

optional, default channel for all methods

=item * publish_callback

optional. default callback for publish

=item * debug

set ENV MOJO_USERAGENT_DEBUG to debug

=back

=head2 subscribe

subscribe channel to listen for the messages.

Arguments are:

=over

=item callback

Callback to run on the channel

=item channel

Channel to listen on, defaults to the base object's channel attribute.

=item subkey

Subscription key.  Defaults to base object's subkey attribute.

=item raw_msg

Pass the whole message in, as opposed to the json element of the payload.

This is useful when you need to process time tokens or channel names.

The format is a triple of (\@messages, $timetoken, $channel).

=item timetoken

Time token for initial request.  Defaults to 0.

=back

    $pubnub->subscribe({
        callback => sub {
            my (@messages) = @_;
            foreach my $msg (@messages) {
                print "# Got message: $msg\n";
            }
            return 1; # 1 to continue, 0 to stop
        }
    });

return 0 to stop

=head2 subscribe_multi

Subscribe to multiple channels.  Arguments are:

=over

=item channels

an arrayref of channel names

=item callback

A callback, either a coderef which handles all requests, or a hashref dispatch
table with one entry per channel.

If a dispatch table is used a _default entry catches all unrecognized channels. 
If an unrecognized channel is found, a warning is generated and the loop exits.

The message results are passed into the functions in raw_msg form (i.e. a tuple 
ref of (\@messages, $timetoken, $channel) for performance reasons.

=back

=head2 publish

publish messages to channel

    $pubnub->publish({
        messages => ['message1', 'message2'],
        callback => sub {
            my ($res) = @_;

            # $res is a L<Mojo::Message::Response>
            say $res->code; # 200
            say Dumper(\$res->json); # [1,"Sent","14108733777591385"]
        }
    });
    $pubnub->publish({
        channel  => 'sandbox2', # optional, if not applied, the one in ->new will be used.
        messages => ['message3', 'message4']
    });

Note if you need shared callback, please pass it when do ->new with B<publish_callback>.

new Parameters specifically for B<Publish V2 ONLY>

=over 4

=item * ortt - Origination TimeToken where "r" = DOMAIN and "t" = TIMETOKEN

=item * meta - any JSON payload - intended as a safe and unencrypted payload

=item * ear - Eat At Read (read once)

=item * seqn - Sequence Number - for Guaranteed Delivery/Ordering

=back

We'll first try to read from B<messages>, if not specified, fall back to the same level as messages. eg:

    $pubnub->publish({
        messages => [
            {
                message => 'test message.',
                ortt => {
                    "r" => 13,
                    "t" => "13978641831137500"
                },
                meta => {
                    "stuff" => []
                },
                ear  => 'True',
                seqn => 12345,
            },
            {
                ...
            }
        ]
    });

    ## if you have common part, you can specified as the same level as messages
    $pubnub->publish({
        messages => [
            {
                message => 'test message.',
                ortt => {
                    "r" => 13,
                    "t" => "13978641831137500"
                },
                seqn => 12345,
            },
            {
                ...
            }
        ],
        meta => {
            "stuff" => []
        },
        ear  => 'True',
    });

=head2 history

fetches historical messages of a channel

=over 4

=item * sub_key

optional, default will use the one passed to ->new

=item * channel

optional, default will use the one passed to ->new

=item * count

Specifies the number of historical messages to return. The Default is 100.

=item * reverse

Setting to true will traverse the time line in reverse starting with the newest message first. Default is false. If both start and end arguments are provided, reverse is ignored and messages are returned starting with the newest message.

=item * start

Time token delimiting the start of time slice (exclusive) to pull messages from.

=item * end

Time token delimiting the end of time slice (inclusive) to pull messages from.

=back

Sample code:

    my $history = $pubnub->history({
        count => 20,
        reverse => "false"
    });
    # $history is [["message1", "message2", ... ],"Start Time Token","End Time Token"]

for example, to fetch all the rows in history

    my $history = $pubnub->history({
        reverse => "true",
    });
    while (1) {
        print Dumper(\$history);
        last unless @{$history->[0]}; # no messages
        sleep 1;
        $history = $pubnub->history({
            reverse => "true",
            start => $history->[2]
        });
    }

=head1 JSON USAGE

This module effectively runs a Mojolicious application in the background.  For
those parts of JSON which do not have a hard Perl equivalent, such as booleans,
the Mojo::JSON module's semantics work.  This means that JSON bools are 
handled as references to scalar values 0 and 1 (i.e. \0 for false and \1 for 
true).

This has changed since 0.08, where True and False were used.

=head1 GITHUB

L<https://github.com/binary-com/perl-pubnub-pubsub>

=head1 AUTHOR

Binary.com E<lt>fayland@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright 2014- binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
