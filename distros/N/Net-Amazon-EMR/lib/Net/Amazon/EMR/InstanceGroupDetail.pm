package Net::Amazon::EMR::InstanceGroupDetail;
use Moose;
with 'Net::Amazon::EMR::Role::AttrHash';
use Net::Amazon::EMR::Coercions;

has 'BidPrice' => ( is => 'ro', 
                    isa => 'Str' );

has 'CreationDateTime' => ( is => 'ro', 
                            isa => 'Net::Amazon::EMR::Type::DateTime',
                            coerce => 1,
    );

has 'EndDateTime' => ( is => 'ro', 
                       isa => 'Net::Amazon::EMR::Type::DateTime',
                       coerce => 1,
    );

has 'InstanceGroupId' => ( is => 'ro', 
                           isa => 'Str' );

has 'InstanceRequestCount' => ( is => 'ro', 
                                isa => 'Int' );

has 'InstanceRole' => ( is => 'ro', 
                        isa => 'Str' );

has 'InstanceRunningCount' => ( is => 'ro', 
                                isa => 'Int' );

has 'InstanceType' => ( is => 'ro', 
                        isa => 'Str' );

has 'LastStateChangeReason' => ( is => 'ro', 
                                 isa => 'Str | Undef' );

has 'Market' => ( is => 'ro', 
                  isa => 'Str' );

has 'Name' => ( is => 'ro', 
                isa => 'Str' );


has 'ReadyDateTime' => ( is => 'ro', 
                         isa => 'Net::Amazon::EMR::Type::DateTime',
                         coerce => 1,
    );

has 'StartDateTime' => ( is => 'ro', 
                         isa => 'Net::Amazon::EMR::Type::DateTime',
                         coerce => 1,
    );

has 'State' => ( is => 'ro', 
                 isa => 'Str' );


__PACKAGE__->meta->make_immutable();

1;

__END__

=head1 NAME

Net::Amazon::EMR::InstanceGroupDetail

=head1 DESCRIPTION

Implements the InstanceGroupDetail data type described at L<http://docs.amazonwebservices.com/ElasticMapReduce/latest/APIReference/API_InstanceGroupDetail.html>.

=head1 AUTHOR

Jon Schutz 

L<http://notes.jschutz.net>

=head1 DOCUMENTATION, LICENSE AND COPYRIGHT

See L<Net::Amazon::EMR>.

=cut
