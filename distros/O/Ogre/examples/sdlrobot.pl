#!/usr/bin/perl

use strict;
use warnings;

use Time::HiRes qw/time usleep/;

use Ogre 0.38 qw(:SceneType);
use Ogre::ConfigFile;
use Ogre::ColourValue;
use Ogre::Light qw(:LightTypes);
use Ogre::Root;
use Ogre::ResourceGroupManager;
use Ogre::RenderWindow;
use Ogre::TextureManager;

use SDL;
use SDL::Event;
use SDL::App;

my ($W, $H, $D) = (1024, 768, 0);


main();
exit;


# http://www.ogre3d.org/wiki/index.php/Hello_World_with_minimal_Ogre_init
# http://www.ogre3d.org/wiki/index.php/Using_SDL_Input#New.2C_Experimental_Way_.28OGRE_v1.6_and_Later.29
sub main {
    my $app = SDL::App->new(
        '-title'            => 'Ogre on SDL',
        '-width'            => $W,
        '-height'           => $H,
        '-depth'            => $D,
        '-opengl'           => 1,
        #'-double_buffer'    => 1,
    );

    my $root = Ogre::Root->new('plugins.cfg', 'ogre.cfg', 'Ogre.log');
    defineResources();
    setupRenderSystem($root);

    $root->initialise(0);               # tell Ogre not to make an OpenGL window

    # this is how it works on Linux, at least -
    # will need some work on Windows
    my $renderwindow = $root->createRenderWindow(
        'OgreRenderWindow', $W, $H, 0,
        {currentGLContext => 'True'},   # tell Ogre to use the SDL OpenGL context
    );

    Ogre::ResourceGroupManager->getSingletonPtr->initialiseAllResourceGroups();
    $renderwindow->setVisible(1);

    my $cam = setupScene($root, $renderwindow);
    moveCamPos($cam, 200);

    #my $framelistener = createFrameListener($root, $renderwindow, $cam);


    # $app->grab_input(....);

    mainLoop($root, $renderwindow, $cam);
}

sub mainLoop {
    my ($root, $renderwindow, $cam) = @_;

    my $event = SDL::Event->new();

    my $done = 0;
    GAMELOOP: while (!$done) {
        sync_to(1);
        $event->pump();

        while ($event->poll()) {
            if (($event->type == SDL_QUIT) || ($event->key_sym eq SDLK_q)) {
                $done = 1;
                last;
            }
            if ($event->key_sym == SDLK_RIGHT) {
                moveCamPos($cam, 200);
            }
            elsif ($event->key_sym == SDLK_LEFT) {
                moveCamPos($cam, -200);
            }
            renderOne($root);
        }

        last GAMELOOP if $done;
    }
}

sub sync_to {
    my $n = shift;

    # xxx: figure out time to sleep
    # my $t = time;

    my $sleep = 100000;
    usleep ($sleep);
}

sub createFrameListener {
    #
}

sub renderOne {
    my ($root) = @_;

    $root->renderOneFrame();            # Ogre renders to the SDL window
#    SDL::GLSwapBuffers();
}

sub moveCamPos {
    my ($cam, $z) = @_;

    $cam->setPosition(0, 0, $z);
    $cam->lookAt(0, 50, 0);
}

sub setupScene {
    my ($root, $renderwindow) = @_;

    my $mgr = $root->createSceneManager(ST_GENERIC, 'Default SceneManager');

    my $cam = $mgr->createCamera('Camera');
    $cam->setNearClipDistance(5);

    my $vp = $renderwindow->addViewport($cam, 0, 0, 0, 1, 1);
    $vp->setBackgroundColour(Ogre::ColourValue->new(0.5, 0.5, 0.5, 1));

    $cam->setAspectRatio($vp->getActualWidth / $vp->getActualHeight);

    $mgr->setAmbientLight(Ogre::ColourValue->new(0.8, 0.7, 0.6, 1));
    my $ent1 = $mgr->createEntity('Robot', 'robot.mesh');
    my $node1 = $mgr->getRootSceneNode()->createChildSceneNode('RobotNode');
    $node1->attachObject($ent1);

    my $light = $mgr->createLight('Light1');
    $light->setType(LT_POINT);
    $light->setPosition(0, 0, 200);
    $light->setDiffuseColour(1.0, 0.0, 0.0);
    $light->setSpecularColour(1.0, 0.0, 0.0);

    return $cam;
}

sub setupRenderSystem {
    my $root = shift;
    if (! $root->restoreConfig() && ! $root->showConfigDialog()) {
        die "User cancelled the config dialog!\n";
    }
}

sub defineResources {
    my $cf = Ogre::ConfigFile->new();
    $cf->load('resources.cfg');

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
