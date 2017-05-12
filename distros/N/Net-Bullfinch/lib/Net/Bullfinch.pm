package Net::Bullfinch;
{
  $Net::Bullfinch::VERSION = '0.16';
}
use Moose;
use MooseX::Params::Validate;
use MooseX::Types::DateTime;
use Moose::Util::TypeConstraints;

# ABSTRACT: Perl wrapper for talking with Bullfinch

use Data::UUID;
use JSON::XS;
use Memcached::Client;

use Net::Bullfinch::Iterator;

subtype 'QueueName',
    as 'Str',
    where { $_ =~ /^[a-zA-Z0-9_-]*$/ };


has '_client' => (
    is => 'rw',
    isa => 'Memcached::Client',
    default => sub {
        my $self = shift;
        return Memcached::Client->new ({
            servers => [ $self->host.':'.$self->port ]
        });
    },
    lazy => 1
);

has 'host' => (
    is => 'rw',
    isa => 'Str',
    required => 1
);

has 'port' => (
    is => 'rw',
    isa => 'Int',
    default => '22133'
);

has 'response_prefix' => (
    is => 'rw',
    isa => 'Str',
    default => 'response-net-kestrel-'
);

has 'timeout' => (
    is => 'rw',
    isa => 'Int',
    default => 30000
);

has 'error_on_no_response' => (
    is => 'rw',
    isa => 'Bool',
    default => 0
);



sub send {
    my ($self, $queue, $data, $queuename, $trace, $procby, $expire, $no_response ) = validated_list(\@_,
        request_queue         => { isa => 'QueueName' },
        request               => { isa => 'HashRef' },
        response_queue_suffix => { isa => 'QueueName', optional => 1 },
        trace                 => { isa => 'Bool', default => 0, optional => 1 },
        process_by            => { isa => 'DateTime', optional => 1 },
        expiration            => { isa => 'Int', optional => 1 },
        no_response           => { isa => 'Bool', default => 0, optional => 1 }
    );


    my ($rname, $json);
    if ( $no_response ) {
      ($rname, $json) = $self->_prepare_request($data, undef, undef, $trace, $procby);
    } else {
      ($rname, $json) = $self->_prepare_request($data, $queuename, $self->response_prefix, $trace, $procby);
    }
    my $kes = $self->_client;

    my $src = $kes->set($queue, $json, $expire);
    die "Failed to send request!" unless $src;
    my @items = ();
    return \@items if ( $no_response );

    while(1) {
        my $resp = $kes->get($rname.'/t='.$self->timeout);
        if(defined($resp)) {
            my $decoded = decode_json($resp);
            if(exists($decoded->{EOF})) {
                last;
            }
            push(@items, $decoded);
        }

        if(!defined($resp)) {
            if ( $self->error_on_no_response  ) {
                push @items,{ ERROR => "no response from $queue,$queuename" };
            }
            last;
        }
    }
    my $drc = $kes->delete($rname);
    warn "Failed to delete response queue!" unless $drc;

    return \@items;
}

sub iterate {
    my ($self, $queue, $data, $queuename, $iterator_options) = validated_list(\@_,
        request_queue         => { isa => 'Str' },
        request               => { isa => 'HashRef' },
        response_queue_suffix => { isa => 'Str', optional => 1 },
        iterator_options      => { isa => 'HashRef', optional => 1 }
    );

    my ($rname, $json) = $self->_prepare_request($data, $queuename, $self->response_prefix);
    my $kes = $self->_client;

    $kes->set($queue, $json);

    Net::Bullfinch::Iterator->new(
        bullfinch      => $self,
        response_queue => $rname,
        %$iterator_options
    );
}


sub iterate_async {
    my ($self, $queue, $data, $queuename, $expire, $error_cb, $result_cb) = validated_list(\@_,
        request_queue         => { isa => 'Str' },
        request               => { isa => 'HashRef' },
        response_queue_suffix => { isa => 'Str', optional => 1 },
        expiration            => { isa => 'Int', optional => 1 },
        error_cb              => { isa => 'CodeRef' },
        result_cb             => { isa => 'CodeRef' },
    );

    my ($rname, $json) = $self->_prepare_request($data, $queuename, $self->response_prefix);

    my $request_row_async;
    $request_row_async = sub {
        $self->_client->set($queue, $json, $expire, sub {
            my ($rc) = @_;
            return $error_cb->('Failed to send request!') unless $rc;

            $self->_client->get($rname.'/t='.$self->timeout, sub {
                my ($resp) = @_;
                return $error_cb->('timeout') unless defined $resp;

                my $decoded = decode_json $resp;
                return $result_cb->() if exists $decoded->{EOF};

                $result_cb->($decoded);

                $request_row_async->();
            });
        });
    };

    $request_row_async->();
}

