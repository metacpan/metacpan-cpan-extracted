#!/usr/bin/perl -w
# slightly less minimal wxPOE sample
# Ed Heil, 5/5/05

use Wx;
use strict;
my $app = MyApp->new();
POE::Kernel->loop_run();
POE::Kernel->run();

package MyFrame;
use base 'Wx::Frame';
use POE;
use POE::Session;
use POE::Kernel;
use Wx(
    qw [wxDefaultPosition wxDefaultSize wxVERTICAL wxFIXED_MINSIZE
      wxEXPAND wxALL wxTE_MULTILINE ]
);

use Wx::Event qw(EVT_BUTTON EVT_CLOSE);
use vars qw($alias_id);

sub new {
    my $class = shift;
    my $self  =
      $class->SUPER::new( undef, -1, 'wxPOE demo', wxDefaultPosition,
        wxDefaultSize, );
    $self->{panel} =
      Wx::Panel->new( $self, -1, wxDefaultPosition, wxDefaultSize, );
    $self->{text} =
      Wx::TextCtrl->new( $self->{panel}, -1, '', wxDefaultPosition,
        wxDefaultSize, wxTE_MULTILINE );
    $self->{button} =
      Wx::Button->new( $self->{panel}, -1, 'Press me', wxDefaultPosition,
        wxDefaultSize, );
    my $sizer1 = Wx::BoxSizer->new(wxVERTICAL);
    $sizer1->Add( $self->{panel}, 1, wxEXPAND, 0 );
    $self->SetSizer($sizer1);
    $sizer1->SetSizeHints($self);
    my $sizer2 = Wx::BoxSizer->new(wxVERTICAL);
    $sizer2->Add( $self->{text}, 1, wxEXPAND | wxALL, 10 );
    $sizer2->Add( $self->{button}, 0, wxALL, 10 );
    $self->{panel}->SetSizer($sizer2);
    $sizer2->SetSizeHints( $self->{panel} );
    $self->SetSize( [ 300, 200 ] );
    EVT_BUTTON( $self, $self->{button}, sub { $self->ButtonEvent } );
    EVT_CLOSE( $self, \&OnClose );

    # as part of its initialization, every frame will get its own session.

    # we'll use object_states for our states, so that our session can have
    # easy access to its object via $_[OBJECT].

    # on the downside, we're now responsible for cleaning up after
    # ourselves.  If we close a window and the session is still
    # running trying to send it events, that spells trouble.

    # the object has to be able to send itself POE events, to clean up
    # after itself, and that means knowing the alias for its session.
    # (That means the session had better HAVE an alias.)

    # we need a unique alias for our session.  We'll generate them via
    # a package variable, $alias_id.

    POE::Session->create( object_states =>
          [ $self => [ '_start', 'PoeEvent', 'clear_PoeEvent', ] ] );
    return $self;
}

sub _start {
    my ($self) = $_[OBJECT];
    ++$alias_id;    # package variable
    my $alias = sprintf( "FRAME_SESSION_%02d", $alias_id );
    $self->{ALIAS} = $alias;
    $_[KERNEL]->alias_set($alias);
    $_[KERNEL]->yield('PoeEvent');
}

sub clear_PoeEvent {
    $_[KERNEL]->delay('PoeEvent');    # clears out delayed PoeEvents
}

sub OnClose {
    my ( $self, $event ) = @_;
    POE::Kernel->call( $self->{ALIAS}, 'clear_PoeEvent' );
    $self->Destroy();
}

sub PoeEvent {
    my ($self) = $_[OBJECT];
    $self->{text}->AppendText("POE Event.  My alias is $self->{ALIAS}\n");
    $_[KERNEL]->delay( 'PoeEvent' => 3 );
}

sub ButtonEvent { $_[0]->{text}->AppendText("Button Event.\n"); }

1;

package MyApp;
use base qw(Wx::App);
use POE;
use POE::Loop::Wx;

sub OnInit {
    my $self = shift;
    Wx::InitAllImageHandlers();

    my $frame = MyFrame->new();    # this also creates a poe session
    $self->SetTopWindow($frame);
    $frame->Show(1);

    my $frame2 = MyFrame->new();    # this also creates a poe session
    $frame2->Show(1);
    1;
}

sub OnExit {

}

1;

