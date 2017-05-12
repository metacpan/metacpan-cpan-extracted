#!/usr/bin/perl
# This is OgreAL's "Basic" demo ported to Perl.
# Read README.txt in this directory for how to set
# up the resources for this demo.
#
# Search for "soundManager" below, as the rest is not relevant to Ogre::AL
# (unlike the Ogre samples, this one doesn't use Ogre::ExampleApplication
# or ExampleFrameListener)
# See Demos/Basic/ in the OgreAL distribution.


# Note: as always, I put the packages in one file for the examples here,
# but you could put them in separate files.


package DeviceListener;
# implements FrameListener, WindowEventListener, MouseListener, KeyListener

use strict;
use warnings;

use Ogre 0.39;
use Ogre::Degree;
use Ogre::Vector3;
use Ogre::WindowEventUtilities;

use Ogre::AL;
use Ogre::AL::SoundManager;

use OIS 0.05;
use OIS::InputManager;
use OIS::Keyboard qw(:KeyCode);
use OIS::Mouse qw(:MouseButtonID);

use constant ROTATION_SPEED => 10;
use constant MOVEMENT_SPEED => 500;


sub new {
    my ($pkg, $win, $cam, $sceneMgr) = @_;

    my $self = bless {
        mSceneMgr => $sceneMgr,
        camera => $cam,
        mWindow => $win,
        mPitchNode => $cam->getParentSceneNode,
        mContinue => 1,
        mDirection => Ogre::Vector3->new(0, 0, 0),
        yaw => 0,
        pitch => 0,
        mMouse => undef,
        mKeyboard => undef,
        mInputManager => undef,
        mNumScreenShots => 0,
    }, $pkg;

    $self->{mCamNode} = $self->{mPitchNode}->getParentSceneNode;

    # Initialize OIS (Perl version differs somewhat from C++)
    my $windowHnd = $win->getCustomAttributePtr('WINDOW');
    $self->{mInputManager} = OIS::InputManager->createInputSystemPtr($windowHnd);

    if ($self->{mInputManager}->numMice() > 0) {
        # note again this is a little different than in C++
        $self->{mMouse} = $self->{mInputManager}->createInputObjectMouse(1);
        $self->{mMouse}->setEventCallback($self);
    }

    # some checks just in case you had OIS already installed and it wasn't really version 1.0.0
    my $numkbs = $self->{mInputManager}->can('numKeyboards');
    $numkbs = $self->{mInputManager}->can('numKeyBoards') if not defined $numkbs;
    if ($self->{mInputManager}->$numkbs > 0) {
        # note again this is a little different than in C++
        $self->{mKeyboard} = $self->{mInputManager}->createInputObjectKeyboard(1);
        $self->{mKeyboard}->setEventCallback($self);
    }

    $self->windowResized($win);
    Ogre::WindowEventUtilities->addWindowEventListener($win, $self);

    return $self;
}

# note: until I figure out how to get DESTROY to work properly
# (see Ogre::ExampleFrameListener), whenever you close an app it will
# disable autorepeat. If you have an XWindow system (e.g. Linux),
# you can turn it back on with for example:  xset r rate 300 30
# Thanks to akem on #ogre3d for pointing this out.

# These are the same as in Ogre::ExampleFrameListener
sub windowResized {
    my ($self, $win) = @_;

    my ($width, $height) = $win->getMetrics();
    my $mousestate = $self->{mMouse}->getMouseState();

    # note: in C++ this would be like  mousestate.width = width;
    $mousestate->setWidth($width);
    $mousestate->setHeight($height);
}
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

            OIS::InputManager->destroyInputSystem($im);
            delete $self->{mInputManager};
        }
    }
}

