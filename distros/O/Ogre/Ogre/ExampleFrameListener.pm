package Ogre::ExampleFrameListener;
# implements FrameListener, WindowEventListener

use strict;
use warnings;

use Ogre 0.38 qw(:TextureFilterOptions :PolygonMode);
use Ogre::Degree;
use Ogre::OverlayManager;
use Ogre::LogManager;
use Ogre::MaterialManager;
use Ogre::Vector3;
use Ogre::WindowEventUtilities;

# keep CPAN indexer from barfing on OIS below
our $VERSION = 0.38;

BEGIN {
    if (eval { require OIS && $OIS::VERSION >= 0.05 }) {
        require OIS::InputManager;
        OIS::InputManager->import();
        # xxx: these constants don't export right...
        require OIS::Keyboard;
        OIS::Keyboard->import(qw(:KeyCode));
        require OIS::Mouse;
        OIS::Mouse->import(qw(:MouseButtonID));
    }
    else {
        die(__PACKAGE__ . " requires OIS 0.05 or greater\n");
    }
}


# Note: I don't have a joystick to test with.... :P

sub new {
    my ($pkg, $win, $cam, $bufferedKeys, $bufferedMouse, $bufferedJoy) = @_;

    $bufferedKeys  = 0 unless defined $bufferedKeys;
    $bufferedMouse = 0 unless defined $bufferedMouse;
    $bufferedJoy   = 0 unless defined $bufferedJoy;

    my $self = bless {
        mWindow              => $win,   # RenderWindow
        mCamera              => $cam,   # Camera
        mTranslateVector     => Ogre::Vector3->new(0, 0, 0),
        mStatsOn             => 1,
        mNumScreenShots      => 0,
        mMoveScale           => 0,
        mRotScale            => 0,
        mTimeUntilNextToggle => 0,
        mFiltering           => TFO_BILINEAR,
        mAniso               => 1,
        mSceneDetailIndex    => 0,
        mMoveSpeed           => 100,
        mRotateSpeed         => 36,
        mDebugOverlay        => undef,
        mInputManager        => undef,
        mMouse               => undef,
        mKeyboard            => undef,
        mJoy                 => undef,
        mDebugText           => '',
        displayCameraDetails => 0,    # static variable, I put it here instead
    }, $pkg;

    $self->{mDebugOverlay} = Ogre::OverlayManager->getSingletonPtr->getByName("Core/DebugOverlay");

    Ogre::LogManager->getSingletonPtr->logMessage("*** Initializing OIS ***");

    my $windowHnd = $win->getCustomAttributePtr('WINDOW');
    $self->{mInputManager} = OIS::InputManager->createInputSystemPtr($windowHnd);

    $self->{mKeyboard} = $self->{mInputManager}->createInputObjectKeyboard($bufferedKeys);
    $self->{mMouse} = $self->{mInputManager}->createInputObjectMouse($bufferedMouse);
    # $self->{mJoy} = $self->{mInputManager}->createInputObjectJoyStick($bufferedJoy);

    $self->windowResized($win);
    $self->showDebugOverlay(1);

    Ogre::WindowEventUtilities->addWindowEventListener($win, $self);

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    # XXX: not sure where things are getting destroyed...
    # I wonder if this is why autorepeat turns off when you close
    # the application....

    # Ogre::WindowEventUtilities->removeWindowEventListener($self->{mWindow}, $self);
    # $self->windowClosed($self->{mWindow});
}

sub updateStats {
    my ($self) = @_;

    # there's a `try' block around this in C++,
    # not sure why - maybe for when these overlay elements
    # don't exist?

    my $om = Ogre::OverlayManager->getSingletonPtr();
    my $guiAvg = $om->getOverlayElement("Core/AverageFps");
    my $guiCurr = $om->getOverlayElement("Core/CurrFps");
    my $guiBest = $om->getOverlayElement("Core/BestFps");
    my $guiWorst = $om->getOverlayElement("Core/WorstFps");

    # I can't get getStatistics to work, so have to use individual
    # methods from RenderTarget as follows.
    # my $stats = $self->{mWindow}->getStatistics();

    my $win = $self->{mWindow};

    $guiAvg->setCaption("Average FPS: " . $win->getAverageFPS);
    $guiCurr->setCaption("Current FPS: " . $win->getLastFPS);
    $guiBest->setCaption("Best FPS: " . $win->getBestFPS
                          . " " . $win->getBestFrameTime . " ms");
    $guiWorst->setCaption("Worst FPS: " . $win->getWorstFPS
                           . " " . $win->getWorstFrameTime . " ms");

    my $guiTris = $om->getOverlayElement("Core/NumTris");
    my $guiBatches = $om->getOverlayElement("Core/NumBatches");
    my $guiDbg = $om->getOverlayElement("Core/DebugText");

    $guiTris->setCaption("Triangle Count: " . $win->getTriangleCount);
    $guiBatches->setCaption("Batch Count: " . $win->getBatchCount);
    $guiDbg->setCaption($self->{mDebugText});
}

