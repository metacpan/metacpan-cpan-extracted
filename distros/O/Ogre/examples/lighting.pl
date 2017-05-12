#!/usr/bin/perl
# This is OGRE's sample application "Lighting" in Perl;
# see Samples/Lighting/ in the OGRE distribution.

# note: this example is a bit incomplete
# because I didn't implement the part that was commented out
# in the C++ version, so it doesn't even use the ControllerValue
# or ControllerFunction classes yet...

package LightFlasher;
# implements ControllerValueReal  (ControllerValue<Real>) interface
# N.B. DO NOT INHERIT from ControllerValueReal

use strict;
use warnings;

use Ogre 0.32;
use Ogre::ColourValue;

sub new {
    my ($pkg, $light, $billboard, $maxColour) = @_;

    my $self = bless {
        mLight => $light,
        mBillboard => $billboard,
        mMaxColour => $maxColour,
        intensity => undef,
    }, $pkg;

    return $self;
}

# getValue and setValue are for implementing ControllerValueReal
sub getValue {
    my ($self) = @_;

    return $self->{intensity};
}

sub setValue {
    my ($self, $value) = @_;

    $self->{intensity} = $value;

    my $maxColour = $self->{mMaxColour};
    my $newColour = Ogre::ColourValue->new($maxColour->r * $value,
                                           $maxColour->g * $value,
                                           $maxColour->b * $value);
    $self->{mLight}->setDiffuseColour($newColour);
    $self->{mBillboard}->setColour($newColour);
}

1;


package LightFlasherControllerFunction;
# implements ControllerFunctionReal  (ControllerFunction<Real>) interface
# N.B. DO NOT INHERIT from ControllerFunctionReal

use strict;
use warnings;

use Ogre 0.32 qw(:WaveformType);
use Ogre::WaveformControllerFunction;
# Note: it is OK to inherit from other ControllerFunction classes like here
@LightFlasherControllerFunction::ISA = qw(Ogre::WaveformControllerFunction);


sub new {
    my ($pkg, $wavetype, $frequency, $phase) = @_;

    # all taken care of by base class
    my $super = $pkg->SUPER::new($wavetype, 0, $frequency, $phase, 1, 1);
    my $self = bless $super, $pkg;

    return $self;
}


1;


package LightingListener;

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@LightingListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.32;

sub new {
    # note: mAnimStateList is a global in the C++ sample,
    # but I passed it as an arg here from the app class
    my ($pkg, $win, $cam, $animStateList) = @_;

    my $super = $pkg->SUPER::new($win, $cam);
    my $self = bless $super, $pkg;

    $self->{mAnimStateList} = $animStateList;

    return $self;
}

sub frameStarted {
    my ($self, $evt) = @_;

    return 0 unless $self->SUPER::frameStarted($evt);

    my $deltaT = $evt->timeSinceLastFrame;
    $_->addTime($deltaT) for @{ $self->{mAnimStateList} };

    return 1;
}


1;


package LightingApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@LightingApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.32;
use Ogre::Animation qw(:InterpolationMode);
use Ogre::ColourValue;
use Ogre::Light qw(:LightTypes);
use Ogre::Vector3;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mAnimStateList} = [];   # gets passed to frame listener

    # skip all the declarations done in C++

    return $self;
}

sub createScene {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.1, 0.1, 0.1));
    $scenemgr->setSkyBox(1, "Examples/SpaceSkyBox");

    my $head = $scenemgr->createEntity("head", "ogrehead.mesh");
    $scenemgr->getRootSceneNode->attachObject($head);

    $self->setupTrailLights();
}

