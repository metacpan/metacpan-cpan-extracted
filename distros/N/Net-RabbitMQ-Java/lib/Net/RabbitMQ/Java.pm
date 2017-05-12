package Net::RabbitMQ::Java;

use strict;
use warnings;

our $VERSION = '2.030102';

use Data::UUID;
use File::ShareDir qw(dist_dir);
use Inline::Java qw(cast);

my %callbacks = ();       # callback_id => [ CallbackCaller, sub {} ]
my %obj_callbacks = ();   # object_ref => [ callback_id, ... ]
my ($Helper);

# callback helpers
sub _callback {
    my ($callback_id, $args) = @_;
    $callbacks{$callback_id}->[1]->(@$args);
}
sub _callback_error {
    print STDERR shift, "\n";
    exit;
}
sub processCallbacks { # class method
    my $class = shift;
    $_->[0]->process for values %callbacks;
}

# prototypes for method overloading
sub method_with_3_args_or_map {
    my $orig = shift;
    
    # if we were called with more than 3 arguments,
    # last one can be a hash
    splice @_, -1, 1, encode_Map($_[-1]) if @_ > 1+3;
    
    return $orig->(@_);
}
sub decoding_accessor {
    my $decoder = shift;
    return sub {
        my $orig = shift;
        return $decoder->($orig->(@_));
    };
}
sub encoding_setter {
    my $encoder = shift;
    return sub {
        my $orig = shift;
        return $orig->($encoder->(@_));
    };
}
sub callback_setter {
    my ($type, $decode_coderef) = @_;
    $decode_coderef ||= sub {@_}; # second arg is optional
    return sub {
        my ($orig, $obj, $coderef) = @_;
    
        # generate the callback unique identifier
        my $callback_id = "${type}_${obj}_" . Data::UUID->new->create_hex;
        
        # create a Java helper listener
        my $listener_obj = "Net::RabbitMQ::Java::Helper::$type"->new($Helper, $callback_id);
        $orig->($obj, $listener_obj);
        my $callbackCaller = $listener_obj->getCallbackCaller;
        
        # save the callback in Perl-land
        $coderef ||= sub {};
        $callbacks{$callback_id} = [
            $callbackCaller, 
            sub { $coderef->($decode_coderef->(@_)) }
        ];
        
        # save an index of callbacks added to channels, so that we
        # can remove them when channel objects get destroyed
        $obj_callbacks{"$obj"} ||= [];
        push @{ $obj_callbacks{"$obj"} }, $callback_id;
        
        return $callbackCaller;
    };
}
sub destroy_callbacks {
    my $self = shift;
    if ($obj_callbacks{"$self"}) {
        delete $callbacks{$_} for @{ $obj_callbacks{"$self"} };
        delete $obj_callbacks{"$self"};
    }
    return Inline::Java::Object::DESTROY($self, @_);
}

# encoding/decoding subroutines
sub encode_ByteArray ($) {
    my $string = shift;
    # this is very inefficient; an idea would be to 
    # convert to hexadecimal (base64?) and pass it as a String
    # to a Java helper object to call .getBytes() on
    return [ unpack("c*", $string) ];
}

sub decode_ByteArray ($) {
    my $byteArray = shift;
    return pack("c*", @$byteArray);
}

sub encode_Map ($) {
    my $hash = shift;
    return undef unless $hash;
    return $hash if ref $hash =~ /java::util::HashMap$/;
    my $map_obj = new java::util::HashMap;
    foreach my $key (keys %$hash) {
        $map_obj->put($key, $hash->{$key});
    }
    return $map_obj;
}

sub decode_Map ($) {
    my $map_obj = shift;
    my $hash = {};
    return $hash unless $map_obj;
    my $it = $map_obj->entrySet->iterator;
    while ($it->hasNext) {
        my $entry_obj = cast('java.util.Map$Entry', $it->next);
        # getValue returns a com.rabbitmq.client.impl.LongStringHelper.ByteArrayLongString
        $hash->{ $entry_obj->getKey } = $entry_obj->getValue->toString;
    }
    return $hash;
}