# windowEventListener
sub windowResized {
    my ($self, $win) = @_;

    my ($width, $height) = $win->getMetrics();
    my $mousestate = $self->{mMouse}->getMouseState();

    # note: in C++ this would be like  mousestate.width = width;
    $mousestate->setWidth($width);
    $mousestate->setHeight($height);
}

# windowEventListener
sub windowClosed {
    my ($self, $win) = @_;

    # note: NEED TO IMPLEMENT overload == operator (etc...)
    # if ($win == $self->{mWindow}) {
    if ($win->getName == $self->{mWindow}->getName) {
        if ($self->{mInputManager}) {
            my $im = $self->{mInputManager};
            if ($self->{mMouse}) {
                $im->destroyInputObject($self->{mMouse});
                delete $self->{mMouse};
            }
            if ($self->{mKeyboard}) {
                $im->destroyInputObject($self->{mKeyboard});
                delete $self->{mMouse};
            }
            if ($self->{mJoy}) {
                $im->destroyInputObject($self->{mJoy});
                delete $self->{mJoy};
            }

            OIS::InputManager->destroyInputSystem($im);
            delete $self->{mInputManager};
        }
    }
}

sub processUnbufferedKeyInput {
    my ($self, $evt) = @_;
    my $kb = $self->{mKeyboard};
    my $tv = $self->{mTranslateVector};
    my $cam = $self->{mCamera};

    if ($kb->isKeyDown(OIS::Keyboard->KC_A)) {
        $tv->setX(-$self->{mMoveScale});   # Move camera left
    }
    if ($kb->isKeyDown(OIS::Keyboard->KC_D)) {
        $tv->setX($self->{mMoveScale});    # Move camera RIGHT
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_UP) || $kb->isKeyDown(OIS::Keyboard->KC_W) ) {
        $tv->setZ(-$self->{mMoveScale});   # Move camera forward
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_DOWN) || $kb->isKeyDown(OIS::Keyboard->KC_S) ) {
        $tv->setZ($self->{mMoveScale});    # Move camera backward
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_PGUP)) {
        $tv->setY($self->{mMoveScale});    # Move camera up
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_PGDOWN)) {
        $tv->setY(-$self->{mMoveScale});   # Move camera down
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_RIGHT)) {
        $cam->yaw(Ogre::Degree->new(- $self->{mRotScale}));
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_LEFT)) {
        $cam->yaw(Ogre::Degree->new($self->{mRotScale}));
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_ESCAPE) || $kb->isKeyDown(OIS::Keyboard->KC_Q)) {
        return 0;
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_F) && $self->{mTimeUntilNextToggle} <= 0) {
        $self->{mStatsOn} = !$self->{mStatsOn};
        $self->showDebugOverlay($self->{mStatsOn});
        $self->{mTimeUntilNextToggle} = 1;
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_T) && $self->{mTimeUntilNextToggle} <= 0) {
        if ($self->{mFiltering} == TFO_BILINEAR) {
            $self->{mFiltering} = TFO_TRILINEAR;
            $self->{mAniso} = 1;
        }
        elsif ($self->{mFiltering} == TFO_TRILINEAR) {
            $self->{mFiltering} = TFO_ANISOTROPIC;
            $self->{mAniso} = 8;
        }
        elsif ($self->{mFiltering} == TFO_ANISOTROPIC) {
            $self->{mFiltering} = TFO_BILINEAR;
            $self->{mAniso} = 1;
        }

        Ogre::MaterialManager->getSingletonPtr->setDefaultTextureFiltering($self->{mFiltering});
        Ogre::MaterialManager->getSingletonPtr->setDefaultAnisotropy($self->{mAniso});

        $self->showDebugOverlay($self->{mStatsOn});
        $self->{mTimeUntilNextToggle} = 1;
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_SYSRQ) && $self->{mTimeUntilNextToggle} <= 0) {
        my $ss = "screenshot_" . ++$self->{mNumScreenShots} . ".png";
        $self->{mWindow}->writeContentsToFile($ss);
        $self->{mTimeUntilNextToggle} = 0.5;
        $self->{mDebugText} = "Saved: $ss";
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_R) && $self->{mTimeUntilNextToggle} <= 0) {
        $self->{mSceneDetailIndex} = ($self->{mSceneDetailIndex} + 1) % 3;

        if ($self->{mSceneDetailIndex} == 0) {
            $cam->setPolygonMode(PM_SOLID);
        }
        elsif ($self->{mSceneDetailIndex} == 1) {
            $cam->setPolygonMode(PM_WIREFRAME);
        }
        elsif ($self->{mSceneDetailIndex} == 2) {
            $cam->setPolygonMode(PM_POINTS);
        }

        $self->{mTimeUntilNextToggle} = 0.5;
    }

    if ($kb->isKeyDown(OIS::Keyboard->KC_P) && $self->{mTimeUntilNextToggle} <= 0) {
        $self->{displayCameraDetails} = !$self->{displayCameraDetails};
        $self->{$self->{mTimeUntilNextToggle}} = 0.5;
        if (!$self->{displayCameraDetails}) {
            $self->{mDebugText} = "";
        }
    }

    # Print camera details
    # XXX: not for now - requires overloading "" for Quaternion
    # and Vector3
    #if ($self-{displayCameraDetails}) {
    #    $self->{mDebugText} = "P: " . $cam->getDerivedPosition() .
    #      " " . "O: " . $cam->getDerivedOrientation();
    #}

    if ($self->{displayCameraDetails}) {
        $self->{mDebugText} = "P: ---  O: ---";
    }

    # Return true to continue rendering
    return 1;
}

