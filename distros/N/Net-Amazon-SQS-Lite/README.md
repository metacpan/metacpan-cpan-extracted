# NAME

Net::Amazon::SQS::Lite - Amazon SQS client

# SYNOPSIS

    use Net::Amazon::SQS::Lite;

    my $sqs = Net::Amazon::SQS::Lite->new(
        access_key => "XXXXX",
        secret_key => "YYYYY",
        region => "ap-northeast-1",
    );
    my %queue = $sqs->list_queues->{ListQueueResult};

# DESCRIPTION

Net::Amazon::SQS::Lite is simple Amazon SQS simple client.

THIS IS A DEVELOPMENT RELEASE. API MAY CHANGE WITHOUT NOTICE.

# METHODS

## add\_permission

Adds a permission to a queue for a specific principal.

    $sqs->add_permission({
        "AWSAccountId.1" => "12345678",
        "ActionName.1" => "SendMessage",
        QueueUrl => "http://localhost:9324/queue/test_queue",
        Label => "testLabel"
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_AddPermission.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_AddPermission.html)

## change\_message\_visibility

Changes the visibility timeout of a specified message in a queue to a new value.

    $sqs->change_message_visibility({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        ReceiptHandle => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
        VisibilityTimeout => 60
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_ChangeMessageVisibility.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ChangeMessageVisibility.html)

## change\_message\_visibility\_bacth

Changes the visibility timeout of multiple messages.

    $sqs->change_message_visibility_batch({
        "ChangeMessageVisibilityBatchRequestEntry.1.Id" => "change_visibility_msg_2",
        "ChangeMessageVisibilityBatchRequestEntry.1.ReceiptHandle" => "gfk0T0R0waama4fVFffkjKzmhMCymjQvfTFk2LxT33G4ms5subrE0deLKWSscPU1oD3J9zgeS4PQQ3U30qOumIE6AdAv3w%2F%2Fa1IXW6AqaWhGsEPaLm3Vf6IiWqdM8u5imB%2BNTwj3tQRzOWdTOePjOjPcTpRxBtXix%2BEvwJOZUma9wabv%2BSw6ZHjwmNcVDx8dZXJhVp16Bksiox%2FGrUvrVTCJRTWTLc59oHLLF8sEkKzRmGNzTDGTiV%2BYjHfQj60FD3rVaXmzTsoNxRhKJ72uIHVMGVQiAGgBX6HGv9LDmYhPXw4hy%2FNgIg%3D%3D",
        "ChangeMessageVisibilityBatchRequestEntry.1.VisibilityTimeout" => 45,
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_ChangeMessageVisibilityBatch.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ChangeMessageVisibilityBatch.html)

## create\_queue

Create a new queue, or returns the URL of an existing one.

    $sqs->create_queue({
        QueueName => "test_queue"
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_CreateQueue.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_CreateQueue.html)

## delete\_message

Deletes the specified message from the specified queue.

    $sqs->delete_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        ReceiptHandle => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
        VisibilityTimeout => 60
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_DeleteMessage.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_DeleteMessage.html)

## delete\_message\_batch

Deletes up to ten messages from the specified queue.

    $sqs->delete_message_batch({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "DeleteMessageBatchRequestEntry.1.Id" => "msg1",
        "DeleteMessageBatchRequestEntry.1.ReceiptHandle" => $res->{ReceiveMessageResult}->{Message}->{ReceiptHandle},
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_DeleteMessageBatch.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_DeleteMessageBatch.html)

## delete\_queue

Deletes the queue specified by the queue URL.

    $sqs->delete_queue({
        QueueUrl => "http://localhost:9324/queue/test_queue"
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_DeleteQueue.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_DeleteQueue.html)

## get\_queue\_attributes

Gets attributes for the specified queue.

    $sqs->get_queue_attributes({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "AttributeName.1" => "VisibilityTimeout",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_GetQueueAttributes.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_GetQueueAttributes.html)

## get\_queue\_url

Returns the URL of an existing queue.

    $sqs->get_queue_url({
        QueueName => "test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_GetQueueUrl.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_GetQueueUrl.html)

## list\_dead\_letter\_source\_queues

Returns a list of your queues that have the Redrive Policy queue attribute configured with a dead letter queue.

    $sqs->list_dead_letter_source_queues({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_ListDeadLetterSourceQueues.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ListDeadLetterSourceQueues.html)

## list\_queues

Returns a list of you queues.

    $sqs->list_queues;

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_ListQueues.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ListQueues.html)

## purge\_queue

Deletes the messages in a queue specified by the queue URL.

    $sqs->purge_queue({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_PurgeQueue.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_PurgeQueue.html)

## receive\_message

Retrieves one or more messages, with a maximum limit of 10 messages, from the specified queue.

    $sqs->receive_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_ReceiveMessage.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_ReceiveMessage.html)

## remove\_permission

Revokes any permissions in the queue policy that matches the specified Lable parameter.

    $sqs->remove_permission({
        Label => "testLabel"
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_RemovePermission.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_RemovePermission.html)

## send\_message

Delivers a message to the specified queue.

    $sqs->send_message({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        MessageBody => "Hello!"
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_SendMessage.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_SendMessage.html)

## send\_message\_batch

Delivers up to ten messages to the specified queue.

    $sqs->send_message_batch({
        "SendMessageBatchRequestEntry.1.Id" => "msg1",
        "SendMessageBatchRequestEntry.1.MessageBody" => "Hello!",
        QueueUrl => "http://localhost:9324/queue/test_queue",
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_SendMessageBatch.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_SendMessageBatch.html)

## set\_queue\_attributes

Sets the value of one or more queue attributes.

    $sqs->set_queue_attributes({
        QueueUrl => "http://localhost:9324/queue/test_queue",
        "Attribute.Name" => "VisibilityTimeout",
        "Attribute.Value" => 40,
    });

- SEE [http://docs.aws.amazon.com/ja\_jp/AWSSimpleQueueService/latest/APIReference/API\_SetQueueAttributes.html](http://docs.aws.amazon.com/ja_jp/AWSSimpleQueueService/latest/APIReference/API_SetQueueAttributes.html)

# LICENSE

Copyright (C) Kazuhiro Shibuya.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazuhiro Shibuya <stevenlabs@gmail.com>
