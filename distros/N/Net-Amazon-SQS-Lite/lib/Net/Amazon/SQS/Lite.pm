package Net::Amazon::SQS::Lite;
use 5.008001;
use strict;
use warnings;

our $VERSION = "0.04";

use Carp;
use Encode qw(decode);
use Furl;
use HTTP::Request::Common;
use Moo;
use POSIX qw(setlocale LC_TIME strftime);
use Time::Piece;
use URI;
use URI::QueryParam;
use WebService::Amazon::Signature::v4;
use XML::Simple;

has signature => (
    is => 'lazy',
);

has scope => (
    is => 'lazy',
);

has ua => (
    is => 'lazy',
);

has uri => (
    is => 'lazy',
);

has access_key => (
    is => 'ro',
);

has secret_key => (
    is => 'ro',
);

has region => (
    is => 'ro',
);

has ca_path => (
    is => 'rw',
    default => sub {
        '/etc/ssl/certs',
    },
);

has connection_timeout => (
    is => 'rw',
    default => sub {
        1,
    },
);

has version => (
    is => 'rw',
    default => sub {
        '2012-11-05'
    },
);

has xml_decoder => (
    is => 'rw',
    default => sub {
        XML::Simple->new;
    },
);

sub _build_signature {
    my ($self) = @_;
    my $locale = setlocale(LC_TIME);
    setlocale(LC_TIME, "C");
    my $v4 = WebService::Amazon::Signature::v4->new(
        scope => $self->scope,
        access_key => $self->access_key,
        secret_key => $self->secret_key,
    );
    setlocale(LC_TIME, $locale);
    $v4;
}

sub _build_scope {
    my ($self) = @_;
    join '/', strftime('%Y%m%d', gmtime), $self->region, qw(sqs aws4_request);
}

sub _build_ua {
    my ($self) = @_;

    my $ua = Furl->new(
        agent => 'Net::Amazon::SQS::Lite v0.01',
        timeout => $self->connection_timeout,
        ssl_opts => {
            SSL_ca_path => $self->ca_path,
        },
    );
}

sub _build_uri {
    my ($self) = @_;
    URI->new('http://sqs.' . $self->region . '.amazonaws.com/');
}

sub make_request {
    my ($self, $content) = @_;

    my $req = POST($self->uri, $content);
    my $locale = setlocale(LC_TIME);
    setlocale(LC_TIME, "C");
    $req->header(host => $self->uri->host);
    my $http_date = strftime('%a, %d %b %Y %H:%M:%S %Z', localtime);
    my $amz_date = strftime('%Y%m%dT%H%M%SZ', gmtime);
    $req->header(Date => $http_date);
    $req->header('x-amz-date' => $amz_date);
    $req->header('content-type' => 'application/x-www-form-urlencoded');
    $self->signature->from_http_request($req);
    $req->header(Authorization => $self->signature->calculate_signature);
    setlocale(LC_TIME, $locale);
    return $req;
}

sub _request {
    my ($self, $req_param) = @_;
    my $req = $self->make_request($req_param);
    my $res = $self->ua->request($req);
    my $decoded = $self->xml_decoder->XMLin($res->content);
    if ($res->is_success) {
        return $decoded;
    } else {
        Carp::croak $decoded;
    }
}

