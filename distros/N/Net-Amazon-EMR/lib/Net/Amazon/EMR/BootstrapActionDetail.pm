package Net::Amazon::EMR::BootstrapActionDetail;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';

use Net::Amazon::EMR::Coercions;

has 'BootstrapActionConfig' => ( is => 'ro',
                                isa => 'Net::Amazon::EMR::Type::BootstrapActionConfig',
                                coerce => 1,
);

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::BootstrapActionDetail

=head1 DESCRIPTION

Implements the BootstrapActionDetail data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_BootstrapActionDetail.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
