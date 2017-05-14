package Net::Amazon::EMR::PlacementType;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';


has 'AvailabilityZone' => ( is => 'ro', 
                            isa => 'Str' );


__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::PlacementType

=head1 DESCRIPTION

Implements the PlacementType data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_PlacementType.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
