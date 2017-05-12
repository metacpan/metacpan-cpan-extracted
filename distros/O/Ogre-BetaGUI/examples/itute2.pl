#!/usr/bin/perl
# This is OGRE's "Intermediate Tutorial 2" but in Perl
# and using BetaGUI instead of CEGUI.


package MouseQueryGUI;

use strict;
use warnings;

use Ogre::BetaGUI::BetaGUIListener;
@MouseQueryGUI::ISA = qw(Ogre::BetaGUI::BetaGUIListener);

use Ogre 0.37;
use Ogre::BetaGUI::GUI;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mouseX} = 0;
    $self->{mouseY} = 0;

    $self->{mBetaGUI} = Ogre::BetaGUI::GUI->new("WhoCares", "BlueHighway", 20);
    # note: the C++ version uses Vector2, but we just use array refs
    $self->{mPointer} = $self->{mBetaGUI}->createMousePointer([32,32], "bgui.pointer");

    return $self;
}

sub onButtonPress {
    my ($self, $button, $lmb) = @_;

    # empty...
}


1;


package MouseQueryListener;

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@MouseQueryListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.33;
use Ogre::Ray;
use Ogre::Vector3;

use OIS 0.04;
use OIS::Mouse;


sub new {
    my ($pkg, $win, $cam, $sceneManager, $gui) = @_;

    my $super = $pkg->SUPER::new($win, $cam, 0, 1);
    my $self = bless $super, $pkg;

    $self->{mMQGUI} = $gui;

    $self->{mCount} = 0;
    $self->{mCurrentObject} = undef;
    $self->{mLMouseDown} = 0;
    $self->{mRMouseDown} = 0;
    $self->{mSceneMgr} = $sceneManager;

    $self->{mDOWN} = Ogre::Vector3->new(0, -1, 0);

    # Reduce move speed
    $self->{mMoveSpeed} = 50;
    $self->{mRotateSpeed} /= 500;

    # Register this so that we get mouse events.
    $self->{mMouse}->setEventCallback($self);

    # Create RaySceneQuery
    $self->{mRaySceneQuery} = $self->{mSceneMgr}->createRayQuery(Ogre::Ray->new());

    return $self;
}

sub frameStarted {
    my ($self, $evt) = @_;

    return 0 unless $self->SUPER::frameStarted($evt);

    # Setup the scene query
    my $camPos = $self->{mCamera}->getPosition();
    my $cameraRay = Ogre::Ray->new(Ogre::Vector3->new($camPos->x, 5000.0, $camPos->z),
                                   $self->{mDOWN});
    $self->{mRaySceneQuery}->setRay($cameraRay);

    # Perform the scene query
    my $qryResult = $self->{mRaySceneQuery}->execute();

    # Get the results, set the camera height
    if (@$qryResult && defined $qryResult->[0]->{worldFragment}) {
        my $terrainHeight = $qryResult->[0]->{worldFragment}->singleIntersection->y;

        if (($terrainHeight + 10.0) > $camPos->y) {
            $self->{mCamera}->setPosition($camPos->x, $terrainHeight + 10.0, $camPos->z);
        }
    }

    return 1;
}

# MouseListener callbacks
sub mouseMoved {
    my ($self, $evt) = @_;

    my $state = $evt->state;

    # Update BetaGUI with the mouse motion
    $self->injectMouse($state);

    # If we are dragging the left mouse button.
    if ($self->{mLMouseDown}) {
        my $mouseRay = $self->{mCamera}->getCameraToViewportRay($self->{mMQGUI}{mouseX} / $state->width,
                                                                $self->{mMQGUI}{mouseY} / $state->height);
        $self->{mRaySceneQuery}->setRay($mouseRay);

        my $qryResult = $self->{mRaySceneQuery}->execute();

        if (@$qryResult && defined $qryResult->[0]->{worldFragment}) {
            $self->{mCurrentObject}->setPosition($qryResult->[0]->{worldFragment}->singleIntersection);
        }
    }

    # If we are dragging the right mouse button.
    elsif ($self->{mRMouseDown}) {
        $self->{mCamera}->yaw(Ogre::Degree->new(- $state->X->rel * $self->{mRotateSpeed}));
        $self->{mCamera}->pitch(Ogre::Degree->new(- $state->Y->rel * $self->{mRotateSpeed}));
    }

    return 1;
}

