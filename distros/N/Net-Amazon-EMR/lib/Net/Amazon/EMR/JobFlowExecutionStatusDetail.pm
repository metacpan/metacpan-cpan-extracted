package Net::Amazon::EMR::JobFlowExecutionStatusDetail;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'CreationDateTime' => ( is => 'ro', 
                            isa => 'Net::Amazon::EMR::Type::DateTime',
                            coerce => 1,
    );

has 'EndDateTime' => ( is => 'ro', 
                       isa => 'Net::Amazon::EMR::Type::DateTime',
                       coerce => 1,
    );

has 'LastStateChangeReason' => ( is => 'ro', 
                                 isa => 'Str' );

has 'ReadyDateTime' => ( is => 'ro', 
                         isa => 'Net::Amazon::EMR::Type::DateTime',
                         coerce => 1,
    );

has 'StartDateTime' => ( is => 'ro', 
                         isa => 'Net::Amazon::EMR::Type::DateTime',
                         coerce => 1,
    );

has 'State' => ( is => 'ro', 
                 isa => 'Str' );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::JobFlowExecutionStatusDetail

=head1 DESCRIPTION

Implements the JobFlowExecutionStatusDetail data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_JobFlowExecutionStatusDetail.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