sub frameStarted {
    my ($self, $evt) = @_;
    my $mouse = $self->{mMouse};
    my $keyboard = $self->{mKeyboard};

    return 0 if $self->{mWindow}->isClosed;

    $keyboard->capture();
    $mouse->capture();

    # rotate camera
    $self->{mCamNode}->yaw($self->{yaw} * $evt->timeSinceLastFrame);
    $self->{mCamNode}->pitch($self->{pitch} * $evt->timeSinceLastFrame);

    $self->{yaw} = 0;
    $self->{pitch} = 0;

    # move camera
    # Quaternion * Vector3 * Real   =  fancy!
    $self->{mCamNode}->translate($self->{mPitchNode}->_getDerivedOrientation * $self->{mDirection} * $evt->timeSinceLastFrame);

    # update stats
    my $om = Ogre::OverlayManager->getSingletonPtr();
    my $taname = $om->getOverlayElement("TextAreaName");
    $taname->setCaption($self->{mWindow}->getAverageFPS
                          . "\n\nRoar       Music:\nF1 = Play   F5 = Play\nF2 = Pause F6 = Pause\nF3 = Stop   F7 = Stop");

    return $self->{mContinue};
}

sub mouseMoved {
    my ($self, $arg) = @_;
    my $ms = $self->{mMouse}->getMouseState();

    $self->{yaw} = - Ogre::Degree->new($ms->X->rel * ROTATION_SPEED);
    $self->{pitch} = - Ogre::Degree->new($ms->Y->rel * ROTATION_SPEED);

    return 1;
}

