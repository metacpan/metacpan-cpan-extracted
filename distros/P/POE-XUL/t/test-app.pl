#!/usr/bin/perl -w

use strict;

sub POE::Kernel::CATCH_EXCEPTIONS () { 0 }

use POE;
use POE::Component::XUL;

# warn "$$: ", join "\n", map { "$_: $ENV{$_}" } sort keys %ENV;

my $port = shift;
my $root = shift;
POE::Component::XUL->spawn( {
        port => $port,
        root => $root,
        timeout=> 5*60,
        apps => {
            Test => 'My::App',
            Complete => 'My::Complete'
        }
    } );

warn "# http://localhost:$port\n" unless $ENV{AUTOMATED_TESTING};
$poe_kernel->run();

warn "# exit" unless $ENV{AUTOMATED_TESTING};

###############################################################
package My::App;

use strict;
use POE;

use POE::XUL::Node;

use constant DEBUG => 0;

###############################################################
sub spawn
{
    my( $package, $event ) = @_;
    my $SID = $event->SID;

    DEBUG and warn "# spawn";

    my $self = bless { SID=>$event->SID }, $package;
    POE::Session->create(
            object_states => [
                $self => [ qw( _start boot Click1 Click2 Click2_later ) ]
            ]
        );
}

###############################################################
sub _start
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_set( $self->{SID} );
}

###############################################################
sub boot
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];
    DEBUG and warn "# boot";
    $event->wrap( sub {
            Boot( "Booting $0" );
            DEBUG and warn "# boot CM=$POE::XUL::Node::CM";
            $self->{D} = Description( "do the following" );
            $self->{B1} = Button( label => "click me", 
                                 Click => 'Click1' );
            $self->{W} = Window( HBox( $self->{D}, $self->{B1} ) );

            $event->finish;
        } );
}

###############################################################
sub Click1
{
    my( $self, $kernel, $session, $event ) = 
                @_[ OBJECT, KERNEL, SESSION, ARG0 ];

    DEBUG and warn "# Click1";

    DEBUG and warn "# Click1 CM=$POE::XUL::Node::CM";
    $self->{D}->textNode( 'You did it!' );

    $self->{B2} = Button( label=>'click me too', 
                            Click => $session->callback( 'Click2' )
                        );
    $self->{W}->firstChild->appendChild( $self->{B2} );   
}


###############################################################
sub Click2
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG1 ];

    $event = $event->[0];
    DEBUG and warn "# Click2 event=$event";
    $event->done( 0 );
    $kernel->post( $event->SID(), 'Click2_later', $event );
}

sub Click2_later
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Click2_later";
    $event->wrap( sub {
            DEBUG and warn "# Click2 CM=$POE::XUL::Node::CM";
            $self->{D}->textNode( 'Thank you' );

            $event->done( 1 );
            $event->finish;
        } );
}






#############################################################################
package My::Complete;

use strict;
use POE;

use POE::XUL::Node;
use POE::XUL::Constants;
use POE::XUL::Logging;

use constant DEBUG => 0;

###############################################################
sub spawn
{
    my( $package, $event ) = @_;
    my $SID = $event->SID;

    DEBUG and warn "# spawn";

    my $self = bless { SID=>$event->SID }, $package;
    POE::Session->create(
            object_states => [
                $self => [ qw( _start boot Clear
                                Click1 Click2 Change1 Click3 Alert
                                MenuSelect Radio1 Round ListSelect
                                Framify expandGB2
                             ) 
                         ]
            ]
        );
}

###############################################################
sub _start
{
    my( $self, $kernel ) = @_[ OBJECT, KERNEL ];
    $kernel->alias_set( $self->{SID} );
}

###############################################################
sub boot
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];
    DEBUG and warn "# boot";
    $event->wrap( sub {

            $self->build_window( $event->SID );
            $event->finish;
        } );
}

###############################################################
sub Clear
{
    my( $self, $kernel, $session, $event ) = 
                @_[ OBJECT, KERNEL, SESSION, ARG0 ];

    DEBUG and 
        xwarn "# Clear";
    
    $self->recolour( 'white' );

    $self->clear_message;
}

