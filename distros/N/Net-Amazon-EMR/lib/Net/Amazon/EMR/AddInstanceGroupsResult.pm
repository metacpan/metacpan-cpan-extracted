package Net::Amazon::EMR::AddInstanceGroupsResult;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;


has 'InstanceGroupIds' => ( is => 'ro', isa => 'Net::Amazon::EMR::Type::ArrayRefofStr', coerce => 1 );

has 'JobFlowId' => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::AddInstanceGroupsResult

=head1 DESCRIPTION

Implements the AddInstanceGroupsResult data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_AddInstanceGroupsResult.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
