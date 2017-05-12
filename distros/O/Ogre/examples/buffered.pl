#!/usr/bin/perl
# This is OGRE's "Basic Tutorial 5" but in Perl.
# Read that tutorial, but see keyPressed() if you want
# to know what the key commands are.


# Note: normally you'd want to put these packages in separate files
# (and call `use' when needed, uncomment below).
# Note that package 'main' is at bottom.


package TutorialFrameListener;
# implements ExampleFrameListener, OIS::MouseListener, OIS::KeyListener

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@TutorialFrameListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.27;
use Ogre::Node qw(:TransformSpace);

use OIS 0.03;
use OIS::Keyboard;
use OIS::Mouse;


sub new {
    my ($pkg, $win, $cam, $sceneMgr) = @_;

    # call ExampleFrameListener's constructor
    my $super = $pkg->SUPER::new($win, $cam, 1, 1);
    my $self = bless $super, $pkg;

    $self->{mRotate}    = 0.13;       # the rotate constant
    $self->{mMove}      = 250;        # the movement constant
    $self->{mSceneMgr}  = $sceneMgr;  # the current SceneManager
    $self->{mContinue}  = 1;          # whether to continue rendering or not
    # value to move in the correct direction
    $self->{mDirection} = Ogre::Vector3->new(0, 0, 0);
    # the SceneNode the camera is currently attached to
    $self->{mCamNode} = $cam->getParentSceneNode();

    # note: mMouse, mKeyboard are from ExampleFrameListener constructor
    $self->{mMouse}->setEventCallback($self);
    $self->{mKeyboard}->setEventCallback($self);

    return $self;
}

# FrameListener
sub frameStarted {
    my ($self, $evt) = @_;

    if ($self->{mMouse}) {
        $self->{mMouse}->capture();
    }
    if ($self->{mKeyboard}) {
        $self->{mKeyboard}->capture();
    }

    # xxx: have yet to overload * for Vector3,
    # so can't just multiply it by $t
    my $t = $evt->timeSinceLastFrame;
    my $d = $self->{mDirection};
    $self->{mCamNode}->translate($t * $d->x,
                                 $t * $d->y,
                                 $t * $d->z,
                                 TS_LOCAL);

    return $self->{mContinue};
}

# MouseListener
sub mouseMoved {
    my ($self, $evt) = @_;

    my $state = $evt->state;
    if ($state->buttonDown(OIS::Mouse->MB_Right)) {
        $self->{mCamNode}->yaw(Ogre::Degree->new(- $self->{mRotate} * $state->X->rel),
                               TS_WORLD);
        $self->{mCamNode}->pitch(Ogre::Degree->new(- $self->{mRotate} * $state->Y->rel),
                                 TS_LOCAL);
    }

    return 1;
}

# MouseListener
sub mousePressed {
    my ($self, $evt, $id) = @_;

    my $light = $self->{mSceneMgr}->getLight("Light1");

    # left click toggles light on/off
    if ($id == OIS::Mouse->MB_Left) {
        $light->setVisible(! $light->isVisible);
    }

    return 1;
}

# note: it's more efficient to leave out callback methods
# if they're not overridden
# MouseListener
# sub mouseReleased {
#     my ($self, $evt, $id) = @_;
#     return 1;
# }

