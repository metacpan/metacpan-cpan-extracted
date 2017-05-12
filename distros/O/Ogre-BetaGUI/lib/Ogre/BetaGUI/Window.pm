package Ogre::BetaGUI::Window;

### Note: this was ported to Perl from:
# /// Betajaen's GUI 016 Uncompressed
# /// Written by Robin "Betajaen" Southern 07-Nov-2006, http://www.ogre3d.org/wiki/index.php/BetaGUI
# /// This code is under the Whatevar! licence. Do what you want; but keep the original copyright header.
###

use strict;
use warnings;
use Scalar::Util qw(refaddr);   # note: in core as of Perl 5.8

use Ogre 0.33;

use Ogre::BetaGUI qw(:wt);
use Ogre::BetaGUI::Button;
use Ogre::BetaGUI::Callback;
use Ogre::BetaGUI::TextInput;


# note: $Dimensions is an array ref with 4 values (Vector4)
sub new {
    my ($pkg, $Dimensions, $Material, $t, $caption, $gui) = @_;

    # Perl doesn't have enums (:wt exported above), so this sucks
    unless ($t == NONE or $t == MOVE or $t == RESIZE or $t == RESIZE_AND_MOVE) {
        die __PACKAGE__ . ": invalid type number '$t' (see :wt in Ogre::BetaGUI)";
    }

    my $self = bless {
        'x'     => $Dimensions->[0],  # x
        'y'     => $Dimensions->[1],  # y
        'w'     => $Dimensions->[2],  # z
        'h'     => $Dimensions->[3],  # w
        mGUI  => $gui,    # GUI *
        mTB   => undef,   # Button *
        mRZ   => undef,   # Button *
        mATI  => undef,   # TextInput *
        mAB   => undef,   # Button *
        mO    => undef,   # OverlayContainer *
        mB    => [],      # Buttons
        mT    => [],      # TextInputs
    }, $pkg;

    $self->{mO} = $gui->createOverlay($gui->{mO}->getName . ".w" . $gui->{wc},
                                      [$self->{'x'}, $self->{'y'}],
                                      [$self->{'w'}, $self->{'h'}], $Material);
    $gui->{wc}++;

    if ($t >= 2) {  # RESIZE
        my $c = Ogre::BetaGUI::Callback->new();
        $c->{t} = 4;

        $self->{mRZ} = $self->createButton([($Dimensions->[2] - 16), ($Dimensions->[3] - 16), 16, 16],
                                           $Material . ".resize", "", $c);
    }

    if ($t == 1 || $t == 3) {  # MOVE or RESIZE_AND_MOVE
        my $c = Ogre::BetaGUI::Callback->new();
        $c->{t} = 3;

        $self->{mTB} = $self->createButton([0, 0, $Dimensions->[2], 22],
                                           $Material . ".titlebar", $caption, $c);
    }

    return $self;
}

sub DESTROY {
    my ($self) = @_;
    $self->{mGUI}{mO}->remove2D($self->{mO})
      if defined($self->{mGUI}) && defined($self->{mGUI}{mO}) && defined($self->{mO});
}

sub createButton {
    my ($self, $Dimensions, $Material, $Text, $callback) = @_;

    my $x = Ogre::BetaGUI::Button->new($Dimensions, $Material, $Text, $callback, $self);
    push @{ $self->{mB} }, $x;
    return $x;
}

sub createTextInput {
    my ($self, $Dimensions, $Material, $Value, $length) = @_;
    my $x = Ogre::BetaGUI::TextInput->new($Dimensions, $Material, $Value, $length, $self);
    push @{ $self->{mT} }, $x;
    return $x;
}

sub createStaticText {
    my ($self, $Dimensions, $Text) = @_;

    my $x = $self->{mGUI}->createOverlay($self->{mO}->getName . "st." . $self->{mGUI}{tc},
                                         [$Dimensions->[0], $Dimensions->[1]],
                                         [$Dimensions->[2], $Dimensions->[3]],
                                         '', $Text, 0);
    $self->{mGUI}{tc}++;

    $self->{mO}->addChild($x);
    $x->show();
    return $x;
}

sub hide { $_[0]->{mO}->hide() }
sub show { $_[0]->{mO}->show() }
sub isVisible { $_[0]->{mO}->isVisible() }

sub setPosition {
    my ($self, $X, $Y) = @_;
    $self->{'x'} = $X;
    $self->{'y'} = $Y;
    $self->{mO}->setPosition($X, $Y);
}

# these return array ref, not Vector2
sub getPosition { [$_[0]->{'x'}, $_[0]->{'y'}] }
sub getSize { [$_[0]->{'w'}, $_[0]->{'h'}] }