sub _prepare_request {
    my ($self, $data, $queuename, $rname, $trace, $procby) = @_;

    # Make a copy of the hash so that we can add a key to it
    my %copy = %{ $data };

    if ( defined($queuename) ) {
       if ( defined($rname) ) {
          $rname .= $queuename;
       }
    }
    $copy{response_queue} = $rname if ( $rname );

    # User requested a trace, generate one
    if($trace) {
        my $ug = Data::UUID->new;
        $copy{tracer} = $ug->create_str;
    }

    if($procby) {
        $copy{'process-by'} = $procby->iso8601;
    }

    return ($rname, encode_json(\%copy));
}

1;

__END__

=pod

=head1 NAME

Net::Bullfinch - Perl wrapper for talking with Bullfinch

=head1 VERSION

version 0.16

=head1 SYNOPSIS

    use Net::Bullfinch;

    my $client = Net::Bullfinch->new(host => '172.16.49.130');
    my $req = { statement => 'some-query' };
    my $items = $client->send(
        request_queue => 'test-net-kestrel',
        request => $req,
        response_queue_suffix => 'foobar'
    );
    foreach my $item (@{ $items }) {
        # whatever
    }

=head1 DESCRIPTION

Net::Bullfinch is a thin wrapper around L<Memcached::Client> for communicating with
a L<Bullfinch|https://github.com/gphat/bullfinch/>.

This module handles JSON encoding of the request, the addition of a response
queue, waiting for a response, confirmation of the message, decoding of the
response and deletion of the response queue.

If you're expecting large numbers of results you might enjoy using
L<Net::Bullfinch::Iterator> to return any given number of max_results at a time.

=head1 TRACING

Bullfinch supports adding a tracing a request so that performance metrics
and responses can be tracked.

    my $items = $client->send(
        request_queue => 'test-net-kestrel',
        request => $req,
        response_queue_suffix => 'foobar'
        trace => 1
    );

A UUID will be added to the request.  This UUID will be included in the
performance code in bullfinch workers and included in the response you
receive.

=head1 ATTRIBUTES

=head2 host

The IP address of the host that we'll be connecting to.

=head2 port

The port of the IP address of the host we'll be connecting to.

=head2 response_prefix

The prefix used for the name of the response queue.

=head2 timeout

Set the timeout (in milliseconds) that will be used when awaiting a response
back from Bullfinch.

=head2 error_on_no_response

Set an error explicitly when there is no response from bullfinch default
behavior is false which will return them same empty array is for success or
timeout on insert/delete/update statements

=head1 METHODS

=head2 send( request_queue => $queue, request => \%data, response_queue_suffix => $response_name, process_by => $procby, expiration => $expire);

Send the request to the specified queue and await a response.  The data
should be a hashref and the queuename (optional) will be appended to
C<response_prefix>.  This allows you to create a unique response queue per
request.

    # Response queue will be "response-net-kestrel-foobar"
    my $items = $client->send(\%data, "foobar");

Any messages sent in response (save the EOF message) are returned as an
arrayref to the caller.

The optional C<no_response> will cause no response to be returned

The optional C<process_by> must be an ISO 8601 date.

The optional C<expiration> is the number of seconds this request should live
in the queue before expiring.

B<Note:> Send will die if it fails to properly enqueue the request.

=head2 iterate_async( request_queue => $queue, request => \%data, response_queue_suffix => $response_name, expiration => $expire, result_cb => \&cb, error_cb => \&err_cb);

Send the request to the specified queue asynchronously and register C<result_cb>
and C<error_cb> to be called upon the arrival of any results or the occurence of
an error, respectively.

The data should be a hashref and the queuename (optional) will be appended to
C<response_prefix>.  This allows you to create a unique response queue per
request.

Any messages received in response (save the EOF message) are passed to a call to
the C<result_cb> as the only argument.

The optional C<expiration> is the number of seconds this request should live
in the queue before expiring.

Encountering any errors, such as not being able to enqueue the request, will
cause the C<error_cb> to be invoked with a string describing the error as the
only argument.

B<Note> that this method returns immediately after enqueueing the request. It's
the callers responsibility to run an L<AnyEvent> compatible event loop in order
for the enqueued request to actually be sent and the result callbacks to be
invoked.

=head1 AUTHORS

=over 4

=item *

Cory G Watson <gphat@cpan.org>

=item *

Stevan Little <stevan.little@iinteractive.com>

=item *

Jay Hannah <jay.hannah@iinteractive.com>

=item *

Trey Bianchini <trey.bianchini@iinteractive.com>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Florian Ragwitz <rafl@debian.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
