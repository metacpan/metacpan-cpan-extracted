package Net::Stomp::Producer;
$Net::Stomp::Producer::VERSION = '2.005';
{
  $Net::Stomp::Producer::DIST = 'Net-Stomp-Producer';
}
use Moose;
use namespace::autoclean;
with 'Net::Stomp::MooseHelpers::CanConnect' => { -version => '2.6' };
with 'Net::Stomp::MooseHelpers::ReconnectOnFailure';
use MooseX::Types::Moose qw(Str Bool CodeRef HashRef);
use Net::Stomp::Producer::Exceptions;
use Module::Runtime 'use_package_optimistically';
use Try::Tiny;

# ABSTRACT: helper object to send messages via Net::Stomp


has serializer => (
    isa => CodeRef,
    is => 'rw',
    default => sub { \&_no_serializer },
);

sub _no_serializer {
    my ($message) = @_;
    return $message unless ref $message;

    Net::Stomp::Producer::Exceptions::CantSerialize->throw({
        previous_exception => q{can't send a reference without a serializer},
        message_body => $message,
    });
}


has default_headers => (
    isa => HashRef,
    is => 'rw',
    default => sub { { } },
);


has transactional_sending => (
    isa => Bool,
    is => 'rw',
    default => 0,
    trigger => \&_transactional_sending_compat,
);

sub _transactional_sending_compat {
    my ($self, $value) = @_;

    if ($value) { $self->sending_method('transactional') }
    else { $self->sending_method('') }
}


has sending_method => (
    isa => Str,
    is => 'rw',
    default => '',
);

sub _send_method_to_call {
    my ($self,$requested_method) = @_;

    $requested_method ||= $self->sending_method;
    my $method_name =
        ($requested_method eq '' or $requested_method eq 'default')
        ? 'send'
        : "send_${requested_method}";
    return $method_name;
}

around 'sending_method' => sub {
    my ($orig,$self,$value) = @_;
    return $self->$orig() unless @_ > 2;

    my $method = $self->_send_method_to_call($value);
    Net::Stomp::Producer::Exceptions::BadMethod->throw({
        sending_method_value => $value,
        method_to_call => $method,
    }) unless $self->connection->can($method);

    return $self->$orig($value);
};


sub _prepare_message {
    my ($self,$destination,$headers,$body) = @_;
    use bytes;

    try { $body = $self->serializer->($body) }
    catch {
        if (eval {$_[0]->isa('Net::Stomp::Producer::Exceptions::CantSerialize')}) {
            die $_[0];
        }
        my $prev=$_[0];
        Net::Stomp::Producer::Exceptions::CantSerialize->throw({
            message_body => $body,
            previous_exception => $prev,
        });
    };

    my %actual_headers=(
        %{$self->default_headers},
        %$headers,
        #'content-length' => length($body),
        body => $body,
    );

    $actual_headers{destination} = $destination if defined $destination;

    for ($actual_headers{destination}) {
        $_ = "/$_"
            unless m{^/};
    }

    return \%actual_headers;
}

sub _really_send {
    my ($self,$frame) = @_;

    my $method = $self->_send_method_to_call;

    $self->reconnect_on_failure(
        sub {
            my $ret = $_[0]->connection->$method($_[1]);
            die "Call to $method failed"
                unless $ret;
        },
        $frame,
    );
}

sub send {
    my ($self,$destination,$headers,$body) = @_;

    my $actual_headers = $self->_prepare_message($destination,$headers,$body);

    $self->_really_send($actual_headers);

    return;
}


has transformer_args => (
    is => 'rw',
    isa => HashRef,
    default => sub { { } },
);


sub make_transformer {
    my ($self,$transformer) = @_;

    return $transformer if ref($transformer);

    use_package_optimistically($transformer);
    if ($transformer->can('new')) {
        # shallow clone, to make it less likely that a transformer
        # will clobber our args
        return $transformer->new(
            { %{$self->transformer_args} }
        );
    }
    return $transformer;
}


sub transform {
    my ($self,$transformer,@input) = @_;

    $transformer=$self->make_transformer($transformer);

    my $method = try { $transformer->can('transform') }
        or Net::Stomp::Producer::Exceptions::BadTransformer->throw({
            transformer => $transformer,
        });

    my @messages = $transformer->$method(@input);

    my $vmethod = try { $transformer->can('validate') };

    my @ret;

    while (my ($headers, $body) = splice @messages, 0, 2) {
        if ($vmethod) {
            my ($exception,$valid);
            try {
                $valid = $transformer->$vmethod($headers,$body);
            } catch { $exception = $_ };
            if (!$valid) {
                Net::Stomp::Producer::Exceptions::Invalid->throw({
                    transformer => $transformer,
                    message_body => $body,
                    message_headers => $headers,
                    previous_exception => $exception,
                });
            }
        }
        push @ret,$headers,$body;
    }

    return @ret;
}


sub send_many {
    my ($self,@messages) = @_;

    while (my ($headers, $body) = splice @messages, 0, 2) {
        $self->send(undef,$headers,$body);
    }

    return;
}


sub transform_and_send {
    my ($self,$transformer,@input) = @_;

    my @messages = $self->transform($transformer,@input);

    $self->send_many(@messages);

    return;
}

__PACKAGE__->meta->make_immutable;


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Stomp::Producer - helper object to send messages via Net::Stomp

=head1 VERSION

version 2.005

=head1 SYNOPSIS

  my $ser = JSON::XS->new->utf8;

  my $p = Net::Stomp::Producer->new({
    connect_headers => { login => 'some-login', passcode => 's3cr3t' },
    servers => [
      { hostname => 'broker1.local', port => 61613 },
      { hostname => 'broker2.local', port => 61613, ssl => 1 },
      { hostname => 'broker3.local', port => 61613, ssl => 1,
        connect_headers => { login => 'some-different-login',
                             passcode => 'an0th3r-s3cr3t' },
      },
    ],
    serializer => sub { $ser->encode($_[0]) },
    default_headers => { 'content-type' => 'json' },
  });

  $p->send('/queue/somewhere',
           { type => 'my_message' },
           { a => [ 'data', 'structure' ] });

Also:

  package My::Message::Transformer {
    use Moose;
    sub transform {
      my ($self,@elems) = @_;

      return { destination => '/queue/somewhere',
               type => 'my_message', },
             { a => \@elems };
    }
  }

  $p->transform_and_send('My::Message::Transformer',
                         'data','structure');

Or even:

  my $t = My::Message::Transformer->new();
  $p->transform_and_send($t,
                         'data','structure');

They all send the same message.

=head1 DESCRIPTION

This class sends messages via a STOMP connection (see
L<Net::Stomp::MooseHelpers::CanConnect>). It provides facilities for
serialisation and validation. You can have an instance of this class
as a singleton / global in your process, and use it to send all your
messages: this is recommended, as it will prevent flooding the broker
with many connections (each instance would connect independently, and
if you create many instances per second, the broker or your process
may run out of file descriptiors and stop working).

You can use it at several levels:

=head2 Raw sending

  my $p = Net::Stomp::Producer->new({
    servers => [ { hostname => 'localhost', port => 61613 } ],
  });

  $p->send($destination,\%headers,$body_byte_string);

This will just wrap the parameters in a L<Net::Stomp::Frame> and send
it. C<$destination> can be undef, if you have set it in the
C<%headers>.

=head2 Serialisation support

  my $p = Net::Stomp::Producer->new({
    servers => [ { hostname => 'localhost', port => 61613 } ],
    serializer => sub { encode_json($_[0]) },
  });

  $p->send($destination,\%headers,$body_hashref);

The body will be passed through the C<serializer>, and the resulting
string will be used as above.

=head2 Transformer instance

  $p->transform_and_send($transformer_obj,@args);

This will call C<< $transformer_obj->transform(@args) >>. That
function should return a list (with an even number of elements). Each
pair of elements is interpreted as C<< \%headers, $body_ref >> and
passed to L</send> as above (with no C<destination>, so the
transformer should set it in the headers). It's not an error for the
transformer to return an empty list: it just means that nothing will
be sent.

=head2 Transformer class

  my $p = Net::Stomp::Producer->new({
    servers => [ { hostname => 'localhost', port => 61613 } ],
    transformer_args => { some => 'param' },
  });

  $p->transform_and_send($transformer_class,@args);

The transformer will be instantiated like C<<
$transformer_class->new($p->transformer_args) >>, then the object will
be called as above.

=head2 Transform & validate

If the transformer class / object supports the C<validate> method, it
will be called before sending each message, like:

  $transformer_obj->validate(\%headers,$body_ref);

This method is expected to return a true value if the message is
valid, and throw a meaningful exception if it is not. The exception
will be wrapped in a L<Net::Stomp::Producer::Exceptions::Invalid>. If
the C<validate> method returns false without throwing any exception,
L<Net::Stomp::Producer::Exceptions::Invalid> will still be throw, but
the C<previous_exception> slot will be undef.

=head1 ATTRIBUTES

=head2 C<serializer>

A coderef that, passed the body parameter from L</send>, returns a
byte string to use as the frame body. The default coderef will just
pass non-refs through, and die (with a
L<Net::Stomp::Producer::Exceptions::CantSerialize> exception) if
passed a ref.

=head2 C<default_headers>

Hashref of STOMP headers to use for every frame we send. Headers
passed in to L</send> take precedence. There is no support for
I<removing> a default header for a single send.

=head2 C<transactional_sending>

B<DEPRECATED>. Use L</sending_method> instead. This boolean was too
restrictive.

Instead of doing C<< ->transactional_sending(1) >> do C<<
->sending_method('transactional') >>.

Instead of doing C<< ->transactional_sending(0) >> do C<<
->sending_method('') >> or C<< ->sending_method('default') >>.

Boolean, defaults to false. If true, use
L<Net::Stomp/send_transactional> instead of L<Net::Stomp/send> to send
frames.

=head2 C<sending_method>

String, defaults to C<''>. Selects which method to use on the
connection's L<Net::Stomp> object to actually send a message. The name
of the method is derived from the value of this attribute by
prepending C<send_> to it (so you can't abuse this to call arbitrary
methods), unless this attribute's value is C<''> or C<'default'>, in
which case the simple C<send> method will be used.

For example, C<< sending_method => 'with_receipt' >> will block
sending until the broker sends back a receipt for the message (or it
times out).

C<< sending_method => 'transactional' >> will send a C<COMMIT> frame
when the receipt is received, or a C<ROLLBACK> frame if something
breaks.

I<NOTE>: these methods work when the connection is used only to send
messages, and not to receive them! The current implementation will
very probably deadlock or throw exceptions at random moments if
messages arrive while you're sending.

=head2 C<transformer_args>

Hashref to pass to the transformer constructor when
L</make_transformer> instantiates a transformer class.

=head1 METHODS

=head2 C<send>

  $p->send($destination,\%headers,$body);

Serializes the C<$body> via the L</serializer>, merges the C<%headers>
with the L</default_headers>, setting the C<content-length> to the
byte length of the serialized body. Overrides the destination in the
headers with C<$destination> if it's defined.

Finally, sends the frame.

=head2 C<make_transformer>

  $p->make_transformer($class);

If passed a reference, this function just returns it (it assumes it's
a transformer object ready to use).

If passed a string, tries to load the class with
L<Module::Runtime::use_package_optimistically|Module::Runtime/use_package_optimistically>. If
the class has a C<new> method, it's invoked with the value of
L</transformer_args> to obtain an object that is then returned. If the
class does not have a C<new>, the class name is returned.

=head2 C<transform>

  my (@headers_and_bodies) = $p->transform($transformer,@data);

Uses L</make_transformer> to (optionally) instantiate a transformer
object, then tries to call C<transform> on it. If there is no such
method, a L<Net::Stomp::Producer::Exceptions::BadTransformer> is
thrown.

The transformer is expected to return a list of (header,body) pairs
(that is, a list with an even number of elements; I<not> a list of
arrayrefs!).

Each message in the returned list is optionally validated, then returned.

The optional validation happens if the transformer C<<
->can('validate') >>. If it can, that method is called like:

  $transformer->validate($header,$body_ref);

The method is expected to return a true value if the message is valid,
and throw a meaningful exception if it is not. The exception will be
wrapped in a L<Net::Stomp::Producer::Exceptions::Invalid>. If the
C<validate> method returns false without throwing any exception,
L<Net::Stomp::Producer::Exceptions::Invalid> will still be throw, but
the C<previous_exception> slot will be undef.

It's not an error for the transformer to return an empty list: it just
means that nothing will be returned.

=head2 C<send_many>

  $p->send_many(@headers_and_bodies);

Given a list of (header,body) pairs (that is, a list with an even
number of elements; I<not> a list of arrayrefs!), it will send each
pair as a message. Useful in combination with L</transform>.

It's not an error for the list to beempty: it just means that nothing
will be sent.

=head2 C<transform_and_send>

  $p->transform_and_send($transformer,@data);

Equivalent to:

  $p->send_many($p->transform($transformer,@data));

which is similar to:

  my ($header,$body) = $p->transform($transformer,@data);
  $p->send(undef,$header,$body);

but it works also when the transformer returns more than one pair.

It's not an error for the transformer to return an empty list: it just
means that nothing will be sent.

I<< Why would I ever want to use L</transform> and L</send_many> separately? >>

Let's say you are in a transaction, and you want to fail if the
messages cannot be prepared, but not fail if the prepared messages
cannot be sent. In this case, you call L</transform> inside the
transaction, and L</send_many> outside of it.

But yes, in most cases you should really just call
C<transform_and_send>.

=head1 EXAMPLES

You can find examples of use in the tests, or at
https://github.com/dakkar/CatalystX-StompSampleApps

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Net-a-porter.com.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