sub encode_Date ($) {
    my $dt = shift;
    return undef unless $dt;
    return $dt if ref $dt =~ /java::util::Date$/;
    return new java::util::Date(ref $dt eq 'DateTime' ? $dt->epoch : $dt);
}

sub encode_BasicProperties ($) {
    return undef unless $_[0];
    return $_[0] if ref $_[0] =~ /AMQP::BasicProperties$/;
    my %args = %{$_[0]};
    
    $args{headers}   = encode_Map $args{headers};
    $args{timestamp} = encode_Date $args{timestamp};
    
    my $props_obj = Net::RabbitMQ::Java::Client::AMQP::BasicProperties->new(
        map delete $args{$_},
        qw(contentType contentEncoding headers deliveryMode priority
        correlationId replyTo expiration messageId timestamp type
        userId appId clusterId)
    );
    !%args or die "Unknown properties: " . join(', ', keys %args);
    return $props_obj;
}

# main code
my $inited = 0;
sub init {
    my ($class, %params) = @_;
    return if $inited;
    $inited = 1;
    
    # load Java code
    my $share_dir = dist_dir('Net-RabbitMQ-Java');
    my $helper_code;
    {
        # TODO: we should pre-compile Helper.java
        # borrowing code from Inline-Java/Makefile.PL
        # (or maybe Inline::Java itself provides helper methods?) 
        local $/;
        open(my $fh, '<', "$share_dir/java/Helper.java") or die;
        $helper_code = <$fh>;
        close $fh;
    }
    
    $params{CLASSPATH} ||= '';
    $params{CLASSPATH} .= ":$share_dir/java/rabbitmq-client.jar:$share_dir/java/commons-io-1.2.jar";
    Inline->bind(
        Java       => $helper_code,
        %params,
        AUTOSTUDY  => 1,
        STUDY      => [qw(
            Helper
            java.util.Date
            java.util.HashMap
            com.rabbitmq.client.ConnectionFactory
            com.rabbitmq.client.AMQP$BasicProperties
            com.rabbitmq.client.impl.AMQConnection
            com.rabbitmq.client.impl.ChannelN
            com.rabbitmq.client.GetResponse
            com.rabbitmq.client.QueueingConsumer
            com.rabbitmq.client.QueueingConsumer$Delivery
        )],
    );
    
    # alias our namespaces
    $Helper = Net::RabbitMQ::Java::Helper->new;
    *java:: = *Net::RabbitMQ::Java::java::;
    *Net::RabbitMQ::Java::Client:: = *Net::RabbitMQ::Java::com::rabbitmq::client::;
    
    # override methods that need to be more Perl-friendly
    my %override_subs = (
        'impl::ChannelN::basicPublish' => sub {
            my $orig = shift;
            
            # last argument is message body
            splice @_, -1, 1, encode_ByteArray $_[-1];
            
            # next-to-last argument is a basic properties hash
            splice @_, -2, 1, encode_BasicProperties $_[-2];
            
            return $orig->(@_);
        },
        'impl::ChannelN::basicConsume' => sub {
            my $orig = shift;
            
            # if called with 7 arguments, 6th is a map
            splice @_, -2, 1, encode_Map $_[-2] if @_ == 1+7;
            
            return $orig->(@_);
        },
        'impl::ChannelN::exchangeBind'      => \&method_with_3_args_or_map,
        'impl::ChannelN::exchangeDeclare'   => \&method_with_3_args_or_map,
        'impl::ChannelN::exchangeUnbind'    => \&method_with_3_args_or_map,
        'impl::ChannelN::queueBind'         => \&method_with_3_args_or_map,
        'impl::ChannelN::queueDeclare'      => \&method_with_3_args_or_map,
        'impl::ChannelN::queueUnbind'       => \&method_with_3_args_or_map,
        
        'impl::ChannelN::setReturnListener' => callback_setter('ReturnListener', sub {
            # last argument is message body
            splice @_, -1, 1, decode_ByteArray $_[-1];
            @_;
        }),
        'impl::ChannelN::setConfirmListener'        => callback_setter('ConfirmListener'),
        'impl::ChannelN::setFlowListener'           => callback_setter('FlowListener'),
        'impl::ChannelN::addShutdownListener'       => callback_setter('ShutdownListener'),
        'impl::AMQConnection::addShutdownListener'  => callback_setter('ShutdownListener'),
        
        'ConnectionFactory::getClientProperties'    => decoding_accessor(\&decode_Map),
        'impl::AMQConnection::getClientProperties'  => decoding_accessor(\&decode_Map),
        'impl::AMQConnection::getServerProperties'  => decoding_accessor(\&decode_Map),
        'QueueingConsumer::Delivery::getBody'       => decoding_accessor(\&decode_ByteArray),
        'GetResponse::getBody'                      => decoding_accessor(\&decode_ByteArray),
        'AMQP::BasicProperties::getHeaders'         => decoding_accessor(\&decode_Map),
        
        'ConnectionFactory::setClientProperties'    => encoding_setter(\&encode_Map),
    );
    my %new_subs = (
        'impl::ChannelN::DESTROY'       => \&destroy_callbacks,
        'impl::AMQConnection::DESTROY'  => \&destroy_callbacks,
    );
    {
        no strict 'refs';
        no warnings 'redefine';
        foreach my $sub (keys %override_subs) {
            my $fullname = "Net::RabbitMQ::Java::Client::$sub";
            my $orig = *$fullname{CODE} or die "failed to override $fullname";
            
            *{ $fullname } = sub {
                return $override_subs{$sub}->($orig, @_);
            };
        }
        *{ "Net::RabbitMQ::Java::Client::$_" } = $new_subs{$_}
            for keys %new_subs;
    }
}


