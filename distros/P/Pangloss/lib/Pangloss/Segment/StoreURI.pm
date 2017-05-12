package Pangloss::Segment::StoreURI;

use URI;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('HTTP::Request') ||
                  $self->store->get('Apache::Request') ||
		  return;
    my $uri = $request->uri->clone;
    $self->emit( "saving copy of original uri" );
    # URI blesses into different sub-classes, so:
    return bless \$uri, 'OriginalURI';
}

1;
