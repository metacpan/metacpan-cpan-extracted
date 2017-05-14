package Net::Amazon::EMR::BootstrapActionConfig;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'Name' => ( is => 'ro', 
                isa => 'Str' );

has 'ScriptBootstrapAction' => ( is => 'ro',
                                      isa => 'Net::Amazon::EMR::Type::ScriptBootstrapActionConfig',
                                      coerce => 1,
);

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::BootstrapActionConfig

=head1 DESCRIPTION

Implements the BootstrapActionConfig data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_BootstrapActionConfig.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
