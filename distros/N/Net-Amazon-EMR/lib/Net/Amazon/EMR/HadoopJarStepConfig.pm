package Net::Amazon::EMR::HadoopJarStepConfig;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'Args' => ( is => 'ro', 
                isa => 'Net::Amazon::EMR::Type::ArrayRefofStr | Undef',
                coerce => 1,
 );

has 'Jar' => ( is => 'ro', 
               isa => 'Str' );

has 'MainClass' => ( is => 'ro', 
                     isa => 'Str' );

has 'Properties' => ( is => 'ro', 
                      isa => 'Net::Amazon::EMR::Type::ArrayRefofKeyValue | Undef',
                      coerce => 1,
    );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::HadoopJarStepConfig

=head1 DESCRIPTION

Implements the HadoopJarStepConfig data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_HadoopJarStepConfig.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
