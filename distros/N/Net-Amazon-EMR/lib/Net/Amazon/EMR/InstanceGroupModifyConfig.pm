package Net::Amazon::EMR::InstanceGroupModifyConfig;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'InstanceCount' => ( is => 'ro', 
                         isa => 'Int' );

has 'InstanceGroupId' => ( is => 'ro', 
                           isa => 'Str' );


__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::InstanceGroupModifyConfig

=head1 DESCRIPTION

Implements the InstanceGroupModifyConfig data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_InstanceGroupModifyConfig.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
