#!/usr/bin/perl
# This is OGRE's sample application "SkeletalAnimation" in Perl;
# see Samples/SkeletalAnimation/ in the OGRE distribution.


package SkeletalAnimationFrameListener;

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@SkeletalAnimationFrameListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.30;
use Ogre::Degree;
use Ogre::Quaternion;
use Ogre::Vector3;


sub new {
    # appconf replaces all the global variables
    # that the C++ version used
    my ($pkg, $win, $cam, $appconf) = @_;

    my $super = $pkg->SUPER::new($win, $cam);
    my $self = bless $super, $pkg;

    foreach my $key (keys %$appconf) {
        $self->{$key} = $appconf->{$key};
    }

    $self->{mUP} = Ogre::Vector3->new(0, 1, 0);

    return $self;
}

sub frameStarted {
    my ($self, $evt) = @_;

    return 0 unless $self->SUPER::frameStarted($evt);

    for (my $i = 0; $i < $self->{NUM_JAIQUAS}; $i++) {
        my $inc = $evt->timeSinceLastFrame * $self->{mAnimationSpeed}->[$i];

        if ($self->{mAnimState}->[$i]->getTimePosition + $inc >= $self->{mAnimChop}) {
            # Loop
            # Need to reposition the scene node origin since animation includes translation
            # Calculate as an offset to the end position, rotated by the
            # amount the animation turns the character
            my $scenenode = $self->{mSceneNode}->[$i];
            my $rot = Ogre::Quaternion->new($self->{mAnimationRotation}, $self->{mUP});
            my $snorient = $scenenode->getOrientation;
            my $startoffset = $snorient * -$self->{mSneakStartOffset};
            my $endoffset = $self->{mSneakEndOffset};
            my $offset = $rot * $startoffset;
            my $currEnd = $snorient * $endoffset + $scenenode->getPosition;
            $scenenode->setPosition($currEnd + $offset);
            $scenenode->rotate($rot);

            my $timepos = $self->{mAnimState}->[$i]->getTimePosition + $inc - $self->{mAnimChop};
            $self->{mAnimState}->[$i]->setTimePosition($timepos);
        }
        else {
            $self->{mAnimState}->[$i]->addTime($inc);
        }
    }

    return 1;
}


1;


package SkeletalApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@SkeletalApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.30 qw(:ShadowTechnique);

use Ogre::Animation qw(:InterpolationMode :RotationInterpolationMode);
use Ogre::ColourValue;
use Ogre::Light qw(:LightTypes);
use Ogre::Math;
use Ogre::Plane;
use Ogre::Quaternion;
use Ogre::Radian;
use Ogre::ResourceGroupManager qw(:GroupName);
use Ogre::SkeletonManager;
use Ogre::TimeIndex;
use Ogre::Vector3;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{appconf} = {
        mDebugText => '',

        mAnimationSpeed => [],
        mAnimState => [],
        mSneakStartOffset => Ogre::Vector3->new(),
        mSneakEndOffset => Ogre::Vector3->new(),

        mOrientations => [],
        mBasePositions => [],
        mSceneNode => [],
        mAnimationRotation => Ogre::Degree->new(-60),
        mAnimChop => 7.96666,
        mAnimChopBlend => 0.3,

        NUM_JAIQUAS => 6,
    };

    return $self;
}