sub setupTrailLights {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.5, 0.5, 0.5));
    my $dir = Ogre::Vector3->new(-1, -1, 0.5);
    $dir->normalise();
    my $l = $scenemgr->createLight("light1");
    $l->setType(LT_DIRECTIONAL);
    $l->setDirection($dir);

    # note: instead of calling createMovableObject with a params arg,
    # as the C++ sample does, we call createRibbonTrail plus two methods.
    # At least for now it has to be done that way
    # because of the way the XS is currently implemented
    # (need static_cast<RibbonTrail>, etc., within the XS for createMovableObject)
    my $trail = $scenemgr->createRibbonTrail("1");
    $trail->setNumberOfChains(2);
    $trail->setMaxChainElements(80);

    $trail->setMaterialName("Examples/LightRibbonTrail");
    $trail->setTrailLength(400);

    $scenemgr->getRootSceneNode()->createChildSceneNode()->attachObject($trail);


    # Create 3 nodes for trail to follow
    my $animNode = $scenemgr->getRootSceneNode()->createChildSceneNode();
    $animNode->setPosition(50,30,0);
    my $anim = $scenemgr->createAnimation("an1", 14);
    $anim->setInterpolationMode(IM_SPLINE);

    my $track = $anim->createNodeTrack(1, $animNode);
    my $kf = $track->createNodeKeyFrame(0);
    $kf->setTranslate(Ogre::Vector3->new(50,30,0));
    $kf = $track->createNodeKeyFrame(2);
    $kf->setTranslate(Ogre::Vector3->new(100, -30, 0));
    $kf = $track->createNodeKeyFrame(4);
    $kf->setTranslate(Ogre::Vector3->new(120, -100, 150));
    $kf = $track->createNodeKeyFrame(6);
    $kf->setTranslate(Ogre::Vector3->new(30, -100, 50));
    $kf = $track->createNodeKeyFrame(8);
    $kf->setTranslate(Ogre::Vector3->new(-50, 30, -50));
    $kf = $track->createNodeKeyFrame(10);
    $kf->setTranslate(Ogre::Vector3->new(-150, -20, -100));
    $kf = $track->createNodeKeyFrame(12);
    $kf->setTranslate(Ogre::Vector3->new(-50, -30, 0));
    $kf = $track->createNodeKeyFrame(14);
    $kf->setTranslate(Ogre::Vector3->new(50,30,0));

    my $animState = $scenemgr->createAnimationState("an1");
    $animState->setEnabled(1);
    push @{ $self->{mAnimStateList} }, $animState;

    $trail->setInitialColour(0, 1.0, 0.8, 0);
    $trail->setColourChange(0, 0.5, 0.5, 0.5, 0.5);
    $trail->setInitialWidth(0, 5);
    $trail->addNode($animNode);

    # Add light
    my $l2 = $scenemgr->createLight("l2");
    my $color = $trail->getInitialColour(0);
    $l2->setDiffuseColour($color);
    $animNode->attachObject($l2);

    # Add billboard
    my $bbs = $scenemgr->createBillboardSet("bb", 1);
    # xxx: I didn't add the Vector3 arg version yet
    $bbs->createBillboard(0, 0, 0, $color);
    $bbs->setMaterialName("Examples/Flare");
    $animNode->attachObject($bbs);


    # another animation
    $animNode = $scenemgr->getRootSceneNode()->createChildSceneNode();
    $animNode->setPosition(-50,100,0);
    $anim = $scenemgr->createAnimation("an2", 10);
    $anim->setInterpolationMode(IM_SPLINE);
    $track = $anim->createNodeTrack(1, $animNode);
    $kf = $track->createNodeKeyFrame(0);
    $kf->setTranslate(Ogre::Vector3->new(-50,100,0));
    $kf = $track->createNodeKeyFrame(2);
    $kf->setTranslate(Ogre::Vector3->new(-100, 150, -30));
    $kf = $track->createNodeKeyFrame(4);
    $kf->setTranslate(Ogre::Vector3->new(-200, 0, 40));
    $kf = $track->createNodeKeyFrame(6);
    $kf->setTranslate(Ogre::Vector3->new(0, -150, 70));
    $kf = $track->createNodeKeyFrame(8);
    $kf->setTranslate(Ogre::Vector3->new(50, 0, 30));
    $kf = $track->createNodeKeyFrame(10);
    $kf->setTranslate(Ogre::Vector3->new(-50,100,0));

    $animState = $scenemgr->createAnimationState("an2");
    $animState->setEnabled(1);
    push @{ $self->{mAnimStateList} }, $animState;

    $trail->setInitialColour(1, 0.0, 1.0, 0.4);
    $trail->setColourChange(1, 0.5, 0.5, 0.5, 0.5);
    $trail->setInitialWidth(1, 5);
    $trail->addNode($animNode);


    # Add light
    $l2 = $scenemgr->createLight("l3");
    $l2->setDiffuseColour($trail->getInitialColour(1));
    $animNode->attachObject($l2);

    # Add billboard
    $bbs = $scenemgr->createBillboardSet("bb2", 1);
    $bbs->createBillboard(0, 0, 0, $trail->getInitialColour(1));
    $bbs->setMaterialName("Examples/Flare");
    $animNode->attachObject($bbs);
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = LightingListener->new($self->{mWindow},
                                                    $self->{mCamera},
                                                    $self->{mAnimStateList});
    # $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use LightingApplication;

LightingApplication->new->go();
