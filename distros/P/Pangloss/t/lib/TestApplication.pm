package TestApplication;

use strict;
use warnings;

use Pixie;

use TestStore;
use TestFramework;
use CreateCollections;

use base qw( Pangloss::Application );

sub init {
    my $self = shift;
    my %args = @_;

    $self->SUPER::init( @_ ) || return;

    # is a store already set up?
    if ( TestStore->STORE ) {
	$self->store( TestStore->STORE );
	return $self;
    }

    $self->store( Pixie->new->connect('memory') )
         ->init_store_from_framework;
}

sub init_store_from_framework {
    my $self = shift;

    $self->emit( "initializing store from test framework" );

    my $framework = TestFramework->load;

    foreach my $name (qw( languages categories users concepts terms )) {
	my $collection = $framework->$name;
	$self->store->insert( $collection );
	$self->store->bind_name( $name, $collection );
    }

    return $self;
}


1;
