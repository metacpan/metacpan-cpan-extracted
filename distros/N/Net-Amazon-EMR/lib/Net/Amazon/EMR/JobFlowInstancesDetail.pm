package Net::Amazon::EMR::JobFlowInstancesDetail;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'Ec2KeyName' => ( is => 'ro', 
                      isa => 'Str' );

has 'Ec2SubnetId' => ( is => 'ro', 
                       isa => 'Str' );

has 'HadoopVersion' => ( is => 'ro', 
                         isa => 'Str' );

has 'InstanceCount' => ( is => 'ro', 
                         isa => 'Int' );

has 'InstanceGroups' => ( is => 'ro', 
                          isa => 'Net::Amazon::EMR::Type::ArrayRefofInstanceGroupDetail',
                          coerce => 1 );

has 'KeepJobFlowAliveWhenNoSteps' => ( is => 'ro', 
                                       isa => 'Net::Amazon::EMR::Type::Bool',
                                       coerce => 1 );

has 'MasterInstanceId' => ( is => 'ro', 
                            isa => 'Str' );

has 'MasterInstanceType' => ( is => 'ro', 
                              isa => 'Str' );

has 'MasterPublicDnsName' => ( is => 'ro', 
                               isa => 'Str' );

has 'NormalizedInstanceHours' => ( is => 'ro', 
                                   isa => 'Int' );

has 'Placement' => ( is => 'ro', 
                     isa => 'Net::Amazon::EMR::Type::PlacementType | Undef',
                     coerce => 1  );

has 'SlaveInstanceType' => ( is => 'ro', 
                             isa => 'Str' );


has 'TerminationProtected' => ( is => 'ro', 
                                isa => 'Net::Amazon::EMR::Type::Bool',
                                coerce => 1 );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::JobFlowInstancesDetail

=head1 DESCRIPTION

Implements the JobFlowInstancesDetail data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_JobFlowInstancesDetail.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
