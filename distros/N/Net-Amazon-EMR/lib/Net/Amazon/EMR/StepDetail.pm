package Net::Amazon::EMR::StepDetail;
use Moose;

with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'ExecutionStatusDetail' => ( is => 'ro', 
                                 isa => 'Net::Amazon::EMR::Type::StepExecutionStatusDetail',
                                 coerce => 1 );

has 'StepConfig' => ( is => 'ro', 
                      isa => 'Net::Amazon::EMR::Type::StepConfig',
                      coerce => 1 );


__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::StepDetail

=head1 DESCRIPTION

Implements the StepDetail data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_StepDetail.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