sub createScene {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    $scenemgr->setShadowTechnique(SHADOWTYPE_TEXTURE_MODULATIVE);
    $scenemgr->setShadowTextureSize(512);
    $scenemgr->setShadowColour(Ogre::ColourValue->new(0.6, 0.6, 0.6));

    # Setup animation default
    Ogre::Animation->setDefaultInterpolationMode(IM_LINEAR);
    Ogre::Animation->setDefaultRotationInterpolationMode(RIM_LINEAR);

    # ambient light
    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.5, 0.5, 0.5));

    # The jaiqua sneak animation doesn't loop properly, so lets hack it so it does
    # We want to copy the initial keyframes of all bones, but alter the Spineroot
    # to give it an offset of where the animation ends

    my $skelmgr = Ogre::SkeletonManager->getSingletonPtr;
    my $skel = $skelmgr->load("jaiqua.skeleton", DEFAULT_RESOURCE_GROUP_NAME);
    my $anim = $skel->getAnimation("Sneak");

    # Note: getNodeTrackAref replaces getNodeTrackIterator
    foreach my $track (@{ $anim->getNodeTrackAref }) {
        # Note: C++ API passes in pointer for 2nd arg to fish out the KeyFrame,
        # but the Perl interface just returns it instead
        my $oldKf = $track->getInterpolatedKeyFrame(Ogre::TimeIndex->new($self->{appconf}{mAnimChop}));

        # Drop all keyframes after the chop
        while ($track->getKeyFrame($track->getNumKeyFrames - 1)->getTime >= $self->{appconf}{mAnimChop} - $self->{appconf}{mAnimChopBlend}) {
            $track->removeKeyFrame($track->getNumKeyFrames - 1);
        }

        my $newKf = $track->createNodeKeyFrame($self->{appconf}{mAnimChop});

        my $startKf = $track->getNodeKeyFrame(0);

        my $bone = $skel->getBone($track->getHandle);
        if ($bone->getName eq "Spineroot") {
            $self->{appconf}{mSneakStartOffset} = $startKf->getTranslate + $bone->getInitialPosition;
            $self->{appconf}{mSneakEndOffset} = $oldKf->getTranslate + $bone->getInitialPosition;
            $self->{appconf}{mSneakStartOffset}->setY($self->{appconf}{mSneakEndOffset}->y);

            # Adjust spine root relative to new location
            $newKf->setRotation($oldKf->getRotation);
            $newKf->setTranslate($oldKf->getTranslate);
            $newKf->setScale($oldKf->getScale);
        }
        else {
            $newKf->setRotation($startKf->getRotation);
            $newKf->setTranslate($startKf->getTranslate);
            $newKf->setScale($startKf->getScale);
        }
    }


    my $rotInc = Ogre::Math->TWO_PI / $self->{appconf}{NUM_JAIQUAS};
    my $rot = 0.0;

    my $ent;

    for (my $i = 0; $i < $self->{appconf}{NUM_JAIQUAS}; $i++) {
        my $q = Ogre::Quaternion->new();    # quaternion ==> rotation
        $q->FromAngleAxis(Ogre::Radian->new($rot), Ogre::Vector3->new(0, 1, 0));
        $self->{appconf}{mOrientations}->[$i] = $q;
        $self->{appconf}{mBasePositions}->[$i] = $q * Ogre::Vector3->new(0, 0, -20);

        $ent = $scenemgr->createEntity("jaiqua$i", "jaiqua.mesh");
        $self->{appconf}{mSceneNode}->[$i] = $scenemgr->getRootSceneNode->createChildSceneNode();
        $self->{appconf}{mSceneNode}->[$i]->attachObject($ent);
        $self->{appconf}{mSceneNode}->[$i]->rotate($q);
        $self->{appconf}{mSceneNode}->[$i]->translate($self->{appconf}{mBasePositions}->[$i]);

        $self->{appconf}{mAnimState}->[$i] = $ent->getAnimationState("Sneak");
        $self->{appconf}{mAnimState}->[$i]->setEnabled(1);
        $self->{appconf}{mAnimState}->[$i]->setLoop(0);   # manual loop since translation involved
        $self->{appconf}{mAnimationSpeed}->[$i] = Ogre::Math->RangeRandom(0.5, 1.5);

        $rot += $rotInc;
    }

    # Give it a little ambience with lights
    my $l = $scenemgr->createLight("BlueLight");
    $l->setType(LT_SPOTLIGHT);
    $l->setPosition(-200, 150, -100);
    # xxx : need to do 'neg' overload for Vector3 ?
    my $dir = - $l->getPosition();
    $dir->normalise();
    $l->setDirection($dir);
    $l->setDiffuseColour(0.5, 0.5, 1.0);

    $l = $scenemgr->createLight("GreenLight");
    $l->setType(LT_SPOTLIGHT);
    $l->setPosition(0, 150, -100);
    # xxx : need to do 'neg' overload for Vector3 ?
    $dir = - $l->getPosition();
    $dir->normalise();
    $l->setDirection($dir);
    $l->setDiffuseColour(0.5, 1.0, 0.5);

    # position the camera
    $self->{mCamera}->setPosition(100, 20, 0);
    $self->{mCamera}->lookAt(0, 10, 0);

    # Report whether hardware skinning is enabled or not
    my $t = $ent->getSubEntity(0)->getMaterial->getBestTechnique;
    my $p = $t->getPass(0);

    if ($p->hasVertexProgram && $p->getVertexProgram->isSkeletalAnimationIncluded) {
        $self->{appconf}{mDebugText} = "Hardware skinning is enabled";
    }
    else {
        $self->{appconf}{mDebugText} = "Software skinning is enabled";
    }

    my $plane = Ogre::Plane->new();
    $plane->setNormal(Ogre::Vector3->new(0, 1, 0));
    $plane->setD(100);

    my $meshmgr = Ogre::MeshManager->getSingletonPtr();
    $meshmgr->createPlane("Myplane",
                          DEFAULT_RESOURCE_GROUP_NAME, $plane,
                          1500, 1500, 20, 20, 1, 1, 60, 60,
                          Ogre::Vector3->new(0, 0, 1));

    my $pPlaneEnt = $scenemgr->createEntity("plane", "Myplane");
    $pPlaneEnt->setMaterialName("Examples/Rockwall");
    $pPlaneEnt->setCastShadows(0);
    my $kidnode = $scenemgr->getRootSceneNode->createChildSceneNode(Ogre::Vector3->new(0, 99, 0));
    $kidnode->attachObject($pPlaneEnt);
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = SkeletalAnimationFrameListener->new($self->{mWindow},
                                                       $self->{mCamera},
                                                       $self->{appconf});
    # $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use SkeletalApplication;

SkeletalApplication->new->go();