###############################################################
sub Click1
{
    my( $self, $kernel, $session, $event ) = 
                @_[ OBJECT, KERNEL, SESSION, ARG0 ];

    DEBUG and warn "# Click1";
    $self->message( 'Clicked button #1' );
}


###############################################################
sub Click2
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Click2 event=$event";
    $self->message( 'Clicked button #2' );
    $self->{N}++;
    $self->{button2}->setAttribute( label => "Click #" . $self->{N} );
}

###############################################################
sub Change1
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Change1 event=$event";
    $self->message( 'Changed the first textbox' );

    my $text = $self->{textbox1}->getAttribute( 'value' );
    DEBUG and warn "# tb1 = $text";
    $self->{textbox2}->setAttribute( value => $text );
    $self->{textbox1}->setAttribute( value => '' );
    $self->{button3}->setAttribute( 'disabled' => 0 ); 
}

###############################################################
sub Click3
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Click3 event=$event";
    $self->message( $self->{textbox2}->getAttribute( 'value' )  );
    $self->{textbox2}->setAttribute( value => '' );
    $self->{button3}->setAttribute( 'disabled' => 1 ); 
}

###############################################################
sub Alert
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Alert event=$event";
    $self->{W}->appendChild( Script( 'alert( "ACTIVATE!" )' ) );
}


###############################################################
sub Radio1
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Radio1";

    foreach my $R ( $event->source->children ) {
        next unless $R->selected;

        $self->recolour( lc $R->label );
        $self->message( $R->label );
        return;
    }
    die "Why can't I find a selected radio button?";
}


###############################################################
sub Round
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# Round";
    $self->message( "Hey!  That's not even a colour!" );
}


###############################################################
sub MenuSelect
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# MenuSelect event=$event";

    my $menulist = $event->source;

    my $index = $menulist->selectedIndex;
    DEBUG and warn "# Selected index=$index";

    my $popup = $menulist->firstChild;
    my $item  = $popup->get_item( $index );

    $self->message( "You chose ".$item->label );
}


###############################################################
sub ListSelect
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# ListSelect event=$event";

    my $list = $event->source;

    my $index = $list->selectedIndex;
    DEBUG and warn "# Selected index=$index";

    my $item  = $list->get_item( $index );
    my @msg;
    foreach my $L ( $item->children ) {
        push @msg, $L->label;
    }
#    use Data::Dumper;
#    die Dumper $item unless @msg;

    $self->message( "You chose ".join '-', @msg );
}


###############################################################
sub Framify
{
    my( $self, $kernel, $event ) = @_[ OBJECT, KERNEL, ARG0 ];

    my $gb2 = $event->CM->getElementById( 'GB2' );

    $gb2->framify();

    $kernel->yield( 'expandGB2', $gb2 );
}

sub expandGB2
{
    my( $self, $kernel, $gb2 ) = @_[ OBJECT, KERNEL, ARG0 ];

    DEBUG and warn "# CM=", $POE::XUL::Node::CM;

    for my $n ( 0..40 ) {
        $gb2->appendChild( Description( "Line #$n" ) );
    }
}


###############################################################
sub message
{
    my( $self, $text ) = @_;
    $self->{message}->appendChild( "$text\n" );
}

###############################################################
sub clear_message
{
    my( $self, $text ) = @_;
    $self->{message}->remove_child( 1 ) while 1 < 
                                    $self->{message}->child_count;

    $self->{message}->children->[0]->nodeValue( "hello world" );
}

###############################################################
sub recolour
{
    my( $self, $colour ) = @_;

    my $css = $self->{message}->style;
    $css =~ s/(background-color: )\w+/$1$colour/;
    $self->{message}->style( $css );
}




###############################################################
sub build_window
{
    my( $self, $SID ) = @_;

    $self->{N} = 0;

    $self->{SID}     = Description( id=>"XUL-SID", textNode=>$SID );
    $self->{message} = Description(     
                            style=><<CSS,
width: 256px; 
height: 600px; 
background-color: white;
padding-left: 0.5em;
padding-right: 0.5em;
border: 2px inset ThreeDFace;
white-space: pre;
CSS
                            id=>"USER-Message" 
                        );

    my @groups;

    push @groups, $self->GB1();
    push @groups, $self->GB2();

    $self->{W} = 
        Window( 
            HBox( 
                HBox( id=>'XUL-Groups', @groups ),
                VBox( style=>"min-width: 256px;", 
                      $self->{message},
                      Spacer( FLEX ),
                      Button( label=>'Clear', 
                              Click=>'Clear', 
                              id=>'message-clear' 
                            )
                    ),
            ),
            HBox(
                Description( id=>"XUL-Status", FLEX, textNode=>"Done." ),
                Spacer( FLEX ),
                $self->{SID}
            )
        );
                
    return;
}

