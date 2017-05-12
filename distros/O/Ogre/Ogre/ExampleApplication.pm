package Ogre::ExampleApplication;

use strict;
use warnings;

use Ogre 0.27 qw(:SceneType);
use Ogre::ColourValue;
use Ogre::Root;
use Ogre::SceneManager;
use Ogre::ResourceGroupManager;
use Ogre::TextureManager;

use Ogre::ExampleFrameListener;

sub new {
    my ($pkg) = @_;

    my $self = bless {
        mFrameListener => undef,
        mRoot          => undef,
        mResourcePath  => '',
        mCamera        => undef,
        mSceneMgr      => undef,
        mWindow        => undef,
    }, $pkg;

    # if OGRE_PLATFORM == OGRE_PLATFORM_APPLE
    # $self->mResourcePath = macBundlePath() + "/Contents/Resources/";

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    # not sure this is right..
    if ($self->{mFrameListener}) {
        delete $self->{mFrameListener};
    }
    if ($self->{mRoot}) {
        delete $self->{mRoot};
    }
}

# XXX:
# This function will locate the path to our application on OS X,
# unlike windows you can not rely on the curent working directory
# for locating your configuration files and resources.
# (note: this is a FUNCTION, not a method)
sub macBundlePath {
    # xxx: ExampleApplication.h contains a function macBundlePath
    # which gets the full path for mResourcePath (it says OS X must
    # be given a full path, not relative). That needs to be implemented
    # (presumably in Perl, though).
    # I'm not sure if all platforms can take a full path;
    # assuming so, it'll be easy enough, but otherwise I'll also
    # have to get the OGRE_PLATFORM, OGRE_PLATFORM_APPLE #defines

    return '';
}

sub go {
    my ($self) = @_;

    return unless $self->setup();

    $self->{mRoot}->startRendering();
    $self->destroyScene();
}

# These internal methods package up the stages in the startup process

# Sets up the application - returns false if the user chooses to abandon configuration.
sub setup {
    my ($self) = @_;

    $self->{mRoot} = Ogre::Root->new($self->{mResourcePath} . 'plugins.cfg',
                                     $self->{mResourcePath} . 'ogre.cfg',
                                     $self->{mResourcePath} . 'Ogre.log');

    $self->setupResources();

    return 0 unless $self->configure();

    $self->chooseSceneManager();
    $self->createCamera();
    $self->createViewports();

    # Set default mipmap level (NB some APIs ignore this)
    Ogre::TextureManager->getSingletonPtr->setDefaultNumMipmaps(5);

    # Create any resource listeners (for loading screens)
    $self->createResourceListener();

    $self->loadResources();
    $self->createScene();
    $self->createFrameListener();

    return 1;
}

# Configures the application - returns false if the user chooses to abandon configuration.
sub configure {
    my ($self) = @_;

    # Show the configuration dialog and initialise the system
    # You can skip this and use root.restoreConfig() to load configuration
    # settings if you were sure there are valid ones saved in ogre.cfg
    if ($self->{mRoot}->showConfigDialog()) {
        # If returned true, user clicked OK so initialise
        # Here we choose to let the system create a default rendering window by passing 'true'
        $self->{mWindow} = $self->{mRoot}->initialise(1, "OGRE Render Window");
        return 1;
    }
    else {
        return 0;
    }
}

sub chooseSceneManager {
    my ($self) = @_;

    # Create the SceneManager, in this case a generic one
    $self->{mSceneMgr} = $self->{mRoot}->createSceneManager(ST_GENERIC,
                                                            "ExampleSMInstance");
}

sub createCamera {
    my ($self) = @_;

    # Create the camera
    $self->{mCamera} = $self->{mSceneMgr}->createCamera("PlayerCam");

    # Position it at 500 in Z direction
    $self->{mCamera}->setPosition(0, 0, 500);

    # Look back along -Z
    $self->{mCamera}->lookAt(0, 0, -300);
    $self->{mCamera}->setNearClipDistance(5);
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = Ogre::ExampleFrameListener->new($self->{mWindow},
                                                              $self->{mCamera});
    $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}

sub createScene {
    die "implement createScene!\n";
}

sub destroyScene { }

sub createViewports {
    my ($self) = @_;

    # Create one viewport, entire window
    my $vp = $self->{mWindow}->addViewport($self->{mCamera});
    $vp->setBackgroundColour(Ogre::ColourValue->new(0,0,0));

    # Alter the camera aspect ratio to match the viewport
    $self->{mCamera}->setAspectRatio($vp->getActualWidth() / $vp->getActualHeight());
}

# Method which will define the source of resources (other than current folder)
sub setupResources {
    my ($self) = @_;

    my $cf = Ogre::ConfigFile->new();
    # resources.cfg and its required media files are included in this directory.
    # You may want to change this, and use different media.
    # Look in the source distribution for OGRE under Samples/Media/ .
    $cf->load($self->{mResourcePath} . "resources.cfg");

    # note: this is a Perlish replacement for iterators used in C++
    my $secs = $cf->getSections();

    # moved this outside the for loops
    my $rgm = Ogre::ResourceGroupManager->getSingletonPtr();

    foreach my $sec (@$secs) {
        my $secName = $sec->{name};

        my $settings = $sec->{settings};
        foreach my $setting (@$settings) {
            my ($typeName, $archName) = @$setting;

            # XXX:
            # if OGRE_PLATFORM == OGRE_PLATFORM_APPLE
            # OS X does not set the working directory relative to the app,
            # In order to make things portable on OS X we need to provide
            # the loading with it's own bundle path location
            # $archName = macBundlePath() . "/" . $archName

            $rgm->addResourceLocation($archName, $typeName, $secName);
        }
    }
}

# Optional override method where you can create resource listeners (e.g. for loading screens)
sub createResourceListener { }

# Optional override method where you can perform resource group loading
# Must at least do ResourceGroupManager::getSingleton().initialiseAllResourceGroups();
sub loadResources {
    # Initialise, parse scripts etc
    Ogre::ResourceGroupManager->getSingletonPtr->initialiseAllResourceGroups();
}


1;

__END__
=head1 NAME

Ogre::ExampleApplication

=head1 SYNOPSIS

  package MyApplication;

  use Ogre::ExampleApplication;
  @ISA = qw(Ogre::ExampleApplication);

  # override methods...

=head1 DESCRIPTION

This is a port of OGRE's F<Samples/Common/include/ExampleApplication.h>.
As the name implies, it's an example of how to do things. You can subclass
it to customize it how you want. See the examples referred to in
F<examples/README.txt>.

=head1 AUTHOR

Scott Lanning E<lt>slanning@cpan.orgE<gt>

For licensing information, see README.txt .

=cut