sub processUnbufferedMouseInput {
    my ($self, $evt) = @_;

    # Rotation factors, may not be used if the second mouse button is pressed
    # 2nd mouse button - slide, otherwise rotate
    my $ms = $self->{mMouse}->getMouseState();
    if ($ms->buttonDown(OIS::Mouse->MB_Right)) {
        my $tv = $self->{mTranslateVector};
        $tv->setX($tv->x + $ms->X->rel * 0.13);
        $tv->setY($tv->y - $ms->Y->rel * 0.13);
    }
    else {
        $self->{mRotX} = Ogre::Degree->new(- $ms->X->rel * 0.13);
        $self->{mRotY} = Ogre::Degree->new(- $ms->Y->rel * 0.13);
    }

    return 1;
}

sub moveCamera {
    my ($self) = @_;

    # Make all the changes to the camera
    # Note that YAW direction is around a fixed axis (freelook style) rather than a natural YAW
    # (e.g. airplane)
    my $cam = $self->{mCamera};

    die "mRotX and mRotY must be Ogre::Degree!\n"
      unless ref($self->{mRotX}) && ref($self->{mRotY});
    $cam->yaw($self->{mRotX});
    $cam->pitch($self->{mRotY});

    $cam->moveRelative($self->{mTranslateVector});
}

sub showDebugOverlay {
    my ($self, $show) = @_;
    if ($self->{mDebugOverlay}) {
        if ($show) {
            $self->{mDebugOverlay}->show();
        } else {
            $self->{mDebugOverlay}->hide();
        }
    }
}

sub frameStarted {
    my ($self, $evt) = @_;
    my $mouse = $self->{mMouse};
    my $keyboard = $self->{mKeyboard};
    my $joy = $self->{mJoy};

    if ($self->{mWindow}->isClosed()) {
        return 0;
    }

    # Need to capture/update each device
    $keyboard->capture();
    $mouse->capture();
    if ($joy) {
        $joy->capture();
    }

    my $buffJ = $joy ? $joy->buffered() : 1;

    # Check if one of the devices is not buffered
    if (!$mouse->buffered() || !$keyboard->buffered() || !$buffJ) {
        # one of the input modes is immediate, so setup what is needed for immediate movement
        if ($self->{mTimeUntilNextToggle} >= 0) {
            $self->{mTimeUntilNextToggle} -= $evt->timeSinceLastFrame;
        }

        # If this is the first frame, pick a speed
        if ($evt->timeSinceLastFrame == 0) {
            $self->{mMoveScale} = 1;
            $self->{mRotScale} = 0.1;
        }
        # Otherwise scale movement units by time passed since last frame
        else {
            # Move about 100 units per second,
            $self->{mMoveScale} = $self->{mMoveSpeed} * $evt->timeSinceLastFrame;
            # Take about 10 seconds for full rotation
            $self->{mRotScale} = $self->{mRotateSpeed} * $evt->timeSinceLastFrame;
        }

        $self->{mRotX} = Ogre::Degree->new(0);
        $self->{mRotY} = Ogre::Degree->new(0);
        $self->{mTranslateVector} = Ogre::Vector3->new(0, 0, 0);
    }

    # Check to see which device is not buffered, and handle it
    if (!$keyboard->buffered()) {
        unless ($self->processUnbufferedKeyInput($evt)) {
            return 0;
        }
    }
    if (!$mouse->buffered()) {
        unless ($self->processUnbufferedMouseInput($evt)) {
            return 0;
        }
    }
    if (!$mouse->buffered() || !$keyboard->buffered() || !$buffJ) {
        $self->moveCamera();
    }

    return 1;
}

sub frameEnded {
    $_[0]->updateStats();
    return 1;
}


1;

__END__
=head1 NAME

Ogre::ExampleFrameListener

=head1 SYNOPSIS

  package MyFrameListener;

  use Ogre::ExampleFrameListener;
  @ISA = qw(Ogre::ExampleFrameListener);

  # override methods...

  package MyApplication;

  # ...

  my $framelistener = MyFrameListener->new();
  $root->addFrameListener($framelistener);

=head1 DESCRIPTION

This is a port of OGRE's F<Samples/Common/include/ExampleFrameListener.h>.
See the examples referred to in F<examples/README.txt>.

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
