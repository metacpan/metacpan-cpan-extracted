package NewsExtractor::Error;
use Moo;
use NewsExtractor::Types qw<Bool Text HashRef>;

has is_exception => ( required => 1, is => 'ro', isa => Bool, default => 0 );
has message => ( required => 1, is => 'ro', isa => Text );
has debug => ( required => 0, is => 'ro', isa => HashRef );

1;