sub keyPressed {
    my ($self, $arg) = @_;

    # xxx: I still haven't fixed these OIS constants....
    my $key = $arg->key;
    if ($key == OIS::Keyboard->KC_ESCAPE) {
        $self->{mContinue} = 0;
    }
    elsif ($key == OIS::Keyboard->KC_SYSRQ) {
        my $ss = "screenshot_" . ($self->{mNumScreenShots}++) . ".png";
        $self->{mWindow}->writeContentsToFile($ss);
    }
    elsif ($key == OIS::Keyboard->KC_F1) {
        Ogre::AL::SoundManager->getSingletonPtr->getSound("Roar")->play();
    }
    elsif ($key == OIS::Keyboard->KC_F2) {
        Ogre::AL::SoundManager->getSingletonPtr->getSound("Roar")->pause();
    }
    elsif ($key == OIS::Keyboard->KC_F3) {
        Ogre::AL::SoundManager->getSingletonPtr->getSound("Roar")->stop();
    }
    elsif ($key == OIS::Keyboard->KC_F5) {
        Ogre::AL::SoundManager->getSingletonPtr->getSound("ZeroFactor")->play();
    }
    elsif ($key == OIS::Keyboard->KC_F6) {
        Ogre::AL::SoundManager->getSingletonPtr->getSound("ZeroFactor")->pause();
    }
    elsif ($key == OIS::Keyboard->KC_F7) {
        Ogre::AL::SoundManager->getSingletonPtr->getSound("ZeroFactor")->stop();
    }
    elsif ($key == OIS::Keyboard->KC_UP || $key == OIS::Keyboard->KC_W) {
        # a little weird due to crappy Perl bindings
        $self->{mDirection}->setZ($self->{mDirection}->z - MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_DOWN || $key == OIS::Keyboard->KC_S) {
        $self->{mDirection}->setZ($self->{mDirection}->z + MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_LEFT || $key == OIS::Keyboard->KC_A) {
        # a little weird due to crappy Perl bindings
        $self->{mDirection}->setX($self->{mDirection}->x - MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_RIGHT || $key == OIS::Keyboard->KC_D) {
        $self->{mDirection}->setX($self->{mDirection}->x + MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_PGDOWN || $key == OIS::Keyboard->KC_Q) {
        $self->{mDirection}->setY($self->{mDirection}->y - MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_PGUP || $key == OIS::Keyboard->KC_E) {
        # a little weird due to crappy Perl bindings
        $self->{mDirection}->setY($self->{mDirection}->y + MOVEMENT_SPEED);
    }

    return 1;
}

sub keyReleased {
    my ($self, $arg) = @_;

    # xxx: I still haven't fixed these OIS constants....
    my $key = $arg->key;

    if ($key == OIS::Keyboard->KC_UP || $key == OIS::Keyboard->KC_W) {
        # a little weird due to crappy Perl bindings
        $self->{mDirection}->setZ($self->{mDirection}->z + MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_DOWN || $key == OIS::Keyboard->KC_S) {
        $self->{mDirection}->setZ($self->{mDirection}->z - MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_LEFT || $key == OIS::Keyboard->KC_A) {
        # a little weird due to crappy Perl bindings
        $self->{mDirection}->setX($self->{mDirection}->x + MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_RIGHT || $key == OIS::Keyboard->KC_D) {
        $self->{mDirection}->setX($self->{mDirection}->x - MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_PGDOWN || $key == OIS::Keyboard->KC_Q) {
        $self->{mDirection}->setY($self->{mDirection}->y + MOVEMENT_SPEED);
    }
    elsif ($key == OIS::Keyboard->KC_PGUP || $key == OIS::Keyboard->KC_E) {
        # a little weird due to crappy Perl bindings
        $self->{mDirection}->setY($self->{mDirection}->y - MOVEMENT_SPEED);
    }
}


1;


package OgreApp;

use strict;
use warnings;

use Ogre 0.35 qw(:SceneType :ShadowTechnique :GuiMetricsMode);
use Ogre::ColourValue;
use Ogre::Degree;
use Ogre::Light qw(:LightTypes);
use Ogre::OverlayManager;
use Ogre::Plane;
use Ogre::ResourceGroupManager qw(:GroupName);
use Ogre::Root;
use Ogre::Vector3;

use Ogre::AL::Sound;
use Ogre::AL::SoundManager;


sub new {
    my ($pkg) = @_;
    my $self = bless {
        root => Ogre::Root->new(),
        win => undef,
        sceneMgr => undef,
        camera => undef,
        soundManager => undef,
    }, $pkg;

    # note: I've rearranged this a little differently than Demos/Basic/,
    # showing how it's similar to Ogre::ExampleApplication
    $self->setupResources();
    $self->configure();
    $self->chooseSceneManager();
    $self->createCamera();
    $self->createViewports();

    $self->{soundManager} = Ogre::AL::SoundManager->new();

    $self->createScene();

    my $listener = DeviceListener->new($self->{win}, $self->{camera}, $self->{sceneMgr});
    $self->{root}->addFrameListener($listener);

    return $self;
}

sub start {
    my ($self) = @_;
    $self->{root}->startRendering();
}

sub createScene {
    my ($self) = @_;

    my $mgr = $self->{sceneMgr};

    # xxx: I have no idea what voodoo makes this work in C++....
    # This is the API:
    # void setSkyBox(bool enable, const String &materialName, Real distance=5000, bool drawFirst=true, const Quaternion &orientation=Quaternion::IDENTITY, const String &groupName=ResourceGroupManager::DEFAULT_RESOURCE_GROUP_NAME)
    # $mgr->setSkyBox(1, "Sky", 5, 8, 4000);
    $mgr->setSkyBox(1, "Sky", 4000);
    $mgr->setAmbientLight(Ogre::ColourValue->new(0.5, 0.5, 0.5));
    $mgr->setShadowTechnique(SHADOWTYPE_STENCIL_ADDITIVE);

    my $node = $mgr->getRootSceneNode->createChildSceneNode("OgreHead");
    my $ent = $mgr->createEntity("Ogre", "ogrehead.mesh");

    $node->attachObject($ent);
    $node->setPosition(0, 50, 0);

    my $sound = $self->{soundManager}->createSound("Roar", "roar.wav", 1);
    $node->attachObject($sound);
    $sound->play();

    my $bgSound = $self->{soundManager}->createSound("ZeroFactor", "Zero Factor - Untitled.ogg", 1, 1);
    $bgSound->setGain(0.7);
    $bgSound->setRelativeToListener(1);
    $bgSound->play();

    $node = $mgr->getRootSceneNode->createChildSceneNode("CameraNode");
    $node->setPosition(0, 100, 100);
    my $pitchNode = $node->createChildSceneNode("PitchNode");
    $pitchNode->attachObject($self->{camera});
    $pitchNode->attachObject($self->{soundManager}->getListener());
    $pitchNode->pitch(Ogre::Degree->new(-30));

    # Create a ground plane (just like examples/ninja.pl in Perl Ogre distribution)
    my $plane = Ogre::Plane->new(Ogre::Vector3->new(0, 1, 0), 0);
    my $meshmgr = Ogre::MeshManager->getSingletonPtr();
    $meshmgr->createPlane("ground",
                          DEFAULT_RESOURCE_GROUP_NAME,
                          $plane, 15000, 15000, 20, 20, 1, 1, 5, 5,
                          Ogre::Vector3->new(0, 0, 1));
    $ent = $mgr->createEntity("GroundEntity", "ground");
    $mgr->getRootSceneNode->createChildSceneNode->attachObject($ent);
    $ent->setMaterialName("Ground");
    $ent->setCastShadows(0);

    my $light = $mgr->createLight("sun");
    $light->setType(LT_DIRECTIONAL);
    $light->setDirection(-1,-1,-1);

    # Perl note: see Ogre::BetaGUI::GUI createOverlay for a similar example
    # (note also createOverlayContainer is specific to Perl Ogre)
    my $overlayMgr = Ogre::OverlayManager->getSingletonPtr;
    my $panel = $overlayMgr->createOverlayContainer("Panel", "PanelName");
    $panel->setMetricsMode(GMM_PIXELS);
    $panel->setPosition(10, 10);
    $panel->setDimensions(100, 100);

    my $textArea = $overlayMgr->createTextAreaOverlayElement("TextArea", "TextAreaName");
    $textArea->setMetricsMode(GMM_PIXELS);
    $textArea->setPosition(0, 0);
    $textArea->setDimensions(100, 100);
    $textArea->setCharHeight(16);
    $textArea->setFontName("Arial");
    $textArea->setCaption("Hello, World!");

    my $overlay = $overlayMgr->create("AverageFps");
    $overlay->add2D($panel);
    $panel->addChild($textArea);
    $overlay->show();
}

sub setupResources {
    my ($self) = @_;

    my $cf = Ogre::ConfigFile->new();
    $cf->load("resources.cfg");

    # note: this is a Perlish replacement for iterators used in C++
    my $secs = $cf->getSections();
    my $rgm = Ogre::ResourceGroupManager->getSingletonPtr();

    foreach my $sec (@$secs) {
        my $secName = $sec->{name};

        my $settings = $sec->{settings};
        foreach my $setting (@$settings) {
            my ($typeName, $archName) = @$setting;
            $rgm->addResourceLocation($archName, $typeName, $secName);
        }
    }

    $rgm->initialiseAllResourceGroups();
}

sub configure {
    my ($self) = @_;

    # this shows an alternative to the way Ogre::ExampleApplication does it
    unless ($self->{root}->restoreConfig()) {
        unless ($self->{root}->showConfigDialog()) {
            exit;
        }
    }

    $self->{win} = $self->{root}->initialise(1, "Ogre Framework");
}

sub chooseSceneManager {
    my ($self) = @_;
    $self->{sceneMgr} = $self->{root}->createSceneManager(ST_GENERIC, "MainSceneManager");
}

sub createCamera {
    my ($self) = @_;

    $self->{camera} = $self->{sceneMgr}->createCamera("SimpleCamera");
    $self->{camera}->setNearClipDistance(1.0);
}

sub createViewports {
    my ($self) = @_;

    my $vp = $self->{win}->addViewport($self->{camera});
    $vp->setBackgroundColour(Ogre::ColourValue->new(0,0,0));
    $self->{camera}->setAspectRatio($vp->getActualWidth() / $vp->getActualHeight());
}


1;


package main;

# uncomment this if the packages are in separate files:
# use OgreApp;

OgreApp->new->start();