1;
__END__

=pod

=head1 NAME

Net::RabbitMQ::Java - interface to the RabbitMQ Java AMQP client library

=head1 SYNOPSIS

    Net::RabbitMQ::Java->init;
    
    # connect
    my $factory = Net::RabbitMQ::Java::Client::ConnectionFactory->new;
    $factory->setUsername('guest');
    $factory->setPassword('guest');
    $factory->setHost("localhost");
    my $conn = $factory->newConnection;
    my $channel = $conn->createChannel;
    
    # declare exchange and queues
    $channel->exchangeDeclare('my-exchange', "direct", 1);
    my $queue_name = $channel->queueDeclare->getQueue;
    $channel->queueBind($queue_name, 'my-exchange', 'my.routing.key');
    
    # publish
    $channel->basicPublish('my-exchange', 'my.routing.key', {}, 'Message contents');
    
    # manage transactions
    $channel->txSelect;
    $channel->txRollback;
    $channel->txCommit;
    
    # consume
    my $consumer = Net::RabbitMQ::Java::Client::QueueingConsumer->new($channel);
    $channel->basicConsume($queue_name, 0, $consumer);
    while (1) {
        my $delivery = $consumer->nextDelivery;
        print $delivery->getBody, "\n";
        $channel->basicAck($delivery->getEnvelope->getDeliveryTag, 0);
    }
    
    # set and poll callbacks
    $conn->addShutdownListener(sub {
        my $e = shift;
        print $e->getReason->getMethod->getReplyText, "\n";
    });
    $channel->setReturnListener(sub {
        my ($replyCode, $replyText, $exchange, $routingKey, $properties, $body) = @_;
        print "Unroutable message: $body\n";
    });
    ...
    Net::RabbitMQ::Java->processCallbacks;
    
    # disconnect    
    $channel->close;
    $conn->close;

=head1 ABSTRACT

This module provides full bindings for the AMQP RabbitMQ Java library. It is based
on L<Inline::Java|Inline::Java> and it exposes all of the classes and interfaces of the original
library. You should refer to the original documentation in order to understand how 
to do the various AMQP tasks and to check the exact method signatures:

=over 4

=item L<http://www.rabbitmq.com/api-guide.html>

=item L<http://www.rabbitmq.com/releases/rabbitmq-java-client/v2.3.1/rabbitmq-java-client-javadoc-2.3.1/>

=back

You can also have a look at the test suite to get started.

