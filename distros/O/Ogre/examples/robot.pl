#!/usr/bin/perl
# Minimal example showing that the binding "works".
# It just shows the robot from the basic OGRE tutorials,
# a little rotated and scaled.
# (Note: as there is no input handling, you'll have to Ctrl-C
# the application after closing the window.)

use strict;
use warnings;

main();
exit(0);

sub main {
    my $app = App::Robot->new();
    $app->go();
}


package App::Robot;

use Ogre 0.27 qw(:SceneType);
use Ogre::ConfigFile;
use Ogre::ColourValue;
use Ogre::Degree;
use Ogre::Light qw(:LightTypes);
use Ogre::Node qw(:TransformSpace);
use Ogre::Root;
use Ogre::ResourceGroupManager;
use Ogre::SceneManager;

sub new {
    my ($pkg, %args) = @_;
    my $self = bless {}, $pkg;
    return $self;
}

sub DESTROY {
    my ($self) = @_;
    delete $self->{root};
}

sub go {
    my ($self) = @_;

    $self->createRoot();
    $self->defineResources();
    $self->setupRenderSystem();
    $self->createRenderWindow();
    $self->initializeResourceGroups();
    $self->setupScene();
    $self->startRenderLoop();
}

sub createRoot {
    my ($self) = @_;

    # plugins.cfg should symlink to /etc/OGRE/plugins.cfg (at least on Ubuntu)
    # (ogre.cfg and Ogre.log are automatically created by the config dialog)
    $self->{root} = Ogre::Root->new('plugins.cfg', 'ogre.cfg', 'Ogre.log');
}

sub defineResources {
    my ($self) = @_;

    my $cf = Ogre::ConfigFile->new();
    # resources.cfg and its required media files are included in this directory.
    # You may want to change this, and use different media.
    # Look in the source distribution for OGRE under Samples/Media/ .
    $cf->load('resources.cfg');

    # note: this is a Perlish replacement for iterators used in C++
    my $secs = $cf->getSections();

    foreach my $sec (@$secs) {
        my $secname = $sec->{name};

        my $settings = $sec->{settings};
        foreach my $setting (@$settings) {
            my ($typename, $archname) = @$setting;
            # xxx: getSingletonPtr could move outside the foreach loops
            my $rgm = Ogre::ResourceGroupManager->getSingletonPtr();
            $rgm->addResourceLocation($archname, $typename, $secname);
        }
    }
}

sub setupRenderSystem {
    my ($self) = @_;

    my $root = $self->{root};
    if (! $root->restoreConfig() && ! $root->showConfigDialog()) {
        die "User cancelled the config dialog!\n";
    }
}

sub createRenderWindow {
    my ($self) = @_;
    $self->{root}->initialise(1, 'Tutorial Render Window');
}

sub initializeResourceGroups {
    my ($self) = @_;

    my $tm = Ogre::TextureManager->getSingletonPtr();
    $tm->setDefaultNumMipmaps(5);

    my $rgm = Ogre::ResourceGroupManager->getSingletonPtr();
    $rgm->initialiseAllResourceGroups();
}

sub setupScene {
    my ($self) = @_;

    my $root = $self->{root};

    my $mgr = $root->createSceneManager(ST_GENERIC, 'Default SceneManager');

    my $cam = $mgr->createCamera('Camera');
    $cam->setPosition(0, 10, 500);
    $cam->lookAt(0, 0, 0);
    $cam->setNearClipDistance(5);

    my $vp = $root->getAutoCreatedWindow()->addViewport($cam, 0, 0, 0, 1, 1);
    $vp->setBackgroundColour(Ogre::ColourValue->new(0.5, 0.5, 0.5, 1));

    $cam->setAspectRatio($vp->getActualWidth / $vp->getActualHeight);
    $mgr->setAmbientLight(Ogre::ColourValue->new(0.8, 0.7, 0.6, 1));

    my $ent1 = $mgr->createEntity('Robot', 'robot.mesh');
    my $node1 = $mgr->getRootSceneNode()->createChildSceneNode('RobotNode');
    $node1->attachObject($ent1);

    $node1->yaw(Ogre::Degree->new(-90), TS_LOCAL);
    $node1->roll(Ogre::Degree->new(-45), TS_LOCAL);
    $node1->pitch(Ogre::Degree->new(-30), TS_LOCAL);
    $node1->scale(.5, 2, 1);

    my $light = $mgr->createLight('Light1');
    $light->setType(LT_POINT);
    $light->setPosition(0, 150, 250);
    $light->setDiffuseColour(1.0, 0.0, 0.0);
    $light->setSpecularColour(1.0, 0.0, 0.0);
}

sub startRenderLoop {
    my ($self) = @_;
    $self->{root}->startRendering();
}


1;
