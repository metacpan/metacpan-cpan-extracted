package Net::Amazon::EMR::ScriptBootstrapActionConfig;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';

has 'Args' => ( is => 'ro', 
                isa => 'Net::Amazon::EMR::Type::ArrayRefofStr | Undef',
                coerce => 1);

has 'Path' => ( is => 'ro', 
                isa => 'Str' );


__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::ScriptBootstrapActionConfig

=head1 DESCRIPTION

Implements the ScriptBootstrapActionConfig data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_ScriptBootstrapActionConfig.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