This distribution ships the RabbitMQ client library, so you don't need to download
it yourself. The module version number represents the library version. If a newer 
library is available from the RabbitMQ team and this distribution wasn't updated, 
you can use it (see the C<CLASSPATH> option below).

Don't be scared by the "Java" thing. Using this module is quite easy: if you have 
L<Inline::Java|Inline::Java> installed, it just works. To install L<Inline::Java|Inline::Java> you only need
to have Java SDK installed in your system (no more difficult than a quick 
C<apt-get install openjdk-6-jdk>, probably).

=head1 Yet another RabbitMQ module?

Yes. At the time of writing, CPAN offers incomplete or unmaintained modules. Some
do not support recent AMQP specs such as 0-9-1, others do not support features like
returned messages. This is not criticism, though. Writing and maintaining an AMQP 
module is probably not easy, given the complexity of the protocol, the variety of
broker implementations and different spec versions, so I understand that it's 
difficult to develop and maintain a robust Perl implementation.
I believe that an optimal solution would be a module with XS bindings to an AMQP 
C/C++ library. However, there seem to be no stable or widely-adopted C/C++ libraries,
so I decided to build an interface to the Java client library developed by the 
RabbitMQ team, which appears to be the most actively maintained library.

=head1 INITIALIZATION

Before using AMQP classes you have to initialize the library:

    use Net::RabbitMQ::Java;
    
    Net::RabbitMQ::Java->init;

This will load the Java code, start the background JVM and populate the 
C<Net::RabbitMQ::Java::> namespace with the loaded classes. If you want fine-grained
configuration over L<Inline::Java|Inline::Java> behaviour, you can pass arguments to C<init>:

    Net::RabbitMQ::Java->init(JNI => 1);

So, if you want to use a custom client library JAR (instead of the one shipped with
this module), just populate the C<CLASSPATH> option:

    my $path = '/path/to/your/libraries';
    Net::RabbitMQ::Java->init(
        CLASSPATH => "$path/rabbitmq-client.jar:$path/commons-io-1.2.jar",
    );

=head1 AVAILABLE CLASSES

There are few classes you need to instantiate directly:

=over 4

=item Net::RabbitMQ::Java::Client::ConnectionFactory

=item Net::RabbitMQ::Java::Client::QueueingConsumer

=back

=head1 CALLING METHODS

See the client library original documentation to learn about method signatures. This 
module will take care of casting data types. You only need to take care of the 
number of arguments which must match what the library is expecting, even if you 
want to pass null values:

    $channel->queueDeclare($name, 1, 0, 0, undef);

In Perl you could omit the last argument, but since we're talking to Java you 
must provide the exact number of arguments described in docs as it's needed to
identify which signature are you calling the method with (for the non-Java-savvy
people out there: this is why many methods are listed multiple times with different
argument lists).

=head1 AUGMENTED METHODS

In order to provide you with a better interface to the underlying library, some 
methods are overloaded and augmented. Thus, for these methods you should combine
the RabbitMQ client library docs with the following instructions:

=over 4

=item B<$ConnectionFactory-E<gt>setClientProperties( I<HASHREF> )>

You can pass a Perl hashref to this method.

=item B<I<HASHREF> = $ConnectionFactory-E<gt>getClientProperties()>

=item B<I<HASHREF> = $Connection-E<gt>getClientProperties()>

=item B<I<HASHREF> = $Connection-E<gt>getServerProperties()>

=item B<I<HASHREF> = $BasicProperties-E<gt>getHeaders()>

These methods return a Perl hashref.

=item B<$Channel-E<gt>exchangeBind( ..., I<HASHREF> )>

=item B<$Channel-E<gt>exchangeDeclare( ..., I<HASHREF> )>

=item B<$Channel-E<gt>exchangeUnbind( ..., I<HASHREF> )>

=item B<$Channel-E<gt>queueBind( ..., I<HASHREF> )>

=item B<$Channel-E<gt>queueDeclare( ..., I<HASHREF> )>

=item B<$Channel-E<gt>queueUnbind( ..., I<HASHREF> )>

