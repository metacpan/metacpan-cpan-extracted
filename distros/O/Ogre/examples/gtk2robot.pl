#!/usr/bin/perl
# An example of using gtk2-perl with Ogre.
# With this you can create a normal-style GUI app that
# renders to an Ogre widget. This example is basically
# just robot.pl but now displayed in an Ogre widget
# inside a Gtk2::Widget.
#
# Note: this example requires that you have the Gtk2
# Perl module installed.
#
# It combines code ideas from several places:
# - GtkOgre widget by Christian Lindequist Larsen,
#   see http://dword.dk/ .
# - gtk2-perl: apps from the examples directory
#   and snippets from the docs.
# - Also see robot.pl.

use strict;
use warnings;

main();
exit(0);

sub main {
    my $app = App::Robot->new();
    $app->go();
}


package App::Robot;

# Note: this is really sloppy,
# as I just shove both Gtk2 and Ogre stuff
# into one package. It's only meant to be
# a proof of principle.


use Glib qw(:constants);
use Gtk2 -init;

use Ogre 0.28 qw(:SceneType);
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

    $self->createRoot();
    $self->defineResources();
    $self->createGtkWindow();

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    delete $self->{root};
}

sub go {
    my ($self) = @_;

    $self->setupRenderSystem();
    $self->createRenderWindow();

    $self->initializeResourceGroups();
    $self->setupScene();
    $self->startRenderLoop();
}

sub createGtkWindow {
    my ($self) = @_;

    my $window = Gtk2::Window->new('toplevel');
    $window->signal_connect(delete_event => sub {
        Gtk2->main_quit;
        return FALSE;
    });
    $window->set_default_size(600, 400);
    $window->set_title("This is a Gtk2::Window");

    # Note: we have to draw to something that is drawable,
    # and apparently Gtk2::Window isn't when it's at toplevel.
    my $vbox = Gtk2::VBox->new();
    $window->add($vbox);

    # This is just to "prove" that it's actually Gtk2, not Ogre :)
    my $button = Gtk2::Button->new('Quit');
    $button->signal_connect(clicked => sub { Gtk2->main_quit() });
    $vbox->pack_start($button, TRUE, TRUE, 0);

    my $hbox = Gtk2::HBox->new();
    $vbox->pack_end($hbox, TRUE, TRUE, 0);
    my $button2 = Gtk2::Button->new('Dance!');

    $button2->signal_connect(clicked => sub { $self->toggleCameraPosition });
    $hbox->pack_start($button2, TRUE, TRUE, 0);
    $self->{drawbutton} = $button2;

    $window->show_all();

    $self->{window} = $window;
}

sub toggleCameraPosition {
    my ($self) = @_;
    $self->{mCamPos} = ($self->{mCamPos} == 200) ? -200 : 200;
    $self->{mCamera}->setPosition(0, 0, $self->{mCamPos});
    $self->{mCamera}->lookAt(0, 50, 0);
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

    # Note: we don't pass true, which creates a default window;
    # instead we set the render window manually to be the Gtk window
    $self->{root}->initialise(0, "this won't be displayed anyway");

    # Note: we're drawing to a hbox, not the toplevel window.
    # I think it might be wrong, actually, how I implemented getWindowHandleString.
    # The examples I saw online were for custom widgets
    # which get added to Gtk ones, so they get the "parent" window.
    # I don't know if that's generally what we want. (??)

    my $handle = Ogre->getWindowHandleString($self->{drawbutton});

    my $allocation = $self->{drawbutton}->allocation;
    my ($w, $h) = ($allocation->width, $allocation->height);
    $self->{mRenderWindow} =
      $self->{root}->createRenderWindow("OgreRenderWindow",
                                        $w, $h, 0,
                                        {parentWindowHandle => $handle});
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
    $self->{mCamPos} = 200;
    $cam->setPosition(0, 0, $self->{mCamPos});
    $cam->lookAt(0, 50, 0);
    $cam->setNearClipDistance(5);
    $self->{mCamera} = $cam;

    my $vp = $self->{mRenderWindow}->addViewport($cam, 0, 0, 0, 1, 1);
    # xxx: annoying, C++ API has all values optional for ColourValue
    $vp->setBackgroundColour(Ogre::ColourValue->new(0.5, 0.5, 0.5, 1));

    $cam->setAspectRatio($vp->getActualWidth / $vp->getActualHeight);

    $mgr->setAmbientLight(Ogre::ColourValue->new(0.8, 0.7, 0.6, 1));
    my $ent1 = $mgr->createEntity('Robot', 'robot.mesh');
    my $node1 = $mgr->getRootSceneNode()->createChildSceneNode('RobotNode');
    $node1->attachObject($ent1);

    my $light = $mgr->createLight('Light1');
    $light->setType(LT_POINT);
    $light->setPosition(0, 150, 250);
    $light->setDiffuseColour(1.0, 0.0, 0.0);
    $light->setSpecularColour(1.0, 0.0, 0.0);
}

sub update {
    my ($self) = @_;

    #$self->{root}->renderOneFrame();
    $self->{mRenderWindow}->update();

    return 1;    # so Timeout repeats
}

sub startRenderLoop {
    my ($self) = @_;

    # update frame every 0.1 sec (for no reason, really)
    Glib::Timeout->add(100, sub { $_[0]->update() }, $self);
    Gtk2->main();
}


1;
