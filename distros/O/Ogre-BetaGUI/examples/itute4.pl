#!/usr/bin/perl
# This is OGRE's "Intermediate Tutorial 4" but in Perl
# and using BetaGUI instead of CEGUI.


package DemoGUI;

use strict;
use warnings;

use Ogre::BetaGUI::GUI;
use Ogre::BetaGUI::BetaGUIListener;
@DemoGUI::ISA = qw(Ogre::BetaGUI::BetaGUIListener);

use Ogre 0.37;
use Ogre::ManualObject;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mouseX} = 0;
    $self->{mouseY} = 0;

    $self->{mBetaGUI} = Ogre::BetaGUI::GUI->new("WhoCares", "BlueHighway", 20);
    # note: the C++ version uses Vector2, but we just use array refs
    $self->{mPointer} = $self->{mBetaGUI}->createMousePointer([32,32], "bgui.pointer");

    return $self;
}

sub onButtonPress {
    my ($self, $button, $lmb) = @_;
    # empty...
}


1;


package SelectionRectangle;

use Ogre 0.34 qw(:RenderQueueGroupID);
use Ogre::AxisAlignedBox;
use Ogre::RenderOperation qw(:OperationType);

use Ogre::ManualObject;
@SelectionRectangle::ISA = qw(Ogre::ManualObject);

sub new {
    my ($pkg, $scenemgr, $name) = @_;

    # xxx: cheating a bit here, not subclassing ManualObject,
    # as in the C++ sample where this is instantiated from a SelectionRectangle
    # class that inherits from ManualObject, but it's not currently possible
    # to do that in the Perl version

    my $manobj = $scenemgr->createManualObject($name);
    $manobj->setUseIdentityProjection(1);
    $manobj->setUseIdentityView(1);
    $manobj->setRenderQueueGroup(RENDER_QUEUE_OVERLAY);
    $manobj->setQueryFlags(0);

    my $self = bless $manobj, $pkg;
    return $self;
}

# Sets the corners of the SelectionRectangle.  Every parameter should be in the
# range [0, 1] representing a percentage of the screen the SelectionRectangle
# should take up.
sub setCorners {
    my ($self, $topLeft, $bottomRight) = @_;

    my $left = $topLeft->x;
    my $top = $topLeft->y;
    my $right = $bottomRight->x;
    my $bottom = $bottomRight->y;

    $left = $left * 2 - 1;
    $right = $right * 2 - 1;
    $top = 1 - $top * 2;
    $bottom = 1 - $bottom * 2;

    $self->clear();
    $self->begin("", OT_LINE_STRIP);
    $self->position($left, $top, -1);
    $self->position($right, $top, -1);
    $self->position($right, $bottom, -1);
    $self->position($left, $bottom, -1);
    $self->position($left, $top, -1);
    $self->end();

    my $box = Ogre::AxisAlignedBox->new();
    $box->setInfinite();
    $self->setBoundingBox($box);
}


1;


package DemoListener;
# implements ExampleFrameListener, OIS::MouseListener

use strict;
use warnings;

use Ogre::ExampleFrameListener;
@DemoListener::ISA = qw(Ogre::ExampleFrameListener);

use Ogre 0.34;
use Ogre::Plane;
use Ogre::PlaneBoundedVolume;
use Ogre::Ray;
use Ogre::Vector2;
use Ogre::Vector3;

use OIS 0.04;
use OIS::Mouse;

sub new {
    my ($pkg, $win, $cam, $sceneManager, $gui) = @_;

    my $super = $pkg->SUPER::new($win, $cam, 0, 1);
    my $self = bless $super, $pkg;

    $self->{mSceneMgr} = $sceneManager;
    $self->{mDGUI} = $gui;

    $self->{mRect} = SelectionRectangle->new($sceneManager, "Selection SelectionRectangle");
    $sceneManager->getRootSceneNode->createChildSceneNode->attachObject($self->{mRect});

    $self->{mMouse}->setEventCallback($self);

    $self->{mVolQuery} = $self->{mSceneMgr}->createPlaneBoundedVolumeQuery([]);

    $self->{mStart} = Ogre::Vector2->new();
    $self->{mStop} = Ogre::Vector2->new();
    $self->{mSelecting} = 0;
    $self->{mSelected} = [];

    return $self;
}

# MouseListener callbacks
sub mouseMoved {
    my ($self, $arg) = @_;
    my $state = $arg->state;
    $self->injectMouse($state);

    if ($self->{mSelecting}) {
        $self->{mStop}->setX($self->{mDGUI}{mouseX} / $state->width);
        $self->{mStop}->setY($self->{mDGUI}{mouseY} / $state->height);

        $self->{mRect}->setCorners($self->{mStart}, $self->{mStop});
    }

    return 1;
}

sub mousePressed {
    my ($self, $arg, $id) = @_;
    my $state = $arg->state;

    if ($id == OIS::Mouse->MB_Left) {
        $self->{mStart}->setX($self->{mDGUI}{mouseX} / $state->width);
        $self->{mStart}->setY($self->{mDGUI}{mouseY} / $state->height);

        # xxx: $self->{mStop} = $self->{mStart};
        $self->{mStop}->setX($self->{mStart}->x);
        $self->{mStop}->setY($self->{mStart}->y);

        $self->{mSelecting} = 1;
        $self->{mRect}->clear();
        $self->{mRect}->setVisible(1);
    }

    return 1;
}

