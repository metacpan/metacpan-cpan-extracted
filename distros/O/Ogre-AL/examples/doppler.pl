#!/usr/bin/perl
# This is OgreAL's "Doppler" demo ported to Perl.
# Read README.txt in this directory for how to set
# up the resources for this demo.
# Note: this also requires Ogre::BetaGUI.
#
# A lot of the code here is duplicated from basic.pl and directional.pl.
#
# See Demos/Doppler/ in the OgreAL distribution.


package DeviceListener;
# implements FrameListener, WindowEventListener, MouseListener, KeyListener, BetaGUIListener

use strict;
use warnings;
use Scalar::Util qw(refaddr);   # note: in core as of Perl 5.8

use Ogre 0.39;
use Ogre::Degree;
use Ogre::Node qw(:TransformSpace);
use Ogre::Vector3;
use Ogre::WindowEventUtilities;

use Ogre::AL;
use Ogre::AL::SoundManager;

use OIS 0.05;
use OIS::InputManager;
use OIS::Keyboard qw(:KeyCode);
use OIS::Mouse qw(:MouseButtonID);

use Ogre::BetaGUI 0.03 qw(MOVE);
use Ogre::BetaGUI::Callback;
use Ogre::BetaGUI::GUI;
use Ogre::BetaGUI::BetaGUIListener;
# strangely, of all the interfaces implemented, this is the only one inherited from
@DeviceListener::ISA = qw(Ogre::BetaGUI::BetaGUIListener);

use constant ROTATION_SPEED => 10;
use constant MOVEMENT_SPEED => 500;


sub new {
    my ($pkg, $win, $cam, $sceneMgr) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mSceneMgr} = $sceneMgr;
    $self->{camera} = $cam;
    $self->{mWindow} = $win;
    $self->{mPitchNode} = $cam->getParentSceneNode;
    $self->{mCamNode} = $self->{mPitchNode}->getParentSceneNode;
    $self->{mContinue} = 1;
    $self->{mDirection} = Ogre::Vector3->new(0, 0, 0);
    $self->{yaw} = 0;
    $self->{pitch} = 0;
    $self->{mMouse} = undef;
    $self->{mKeyboard} = undef;
    $self->{mInputManager} = undef;
    $self->{mNumScreenShots} = 0;

    $self->initOIS();

    $self->windowResized($win);
    Ogre::WindowEventUtilities->addWindowEventListener($win, $self);

    $self->{carNode} = $sceneMgr->getSceneNode("CarNode");
    $self->{soundManager} = Ogre::AL::SoundManager->getSingletonPtr;

    $self->createGUI();

    return $self;
}

# note: until I figure out how to get DESTROY to work properly
# (see Ogre::ExampleFrameListener), whenever you close an app it will
# disable autorepeat. If you have an XWindow system (e.g. Linux),
# you can turn it back on with for example:  xset r rate 300 30
# Thanks to akem on #ogre3d for pointing this out.

sub initOIS {
    my ($self) = @_;

    # Initialize OIS (Perl version differs somewhat from C++)
    my $windowHnd = $self->{mWindow}->getCustomAttributePtr('WINDOW');
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
}

