#!/usr/bin/perl
# This example builds on robot.pl.
# Instead of showing the robot, it shows the ninja
# from the basic OGRE tutorials. And I must add,
# he's looking BADASS in the colored spotlight.
# In addition, this example relies on OIS (which I also wrapped
# and put on CPAN) to handle keyboard input.
# I didn't wrap Ogre::FrameListener yet, though,
# so the input handling is primitive and awkward for now.
# (This is basically OGRE's Basic Tutorial 6,
#  with setupCEGUI(), createFrameListener(), and ExitListener removed,
#  and the ninja and lighting from Basic Tutorial 2.)

use strict;
use warnings;

main();
exit(0);

sub main {
    my $app = Application->new();
    $app->go();
}


package Application;

use Ogre 0.27 qw(:SceneType :ShadowTechnique);
use Ogre::ConfigFile;
use Ogre::ColourValue;
use Ogre::Degree;
use Ogre::Light qw(:LightTypes);
use Ogre::Node qw(:TransformSpace);
use Ogre::Plane;
use Ogre::Root;
use Ogre::ResourceGroupManager qw(:GroupName);
use Ogre::SceneManager;
use Ogre::Vector3;

use OIS;
use OIS::InputManager;
use OIS::Keyboard qw(:KeyCode);

use Time::HiRes qw(usleep);


sub new {
    my ($pkg, %args) = @_;
    my $self = bless {
        'root' => undef,
        'keyboard' => undef,
        'inputManager' => undef,
    }, $pkg;
    return $self;
}

sub DESTROY {
    my ($self) = @_;

    if (defined($self->{inputManager})) {
        $self->{inputManager}->destroyInputObject($self->{keyboard})
          if defined($self->{keyboard});
        OIS::InputManager->destroyInputSystem($self->{inputManager});
    }

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
    $self->setupInputSystem();
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
    $cam->setPosition(400, 150, 150);
    $cam->lookAt(0, 50, 0);
    $cam->setNearClipDistance(5);

    # xxx: annoying, in the C++ API all args after $cam are optional
    my $vp = $root->getAutoCreatedWindow()->addViewport($cam, 0, 0, 0, 1, 1);
    # xxx: annoying, C++ API has all values optional for ColourValue
    $vp->setBackgroundColour(Ogre::ColourValue->new(0.5, 0.5, 0.5, 1));

    $cam->setAspectRatio($vp->getActualWidth / $vp->getActualHeight);

    $mgr->setAmbientLight(Ogre::ColourValue->new(0, 0, 0, 1));
    $mgr->setShadowTechnique(SHADOWTYPE_STENCIL_ADDITIVE);

    # note: more meshes are in Samples/Media/models/ ,
    # though obviously none as cool as the ninja
    my $ent = $mgr->createEntity("Ninja", "ninja.mesh");
    $ent->setCastShadows(1);
    my $node1 = $mgr->getRootSceneNode()->createChildSceneNode("NinjaNode");
    $node1->attachObject($ent);

    my $plane = Ogre::Plane->new(Ogre::Vector3->new(0, 1, 0), 0);
    my $meshmgr = Ogre::MeshManager->getSingletonPtr();
    $meshmgr->createPlane("ground",
                          DEFAULT_RESOURCE_GROUP_NAME,
                          $plane, 1500, 1500, 20, 20, 1, 1, 5, 5,
                          Ogre::Vector3->new(0, 0, 1));
    $ent = $mgr->createEntity("GroundEntity", "ground");
    $mgr->getRootSceneNode()->createChildSceneNode("GroundNode")->attachObject($ent);
    $ent->setMaterialName("Examples/Rockwall");
    $ent->setCastShadows(0);

    # xxx: annoying, C++ API has "relativeTo" value optional
    # xxx: also have to use Degree instead of Radian
    $node1->yaw(Ogre::Degree->new(-150), TS_LOCAL);
    $node1->pitch(Ogre::Degree->new(-10), TS_LOCAL);

    my $light = $mgr->createLight("Light1");
    $light->setType(LT_POINT);
    $light->setPosition(0, 150, 250);
    $light->setDiffuseColour(1.0, 0.0, 0.0);
    $light->setSpecularColour(1.0, 0.0, 0.0);

    $light = $mgr->createLight("Light3");
    $light->setType(LT_DIRECTIONAL);
    $light->setDiffuseColour(0.25, 0.25, 0.0);
    $light->setSpecularColour(0.25, 0.25, 0.0);
    $light->setDirection(0, -1, 1);

    $light = $mgr->createLight("Light2");
    $light->setType(LT_SPOTLIGHT);
    $light->setDiffuseColour(0, 0, 1);
    $light->setSpecularColour(0, 0, 1);
    $light->setDirection(-1, -1, 0);
    $light->setPosition(300, 300, 0);
    # xxx: again, sorry only Degree for now (no Radian)
    $light->setSpotlightRange(Ogre::Degree->new(35), Ogre::Degree->new(50));
}

sub setupInputSystem {
    my ($self) = @_;

    # this part is a little abbreviated from tutorial 6,
    # see the "Using OIS" tutorial
    my $win = $self->{root}->getAutoCreatedWindow();
    my $windowHnd = $win->getCustomAttributePtr('WINDOW');
    $self->{inputManager} = OIS::InputManager->createInputSystemPtr($windowHnd);

    $self->{keyboard} = $self->{inputManager}->createInputObjectKeyboard(0);
}

sub startRenderLoop {
    my ($self) = @_;

    my $root = $self->{root};
    my $win = $root->getAutoCreatedWindow();
    my $keyboard = $self->{keyboard};
    my $esc = &KC_ESCAPE;

    # I do it this way just to avoid implementing FrameListener,
    # which I haven't wrapped yet (normally you do $root->startRendering()).
    while ($root->renderOneFrame()) {
        $keyboard->capture();
        last if $keyboard->isKeyDown($esc);

        # xxx: I don't understand why this is necessary,
        # I thought all render targets were automatically
        # updated by renderOneFrame. Oh, well.
        $win->update();

        # I just added this to take some heat off the processor.
        # Comment it out if you want higher FPS. :)
        # It's maybe interesting to note that I get about 300FPS,
        # while "Basic Tutorial 2" in C++ runs at about 350FPS;
        # although the tutorial does have a bit of extra with CEGUI
        # (on the *other* other hand, this isn't using startRendering),
        # it's still not too shabby for Perl, eh?
        usleep 10000;
    }
}


1;