###############################################################
sub GB1
{
    my( $self ) = @_;
    my @G1;
    $self->{button1} = Button( label => "Button the first",
                               Click => 'Click1',
                               id    => 'B1'
                             );

    $self->{button2} = Button( label => "Button the second",
                               Click => 'Click2',
                               id    => 'B2'
                             );
    push @G1, HBox( $self->{button1}, $self->{button2} );

    $self->{textbox1} = TextBox( Change=>'Change1', id=>'TB1' );
    $self->{textbox2} = TextBox( id=>'TB2' );

    push @G1, HBox ( $self->{textbox1}, $self->{textbox2} );

    $self->{button3} = Button( label => "Click to send the text to messages", 
                               id    => 'B3',
                               disabled => 1,
                               Click => 'Click3' 
                             );
    push @G1, $self->{button3};

    push @G1, Button( "Power of the sun", Click=>'Alert', 
                                          id=>'alert-button' );

    return GroupBox( id=>'GB1', Caption( "Groupbox 1" ), @G1 );
}

###############################################################
sub GB2
{
    my( $self ) = @_;
    my @G;

    $self->{select1} = 
            MenuList(
                MenuPopup(
                    MenuItem( "Lions" ), 
                    MenuItem( "Tigers" ), 
                    MenuItem( "Bears" ), 
                ),
                Select => 'MenuSelect',
                id => 'ML1',
            );
    push @G, $self->{select1};

    $self->{radiogroup} = RadioGroup( 
                            id => 'RG1', 
                            Radio( label=>'Orange', selected=>1 ),
                            Radio( 'Violet' ),
                            Radio( 'Yellow', ),
                            Radio( label=>'Round', Click => 'Round' ),
                            Click => 'Radio1'
                        );
    push @G, $self->{radiogroup};

    $self->{select2} =
            ListBox(  rows => 5,
                      ListCols(
                          ListCol(FLEX),
                          Splitter( style=>"width: 0px; border: none; background-color: grey; min-width: 1px;"),
                          ListCol(FLEX),
                          Splitter( style=>"width: 0px; border: none; background-color: grey; min-width: 1px;" ),
                          ListCol(FLEX),
                      ),
                      ListHead(
                              ListHeader(label => 'Name'),
                              ListHeader(label => 'Sex'),
                              ListHeader(label => 'Color'),
                      ),
                      ListItem(
                              ListCell( label => 'Pearl'),
                              ListCell( label => 'Female'),
                              ListCell( label => 'Gray'),
                      ),
                      ListItem(
                              ListCell( label => 'Aramis'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Black'),
                      ),
                      ListItem(
                              ListCell( label => 'Yakima'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Holstein'),
                      ),
                      ListItem(
                              ListCell( label => 'Cosmo'),
                              ListCell( label => 'Female'),
                              ListCell( label => 'White'),
                      ),
                      ListItem(
                              ListCell( label => 'Fergus'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Black'),
                      ),
                      ListItem(
                              ListCell( label => 'Clint'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Black'),
                      ),
                      ListItem(
                              ListCell( label => 'Tribble'),
                              ListCell( label => 'Female'),
                              ListCell( label => 'Orange'),
                      ),
                      ListItem(
                              ListCell( label => 'Zippy'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Orange'),
                      ),
                      ListItem(
                              ListCell( label => 'Feathers'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Tabby'),
                      ),
                      ListItem(
                              ListCell( label => 'Butter'),
                              ListCell( label => 'Male'),
                              ListCell( label => 'Orange'),
                      ),
                      id => 'SB1',
                      Select => 'ListSelect'  
                    );
    push @G, $self->{select2};

    push @G, Button( id=>'Framify', accesskey=>'F', 
                    Click=>'Framify', label=>'Framify' );

    return GroupBox( id=>'GB2', Caption( "Groupbox 2" ), @G );
}
