package NewsExtractor::SiteSpecificExtractor;
use Moo;
use Types::Standard qw(InstanceOf);
has tx => ( required => 1, is => 'ro', isa => InstanceOf['Mojo::Transaction::HTTP'] );
1;
