#!/usr/bin/perl
# This is OGRE's "Basic Tutorial 3", but in Perl.
# Read that tutorial.
# Note: in createScene, I made it where you can set
# $fog and $sky parameters.


package TutorialApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@TutorialApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.27 qw(:SceneType :FogMode);
use Ogre::ColourValue;
use Ogre::Plane;
use Ogre::ResourceGroupManager qw(:GroupName);
use Ogre::SceneManager;
use Ogre::Quaternion;
use Ogre::Vector3;


sub chooseSceneManager {
    my ($self) = @_;
    $self->{mSceneMgr} = $self->{mRoot}->createSceneManager(ST_EXTERIOR_CLOSE,
                                                            "Tute3");
}

sub createScene {
    my ($self) = @_;
    my $mgr = $self->{mSceneMgr};

    # select which fog you want to use
    my $fog = 'exp';
    my $darkfog = 1;

    if ($fog) {
        my $fadeColour = $darkfog
          ? Ogre::ColourValue->new(0.1, 0.1, 0.1)
          : Ogre::ColourValue->new(0.9, 0.9, 0.9);
        $self->{mWindow}->getViewport(0)->setBackgroundColour($fadeColour);

        if ($fog eq 'linear') {
            if ($darkfog) {
                $mgr->g(FOG_LINEAR, $fadeColour, 0.0, 10, 150);
            }
            else {
                $mgr->setFog(FOG_LINEAR, $fadeColour, 0.0, 50, 500);
            }
        }
        elsif ($fog eq 'exp') {
            $mgr->setFog(FOG_EXP, $fadeColour, 0.005);
        }
        elsif ($fog eq 'exp2') {
            $mgr->setFog(FOG_EXP2, $fadeColour, 0.003);
        }
    }


    # load the terrain (do this after setFog)
    $mgr->setWorldGeometry("terrain.cfg");


    # select which scene you want to show
    my $sky = 'plane';

    # (note: unfortunately for now all the args are required to these setSky* methods)
    if ($sky eq 'box') {
        $mgr->setSkyBox(1, "Examples/SpaceSkyBox", 5000, 0,
                        Ogre::Quaternion->new(1, 0, 0, 0),
                        DEFAULT_RESOURCE_GROUP_NAME
                    );
    }

    elsif ($sky eq 'dome') {
        $mgr->setSkyDome(1, "Examples/CloudySky", 5, 8, 4000, 1,
                         Ogre::Quaternion->new(1, 0, 0, 0),
                         16, 16, -1,
                         DEFAULT_RESOURCE_GROUP_NAME
                     );
    }
    elsif ($sky eq 'plane') {
        my $plane = Ogre::Plane->new();
        # Note: Ogre::Plane->new(Ogre::Vector3->new(0, -1, 0), 10)
        # is not the same!
        $plane->setD($darkfog ? 10 : 1000);
        $plane->setNormal(Ogre::Vector3->new(0, -1, 0));

        # annoying here that last arg is required
        $mgr->setSkyPlane(1, $plane, "Examples/SpaceSkyPlane", ($darkfog ? 100 : 1500),
                          45, 1, 0.5, 150, 150,
                          DEFAULT_RESOURCE_GROUP_NAME);
    }
}


1;


package main;

# uncomment this if the packages are in separate files:
# use TutorialApplication;

TutorialApplication->new->go();
