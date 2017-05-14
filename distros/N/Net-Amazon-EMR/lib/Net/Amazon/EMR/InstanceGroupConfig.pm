package Net::Amazon::EMR::InstanceGroupConfig;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'BidPrice' => ( is => 'ro', 
                    isa => 'Str' );

has 'InstanceCount' => ( is => 'ro', 
                         isa => 'Int' );

has 'InstanceRole' => ( is => 'ro', 
                        isa => 'Str' );

has 'InstanceType' => ( is => 'ro', 
                        isa => 'Str' );

has 'Market' => ( is => 'ro', 
                  isa => 'Str' );

has 'Name' => ( is => 'ro', 
                isa => 'Str' );

__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::InstanceGroupConfig

=head1 DESCRIPTION

Implements the InstanceGroupConfig data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_InstanceGroupConfig.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