The C<arguments> argument (which is the last one when you call these methods with a 
signature that requires it) can be a Perl hashref.

=item B<$Channel-E<gt>basicConsume( ..., I<HASHREF>, $consumer )>

When called with the 7-arguments signature, the next-to-last one can be passed as
a Perl hashref.

=item B<$Channel-E<gt>basicPublish( ..., I<HASHREF>, $body )>

Next-to-last argument (which the docs require to be an AMQP.BasicProperties object)
can be passed as a hashref containing the following keys:

    {
        contentType     => '',
        contentEncoding => '',
        headers         => {}, # hashref
        deliveryMode    => 1,  # 1 = non-persistent, 2 = persistent
        priority        => 0,
        correlationId   => '',
        replyTo         => '',
        expiration      => '',
        messageId       => '',
        timestamp       => 1271857990,  # this can also be a DateTime object
        type            => '',
        userId          => '',
        appId           => '',
        clusterId       => '',
    }

Note that C<getProperties()> methods don't return hashrefs. They return 
C<BasicProperties> objects (see Java library docs), so you can call accessor methods 
on them:

    my $reply_key = $delivery->getProperties->getReplyTo;

=back

=head1 CALLBACKS

This module provides some glue to use Perl code as callbacks for reacting to events
thrown by the RabbitMQ client library. The library itself is multi-threading; however
there's currently no way to share Java objects between multiple Perl threads, so your 
application will need to have one connection per Perl thread. Thus, your callbacks
will be executed in a single-threaded environment as soon as you want. The Java library
will catch the events in the background and will put them in a queue so that you can
poll from Perl using the following command:

    Net::RabbitMQ::Java->processCallbacks();

Note that this is a B<non-blocking> call! It will execute any callbacks available in 
the internal queue. If there are no callbacks to execute, it will return immediately.

Each callback setter method returns a reference to the callback too, so you can process
callbacks for individual listeners too:

    my $cb = $channel->setReturnListener(sub { ... });
    ...
    $cb->process;

=head2 Handling returned messages

If a message is published with the "mandatory" or "immediate" flags set, but cannot be 
delivered, the broker will return it to the sending client (via a C<AMQP.Basic.Return> 
command). To be notified of such returns, clients can set up a callback using the 
following syntax:

    my $cb = $channel->setReturnListener(sub {
        my ($replyCode, $replyText, $exchange, $routingKey, $properties, $body) = @_;
        ...
    });

B<Warning>: if you call C<$cb-E<gt>process()> right after publishing a message with
C<$channel-E<gt>basicPublish()>, you likely won't catch an eventual return as the 
server may take some time to send it (milliseconds or even seconds). So it's up to 
you to poll frequently for callbacks. You could use an event-driven environment such
as L<POE> or L<Reflex> to schedule regular calls to C<$cb-E<gt>process()> or 
C<processCallbacks()>.

Another solution is to wrap your C<basicPublish()> in a transaction:

    $channel->txSelect;
    $channel->basicPublish(...);
    $channel->txCommit;
    $cb->process;

