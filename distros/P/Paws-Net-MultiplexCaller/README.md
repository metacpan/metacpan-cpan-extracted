# NAME

Paws::Net::MultiplexCaller - Control routing of services to Paws callers

# SYNOPSIS

    use Paws::Net::MultiplexCaller;
    use Paws::Net::LWPCaller;
    use Paws::Net::MockCaller;

    my $paws = Paws->new(
      config => {
        caller => Paws::Net::MultiplexCaller->new(
          caller_for => {
            SQS => Paws::Net::LWPCaller->new(),
            EC2 => Paws::Net::MockCaller->new(...),
          },
          default_caller => Paws::Net::Caller->new
        )
      }
    );

    # SQS methods will be called with LWPCaller
    # $paws->service('SQS', region => 'eu-west-1')->CreateQueue
    # EC2 with the MockCaller
    # $paws->service('EC2', region => 'us-east-1')->RunInstances
    # others will be called with the default Paws::Net::Caller
    # $paws->service('DynamoDB', region => 'us-east-1')->CreateTable 

# DESCRIPTION

By default, Paws routes all calls to service methods (RunInstances for EC2 and CreateQueue for SQS, for example) to the configured caller (that normally will do HTTP requests to the backing services). All calls go to the one and only caller.

Paws::Net::MultiplexCaller is one of Paws' pluggable callers whose only purpose is to let you route requests to different callers. So you can do special things like:

- Use a special caller for just one service
- Emulate services without doing HTTP calls

# ATTRIBUTES

Attributes are initialized in the constructor

## caller\_for

Is a Hashref which keys are the names of the services to route for. It's values are instances of objects that can handle Paws calls (it's pluggable callers). Note that you can pass the same object for different services

    my $caller2 = Paws::Net::LWPCaller->new;
    my $paws = Paws->new(
      config => {
        caller => Paws::Net::MultiplexCaller->new(
          caller_for => {
            SQS => $caller2,
            EC2 => $caller2,
          },
        )
      }
    );

As opposed to

    my $paws = Paws->new(
      config => {
        caller => Paws::Net::MultiplexCaller->new(
          caller_for => {
            SQS => Paws::Net::LWPCaller->new,
            EC2 => Paws::Net::LWPCaller->new,
          },
        )
      }
    );

Where there would be two independant instances of LWPCaller (consuming double memory), or leading
to unexpected results (should the callers track some sort of state, like [Paw::Net::MockCaller](https://metacpan.org/pod/Paw::Net::MockCaller))

## default\_caller

If not specified, any call to a service that is not in `caller_for` will fail to complete, raising
an exception.

If specified, Paws will route any service that is not in `caller_for` to this caller, that should
be initialized to an instance of any of Paws' pluggable callers.

# Practical use

On CPAN you can find [Paws::Kinesis::MemoryCaller](https://metacpan.org/pod/Paws::Kinesis::MemoryCaller), that emulates the AWS Kinesis service. Using
that caller will not let you call other AWS services. With `Paws::Net::MultiplexCaller` we can
solve that:

    my $paws = Paws->new(
      config => {
        caller => Paws::Net::MultiplexCaller->new(
          caller_for => {
            Kinesis => Paws::Kinesis::MemoryCaller->new(),
          },
          default_caller => Paws::Net::Caller->new
        )
      }
    );

You can also combine the multiplex caller with [PawsX::FakeImplementation::Instance](https://metacpan.org/pod/PawsX::FakeImplementation::Instance) to easily
fake some AWS services for your testing purposes.

# AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

# SEE ALSO

[Paws](https://metacpan.org/pod/Paws)

[Paws::Kinesis::MemoryCaller](https://metacpan.org/pod/Paws::Kinesis::MemoryCaller)

[PawsX::FakeImplementation::Instance](https://metacpan.org/pod/PawsX::FakeImplementation::Instance)

# BUGS and SOURCE

The source code is located here: [https://github.com/pplu/paws-net-multiplexcaller](https://github.com/pplu/paws-net-multiplexcaller)

Please report bugs to: [https://github.com/pplu/paws-net-multiplexcaller/issues](https://github.com/pplu/paws-net-multiplexcaller/issues)

# COPYRIGHT and LICENSE

Copyright (c) 2017 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