sub createGUI {
    my ($self) = @_;

    my $win = $self->{mWindow};

    $self->{mGUI} = Ogre::BetaGUI::GUI->new("DopplerGui", "Arial", 14);
    $self->{mGUI}->createMousePointer([32,32], "bgui.pointer");
    $self->{mGUI}->injectMouse($win->getWidth / 2, $win->getHeight / 2, 0);

    my $mainWindow = $self->{mGUI}->createWindow([($win->getWidth - 235), 10, 225, 95],
                                                 "bgui.window", MOVE, "Doppler Settings");

    $mainWindow->createStaticText([5, 25, 100, 15], "Doppler Factor:");
    $self->{doppler} = $mainWindow->createTextInput([5, 40, 100, 20], "bgui.textinput", "1.0", 3);
    $self->{dfDn10} = $mainWindow->createButton([5, 65, 21, 24], "bgui.button", "<<", Ogre::BetaGUI::Callback->new($self));
    $self->{dfDn01} = $mainWindow->createButton([31, 65, 21, 24], "bgui.button", "<", Ogre::BetaGUI::Callback->new($self));
    $self->{dfUp01} = $mainWindow->createButton([57, 65, 21, 24], "bgui.button", " >", Ogre::BetaGUI::Callback->new($self));
    $self->{dfUp10} = $mainWindow->createButton([83, 65, 21, 24], "bgui.button", ">>", Ogre::BetaGUI::Callback->new($self));

    $mainWindow->createStaticText([115, 25, 100, 15], "Speed of Sound:");
    $self->{speed} = $mainWindow->createTextInput([115, 40, 100, 20], "bgui.textinput", "343.3", 5);
    $self->{ssDn10} = $mainWindow->createButton([116, 65, 21, 24], "bgui.button", "<<", Ogre::BetaGUI::Callback->new($self));
    $self->{ssDn01} = $mainWindow->createButton([142, 65, 21, 24], "bgui.button", "<", Ogre::BetaGUI::Callback->new($self));
    $self->{ssUp01} = $mainWindow->createButton([168, 65, 21, 24], "bgui.button", " >", Ogre::BetaGUI::Callback->new($self));
    $self->{ssUp10} = $mainWindow->createButton([194, 65, 21, 24], "bgui.button", ">>", Ogre::BetaGUI::Callback->new($self));
}

sub onButtonPress {
    my ($self, $ref, $type) = @_;

    if ($type == 1) {  # button down
        my $refaddr = refaddr($ref);

        my $value = $self->{doppler}->getValue || 0;
        if ($refaddr == refaddr($self->{dfUp01})) {
            $value += 0.01;
            $self->{doppler}->setValue($value);
            $self->{soundManager}->setDopplerFactor($value);
        }
        elsif ($refaddr == refaddr($self->{dfUp10})) {
            $value += 0.1;
            $self->{doppler}->setValue($value);
            $self->{soundManager}->setDopplerFactor($value);
        }
        elsif ($refaddr == refaddr($self->{dfDn01})) {
            $value -= 0.01;
            $value = 0 if $value < 0;
            $self->{doppler}->setValue($value);
            $self->{soundManager}->setDopplerFactor($value);
        }
        elsif ($refaddr == refaddr($self->{dfDn10})) {
            $value -= 0.1;
            $value = 0 if $value < 0;
            $self->{doppler}->setValue($value);
            $self->{soundManager}->setDopplerFactor($value);
        }

        $value = $self->{speed}->getValue || 0;
        if ($refaddr == refaddr($self->{ssUp01})) {
            $value += 0.1;
            $self->{speed}->setValue($value);
            $self->{soundManager}->setSpeedOfSound($value);
        }
        elsif ($refaddr == refaddr($self->{ssUp10})) {
            $value += 1;
            $self->{speed}->setValue($value);
            $self->{soundManager}->setSpeedOfSound($value);
        }
        elsif ($refaddr == refaddr($self->{ssDn01})) {
            $value -= 0.1;
            $value = 0 if $value < 0;
            $self->{speed}->setValue($value);
            $self->{soundManager}->setSpeedOfSound($value);
        }
        elsif ($refaddr == refaddr($self->{ssDn10})) {
            $value -= 1;
            $value = 0 if $value < 0;
            $self->{speed}->setValue($value);
            $self->{soundManager}->setSpeedOfSound($value);
        }
    }
}

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
    return 0 if $self->{mWindow}->isClosed;

    $self->{mKeyboard}->capture();
    $self->{mMouse}->capture();

    # rotate camera
    $self->{mCamNode}->yaw($self->{yaw} * $evt->timeSinceLastFrame);
    $self->{mCamNode}->pitch($self->{pitch} * $evt->timeSinceLastFrame);

    $self->{yaw} = 0;
    $self->{pitch} = 0;

    # move camera
    $self->{mCamNode}->translate($self->{mPitchNode}->_getDerivedOrientation * $self->{mDirection} * $evt->timeSinceLastFrame);
    $self->{carNode}->yaw(Ogre::Degree->new(-100 * $evt->timeSinceLastFrame));
    $self->{soundManager}->getSound("BusSound")->setVelocity($self->{carNode}->getOrientation->zAxis * 100);

    # update stats, show help
    my $om = Ogre::OverlayManager->getSingletonPtr();
    my $taname = $om->getOverlayElement("TextAreaName");
    $taname->setCaption($self->{mWindow}->getAverageFPS
                          . "\n\nDoppler:    Speed of Sound:\nF1 = Up    F3 = Up\nF2 = Down F4 = Down");

    return $self->{mContinue};
}

