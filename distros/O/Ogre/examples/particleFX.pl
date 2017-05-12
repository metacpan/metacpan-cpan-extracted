#!/usr/bin/perl
# This is OGRE's sample application "ParticleFX" in Perl;
# see Samples/ParticleFX/ in the OGRE distribution.


package ParticleFrameListener;
# Event handler to add ability to alter curvature

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@ParticleFrameListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.29;
use Ogre::Degree;
use Ogre::ParticleSystem;

sub new {
    my ($pkg, $win, $cam, $fountainNode) = @_;

    my $super = $pkg->SUPER::new($win, $cam);
    my $self = bless $super, $pkg;

    $self->{mFountainNode} = $fountainNode;

    return $self;
}

sub frameStarted {
    my ($self, $evt) = @_;

    return 0 unless $self->SUPER::frameStarted($evt);

    # Rotate fountains
    $self->{mFountainNode}->yaw(Ogre::Degree->new($evt->timeSinceLastFrame * 30));

    return 1;
}


1;


package ParticleApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@ParticleApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.29;
use Ogre::ColourValue;
use Ogre::Vector3;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mFountainNode} = undef;

    return $self;
}

# override the mandatory create scene method
sub createScene {
    my ($self) = @_;

    my $scenemgr = $self->{mSceneMgr};

    # ambient light
    $scenemgr->setAmbientLight(Ogre::ColourValue->new(0.5, 0.5, 0.5));

    # ogre head entity
    my $ent = $scenemgr->createEntity("head", "ogrehead.mesh");
    $scenemgr->getRootSceneNode->createChildSceneNode->attachObject($ent);

    # XXX Note: for some reason createParticleSystem by itself was creating
    # a ParticleSystem that was "pre-attached", and this caused
    # $scenenode->attachObject to throw an exception (already attached),
    # so I made a work-around method "createAndAttachParticleSystem"
    # that does the create and attach in one go. I have no idea why
    # that works.....

    # Green nimbus around Ogre
    my $nnode = $scenemgr->getRootSceneNode->createChildSceneNode();
    $scenemgr->createAndAttachParticleSystem("Nimbus", "Examples/GreenyNimbus", $nnode);

    # fireworks!
    my $fwnode = $scenemgr->getRootSceneNode->createChildSceneNode();
    $scenemgr->createAndAttachParticleSystem("Fireworks", "Examples/Fireworks", $fwnode);

    # shared node for 2 fountains
    $self->{mFountainNode} = $scenemgr->getRootSceneNode->createChildSceneNode();

    # fountain 1
    my $fnode = $self->{mFountainNode}->createChildSceneNode();
    $fnode->translate(200, -100, 0);
    $fnode->rotate(Ogre::Vector3->new(0, 0, 1), Ogre::Degree->new(20));
    $scenemgr->createAndAttachParticleSystem("fountain1", "Examples/PurpleFountain", $fnode);

    # fountain 2
    $fnode = $self->{mFountainNode}->createChildSceneNode();
    $fnode->translate(-200, -100, 0);
    $fnode->rotate(Ogre::Vector3->new(0, 0, 1), Ogre::Degree->new(-20));
    $scenemgr->createAndAttachParticleSystem("fountain2", "Examples/PurpleFountain", $fnode);

    # rain
    my $rnode = $scenemgr->getRootSceneNode->createChildSceneNode();
    $rnode->translate(0, 1000, 0);
    $scenemgr->createAndAttachParticleSystem("rain", "Examples/Rain", $rnode);
    # xxx: this idiocy is also a result of the createParticleSystem problem
    # explained above
    my $psys4 = $scenemgr->getParticleSystem("rain");
    $psys4->fastForward(5);    # so it looks more natural

    # aureola around ogre perpendicular to ground
    my $anode = $scenemgr->getRootSceneNode->createChildSceneNode();
    $scenemgr->createAndAttachParticleSystem("Aureola", "Examples/Aureola", $anode);

    Ogre::ParticleSystem->setDefaultNonVisibleUpdateTimeout(5);
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = ParticleFrameListener->new($self->{mWindow},
                                                       $self->{mCamera},
                                                       $self->{mFountainNode});
    # $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use ParticleApplication;

ParticleApplication->new->go();