If you don't need a transaction, note that calling C<txSelect> and C<txCommit> add a 
significant server overhead due to disk processing and so on, but this lets you ensure
that by calling C<$cb-E<gt>process()> immediately you will catch an eventual return. The 
reason for this relies in the wire traffic order enforced by the transaction commit:
the server sends the C<tx.commit-ok> response after having sent any C<basic.return>
frame, so when the C<txCommit()> methods returns, the AMQP library has already processed
the return frame and enqueued the callback. (I actually haven't checked whether this
ordering is enforced by the AMQP specs or is just RabbitMQ's implementation.)

=head2 Requesting publisher confirms

RabbitMQ extended the AMTP protocol with a feature that lets clients request explicit
confirmation for published messages, without the need to initiate a transaction
(see L<http://www.rabbitmq.com/blog/2011/02/10/introducing-publisher-confirms/>).

You do this by assigning a callback with the following syntax:

    my $confirmed = 0;
    my $cb = $channel->setConfirmListener(sub {
        my ($type, $deliveryTag, $multiple) = @_;
        $confirmed = 1;
        warn 'Message lost!' if $type eq 'nack';
    });
    $channel->confirmSelect;
    $channel->basicPublish(...);
    $cb->process while !$confirmed;

The first argument passed to the callback is C<ack> or C<nack> depending on the kind
of event notified by the server (consult RabbitMQ docs for the semantics of these).
Note that you will get a confirm for every single message published, so you should poll
(i.e. call C<$cb-E<gt>process()> or C<processCallbacks>) until you've got enough confirms:

    my $toConfirm = 0;
    my $cb = $channel->setConfirmListener(sub { $toConfirm-- });
    $channel->confirmSelect;
    ... # publish your messages and increase $toConfirm for each one
    $cb->process while $toConfirm > 0;

=head2 Registering a shutdown handler

The client library will fire a shutdown event whenever a connection or a channel is 
closed by the server or due to a communication failure (see the Core API Guide on RabbitMQ
website linked above). To handle such events you can register a callback using the 
following syntax:

    my $cb = $conn->addShutdownListener(sub {
        my $cause = shift;
        ...
    });
    my $cb2 = $channel->addShutdownListener(sub {
        my $cause = shift;
        ...
    });

You can add as many callbacks as you need. The first argument is a 
C<ShutdownSignalException> as documented in the client library Java docs, that you can
query to get error messages and so on.

Remember to call C<$cb-E<gt>process()> or C<processCallbacks()> often.

To remove a shutdown listener you can use the following method:

    $conn->removeShutdownListener($cb->getListener);
    $channel->removeShutdownListener($cb2->getListener);

=head1 EXCEPTIONS

Net::RabbitMQ::Java will throw exceptions just as documented in the Java client docs.
You can catch them as normal Perl exceptions:

    my $conn = eval { $factory->newConnection };
    if ($@) {
        if ($@->isa('Net::RabbitMQ::Java::Client::PossibleAuthenticationFailureException')) {
            die "Authentication failed";
        } else {
            ...
        }
    }

(Hint: use a module like L<Try::Tiny> or L<TryCatch> to catch your exceptions without 
surprises.)

Note that you should the C<isa()> method instead of doing C<ref $@>, because the resulting
package name might have a different namespace than C<Net::RabbitMQ::Java::Client::>. 
Otherwise you could use a regexp and omit the namespace:

    if ($@ =~ /PossibleAuthenticationFailureException$/) {
        ...
    }

=head1 TODO

Some things will need future work:

=over 4

=item I<Implementation of the RpcClient class>

It should be enabled explicitely by the user, so that we don't load an extra Java class that 
we don't use.

=item I<Full async support>

An async mode would be useful to allow implementation with event-based frameworks such as 
L<POE> and others. This requires a non-blocking behaviour of AMQP sync commands. It could
be achieved by extending the current callback system: a method call like C<txCommit()> 
should accept a coderef as last argument and return immediately; the Java client library
should receive the C<tx.commit-ok> response in a separate Java thread and enqueue the 
callback call.

=item I<Compile java Helper code at install time>

This would speed up start-up.

=item I<Provide named arguments to all methods>

This should be done at least on Channel methods. This module should then decide which Java
signature to call.

=back

=head1 SEE ALSO

=over 4

=item L<Net::RabbitMQ>

=item L<Net::RabbitFoot>

=item L<Net::AMQP>

=item L<POE::Component::Client::AMQP>

=item L<Net::STOMP::Client>

=back

=head1 BUGS

Please report any bugs to C<bug-net-rabbitmq-java@rt.cpan.org>, or through the web
interface at L<https://rt.cpan.org/Public/Bug/Report.html?Queue=Net-RabbitMQ-Java>.
The author will be happy to read your feedback.

=head1 AUTHOR

Alessandro Ranellucci <aar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Alessandro Ranellucci.

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

This distribution includes the RabbitMQ Java client library which is dual-licensed 
under the MPL and the GPL v2. It also includes the commons-io library which is 
licensed under the Apache Licence v2.
If you have any questions or concerns regarding licensing, contact the distribution 
maintainer.

=cut
