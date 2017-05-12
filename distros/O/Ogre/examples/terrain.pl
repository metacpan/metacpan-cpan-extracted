#!/usr/bin/perl
# This is OGRE's sample application "Terrain" in Perl;
# see Samples/Terrain/ in the OGRE distribution.


package TerrainFrameListener;

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@TerrainFrameListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.29;
use Ogre::Ray;
use Ogre::Vector3;

sub new {
    my ($pkg, $win, $cam, $rsq) = @_;

    my $super = $pkg->SUPER::new($win, $cam);
    my $self = bless $super, $pkg;

    # this is the global raySceneQuery in the C++ app
    $self->{mRaySceneQuery} = $rsq;

    $self->{mMoveSpeed} = 50;

    # this is the static Ray in the C++ app
    $self->{mUpdateRay} = Ogre::Ray->new();

    $self->{mDOWN} = Ogre::Vector3->new(0, -1, 0);

    return $self;
}

sub frameStarted {
    my ($self, $evt) = @_;

    return 0 unless $self->SUPER::frameStarted($evt);

    # clamp to terrain

    $self->{mUpdateRay}->setOrigin($self->{mCamera}->getPosition);
    $self->{mUpdateRay}->setDirection($self->{mDOWN});
    $self->{mRaySceneQuery}->setRay($self->{mUpdateRay});

    my $qryResult = $self->{mRaySceneQuery}->execute();

    foreach my $entry (@$qryResult) {
        next unless defined $entry->{worldFragment};

        my $cam = $self->{mCamera};
        my $campos = $cam->getPosition;

        my $ground_y = $entry->{worldFragment}->singleIntersection->y;
        $cam->setPosition($campos->x, $ground_y + 10, $campos->z);
    }

    return 1;
}


1;


package TerrainApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@TerrainApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.29 qw(:Capabilities :FogMode);
use Ogre::ColourValue;
use Ogre::Plane;
use Ogre::Quaternion;
use Ogre::Ray;
use Ogre::Vector3;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mRaySceneQuery} = undef;

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    delete $self->{mRaySceneQuery} if defined $self->{mRaySceneQuery};
}

sub chooseSceneManager {
    my ($self) = @_;
    $self->{mSceneMgr} = $self->{mRoot}->createSceneManager("TerrainSceneManager");
}

sub createCamera {
    my ($self) = @_;
    my $cam = $self->{mSceneMgr}->createCamera("PlayerCam");

    $cam->setPosition(Ogre::Vector3->new(128, 25, 128));
    $cam->lookAt(Ogre::Vector3->new(0, 0, -300));
    $cam->setNearClipDistance(1);
    $cam->setFarClipDistance(1000);

    $self->{mCamera} = $cam;
}

sub createScene {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    # ambient light
    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.5, 0.5, 0.5));

    # point light
    my $light = $scenemgr->createLight("MainLight");
    $light->setPosition(20, 80, 50);

    # Fog
    # NB it's VERY important to set this before calling setWorldGeometry 
    # because the vertex program picked will be different
    my $fadeColour = Ogre::ColourValue->new(0.93, 0.86, 0.76);
    $scenemgr->setFog(FOG_LINEAR, $fadeColour, 0.001, 500, 1000);

    $self->{mWindow}->getViewport(0)->setBackgroundColour($fadeColour);

    # terrain
    $scenemgr->setWorldGeometry($self->{mResourcePath} . "terrain.cfg");

    if ($self->{mRoot}->getRenderSystem->getCapabilities->hasCapability(RSC_INFINITE_FAR_PLANE)) {
        $self->{mCamera}->setFarClipDistance(0);
    }

    my $plane = Ogre::Plane->new();
    $plane->setD(5000);
    $plane->setNormal(- Ogre::Vector3->new(0, 1, 0));

    my $cam = $self->{mCamera};
    $cam->setPosition(707, 2500, 528);
    $cam->setOrientation(Ogre::Quaternion->new(-0.3486, 0.0122, 0.9365, 0.0329));

    my $ray = Ogre::Ray->new($cam->getPosition, Ogre::Vector3->new(0, -1, 0));
    $self->{mRaySceneQuery} = $scenemgr->createRayQuery($ray);
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = TerrainFrameListener->new($self->{mWindow},
                                                        $self->{mCamera},
                                                        $self->{mRaySceneQuery});
    # $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use TerrainApplication;

TerrainApplication->new->go();
