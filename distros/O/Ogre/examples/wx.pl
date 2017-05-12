#!/usr/bin/perl
# modified from Wx/samples/minimal.pl
# and http://www.ogre3d.org/wiki/index.php/WxOgre_for_OGRE_v1.4


package OgrePane;

use strict;
use warnings;

use Wx;
use base qw(Wx::Control);

use Wx::Timer;
use Wx::Event qw(EVT_SIZE EVT_ERASE_BACKGROUND EVT_TIMER);

use Ogre 0.28 qw(:SceneType);
use Ogre::ColourValue;
use Ogre::ConfigFile;
use Ogre::ResourceGroupManager;


my $ID_RENDERTIMER = Wx::NewId();


sub new {
    my ($class, $parent) = @_;
    my $self = $class->SUPER::new($parent, -1);

    # WX members
    $self->{mTimer} = Wx::Timer->new($self, $ID_RENDERTIMER);

    # Ogre members
    $self->{mRoot}         = undef;
    $self->{mViewport}     = undef;
    $self->{mCamera}       = undef;
    $self->{mSceneMgr}     = undef;
    $self->{mRenderWindow} = undef;

    $self->createOgreRenderWindow();   # Create all Ogre objects
    $self->toggleTimerRendering();     # Start the rendering timer

    EVT_SIZE($self, \&OnSize);
    EVT_ERASE_BACKGROUND($self, \&OnEraseBackground);
    EVT_TIMER($self, $ID_RENDERTIMER, \&OnRenderTimer);

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    if ($self->{mViewport}) {
        $self->{mRenderWindow}->removeViewport($self->{mViewport}->getZOrder());
        delete $self->{mViewPort};
    }

    $self->{mRoot}->detachRenderTarget($self->{mRenderWindow});
    delete $self->{mRenderWindow};
    delete $self->{mRoot};
}

sub getCamera {
    return $_[0]->{mCamera};
}

sub setCamera {
    my ($self, $cam) = @_;
    $self->{mCamera} = $cam;
}

# This is the point of the example,
# passing your own window to Ogre
# instead of it creating a default one.
sub createOgreRenderWindow {
    my ($self) = @_;

    $self->{mRoot} = Ogre::Root->new();
    $self->{mRoot}->restoreConfig();

    # You have to pass false here, in order to tell
    # OGRE not to create a default window for you.
    # note to self: need to make 2nd arg optional
    $self->{mRenderWindow} = $self->{mRoot}->initialise(0, "OGRE Render Window");

    # Note: this is specially added for Perl
    # (and much more convenient than the C++ version :)
    # and returns the string needed by createRenderWindow.
    my $handle = Ogre->getWindowHandleString($self->GetHandle());
    my ($w, $h) = $self->GetSizeWH();
    $self->{mRenderWindow} = $self->{mRoot}->createRenderWindow("OgreRenderWindow",
                                                                $w, $h, 0,
                                                                {parentWindowHandle => $handle});

    # the rest is normal stuff

    $self->{mSceneMgr} = $self->{mRoot}->createSceneManager(ST_GENERIC, "ExampleSMInstance");

    $self->{mCamera} = $self->{mSceneMgr}->createCamera("PlayerCam");
    # note to self: need to wrap Vector3 version
    $self->{mCamera}->setPosition(0,0,500);
    # note to self: need to wrap Vector3 version
    $self->{mCamera}->lookAt(0,0,-300);
    $self->{mCamera}->setNearClipDistance(5);

    $self->{mViewport} = $self->{mRenderWindow}->addViewport($self->{mCamera});
    $self->{mViewport}->setBackgroundColour(Ogre::ColourValue->new());
}

sub toggleTimerRendering {
    my ($self) = @_;

    if ($self->{mTimer}->IsRunning) {
        $self->{mTimer}->Stop();
    }

    $self->{mTimer}->Start(10);
}

sub OnSize {
    my ($self, $evt) = @_;

    my ($w, $h) = $self->GetSizeWH();
    $self->{mRenderWindow}->resize($w, $h);
    $self->{mRenderWindow}->windowMovedOrResized();

    $self->{mCamera}->setAspectRatio($w / $h);

    $self->update();
}

sub OnEraseBackground {
    my ($self, $evt) = @_;
    $self->update();
}

sub OnRenderTimer {
    my ($self, $evt) = @_;
    $self->update();
}

sub update {
    my ($self) = @_;
    $self->{mRoot}->renderOneFrame();
}


1;


##################
package MainFrame;

use strict;
use warnings;
use base qw(Wx::Frame);

use Wx qw(wxOK wxICON_INFORMATION wxVERSION_STRING
          wxDefaultPosition wxDEFAULT_FRAME_STYLE
          wxNO_BORDER wxTE_MULTILINE
          wxLEFT wxBOTTOM wxTOP wxCENTER);
use Wx::AUI;

sub new {
    my ($class, $label) = @_;
    my $self = $class->SUPER::new(undef, -1, $label,
                                  wxDefaultPosition, Wx::Size->new(800, 600),
                                  wxDEFAULT_FRAME_STYLE);

    my $mgr = $self->{m_mgr} = Wx::AuiManager->new();
    # notify wxAUI which frame to use
    # (xxx: the WxOgre_for_OGRE tutorial has SetFrame...)
    $mgr->SetManagedWindow($self);

    # create several text controls
    my $text1 = Wx::TextCtrl->new($self, -1, "Pane 1 - sample text",
                                  wxDefaultPosition, Wx::Size->new(250, 150),
                                  wxNO_BORDER | wxTE_MULTILINE);
    my $text2 = Wx::TextCtrl->new($self, -1, "Pane 2 - sample text",
                                  wxDefaultPosition, Wx::Size->new(250, 150),
                                  wxNO_BORDER | wxTE_MULTILINE);
    my $text3 = Wx::TextCtrl->new($self, -1, "Main content window",
                                  wxDefaultPosition, Wx::Size->new(250, 150),
                                  wxNO_BORDER | wxTE_MULTILINE);

    # add the panes to the manager
    $mgr->AddPane($text1, wxLEFT, "Pane Number One");
    $mgr->AddPane($text2, wxBOTTOM, "Pane Number Two");

    # xxx: unable to resolve overloaded method for "Wx::AuiManager::AddPane"
    # if I leave out the empty string
    $mgr->AddPane($text3, wxTOP, "");


    $self->{wxOgrePane} = OgrePane->new($self);
    $mgr->AddPane($self->{wxOgrePane}, wxCENTER, "Ogre Pane");

    # tell the manager to "commit" all the changes just made
    $mgr->Update();

    return $self;
}

# called when the user selects the 'Exit' menu item
sub OnQuit {
    my ($self, $event) = @_;

    # closes the frame
    $self->Close(1);
}

# called when the user selects the 'About' menu item
sub OnAbout {
    my ($self, $event) = @_;

    # display a simple about box
    my $message = sprintf <<EOT, $Wx::VERSION, wxVERSION_STRING;
This is the about dialog of minimal sample.
Welcome to wxPerl %.02f
%s
EOT
    Wx::MessageBox($message, "About minimal", wxOK | wxICON_INFORMATION,
                    $self);
}

sub UpdateOgre {
    my ($self) = @_;
    $self->{wxOgrePane}->update();
}


1;


#############
package main;

# create an instance of the Wx::App-derived class
my $app = Wx::SimpleApp->new();
my $frame = MainFrame->new("wxOgre in Perl");
$app->SetTopWindow($frame);
$frame->Show();
$frame->UpdateOgre();
$app->MainLoop();