sub setSize {
    my ($self, $W, $H) = @_;

    $self->{'w'} = $W;
    $self->{'h'} = $H;
    $self->{mO}->setDimensions($W, $H);

    $self->{mRZ}{'x'} = $self->{'w'} - 16;
    $self->{mRZ}{'y'} = $self->{'h'} - 16;
    $self->{mRZ}{mO}->setPosition($self->{mRZ}{'x'}, $self->{mRZ}{'y'});

    if ($self->{mTB}) {
        $self->{mTB}{'w'} = $self->{'w'};
        $self->{mTB}{mO}->setWidth($self->{mTB}{'w'});
    }
}

sub check {
    my ($self, $px, $py, $lmb) = @_;

    return 0 unless $self->{mO}->isVisible;

    if (!($px >= $self->{'x'} && $py >= $self->{'y'}) ||
        !($px <= $self->{'x'} + $self->{'w'} && $py <= $self->{'y'} + $self->{'h'}))
    {
        if ($self->{mAB}) {
            my $cb = $self->{mAB}{callback};
            if ($cb->{t} == 2) {
                if (exists($cb->{LS}) && defined($cb->{LS})) {
                    $cb->{LS}->onButtonPress($self->{mAB}, 3);
                }
                else {
                    warn "onButtonPress not called: LS undef at ", __FILE__, ":", __LINE__, $/;
                }
            }

            $self->{mAB}->activate(0);
            undef $self->{mAB};
        }
        return 0;
    }

    foreach my $mb (@{ $self->{mB} }) {
        next if $mb->in($px, $py, $self->{'x'}, $self->{'y'});

        if ($self->{mAB}) {
            if (refaddr($mb) != refaddr($self->{mAB})) {
                $self->{mAB}->activate(0);

                # xxx: there's something wrong here.. when you drag a window
                # around quickly, and the mouse cursor detaches from the window
                # (which is a separate bug....) it can go across another button/window
                # and apparently get in here with $cb->{LS} undef.
                my $cb = $self->{mAB}{callback};
                if (exists($cb->{LS}) && defined($cb->{LS})) {
                    $cb->{LS}->onButtonPress($self->{mAB}, 3);
                }
                else {
                    warn "onButtonPress not called: LS undef at ", __FILE__, ":", __LINE__, $/;
                }
            }
        }

        $self->{mAB} = $mb;
        $self->{mAB}->activate(1);

        if ($self->{mATI} && $lmb) {
            $self->{mATI}{mO}->setMaterialName($self->{mATI}{mmn});
            undef $self->{mATI};
        }

        my $t = $self->{mAB}{callback}{t};
        if ($t == 1) {
            $self->{mAB}{callback}{fp}->($self->{mAB}, $lmb);
        }
        elsif ($t == 2) {
            my $cb = $self->{mAB}{callback};
            if (exists($cb->{LS}) && defined($cb->{LS})) {
                $cb->{LS}->onButtonPress($self->{mAB}, $lmb);
            }
            else {
                warn "onButtonPress not called: LS undef at ", __FILE__, ":", __LINE__, $/;
            }
        }
        elsif ($t == 3) {
            if ($lmb) {
                $self->setPosition($px - ($self->{mAB}{'w'} / 2), $py - ($self->{mAB}{'h'} / 2));
            }
        }
        elsif ($t == 4) {
            if ($lmb) {
                $self->setSize($px - $self->{'x'} + 8, $py - $self->{'y'} + 8);
            }
        }

        return 1;
    }

    return 0 unless $lmb;

    foreach my $mt (@{ $self->{mT} }) {
        next if $mt->in($px, $py, $self->{'x'}, $self->{'y'});

        $self->{mATI} = $mt;
        $self->{mATI}{mO}->setMaterialName($self->{mATI}{mma});
        return 1;
    }

    if ($self->{mATI}) {
        $self->{mATI}{mO}->setMaterialName($self->{mATI}{mmn});
        undef $self->{mATI};
        return 1;
    }

    return 0;
}

sub checkKey {
    my ($self, $key, $px, $py) = @_;

    return 0 unless $self->{mO}->isVisible;

    return 0 if !($px >= $self->{'x'} && $py >= $self->{'y'}) ||
        !($px <= $self->{'x'} + $self->{'w'} && $py <= $self->{'y'} + $self->{'h'});

    return 0 unless defined $self->{mATI};

    if ($key eq '!b') {
        chop $self->{mATI}{value};
        $self->{mATI}->setValue($self->{mATI}{value});
    }

    return 1 if length($self->{mATI}{value}) >= $self->{mATI}{length};

    $self->{mATI}{value} .= $key;
    $self->{mATI}{mCP}->setCaption($self->{mATI}{value});
    return 1;
}


1;
