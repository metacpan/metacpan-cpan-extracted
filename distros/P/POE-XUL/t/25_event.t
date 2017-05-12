#!/bin/perl -w

use strict;
use warnings;

use Test::More ( tests => 38 );
use POE::XUL::Event;
use POE::XUL::Request;

use HTTP::Response;

#####
my $CM = My::CM->new( honk => "HONK-HONK", 
                      bonk => "BONK-BONK" 
                    );
my $resp = HTTP::Response->new( 500 );
my $req  = HTTP::Request->new( "POST", "/xul" );
$req = bless $req, 'POE::XUL::Request';
$req->param( 'source_id', 'bonk' );
$req->param( 'window', 'honk' );
$req->param( 'value', 'zip' );

##### constructor
my $event = POE::XUL::Event->new( 'Test', $CM, $resp );
ok( $event, "Built an event" );

##### accessors
is( $event->name, 'Test', "Right type" );
$event->event( 'Honking' );
is( $event->name, 'Honking', "Set event type" );
$event->set( SID => 123456 );
is( $event->get( 'SID' ), 123456, "->set / ->get" );
$event->SID( 654321 );
is( $event->SID, 654321, "->field(v) / ->field" );

##### __init
$event->__init( $req );
pass( "__init didn't blow up" );
is( $event->value, 'zip', "->value" );
is( $event->source, 'BONK-BONK', "->source" );
is( $event->source_id, 'bonk', "->source_id" );
is( $event->target, 'BONK-BONK', "->target" );
is( $event->window, 'HONK-HONK', "->window" );
is( $event->window_id, 'honk', "->window_id" );

##### window defaults to the main window
$req->param( window => '' );
$event->__init( $req );
is( $event->window, 'MAIN WINDOW', "->window defaults to main window" );
is( $event->window_id, '', "->window_id also" );

##### __init special cases
$event->source( '' );
$event->source_id( '' );
$event->window( '' );
$event->window_id( '' );
$req->param( window => 'honk' );

foreach my $E ( qw( boot connect ) ) {
    $event->event( $E );
    $event->__init( $req );
    is( $event->source, '', "$E doesn't have a source" );
    is( $event->window, 'honk', "$E doesn't have a window" );
}

$event->event( 'disconnect' );
$event->__init( $req );
is( $event->source, '', "disconnect doesn't have a source" );
is( $event->window, 'HONK-HONK', "disconnect does have a window" );

##### defer + handled
$event->done( 1 );
$event->defer;
ok( !$event->done, "->defer prevented means response isn't done" );
$event->handled;
is( $CM->{__respond_with}, $resp, "event told CM to send a response" );
ok( $event->flushed, "event marked as flushed" );

eval {
    $event->flush;
};
ok( ($@ =~ /already/), "May only flush an event once" );

$event->{flushed} = 0;

##### coderef + run + wrap + side-effects 
$event->event( 'Honking' );
$event->coderef( sub { is( $_[0], $event, "Coderef gets an event" ) } );
$event->run();
ok( !$event->coderef, "->run clears coderef" );
is( $CM->{did}{Honking}, $event, "called side-effects in CM" );

##### coderef w/o side-effects
$event->coderef( sub { is( $_[0], $event, "Coderef gets an event" ) } );
$event->event( 'Click' );
$event->run();
ok( !$CM->{did}{Click}, "Didn't call unknonwn side-effects in CM" );

##### listener coderefs
my $dest = '';
$CM->{N1} = My::Node->new( name=>'N1', dest=>\$dest );
$CM->{N1}->attach( 'Click' );

$req->param( 'source_id' => 'N1' );
$event->__init( $req );
is( $event->target, $CM->{N1}, "New target" );
$event->run;
is( $dest, 'N1.Click', "N1's handler was called" );
$dest = '';

##### listener error handling
$CM->{N2} = My::Node->new( name=>'N2', dest=>\$dest );
$CM->{N2}->attach( Click => sub { die "KABOOM\n" } );

$req->param( 'source_id' => 'N2' );
$event->__init( $req );
is( $event->target, $CM->{N2}, "New target" );
$event->run;
is( $CM->{__error}, "APPLICATION ERROR: KABOOM\n", "And it blew up" );

##### bubble_to
$CM->{N3} = My::Node->new( name=>'N1', dest=>\$dest );

$req->param( 'source_id' => 'N3' );
$event->__init( $req );
is( $event->target, $CM->{N3}, "New target" );
$event->bubble_to( $CM->{N1} );

is( $dest, '', "Nothing happened" );
$event->run;
is( $dest, 'N1.Click', "Bubbled to N1's handler" );

##### We leave the POE related stuff to be tested by the full POE tests

#####
$event->dispose;
is( $event->resp, undef(), "No more response" );
is( $event->CM, undef(), "No more CM" );



############################################################################
package My::Node;

use strict;
use warnings;

sub new
{
    my $package = shift;
    return bless { @_ }, $package;
}

sub attach
{
    my( $self, $name, $subref ) = @_;
    $subref ||= sub { ${ $self->{dest} } = join '.', $self->{name}, $name };
    $self->{events}{$name} = $subref;
}

sub event
{
    my( $self, $name ) = @_;
    return $self->{events}{$name};
}

############################################################################
package My::CM;

use strict;
use warnings;

sub new
{
    my $package = shift;
    return bless { @_ }, $package;
}


sub getElementById
{
    my( $self, $name ) = @_;
    return $self->{$name};
}

sub request_start
{
    my( $self, $event ) = @_;
    $self->{current_event} = $event;
}

sub window
{
    return "MAIN WINDOW";
}

sub response
{
    my( $self, $resp ) = @_;
    $self->{__respond_with} = $resp;
}

sub responded
{
    my( $self ) = @_;
    return exists $self->{__respond_with};
}

sub error_response
{
    my( $self, $resp, $msg ) = @_;
    $self->{__respond_with} = $resp;
    $self->{__error} = $msg;
}

sub _mk_sideeffect
{
    my( $name ) = @_;
    return sub {
        my( $self, $event ) = @_;
        $self->{did}{$name} = $event;
    }
}

BEGIN {
    *handle_Honking = _mk_sideeffect( 'Honking' );
}

