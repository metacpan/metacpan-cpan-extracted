#!/usr/bin/perl
# This is OGRE's sample application "CameraTrack" in Perl;
# see Samples/CameraTrack/ in the OGRE distribution.


package CameraTrackListener;

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@CameraTrackListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.29;

sub new {
    # note: "mAnimState" is a global variable in the C++ version,
    # but I moved it into the App package
    my ($pkg, $win, $cam, $animstate) = @_;

    my $super = $pkg->SUPER::new($win, $cam);
    my $self = bless $super, $pkg;
    $self->{mAnimState} = $animstate;

    return $self;
}

sub frameStarted {
    my ($self, $evt) = @_;

    return 0 unless $self->SUPER::frameStarted($evt);

    $self->{mAnimState}->addTime($evt->timeSinceLastFrame);

    return 1;
}


1;


package CameraTrackApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@CameraTrackApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.29 qw(:FogMode);
use Ogre::Animation qw(:InterpolationMode);
use Ogre::ColourValue;
use Ogre::Plane;
use Ogre::ResourceGroupManager qw(:GroupName);
use Ogre::Vector3;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    return $self;
}

sub createScene {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    # ambient light
    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.2, 0.2, 0.2));

    # sky dome
    $scenemgr->setSkyDome(1, "Examples/CloudySky", 5, 8);

    # create a light (defaults: point light, white diffuse)
    my $light = $scenemgr->createLight("MainLight");
    $light->setPosition(20, 80, 50);

    # floor plane mesh
    my $plane = Ogre::Plane->new();
    $plane->setNormal(Ogre::Vector3->new(0, 1, 0));
    $plane->setD(200);
    my $meshmgr = Ogre::MeshManager->getSingletonPtr();
    $meshmgr->createPlane("FloorPlane",
                          DEFAULT_RESOURCE_GROUP_NAME,
                          $plane,
                          200000, 200000, 20, 20, 1, 1, 50, 50,
                          Ogre::Vector3->new(0, 0, 1));

    # create floor entity
    my $ent = $scenemgr->createEntity("floor", "FloorPlane");
    $ent->setMaterialName("Examples/RustySteel");
    # Attach to child of root node, better for culling (otherwise bounds are the combination of the 2)
    $scenemgr->getRootSceneNode->createChildSceneNode->attachObject($ent);

    # add a head
    my $headnode = $scenemgr->getRootSceneNode->createChildSceneNode();
    my $ent = $scenemgr->createEntity("head", "ogrehead.mesh");
    $headnode->attachObject($ent);

    # make camera track head
    $self->{mCamera}->setAutoTracking(1, $headnode);

    # create cam node and attach cam
    my $camnode = $scenemgr->getRootSceneNode->createChildSceneNode();
    $camnode->attachObject($self->{mCamera});

    # set up spline animation of node
    my $anim = $scenemgr->createAnimation("CameraTrack", 10);
    # spline it for nice curves
    $anim->setInterpolationMode(IM_SPLINE);

    # Create a track to animate the camera's node
    my $track = $anim->createNodeTrack(0, $camnode);

    # set up keyframes
    my $key = $track->createNodeKeyFrame(0);
    $key = $track->createNodeKeyFrame(2.5);
    $key->setTranslate(Ogre::Vector3->new(500, 500, -1000));
    $key = $track->createNodeKeyFrame(5);
    $key->setTranslate(Ogre::Vector3->new(-1500, 1000, -600));
    $key = $track->createNodeKeyFrame(7.5);
    $key->setTranslate(Ogre::Vector3->new(0, -100, 0));
    $key = $track->createNodeKeyFrame(10);
    $key->setTranslate(Ogre::Vector3->new(0, 0, 0));

    # Create a new animation state to track this
    $self->{mAnimState} = $scenemgr->createAnimationState("CameraTrack");
    $self->{mAnimState}->setEnabled(1);

    # Put in a bit of fog for the hell of it
    $scenemgr->setFog(FOG_EXP, Ogre::ColourValue->new(), 0.0002);
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = CameraTrackListener->new($self->{mWindow},
                                                       $self->{mCamera},
                                                       $self->{mAnimState});
    $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use CameraTrackApplication;

CameraTrackApplication->new->go();
