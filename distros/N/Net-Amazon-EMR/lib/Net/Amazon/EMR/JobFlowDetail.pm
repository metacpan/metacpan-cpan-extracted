package Net::Amazon::EMR::JobFlowDetail;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;


has 'AmiVersion' => ( is => 'ro', isa => 'Str' );

has 'BootstrapActions' => ( is => 'ro', 
                            isa => 'Net::Amazon::EMR::Type::ArrayRefofBootstrapActionDetail | Undef', 
                            coerce => 1 );
has 'ExecutionStatusDetail' => ( is => 'ro', 
                                 isa => 'Net::Amazon::EMR::Type::JobFlowExecutionStatusDetail', 
                                 coerce => 1 );

has 'Instances' => ( is => 'ro', 
                     isa => 'Net::Amazon::EMR::Type::JobFlowInstancesDetail', 
                     coerce => 1 );

has 'JobFlowId' => ( is => 'ro', isa => 'Str' );

has 'LogUri' => ( is => 'ro', isa => 'Str' );

has 'Name' => ( is => 'ro', isa => 'Str' );

has 'Steps' => ( is => 'ro', 
                     isa => 'Net::Amazon::EMR::Type::ArrayRefofStepDetail | Undef', 
                     coerce => 1 );

has 'SupportedProducts' => ( is => 'ro', 
                             isa => 'Net::Amazon::EMR::Type::ArrayRefofStr | Undef',
                             coerce => 1 );
has 'VisibleToAllUsers' => ( is => 'ro', isa => 'Net::Amazon::EMR::Type::Bool',
                             coerce => 1 );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::JobFlowDetail

=head1 DESCRIPTION

Implements the JobFlowDetail data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_JobFlowDetail.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
