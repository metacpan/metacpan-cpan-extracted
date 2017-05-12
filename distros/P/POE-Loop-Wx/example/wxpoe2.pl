#!/usr/bin/perl -w
# absolutely minimal wxPOE sample
# Ed Heil, 5/5/05

use Wx;
use strict;

package MyFrame;
use base 'Wx::Frame';
use Wx(
    qw [wxDefaultPosition wxDefaultSize wxVERTICAL wxFIXED_MINSIZE
      wxEXPAND wxALL wxTE_MULTILINE ]
);
use Wx::Event qw(EVT_BUTTON EVT_CLOSE);

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

    # sizer time!
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

    # events
    EVT_BUTTON( $self, $self->{button}, sub { $self->ButtonEvent } );
    EVT_CLOSE( $self, \&OnClose );
    push @MyApp::frames, $self;    # stow in main for poe session to use
    return $self;
}

sub PoeEvent    { $_[0]->{text}->AppendText("POE Event.\n"); }
sub ButtonEvent { $_[0]->{text}->AppendText("Button Event.\n"); }

sub OnClose {
    my ( $self, $event ) = @_;

    # make sure the POE session doesn't try to send events
    # to a nonexistent widget!
    @MyApp::frames = grep { $_ != $self } @MyApp::frames;
    $self->Destroy();
}

1;

package MyApp;
use base qw(Wx::App);
use vars qw(@frames);

sub OnInit {
    my $self = shift;
    Wx::InitAllImageHandlers();
    my $frame = MyFrame->new();
    $self->SetTopWindow($frame);
    $frame->Show(1);
    my $frame2 = MyFrame->new();
    $frame2->Show(1);
    1;
}

1;

package main;
use POE;
use POE::Loop::Wx;
use POE::Session;

my $app = MyApp->new();
POE::Session->create(
    inline_states => {
        _start => sub {
            $_[KERNEL]->yield('pulse');
        },
        pulse => sub {
            if (@MyApp::frames) {
                foreach (@MyApp::frames) {
                    $_->PoeEvent();
                }

                # relaunch pulse if frames still exist
                $_[KERNEL]->delay( pulse => 3 );
            }
        },
    }
);

POE::Kernel->loop_run();
POE::Kernel->run();