sub mouseMoved {
    my ($self, $arg) = @_;
    my $state = $arg->state;

    if ($state->buttonDown(OIS::Mouse->MB_Right)) {
        $self->{yaw} = - Ogre::Degree->new($state->X->rel * ROTATION_SPEED);
        $self->{pitch} = - Ogre::Degree->new($state->Y->rel * ROTATION_SPEED);
    }
    elsif ($state->buttonDown(OIS::Mouse->MB_Left)) {
        $self->{mGUI}->injectMouse($state->X->abs, $state->Y->abs, 1);
    }
    else {
        $self->{mGUI}->injectMouse($state->X->abs, $state->Y->abs, 0);
    }

    return 1;
}

sub mousePressed {
    my ($self, $arg, $id) = @_;

    $self->{mGUI}->injectMouse($arg->state->X->abs, $arg->state->Y->abs, 1);
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
        my $value = $self->{soundManager}->getDopplerFactor + 1;
        $self->{doppler}->setValue($value);
        $self->{soundManager}->setDopplerFactor($value);
    }
    elsif ($key == OIS::Keyboard->KC_F2) {
        my $factor = $self->{soundManager}->getDopplerFactor - 1;
        if ($factor >= 0) {
            $self->{doppler}->setValue($factor);
            $self->{soundManager}->setDopplerFactor($factor);
        }
    }
    elsif ($key == OIS::Keyboard->KC_F3) {
        my $value = $self->{soundManager}->getSpeedOfSound + 50;
        $self->{speed}->setValue($value);
        $self->{soundManager}->setSpeedOfSound($value);
    }
    elsif ($key == OIS::Keyboard->KC_F4) {
        my $factor = $self->{soundManager}->getSpeedOfSound - 50;
        if ($factor >= 0) {
            $self->{speed}->setValue($factor);
            $self->{soundManager}->setDopplerFactor($factor);
        }
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

    my $carnode = $mgr->getRootSceneNode->createChildSceneNode("CarNode");
    my $node = $carnode->createChildSceneNode(Ogre::Vector3->new(50, 0, 0));
    my $ent = $mgr->createEntity("Civic", "Civic.mesh");
    $node->attachObject($ent);

    my $sound = $self->{soundManager}->createSound("BusSound", "motor_b8.wav", 1);
    $node->attachObject($sound);
    $sound->play();

    $node = $mgr->getRootSceneNode->createChildSceneNode("CameraNode");
    $node->setPosition(-1.6, 1.46, 60.39);
    my $pitchNode = $node->createChildSceneNode("PitchNode");
    $pitchNode->attachObject($self->{camera});
    $pitchNode->attachObject($self->{soundManager}->getListener());

    # Create a ground plane
    my $plane = Ogre::Plane->new(Ogre::Vector3->new(0, 1, 0), 0);
    my $meshmgr = Ogre::MeshManager->getSingletonPtr();
    $meshmgr->createPlane("ground",
                          DEFAULT_RESOURCE_GROUP_NAME,
                          $plane, 15000, 15000, 20, 20, 1, 1, 20, 20,
                          Ogre::Vector3->new(0, 0, 1));
    $ent = $mgr->createEntity("GroundEntity", "ground");
    $mgr->getRootSceneNode->createChildSceneNode->attachObject($ent);
    $ent->setMaterialName("Ground");
    $ent->setCastShadows(0);

    my $light = $mgr->createLight("sun");
    $light->setType(LT_DIRECTIONAL);
    $light->setDirection(-1,-1,-1);

    # note: createOverlayContainer is specific to Perl Ogre
    my $overlayMgr = Ogre::OverlayManager->getSingletonPtr;
    my $panel = $overlayMgr->createOverlayContainer("Panel", "PanelName");
    $panel->setMetricsMode(GMM_PIXELS);
    $panel->setPosition(10, 10);
    $panel->setDimensions(100, 100);

    # note: createTextAreaOverlayElement is specific to Perl Ogre
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
