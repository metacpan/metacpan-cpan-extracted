package Paws::ComputeOptimizer::InstanceRecommendationOption;
  use Moose;
  has InstanceType => (is => 'ro', isa => 'Str', request_name => 'instanceType', traits => ['NameInRequest']);
  has PerformanceRisk => (is => 'ro', isa => 'Num', request_name => 'performanceRisk', traits => ['NameInRequest']);
  has ProjectedUtilizationMetrics => (is => 'ro', isa => 'ArrayRef[Paws::ComputeOptimizer::UtilizationMetric]', request_name => 'projectedUtilizationMetrics', traits => ['NameInRequest']);
  has Rank => (is => 'ro', isa => 'Int', request_name => 'rank', traits => ['NameInRequest']);
1;

### main pod documentation begin ###

=head1 NAME

Paws::ComputeOptimizer::InstanceRecommendationOption

=head1 USAGE

This class represents one of two things:

=head3 Arguments in a call to a service

Use the attributes of this class as arguments to methods. You shouldn't make instances of this class. 
Each attribute should be used as a named argument in the calls that expect this type of object.

As an example, if Att1 is expected to be a Paws::ComputeOptimizer::InstanceRecommendationOption object:

  $service_obj->Method(Att1 => { InstanceType => $value, ..., Rank => $value  });

=head3 Results returned from an API call

Use accessors for each attribute. If Att1 is expected to be an Paws::ComputeOptimizer::InstanceRecommendationOption object:

  $result = $service_obj->Method(...);
  $result->Att1->InstanceType

=head1 DESCRIPTION

Describes a recommendation option for an Amazon EC2 instance.

=head1 ATTRIBUTES


=head2 InstanceType => Str

  The instance type of the instance recommendation.


=head2 PerformanceRisk => Num

  The performance risk of the instance recommendation option.

Performance risk is the likelihood of the recommended instance type not
meeting the performance requirement of your workload.

The lowest performance risk is categorized as C<0>, and the highest as
C<5>.


=head2 ProjectedUtilizationMetrics => ArrayRef[L<Paws::ComputeOptimizer::UtilizationMetric>]

  An array of objects that describe the projected utilization metrics of
the instance recommendation option.


=head2 Rank => Int

  The rank of the instance recommendation option.

The top recommendation option is ranked as C<1>.



=head1 SEE ALSO

This class forms part of L<Paws>, describing an object used in L<Paws::ComputeOptimizer>

=head1 BUGS and CONTRIBUTIONS

The source code is located here: L<https://github.com/pplu/aws-sdk-perl>

Please report bugs to: L<https://github.com/pplu/aws-sdk-perl/issues>

=cut

