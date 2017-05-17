# SQS::Worker

This project is a light framework that allows you to just code asyncronous tasks
that consume messages from an SQS Queue. The framework takes care of launching the 
necessary processes (workers), and executes your code on incoming messages.

Also, since you're surely going to be deserializing the messages that come from the
queue, SQS::Worker provides you with ways to easily consume JSON messages, for example.

# Architecture

## The worker

The worker is the unit of work. Each worker is launched independently of other workers, 
which fits the asynchronous and independent nature of messaging. In fact, each worker 
will be a full process, that will dispatch messages from the queue to your code.

A worker is a role that your code will consume, and that will let the framework know how 
to send messages to it.

The Moose role ```SQS::Worker``` is to be used for this purpose.

```
package YourWorker;

use Moose;
with 'SQS::Worker';

sub process_message {
	my ($self, $message) = @_;

	# do something with that message: f. ex:

  $self->log->debug("I'm going to split the message");
  my @parts = split /:/, $message;

  ...
}
```

You get a logger attached to the worker by default, so you don't need to worry about logging.

By default, if something goes badly in `process_message` (it raises an uncontrolled 
exception) the message will not be deleted from the queue, thus being retried after
the visibility timeout: http://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-visibility-timeout.html

Once you have a worker class, there's a loader (installed as part of the SQS::Worker framework) 
called `spawn_worker` that, along with some extra configuration, will launch a process that 
will receive messages from the queue and pass them to the worker class you've created.

```
spawn_worker --worker YourClass --queue_url sqs_endpoint_url --region aws_sqs_region --log_conf log4perl_config_file_path
```

You can control if the message should be deleted upon reception (before the message is actually processed) with:

```
spawn_worker --worker YourClass --queue_url sqs_endpoint_url --region aws_sqs_region --log_conf log4perl_config_file_path --consumer DeleteAlways
```

`spawn_worker` is just a convenience loader: you don't necessarily need to use it: you can write your own worker (just look at it's code)

## Composable interceptors for workers

While the basic worker role will provide your code with a raw sqs message (as a string), there are interceptors that can be composed into your class that will pre-process the message. Among them:

- SQS::Worker::DecodeJson
- SQS::Worker::DecodeStorable
- SQS::Worker::Multipex
- SQS::Worker::SNS

For example, if you compose your worker with the role SQS::Worker::DecodeJSON, the message received by the process_message will be a perl datastructure, instead of a string.

Look at the documentation of each interceptor too see what each does, and how to be used.

You can compose more than one Worker role into your worker. If you recieve a message in JSON format, and later want to dispatch it to a series
of actions, you can:

```
with 'SQS::Worker', 'SQS::Worker::DecodeJson', 'SQS::Worker::Multiplex';
```

## Credentials handling

SQS::Worker is an abstraction over Paws, it thus uses the same credential system that Paws does, which means the three ways you can provide the access key and secret key for the code to use:

- having the credentials in the home of the user launching the script, in the ~/.aws/credentials file.
- by assigning an IAM role to the EC2 instance that is running the code (if deploying the code inside an EC2 instance)
- by using environment variables: AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY

