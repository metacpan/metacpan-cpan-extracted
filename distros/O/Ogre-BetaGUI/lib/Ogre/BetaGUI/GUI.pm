package Ogre::BetaGUI::GUI;

### Note: this was ported to Perl from:
# /// Betajaen's GUI 016 Uncompressed
# /// Written by Robin "Betajaen" Southern 07-Nov-2006, http://www.ogre3d.org/wiki/index.php/BetaGUI
# /// This code is under the Whatevar! licence. Do what you want; but keep the original copyright header.
###

# Porting notes:
# Wherever there is a Vector2 in the C++ version, expect a 2-element array ref.
# I'll have to be in a really good mood to add docs, since BetaGUI doesn't
# come with any.

use strict;
use warnings;
use List::MoreUtils qw(firstidx);
use Scalar::Util qw(refaddr);   # note: in core as of Perl 5.8

use Ogre 0.35 qw(:GuiMetricsMode);
use Ogre::OverlayManager;

use Ogre::BetaGUI::Window;

sub new {
    my ($pkg, $baseOverlay, $font, $fontSize) = @_;

    my $mO = Ogre::OverlayManager->getSingletonPtr->create($baseOverlay);
    $mO->show();

    my $self = bless {
        mO        => $mO,
        WN        => [],
        mXW       => undef,
        mMP       => undef,
        mFont     => $font,
        mFontSize => $fontSize,
        wc        => 0,
        bc        => 0,
        tc        => 0,
    }, $pkg;

    return $self;
}

sub setZOrder {
    my ($self, $z) = @_;
    $self->{mO}->setZOrder($z);
}

sub injectMouse {
    my ($self, $x, $y, $lmb) = @_;

    if ($self->{mMP}) {
        $self->{mMP}->setPosition($x, $y);
    }

    if ($self->{mXW}) {
        # hopefully refaddr works, otherwise might have to add
        # a unique "ID" attribute to Ogre::BetaGUI::Window
        my $idx = firstidx { refaddr($_) == refaddr($self->{mXW}) } @{ $self->{WN} };
        if ($idx != -1) {
            # remove and delete the Ogre::BetaGUI::Window
            my $win = splice @{ $self->{WN} }, $idx, 1;
            delete $self->{mXW};
            return 0;
        }
    }

    foreach my $wn (@{ $self->{WN} }) {
        return 1 if $wn->check($x, $y, $lmb);
    }
    return 0;
}

sub injectKey {
    my ($self, $key, $x, $y) = @_;

    foreach my $wn (@{ $self->{WN} }) {
        return 1 if $wn->checkKey($key, $x, $y);
    }
    return 0;
}

sub injectBackspace {
    my ($self, $x, $y) = @_;
    $self->injectKey("!b", $x, $y);
}

sub createWindow {
    my ($self, $Dimensions, $Material, $type, $caption) = @_;
    $caption = '' unless defined $caption;

    my $window = Ogre::BetaGUI::Window->new($Dimensions, $Material, $type, $caption, $self);
    push @{ $self->{WN} }, $window;
    return $window;
}

sub destroyWindow {
    my ($self, $window) = @_;
    $self->{mXW} = $window;
    # that gets actually removed in injectMouse
}

sub createOverlay {
    my ($self, $name, $position, $dimensions, $material, $caption, $autoAdd) = @_;
    $material = '' unless defined $material;
    $caption = '' unless defined $caption;
    $autoAdd = 1 unless defined $autoAdd;

    my $om = Ogre::OverlayManager->getSingletonPtr;
    my $e = ($caption eq '')
      ? $om->createPanelOverlayElement("Panel", $name)
      : $om->createTextAreaOverlayElement("TextArea", $name);

    $e->setMetricsMode(GMM_PIXELS);
    $e->setDimensions($dimensions->[0], $dimensions->[1]);
    $e->setPosition($position->[0], $position->[1]);
    $e->setMaterialName($material) unless $material eq '';
    unless ($caption eq '') {
        $e->setCaption($caption);
        $e->setParameter("font_name", $self->{mFont});
        $e->setParameter("char_height", $self->{mFontSize});
    }

    if ($autoAdd) {
        $self->{mO}->add2D($e);
        $e->show();
    }

    return $e;
}

sub createMousePointer {
    my ($self, $d, $m) = @_;

    my $o = Ogre::OverlayManager->getSingletonPtr->create("BetaGUI.MP");
    $o->setZOrder(649);
    $self->{mMP} = $self->createOverlay("bg.mp", [0, 0], $d, $m, '', 0);
    $o->add2D($self->{mMP});
    $o->show();
    $self->{mMP}->show();

    return $self->{mMP};
}


1;