sub mouseReleased {
    my ($self, $arg, $id) = @_;

    if ($id == OIS::Mouse->MB_Left) {
        $self->performSelection($self->{mStart}, $self->{mStop});

        $self->{mSelecting} = 0;
        $self->{mRect}->setVisible(0);
    }

    return 1;
}

sub performSelection {
    my ($self, $first, $second) = @_;

    my $left = $first->x;
    my $right = $second->x;
    my $top = $first->y;
    my $bottom = $second->y;

    if ($left > $right) {
        my $tmp = $left;
        $left = $right;
        $right = $tmp;
    }
    if ($top > $bottom) {
        my $tmp = $top;
        $top = $bottom;
        $bottom = $tmp;
    }

    # I changed this a bit, so it also deselects if you just click
    if (($right - $left) * ($bottom - $top) < 0.0001) {
        $self->deselectObjects();
        return;
    }

    my $topLeft = $self->{mCamera}->getCameraToViewportRay($left, $top);
    my $topRight = $self->{mCamera}->getCameraToViewportRay($right, $top);
    my $bottomLeft = $self->{mCamera}->getCameraToViewportRay($left, $bottom);
    my $bottomRight = $self->{mCamera}->getCameraToViewportRay($right, $bottom);

    ## XXX: big hack, added push_back_plane to PlaneBoundedVolume - will fix later
    my $vol = Ogre::PlaneBoundedVolume->new();
    # front plane
    $vol->push_back_plane(Ogre::Plane->new($topLeft->getPoint(3),
                                           $topRight->getPoint(3),
                                           $bottomRight->getPoint(3)));
    # top plane
    $vol->push_back_plane(Ogre::Plane->new($topLeft->getOrigin(),
                                           $topLeft->getPoint(100),
                                           $topRight->getPoint(100)));
    # left plane
    $vol->push_back_plane(Ogre::Plane->new($topLeft->getOrigin(),
                                           $bottomLeft->getPoint(100),
                                           $topLeft->getPoint(100)));
    # bottom plane
    $vol->push_back_plane(Ogre::Plane->new($topLeft->getOrigin(),
                                           $bottomRight->getPoint(100),
                                           $bottomLeft->getPoint(100)));
    # right plane
    $vol->push_back_plane(Ogre::Plane->new($topLeft->getOrigin(),
                                           $topRight->getPoint(100),
                                           $bottomRight->getPoint(100)));

    $self->{mVolQuery}->setVolumes([$vol]);
    my $result = $self->{mVolQuery}->execute();

    $self->deselectObjects();

    foreach my $obj (@{ $result->{movables} }) {
        $self->selectObject($obj);
    }
}

sub deselectObjects {
    my ($self) = @_;
    foreach my $obj (@{ $self->{mSelected} }) {
        $obj->getParentSceneNode->showBoundingBox(0);
    }
}

sub selectObject {
    my ($self, $obj) = @_;
    $obj->getParentSceneNode->showBoundingBox(1);
    push @{ $self->{mSelected} }, $obj;
}

sub injectMouse {
    my ($self, $state) = @_;

    $self->{mDGUI}{mouseX} += $state->X->rel;
    $self->{mDGUI}{mouseY} += $state->Y->rel;
    if ($state->buttons == 1) {
        $self->{mDGUI}{mBetaGUI}->injectMouse($self->{mDGUI}{mouseX},
                                              $self->{mDGUI}{mouseY},
                                              1);  # LMB is down.
    }
    else {
        $self->{mDGUI}{mBetaGUI}->injectMouse($self->{mDGUI}{mouseX},
                                              $self->{mDGUI}{mouseY},
                                              0); # LMB is not down.
    }
}


1;


package DemoApplication;

use strict;
use warnings;

use Ogre::ExampleApplication;
@DemoApplication::ISA = qw(Ogre::ExampleApplication);

use Ogre 0.34;
use Ogre::ColourValue;
use Ogre::Vector3;

sub new {
    my ($pkg) = @_;

    my $super = $pkg->SUPER::new();
    my $self = bless $super, $pkg;

    $self->{mDGUI} = undef;

    return $self;
}

sub createScene {
    my ($self) = @_;

    my $cam = $self->{mCamera};
    $cam->setPosition(-60, 100, -60);
    $cam->lookAt(60, 0, 60);

    my $scenemgr = $self->{mSceneMgr};
    $scenemgr->setAmbientLight(Ogre::ColourValue->new());
    for my $i (0 .. 9) {
        for my $j (0 .. 9) {
            my $ent = $scenemgr->createEntity("Robot" . ($i + $j * 10), "robot.mesh");
            my $node = $scenemgr->getRootSceneNode->createChildSceneNode(Ogre::Vector3->new($i * 15, 0, $j * 15));
            $node->attachObject($ent);
            $node->setScale(0.1, 0.1, 0.1);
        }
    }

    $self->{mDGUI} = DemoGUI->new();
}

sub createFrameListener {
    my ($self) = @_;

    $self->{mFrameListener} = DemoListener->new($self->{mWindow},
                                                      $self->{mCamera},
                                                      $self->{mSceneMgr},
                                                      $self->{mDGUI});
    $self->{mFrameListener}->showDebugOverlay(1);
    $self->{mRoot}->addFrameListener($self->{mFrameListener});
}


1;


package main;

# uncomment this if the packages are in separate files:
# use DemoApplication;
DemoApplication->new->go();
