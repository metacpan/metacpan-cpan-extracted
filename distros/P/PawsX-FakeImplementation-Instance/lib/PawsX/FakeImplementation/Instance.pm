package PawsX::FakeImplementation::Instance {
  use Moose;
  use Paws;
  use UUID qw/uuid/;

  our $VERSION = '0.02';

  with 'Paws::Net::CallerRole';

  sub caller_to_response {}

  has api_class => (
    is => 'ro',
    isa => 'Str',
    required => 1,
  );

  has params => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
  );

  has instance => (
    is => 'ro',
    lazy => 1,
    default => sub {
      my $self = shift;
      Paws->load_class($self->api_class);
      return $self->api_class->new(%{ $self->params });
    }
  );

  sub do_call {
    my ($self, $service, $call_obj) = @_;

    my $uuid = uuid;

    my ($method_name) = ($call_obj->meta->name =~ m/^Paws::.*?::(.*)$/);

    my $return = eval { $self->instance->$method_name($call_obj) };
    if ($@) {
      if (ref($@)) {
        if ($@->isa('Paws::Exception')){
          $@->throw;
        } else {
          Paws::Exception->throw(message => "$@", code => 'InternalError', request_id => $uuid); 
        }
      } else {
        Paws::Exception->throw(message => "$@", code => 'InternalError', request_id => $uuid);
      }
    } else {
      if (not defined $call_obj->_returns or $call_obj->_returns eq 'Paws::API::Response') {
        $return = Paws::API::Response->new(request_id => $uuid);
      } else {
        $return = $self->new_with_coercions($call_obj->_returns, %$return);
      }
    }
    return $return;
  }

  sub new_with_coercions {
    my ($self, $class, %params) = @_;

    Paws->load_class($class);
    my %p;

    if ($class->does('Paws::API::StrToObjMapParser')) {
      my ($subtype) = ($class->meta->find_attribute_by_name('Map')->type_constraint =~ m/^HashRef\[(.*?)\]$/);
      if (my ($array_of) = ($subtype =~ m/^ArrayRef\[(.*?)\]$/)){
        $p{ Map } = { map { $_ => [ map { $self->new_with_coercions("$array_of", %$_) } @{ $params{ $_ } } ] } keys %params };
      } else {
        $p{ Map } = { map { $_ => $self->new_with_coercions("$subtype", %{ $params{ $_ } }) } keys %params };
      }
    } elsif ($class->does('Paws::API::StrToNativeMapParser')) {
      $p{ Map } = { %params };
    } else {
      foreach my $att (keys %params){
        my $att_meta = $class->meta->find_attribute_by_name($att);
  
        Moose->throw_error("$class doesn't have an $att") if (not defined $att_meta);
        my $type = $att_meta->type_constraint;
  
        if ($type eq 'Bool') {
          $p{ $att } = ($params{ $att } == 1)?1:0;
        } elsif ($type eq 'Str' or $type eq 'Num' or $type eq 'Int') {
          $p{ $att } = $params{ $att };
        } elsif ($type =~ m/^ArrayRef\[(.*?)\]$/){
          my $subtype = "$1";
          if ($subtype eq 'Str' or $subtype eq 'Str|Undef' or $subtype eq 'Num' or $subtype eq 'Int' or $subtype eq 'Bool') {
            $p{ $att } = $params{ $att };
          } else {
            $p{ $att } = [ map { $self->new_with_coercions("$subtype", %{ $_ }) } @{ $params{ $att } } ];
          }
        } elsif ($type->isa('Moose::Meta::TypeConstraint::Enum')){
          $p{ $att } = $params{ $att };
        } else {
          $p{ $att } = $self->new_with_coercions("$type", %{ $params{ $att } });
        }
      }
    }
    return $class->new(%p);
  }
}
1;
### main pod documentation begin ###

=encoding UTF-8

=head1 NAME

PawsX::FakeImplementation::Instance - A Paws extension to help you write fake AWS services

=head1 SYNOPSIS

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

=head1 DESCRIPTION

When working heavily with AWS services you will sometimes have special needs:

=over

=item Working on a plane (or in situations with limited connectivity)

=item Testing your application

=item Generating faults

=back

PawsX::FakeImplementation::Instance will help you create fake implementations for any service you
want. You will be able to emulate any service of your choice, and implement the behaviour you need to
be tested.

