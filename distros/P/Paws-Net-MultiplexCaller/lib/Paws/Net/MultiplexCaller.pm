package Paws::Net::MultiplexCaller;
  use Moose;
  with 'Paws::Net::CallerRole';

  our $VERSION = '0.03';

  # TODO: HashRef of things that do Paws::Net::CallerRole
  has caller_for => (is => 'ro', isa => 'HashRef', required => 1);
  # TODO: thing that does Paws::Net::CallerRole or Undef
  has default_caller => (is => 'ro', isa => 'Object');

  sub get_implementation {
    my ($self, $service) = @_;
    return $self->caller_for->{ $service } if (defined $self->caller_for->{ $service });
    return $self->default_caller if (defined $self->default_caller);
    die "Can't find a caller for $service";
  }

  sub do_call {
    my ($self, $service, $call_object) = @_;
    return $self->get_implementation($self->service_from_callobject($call_object))
             ->do_call($service, $call_object);
  }

  sub caller_to_response {
    #my ($self, $service, $call_object, $status, $content, $headers) = @_;
    die "Die caller_to_response is not needed on the Multiplex caller";
  }

  sub service_from_callobject {
    my ($self, $call_object) = @_;
    my ($svc_name) = ($call_object->meta->name =~ m/^Paws::(\w+)::/);
    die "$call_object doesn't seem to be a Paws::SERVICE::CALL" if (not defined $svc_name);
    return $svc_name;
  }

1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

Paws::Net::MultiplexCaller - Control routing of services to Paws callers

=head1 SYNOPSIS

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

=head1 DESCRIPTION

By default, Paws routes all calls to service methods (RunInstances for EC2 and CreateQueue for SQS, for example) to the configured caller (that normally will do HTTP requests to the backing services). All calls go to the one and only caller.

Paws::Net::MultiplexCaller is one of Paws' pluggable callers whose only purpose is to let you route requests to different callers. So you can do special things like:

=over

=item Use a special caller for just one service

=item Emulate services without doing HTTP calls

=back

=head1 ATTRIBUTES

Attributes are initialized in the constructor

=head2 caller_for

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
to unexpected results (should the callers track some sort of state, like L<Paw::Net::MockCaller>)

=head2 default_caller

If not specified, any call to a service that is not in C<caller_for> will fail to complete, raising
an exception.

If specified, Paws will route any service that is not in C<caller_for> to this caller, that should
be initialized to an instance of any of Paws' pluggable callers.

=head1 Practical use

On CPAN you can find L<Paws::Kinesis::MemoryCaller>, that emulates the AWS Kinesis service. Using
that caller will not let you call other AWS services. With C<Paws::Net::MultiplexCaller> we can
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

You can also combine the multiplex caller with L<PawsX::FakeImplementation::Instance> to easily
fake some AWS services for your testing purposes.

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

=head1 SEE ALSO

L<Paws>

L<Paws::Kinesis::MemoryCaller>

L<PawsX::FakeImplementation::Instance>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/paws-net-multiplexcaller>

Please report bugs to: L<https://github.com/pplu/paws-net-multiplexcaller/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2017 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.

=cut