sub add_permission {
    my ($self, $param) = @_;

    my $account_id_valid = 0;
    my $action_name_valid = 0;
    for my $key (keys %{$param}) {
        $account_id_valid = 1 if $key =~ /AWSAccountId\.\d/;
        $action_name_valid = 1 if $key =~ /ActionName\.\d/;
    }
    Carp::croak "AWSAccountId.[num] is required." unless $account_id_valid;
    Carp::croak "ActionName.[num] is required." unless $action_name_valid;
    Carp::croak "Label is required." unless $param->{Label};
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'AddPermission',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub change_message_visibility {
    my ($self, $param) = @_;

    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    Carp::croak "ReceiptHandle is required." unless $param->{ReceiptHandle};
    Carp::croak "VisibilityTimeout is required." unless $param->{VisibilityTimeout};
    my $req_param = {
        'Action' => 'ChangeMessageVisibility',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub change_message_visibility_batch {
    my ($self, $param) = @_;

    my $batch_request_entry = 0;
    for my $key (keys %{$param}) {
        $batch_request_entry = 1 if $key =~ /ChangeMessageVisibilityBatchRequestEntry\.\d/;
    }
    Carp::croak "ChangeMessageVisibilityBatchRequestEntry.[num] is required." unless $batch_request_entry;
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'ChangeMessageVisibilityBatch',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub list_queues {
    my ($self, $param) = @_;

    my $req_param = {
        'Action' => 'ListQueues',
        'Version' => $self->version,
    };
    $req_param->{QueueNamePrefix} = $param->{QueueNamePrefix} if $param->{QueueNamePrefix};
    $self->_request($req_param);
}

sub create_queue {
    my ($self, $param) = @_;

    Carp::croak "QueueName is required." unless $param->{QueueName};
    my $req_param = {
        'Action' => 'CreateQueue',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub delete_message {
    my ($self, $param) = @_;

    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    Carp::croak "ReceiptHandle is required." unless $param->{ReceiptHandle};
    my $req_param = {
        'Action' => 'DeleteMessage',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub delete_message_batch {
    my ($self, $param) = @_;

    my $batch_request_entry = 0;
    for my $key (keys %{$param}) {
        $batch_request_entry = 1 if $key =~ /DeleteMessageBatchRequestEntry\.\d/;
    }
    Carp::croak "DeleteMessageBatchRequestEntry.[num] is required." unless $batch_request_entry;
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'DeleteMessageBatch',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub delete_queue {
    my ($self, $param) = @_;

    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'DeleteQueue',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub get_queue_attributes {
    my ($self, $param) = @_;

    my $attributes = 0;
    for my $key (keys %{$param}) {
        $attributes = 1 if $key =~ /AttributeName\.\d/;
    }
    Carp::croak "AttributeName.[num] is required." unless $attributes;
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'GetQueueAttributes',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub get_queue_url {
    my ($self, $param) = @_;

    Carp::croak "QueueName is required." unless $param->{QueueName};
    my $req_param = {
        'Action' => 'GetQueueUrl',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub list_dead_letter_source_queues {
    my ($self, $param) = @_;

    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'ListDeadLetterSourceQueues',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub purge_queue {
    my ($self, $param) = @_;

    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'PurgeQueue',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub receive_message {
    my ($self, $param) = @_;

    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'ReceiveMessage',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub remove_permission {
    my ($self, $param) = @_;

    Carp::croak "Label is required." unless $param->{Label};
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'RemovePermission',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub send_message {
    my ($self, $param) = @_;

    Carp::croak "MessageBody is required." unless $param->{MessageBody};
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'SendMessage',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub send_message_batch {
    my ($self, $param) = @_;

    my $request_entry = 0;
    for my $key (keys %{$param}) {
        $request_entry = 1 if $key =~ /SendMessageBatchRequestEntry\.\d/;
    }
    Carp::croak "SendMessageBatchRequestEntry.[num] is required." unless $request_entry;
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'SendMessageBatch',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

sub set_queue_attributes {
    my ($self, $param) = @_;

    my $attributes = 0;
    for my $key (keys %{$param}) {
        $attributes = 1 if $key =~ /Attribute\./;
    }
    Carp::croak "Attribute.[entry] is required." unless $attributes;
    Carp::croak "QueueUrl is required." unless $param->{QueueUrl};
    my $req_param = {
        'Action' => 'SetQueueAttributes',
        'Version' => $self->version,
        %{$param}
    };
    $self->_request($req_param);
}

1;
__END__

=encoding utf-8

=head1 NAME

Net::Amazon::SQS::Lite - Amazon SQS client

=head1 SYNOPSIS

    use Net::Amazon::SQS::Lite;

    my $sqs = Net::Amazon::SQS::Lite->new(
        access_key => "XXXXX",
        secret_key => "YYYYY",
        region => "ap-northeast-1",
    );
    my %queue = $sqs->list_queues->{ListQueueResult};

=head1 DESCRIPTION

Net::Amazon::SQS::Lite is simple Amazon SQS simple client.

THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.

=head1 METHODS

=head2 add_permission

Adds a permission to a queue for a specific principal.

    $sqs->add_permission({
        "AWSAccountId.1" => "12345678",
        "ActionName.1" => "SendMessage",
        QueueUrl => "http://localhost:9324/queue/test_queue",
        Label => "testLabel"
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_AddPermission.html>

=back

=head2 change_message_visibility

Changes the visibility timeout of a specified message in a queue to a new value.

    $sqs->change_message_visibility({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        ReceiptHandle => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
        VisibilityTimeout => 60
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ChangeMessageVisibility.html>

=back

=head2 change_message_visibility_bacth

Changes the visibility timeout of multiple messages.

    $sqs->change_message_visibility_batch({
        "ChangeMessageVisibilityBatchRequestEntry.1.Id" => "change_visibility_msg_2",
        "ChangeMessageVisibilityBatchRequestEntry.1.ReceiptHandle" => "gfk0T0R0waama4fVFffkjKzmhMCymjQvfTFk2LxT33G4ms5subrE0deLKWSscPU1oD3J9zgeS4PQQ3U30qOumIE6AdAv3w%2F%2Fa1IXW6AqaWhGsEPaLm3Vf6IiWqdM8u5imB%2BNTwj3tQRzOWdTOePjOjPcTpRxBtXix%2BEvwJOZUma9wabv%2BSw6ZHjwmNcVDx8dZXJhVp16Bksiox%2FGrUvrVTCJRTWTLc59oHLLF8sEkKzRmGNzTDGTiV%2BYjHfQj60FD3rVaXmzTsoNxRhKJ72uIHVMGVQiAGgBX6HGv9LDmYhPXw4hy%2FNgIg%3D%3D",
        "ChangeMessageVisibilityBatchRequestEntry.1.VisibilityTimeout" => 45,
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ChangeMessageVisibilityBatch.html>

=back

=head2 create_queue

Create a new queue, or returns the URL of an existing one.

    $sqs->create_queue({
        QueueName => "test_queue"
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html>

=back

=head2 delete_message

Deletes the specified message from the specified queue.

    $sqs->delete_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        ReceiptHandle => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
        VisibilityTimeout => 60
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_DeleteMessage.html>

=back

=head2 delete_message_batch

Deletes up to ten messages from the specified queue.

    $sqs->delete_message_batch({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "DeleteMessageBatchRequestEntry.1.Id" => "msg1",
        "DeleteMessageBatchRequestEntry.1.ReceiptHandle" => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_DeleteMessageBatch.html>

=back

=head2 delete_queue

Deletes the queue specified by the queue URL.

    $sqs->delete_queue({
        QueueUrl => "http://localhost:9324/queue/test_queue"
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_DeleteQueue.html>

=back

=head2 get_queue_attributes

Gets attributes for the specified queue.

    $sqs->get_queue_attributes({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "AttributeName.1" => "VisibilityTimeout",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_GetQueueAttributes.html>

=back

=head2 get_queue_url

Returns the URL of an existing queue.

    $sqs->get_queue_url({
        QueueName => "test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_GetQueueUrl.html>

=back

=head2 list_dead_letter_source_queues

Returns a list of your queues that have the Redrive Policy queue attribute configured with a dead letter queue.

    $sqs->list_dead_letter_source_queues({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ListDeadLetterSourceQueues.html>

=back

=head2 list_queues

Returns a list of you queues.

    $sqs->list_queues;

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ListQueues.html>

=back

=head2 purge_queue

Deletes the messages in a queue specified by the queue URL.

    $sqs->purge_queue({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_PurgeQueue.html>

=back

=head2 receive_message

Retrieves one or more messages, with a maximum limit of 10 messages, from the specified queue.

    $sqs->receive_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ReceiveMessage.html>

=back

=head2 remove_permission

Revokes any permissions in the queue policy that matches the specified Lable parameter.

    $sqs->remove_permission({
        Label => "testLabel"
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_RemovePermission.html>

=back

=head2 send_message

Delivers a message to the specified queue.

    $sqs->send_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        MessageBody => "Hello!"
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html>

=back

=head2 send_message_batch

Delivers up to ten messages to the specified queue.

    $sqs->send_message_batch({
        "SendMessageBatchRequestEntry.1.Id" => "msg1",
        "SendMessageBatchRequestEntry.1.MessageBody" => "Hello!",
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_SendMessageBatch.html>

=back

=head2 set_queue_attributes

Sets the value of one or more queue attributes.

    $sqs->set_queue_attributes({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "Attribute.Name" => "VisibilityTimeout",
        "Attribute.Value" => 40,
    });

=over 4

=item * SEE L<http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_SetQueueAttributes.html>

=back

=head1 LICENSE

Copyright (C) Kazuhiro Shibuya.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazuhiro Shibuya E<lt>stevenlabs@gmail.comE<gt>

=cut

