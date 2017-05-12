package Container2;

use strict;
use warnings;

use lib 't';

use Moo;
use MooX::Attributes::Shadow ':all';

use Contained;


has foo => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
	my $self = shift;
	[ map { Contained->new( xtract_attrs( 'Contained', $self, { instance => $_ } ) ) }
	  0, 1
	] }
    );


sub run_shadow_attrs {

    shadow_attrs( Contained => @_ );
}

1;
