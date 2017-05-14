package Net::Amazon::EMR::StepConfig;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'ActionOnFailure' => ( is => 'ro', 
                 isa => 'Str' );

has 'HadoopJarStep' => ( is => 'ro', 
                         isa => 'Net::Amazon::EMR::Type::HadoopJarStepConfig',
                         coerce => 1,
    );

has 'Name' => ( is => 'ro', 
                  isa => 'Str' );


__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::StepConfig

=head1 DESCRIPTION

Implements the StepConfig data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_StepConfig.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