# KeyListener
sub keyPressed {
    my ($self, $evt) = @_;

    my $key = $evt->key;

    # stop rendering if ESC is pressed
    if ($key == OIS::Keyboard->KC_ESCAPE) {
        $self->{mContinue} = 0;
    }

    # switch between two cameras
    elsif ($key == OIS::Keyboard->KC_1) {
        $self->{mCamera}->getParentSceneNode->detachObject($self->{mCamera});
        $self->{mCamNode} = $self->{mSceneMgr}->getSceneNode("CamNode1");
        $self->{mCamNode}->attachObject($self->{mCamera});
    }
    elsif ($key == OIS::Keyboard->KC_2) {
        $self->{mCamera}->getParentSceneNode->detachObject($self->{mCamera});
        $self->{mCamNode} = $self->{mSceneMgr}->getSceneNode("CamNode2");
        $self->{mCamNode}->attachObject($self->{mCamera});
    }

    # keyboard movement
    elsif ($key == OIS::Keyboard->KC_UP || $key == OIS::Keyboard->KC_W) {
        # xxx: this is what I want:
        # $self->{mDirection}{z} -= $self->{mMove};
        $self->{mDirection}->setZ($self->{mDirection}->z - $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_DOWN || $key == OIS::Keyboard->KC_S) {
        $self->{mDirection}->setZ($self->{mDirection}->z + $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_LEFT || $key == OIS::Keyboard->KC_A) {
        $self->{mDirection}->setX($self->{mDirection}->x - $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_RIGHT || $key == OIS::Keyboard->KC_D) {
        $self->{mDirection}->setX($self->{mDirection}->x + $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_PGDOWN || $key == OIS::Keyboard->KC_E) {
        $self->{mDirection}->setY($self->{mDirection}->y - $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_PGUP || $key == OIS::Keyboard->KC_Q) {
        $self->{mDirection}->setY($self->{mDirection}->y + $self->{mMove});
    }

    return 1;
}

# KeyListener
sub keyReleased {
    my ($self, $evt) = @_;

    my $key = $evt->key;

    # undo change to mDirection vector when key is released
    if ($key == OIS::Keyboard->KC_UP || $key == OIS::Keyboard->KC_W) {
        $self->{mDirection}->setZ($self->{mDirection}->z + $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_DOWN || $key == OIS::Keyboard->KC_S) {
        $self->{mDirection}->setZ($self->{mDirection}->z - $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_LEFT || $key == OIS::Keyboard->KC_A) {
        $self->{mDirection}->setX($self->{mDirection}->x + $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_RIGHT || $key == OIS::Keyboard->KC_D) {
        $self->{mDirection}->setX($self->{mDirection}->x - $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_PGDOWN || $key == OIS::Keyboard->KC_E) {
        $self->{mDirection}->setY($self->{mDirection}->y + $self->{mMove});
    }
    elsif ($key == OIS::Keyboard->KC_PGUP || $key == OIS::Keyboard->KC_Q) {
        $self->{mDirection}->setY($self->{mDirection}->y - $self->{mMove});
    }

    return 1;
}


1;


package TutorialApplication;

use strict;
use warnings;

use Ogre 0.27;
use Ogre::ColourValue;
use Ogre::Degree;
use Ogre::Light qw(:LightTypes);
use Ogre::Vector3;

# uncomment this if the packages are in separate files
# use TutorialFrameListener;
use Ogre::ExampleApplication;
@TutorialApplication::ISA = qw(Ogre::ExampleApplication);

sub createCamera {
    my ($self) = @_;

    $self->{mCamera} = $self->{mSceneMgr}->createCamera("PlayerCam");
    $self->{mCamera}->setNearClipDistance(5);
}

sub createScene {
    my ($self) = @_;

    $self->{mSceneMgr}->setAmbientLight(Ogre::ColourValue->new(0.25, 0.25, 0.25));

    # add the ninja
    my $ent = $self->{mSceneMgr}->createEntity("Ninja", "ninja.mesh");
    my $node = $self->{mSceneMgr}->getRootSceneNode()->createChildSceneNode("NinjaNode");
    $node->attachObject($ent);

    # create the light
    my $light = $self->{mSceneMgr}->createLight("Light1");
    $light->setType(LT_POINT);
    $light->setPosition(250, 150, 250);
    $light->setDiffuseColour(1, 1, 1);
    $light->setSpecularColour(1, 1, 1);

    # Create the scene node
    $node = $self->{mSceneMgr}->getRootSceneNode()->createChildSceneNode("CamNode1",
                                                                         Ogre::Vector3->new(-400, 200, 400));

    # Make it look towards the ninja
    $node->yaw(Ogre::Degree->new(-45));

    # Create the pitch node
    $node = $node->createChildSceneNode("PitchNode1");
    $node->attachObject($self->{mCamera});

    # create the second camera node/pitch node
    $node = $self->{mSceneMgr}->getRootSceneNode()->createChildSceneNode("CamNode2",
                                                                         Ogre::Vector3->new(0, 200, 400));
    $node = $node->createChildSceneNode("PitchNode2");
}

sub createFrameListener {
    my ($self) = @_;

    # Create the FrameListener
    $self->{mFrameListener} = TutorialFrameListener->new($self->{mWindow},
                                                         $self->{mCamera},
                                                         $self->{mSceneMgr});
    $self->{mRoot}->addFrameListener($self->{mFrameListener});

    # Show the frame stats overlay
    $self->{mFrameListener}->showDebugOverlay(1);
}


1;


package main;

use strict;
use warnings;


# uncomment this if the packages are in separate files
# use TutorialApplication;

main();
exit(0);

sub main {
    my $app = TutorialApplication->new();
    $app->go();
}