sub mousePressed {
    my ($self, $evt, $id) = @_;

    # Left mouse button down
    if ($id == OIS::Mouse->MB_Left) {
        my $state = $evt->state;

        my $mouseRay = $self->{mCamera}->getCameraToViewportRay($self->{mMQGUI}{mouseX} / $state->width,
                                                                $self->{mMQGUI}{mouseY} / $state->height);
        $self->{mRaySceneQuery}->setRay($mouseRay);

        # Execute query
        my $qryResult = $self->{mRaySceneQuery}->execute();

        if (@$qryResult && defined $qryResult->[0]->{worldFragment}) {
            my $name = sprintf("Robot%d", $self->{mCount}++);
            my $ent = $self->{mSceneMgr}->createEntity($name, "robot.mesh");
            $self->{mCurrentObject} =
              $self->{mSceneMgr}->getRootSceneNode->createChildSceneNode($name . "Node",
                                                                         $qryResult->[0]->{worldFragment}->singleIntersection);
            $self->{mCurrentObject}->attachObject($ent);
            $self->{mCurrentObject}->setScale(0.1, 0.1, 0.1);
        }

        $self->{mLMouseDown} = 1;
    }

    # Right mouse button down
    elsif ($id == OIS::Mouse->MB_Right) {
        $self->{mMQGUI}{mPointer}->hide();
        $self->{mRMouseDown} = 1;
    }

    return 1;
}

sub mouseReleased {
    my ($self, $evt, $id) = @_;

    # Left mouse button up
    if ($id == OIS::Mouse->MB_Left) {
        $self->{mLMouseDown} = 0;
    }

    # Right mouse button up
    elsif ($id == OIS::Mouse->MB_Right) {
        $self->{mMQGUI}{mPointer}->show();
        $self->{mRMouseDown} = 0;
    }

    return 1;
}

sub injectMouse {
    my ($self, $state) = @_;

    $self->{mMQGUI}{mouseX} += $state->X->rel;
    $self->{mMQGUI}{mouseY} += $state->Y->rel;
    if ($state->buttons == 1) {
        $self->{mMQGUI}{mBetaGUI}->injectMouse($self->{mMQGUI}{mouseX},
                                               $self->{mMQGUI}{mouseY},
                                               1);  # LMB is down.
    }
    else {
        $self->{mMQGUI}{mBetaGUI}->injectMouse($self->{mMQGUI}{mouseX},
                                               $self->{mMQGUI}{mouseY},
                                               0); # LMB is not down.
    }
}


1;


package MouseQueryApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@MouseQueryApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.33 qw(:SceneType);
use Ogre::ColourValue;
use Ogre::Degree;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mMQGUI} = undef;

    return $self;
}

sub chooseSceneManager {
    my ($self) = @_;
    $self->{mSceneMgr} = $self->{mRoot}->createSceneManager(ST_EXTERIOR_CLOSE);
}

sub createScene {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    # ambient light
    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.5, 0.5, 0.5));
    $scenemgr->setSkyDome(1, "Examples/CloudySky", 5, 8);

    # terrain
    $scenemgr->setWorldGeometry($self->{mResourcePath} . "terrain.cfg");

    # set cam look point
    my $cam = $self->{mCamera};
    $cam->setPosition(40, 100, 580);
    $cam->pitch(Ogre::Degree->new(-30));
    $cam->yaw(Ogre::Degree->new(-45));

    $self->{mMQGUI} = MouseQueryGUI->new();
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = MouseQueryListener->new($self->{mWindow},
                                                      $self->{mCamera},
                                                      $self->{mSceneMgr},
                                                      $self->{mMQGUI});
    $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use MouseQueryApplication;
MouseQueryApplication->new->go();
