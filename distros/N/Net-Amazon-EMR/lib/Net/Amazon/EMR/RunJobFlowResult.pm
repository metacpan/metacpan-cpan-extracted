package Net::Amazon::EMR::RunJobFlowResult;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;


has 'JobFlowId' => ( is => 'ro', isa => 'Str' );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::RunJobFlowResult

=head1 DESCRIPTION

Implements the RunJobFlowResult data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_RunJobFlowResult.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
