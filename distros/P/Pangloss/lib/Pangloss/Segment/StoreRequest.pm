package Pangloss::Segment::StoreRequest;

use URI;

use base qw( Pipeline::Segment );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.1 $ '))[2];

sub dispatch {
    my $self    = shift;
    my $request = $self->store->get('OpenFrame::Request') || return;
    my $clone   = $self->clone_request( $request );
    $self->emit( "saving copy of original request" );
    # bless a ref to it into different class to
    # avoid it getting overwritten in the store:
    return bless \$clone, 'OriginalRequest';
}

sub clone_request {
    my $self    = shift;
    my $request = shift;
    my $clone   = ref( $request )->new;
    $clone->uri( $request->uri->clone ) if $request->uri;
    $clone->arguments( { %{ $request->arguments } } ) if $request->arguments;
    # forget cookies for now
    return $clone;
}

1;
