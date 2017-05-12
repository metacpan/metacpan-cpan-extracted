package Pangloss::WebApp;

use strict;
use warnings::register;

use Error qw( :try );
use Pixie;
use Storable qw( freeze thaw );
use Pangloss;
use Pipeline;
use Pipeline::Config;
use OpenFrame;
use OpenFrame::WebApp;
use Petal; # TODO: don't load Petal if we're not using Petal templates
use Petal::Utils qw( :default :debug );
use File::Spec::Functions qw( catdir catfile );

use base      qw( Pangloss::Object );
use accessors qw( config app controller frozen_controller ufactory tfactory sfactory );

our $VERSION  = ((require Pangloss::Version), $Pangloss::VERSION)[1];
our $REVISION = (split(/ /, ' $Revision: 1.7 $ '))[2];

#------------------------------------------------------------------------------
# Object initialization

sub init {
    my $self = shift;
    my $hash = shift || \%ENV;
    $self->init_config( $hash )
         ->init_debug
	 ->init_controller
	 ->init_application;
}

sub init_config {
    my $self = shift;
    my $hash = shift;
    $self->emit( "($$) initializing Pangloss config\n" );
    $self->config( Pangloss::Config->new( $hash ) );
}

sub init_controller {
    my $self = shift;

    $self->emit( "($$) initializing Pangloss controller\n" );

    $Petal::ERROR_ON_UNDEF_VAR = 0
      if $self->config->{PG_TEMPLATE_TYPE} =~ /petal/;

    my $controller;
    try {
	$controller = Pipeline::Config->new
			->debug( $self->config->{PG_DEBUG} > 2 )
			->load( $self->config->{PG_CONFIG_FILE} );
    } catch Error with {
	my $e = shift;
	die( "error loading pipeline config from "
	     . $self->config->{PG_CONFIG_FILE} . ": $e" );
    };

    $controller->debug_all( $self->config->{PG_DEBUG} - 1 )
      if $self->config->{PG_DEBUG} > 1;

    $self->frozen_controller( freeze( $controller ) );

    return $self;
}

sub init_application {
    my $self = shift;

    $self->emit( "($$) initializing Pangloss Application\n" );

    $self->app( Pangloss::Application->new )
         ->init_ufactory
	 ->init_tfactory
	 ->init_sfactory
	 ->init_pixie;

    return $self;
}

sub init_ufactory {
    shift->ufactory( OpenFrame::WebApp::User::Factory->new
		     ->type( 'pangloss' ) );
}

sub init_tfactory {
    my $self = shift;
    $self->tfactory( OpenFrame::WebApp::Template::Factory->new
		     ->type( $self->config->{PG_TEMPLATE_TYPE} )
		     ->directory( $self->config->{PG_TEMPLATE_DIR} ) );
}

sub init_sfactory {
    my $self = shift;
    $self->sfactory( OpenFrame::WebApp::Session::Factory->new
		     ->type( $self->config->{PG_SESSION_TYPE} )
		     ->expiry( $self->config->{PG_SESSION_EXPIRY} ) );
}

sub init_pixie {
    my $self = shift;

    $self->emit( "($$) initializing Pixie store\n" );

    my $pixie = eval {
	Pixie->new
	  ->connect( $self->config->{PG_PIXIE_DSN},
		     $self->config->{PG_PIXIE_USER} ? (user => $self->config->{PG_PIXIE_USER}) : (),
		     $self->config->{PG_PIXIE_PASS} ? (pass => $self->config->{PG_PIXIE_PASS}) : () );
    };

    die( "could not connect to pixie store "
	 . $self->config->{PG_PIXIE_DSN} . ": $@" )
      if ($@ or not defined $pixie);

    $self->app->store( $pixie );

    return $self;
}

sub init_debug {
    my $self = shift;
    if (my $debug = $self->config->{PG_DEBUG}) {
	$Pangloss::DEBUG{$self->class} = $debug;
	$Pangloss::DEBUG{ALL}  = ($debug - 2 > 0) ? 1 : 0;
	$OpenFrame::DEBUG{ALL} = ($debug - 1 > 0) ? 1 : 0;
	$self->emit( "($$) debug level set to: $debug\n" );
    }
    return $self;
}

#------------------------------------------------------------------------------
# request handler

sub handle_request ($$) {
    my $self    = shift;
    my $request = shift;

    $self->emit( "\n($$) serving request for " . $request->uri . "\n" );

    # return the pipeline production
    return $self->create_controller( $request )->dispatch();
}

sub create_controller {
    my $self    = shift;
    my $request = shift;

    $self->controller( thaw( $self->frozen_controller ) )
         ->controller->store( $self->create_store->set( $request ) );

    # TODO: patch Pipeline::Config so we can specify this in the controller cfg:
    $self->controller->cleanups->segments( $self->create_cleanups );

    return $self->controller;
}

sub create_store {
    my $self = shift;
    Pipeline::Store::Simple->new
      ->set( $self->app )
      ->set( $self->ufactory )
      ->set( $self->tfactory )
      ->set( $self->sfactory );
};

sub create_cleanups {
    my $self = shift;
    return [];
}


1;