PawsX::FakeImplementation::Instance teams up with Paws::Net::MultiplexCaller to route the appropiate
service calls to the appropiate fake implementation. See L<Paws::Net::MultiplexCaller> for more info

=head1 Creating a fake implementation

PawsX::FakeImplementation::Instance defines an interface between the fake implementations and Paws so
that it's easy to write these fake implementations. Here's a guide by example to do it:

=head2 Create your fake implementation class

We start out creating a new class for our fake service:

  package My::Fake::SQS;
    use Moose;

  1;

Be careful with namespacing: take into account that your fake implementation could be partial 
(not a full emulation of the service), or your fake could have specialized behaviour like:

=over

=item Only implementing a subset of calls

=item Only implementing partial behaviour for some calls (feature incomplete)

=item Implements some type of failure mode (fails one of every 10 calls to the service)

=back

So please try to name your fakes accordingly: C<My::Fake::BasicSQS>, C<My::Fake::SQS::OutOfOrder>, 
C<My::FakeSQS::OnlyAdministrativeCalls>, C<My::FakeSQS::FailSomeCalls>

If you are going to write a generic fake, trying to closely emulate the AWS service, you can use 
the C<PawsX::FakeService::SERVICE_NAME> namespace.

Please have the behaviour of these generic fakes well tested and be willing to accept contributions 
from third parties to these fakes, as people will probably turn to those implementations by default
to test services. Please document any already known differences between the real service and the 
fake service.

=head2 Write a fake method

Just create a sub named like the method you want to fake in your fake service class. It will receive
an object with the parameters that were passed to the service:

  sub CreateQueue {
    my ($self, $params) = @_;
    # $params->QueueName holds what the user passed to 
    #   $sqs->CreateQueue(QueueName => '...');
    return { QueueUrl => 'http://myqueue' };
  }

The $params object in this case is a C<Paws::SQS::CreateQueue> object (that represents the parameters
to the CreateQueue call.

=head2 Return values

The return of CreateQueue is a hashref that contains the attributes for inflating a C<Paws::SQS::CreateQueueResult>. 
PawsX::FakeImplementation::Instance will convert the hashref to the appropiate return object that the calling 
code is expecting.
  
  sub CreateQueue {
    return { QueueUrl => 'http://myqueue' };
  }

from the fake implementation will be received in the calling side as always:

  my $return = $sqs->CreateQueue(QueueName => 'x');
  print $return->QueueUrl; # http://myqueue

=head2 Controlled exceptions

If the code inside a fake implementation throws or returns a Paws::Exception, the "user code" will recieve the 
Paws::Exception just like if Paws had generated it.

  sub CreateQueue {
    Paws::Exception->throw(message => 'The name is duplicate', code => 'DuplicateName');
  }

This helps emulate error conditions just like Paws/AWS returns them

=head2 Uncontrolled exceptions

If the code inside a fake implementation dies, PawsX::FakeImplementation::Instance will wrap it inside a generic
Paws::Exception object with code 'InternalError' and the exception as the message. Paws' contract with the 
outside world is to throw Paws::Exception objects in case of problems, so PawsX::FakeImplementation::Instance
tries to not bubble non-Paws-compliant exceptions.

=head2 Instance Storage

PawsX::FakeImplementation::Instance instances your object one time only, and after that routes method calls
to your object. This lets you use an attribute to store data for the lifetime of your object, and use it
as "storage". A queue service, for example could use

  has _queue => (is => 'ro', isa => 'ArrayRef');

as storage for the messages it enqueues. Every call to the fake services methods will see $self->_queue, and
be able to manipulate it:

  sub ReceiveMessage {
    my ($self, $params) = @_;

    my $message = pop @{ $self->_queue };
    return { Messages => $message };
  } 

=head2 Externally configurable attributes

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

=head1 AUTHOR

    Jose Luis Martinez
    CPAN ID: JLMARTIN
    CAPSiDE
    jlmartinez@capside.com

=head1 SEE ALSO

L<Paws>

L<Paws::Net::MultiplexCaller>

L<https://github.com/pplu/aws-sdk-perl>

=head1 BUGS and SOURCE

The source code is located here: L<https://github.com/pplu/pawsx-fakeimplementation-instance>

Please report bugs to: L<https://github.com/pplu/pawsx-fakeimplementation-instance/issues>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2017 by CAPSiDE

This code is distributed under the Apache 2 License. The full text of the license can be found in the LICENSE file included with this module.
