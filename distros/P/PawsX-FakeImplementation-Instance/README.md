# NAME

PawsX::FakeImplementation::Instance - A Paws extension to help you write fake AWS services

# SYNOPSIS

    use Paws;
    use Paws::Net::MultiplexCaller;
    use PawsX::FakeImplementation::Instance;

    my $paws = Paws->new(
      config => {
        caller => Paws::Net::MultiplexCaller->new(
          caller_for => {
            SQS => PawsX::FakeImplementation::Instance->new(
              api_class => 'FakeSQS',
            ),
          }
        ),
      }
    );

    my $sqs = $paws->service('SQS', region => 'test');
    my $new_queue = $sqs->CreateQueue(QueueName => 'MyQueue');
    # the FakeSQS implementation has returned a $new_queue object just
    # like SQS would:
    # $new_queue->QueueUrl eq 'http://sqs.fake.amazonaws.com/123456789012/MyQueue'

    my $qurl = $result->QueueUrl;
    
    my $sent_mess = $sqs->SendMessage(MessageBody => 'Message 1', QueueUrl => $new_queue->QueueUrl);
    # $sent_mess->MessageId has a unique id

    my $rec_mess = $sqs->ReceiveMessage(QueueUrl => $qurl);
    # $rec_mess->Messages->[0]->Body eq 'Message 1'

# DESCRIPTION

When working heavily with AWS services you will sometimes have special needs:

- Working on a plane (or in situations with limited connectivity)
- Testing your application
- Generating faults

PawsX::FakeImplementation::Instance will help you create fake implementations for any service you
want. You will be able to emulate any service of your choice, and implement the behaviour you need to
be tested.

PawsX::FakeImplementation::Instance teams up with Paws::Net::MultiplexCaller to route the appropiate
service calls to the appropiate fake implementation. See [Paws::Net::MultiplexCaller](https://metacpan.org/pod/Paws::Net::MultiplexCaller) for more info

# Creating a fake implementation

PawsX::FakeImplementation::Instance defines an interface between the fake implementations and Paws so
that it's easy to write these fake implementations. Here's a guide by example to do it:

## Create your fake implementation class

We start out creating a new class for our fake service:

    package My::Fake::SQS;
      use Moose;

    1;

Be careful with namespacing: take into account that your fake implementation could be partial 
(not a full emulation of the service), or your fake could have specialized behaviour like:

- Only implementing a subset of calls
- Only implementing partial behaviour for some calls (feature incomplete)
- Implements some type of failure mode (fails one of every 10 calls to the service)

So please try to name your fakes accordingly: `My::Fake::BasicSQS`, `My::Fake::SQS::OutOfOrder`, 
`My::FakeSQS::OnlyAdministrativeCalls`, `My::FakeSQS::FailSomeCalls`

If you are going to write a generic fake, trying to closely emulate the AWS service, you can use 
the `PawsX::FakeService::SERVICE_NAME` namespace.

Please have the behaviour of these generic fakes well tested and be willing to accept contributions 
from third parties to these fakes, as people will probably turn to those implementations by default
to test services. Please document any already known differences between the real service and the 
fake service.

## Write a fake method

Just create a sub named like the method you want to fake in your fake service class. It will receive
an object with the parameters that were passed to the service:

    sub CreateQueue {
      my ($self, $params) = @_;
      # $params->QueueName holds what the user passed to 
      #   $sqs->CreateQueue(QueueName => '...');
      return { QueueUrl => 'http://myqueue' };
    }

The $params object in this case is a `Paws::SQS::CreateQueue` object (that represents the parameters
to the CreateQueue call.

## Return values

The return of CreateQueue is a hashref that contains the attributes for inflating a `Paws::SQS::CreateQueueResult`. 
PawsX::FakeImplementation::Instance will convert the hashref to the appropiate return object that the calling 
code is expecting.

    sub CreateQueue {
      return { QueueUrl => 'http://myqueue' };
    }

from the fake implementation will be received in the calling side as always:

    my $return = $sqs->CreateQueue(QueueName => 'x');
    print $return->QueueUrl; # http://myqueue

## Controlled exceptions

If the code inside a fake implementation throws or returns a Paws::Exception, the "user code" will recieve the 
Paws::Exception just like if Paws had generated it.

    sub CreateQueue {
      Paws::Exception->throw(message => 'The name is duplicate', code => 'DuplicateName');
    }

This helps emulate error conditions just like Paws/AWS returns them

## Uncontrolled exceptions

If the code inside a fake implementation dies, PawsX::FakeImplementation::Instance will wrap it inside a generic
Paws::Exception object with code 'InternalError' and the exception as the message. Paws' contract with the 
outside world is to throw Paws::Exception objects in case of problems, so PawsX::FakeImplementation::Instance
tries to not bubble non-Paws-compliant exceptions.

## Instance Storage

PawsX::FakeImplementation::Instance instances your object one time only, and after that routes method calls
to your object. This lets you use an attribute to store data for the lifetime of your object, and use it
as "storage". A queue service, for example could use

    has _queue => (is => 'ro', isa => 'ArrayRef');

as storage for the messages it enqueues. Every call to the fake services methods will see $self->\_queue, and
be able to manipulate it:

    sub ReceiveMessage {
      my ($self, $params) = @_;

      my $message = pop @{ $self->_queue };
      return { Messages => $message };
    } 

## Externally configurable attributes

If you want your fake service to be configurable in some way, you can specify an attribute in your
fake service class.

    package My::Fake::FailingSQS;
      use Moose;

      has failing_call_ratio => (is => 'ro', isa => 'Num', default => 0.5);

      sub CreateQueue {
        my ($self, $params) = @_;
        die "Strange error" if (rand() < $self->failing_call_ratio);
      }

    1;

The user of the fake service can then initialize it in the following way:

     my $paws = Paws->new(
      config => {
        caller => Paws::Net::MultiplexCaller->new(
          caller_for => {
            SQS => PawsX::FakeImplementation::Instance->new(
              api_class => 'My::Fake::FailingSQS',
              params => {
                failing_call_ratio => 1 # all calls fail
              }
            ),
          }
        ),
      }
    );

It's recommended that your attribute either has a default (for easy usage), or declares itself as required
as to guide the consumer of the fake service what parameters need to be passed.

# AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

# SEE ALSO

[Paws](https://metacpan.org/pod/Paws)

[Paws::Net::MultiplexCaller](https://metacpan.org/pod/Paws::Net::MultiplexCaller)

[https://github.com/pplu/aws-sdk-perl](https://github.com/pplu/aws-sdk-perl)

# BUGS and SOURCE

The source code is located here: [https://github.com/pplu/pawsx-fakeimplementation-instance](https://github.com/pplu/pawsx-fakeimplementation-instance)

Please report bugs to: [https://github.com/pplu/pawsx-fakeimplementation-instance/issues](https://github.com/pplu/pawsx-fakeimplementation-instance/issues)

# COPYRIGHT and LICENSE

Copyright (c) 2017 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
