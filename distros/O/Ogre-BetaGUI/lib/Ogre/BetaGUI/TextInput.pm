package Ogre::BetaGUI::TextInput;

### Note: this was ported to Perl from:
# /// Betajaen's GUI 016 Uncompressed
# /// Written by Robin "Betajaen" Southern 07-Nov-2006, http://www.ogre3d.org/wiki/index.php/BetaGUI
# /// This code is under the Whatevar! licence. Do what you want; but keep the original copyright header.
###

use strict;
use warnings;

use Ogre 0.33;
use Ogre::MaterialManager;


# note: $Dimensions is an array ref with 4 values (Vector4)
sub new {
    my ($pkg, $Dimensions, $Material, $Value, $length, $parent) = @_;

    my $self = bless {
        'x'      => $Dimensions->[0],  # x
        'y'      => $Dimensions->[1],  # y
        'w'      => $Dimensions->[2],  # z
        'h'      => $Dimensions->[3],  # w
        mO       => undef,       # OverlayContainer *
        mCP      => undef,       # OverlayContainer * (caption)
        mmn      => $Material,   # material name normal
        mma      => $Material,   # material name active
        value    => $Value,
        length   => $length,
    }, $pkg;

    my $ma = Ogre::MaterialManager->getSingletonPtr->getByName($self->{mmn} . ".active");
    $self->{mma} .= ".active" if defined $ma;

    $self->{mO} = $parent->{mGUI}->createOverlay($parent->{mO}->getName . "t" . $parent->{mGUI}{tc},
                                                 [$self->{'x'}, $self->{'y'}],
                                                 [$self->{'w'}, $self->{'h'}],
                                                 $Material, '', 0);
    $parent->{mGUI}{tc}++;
    $self->{mCP} = $parent->{mGUI}->createOverlay($self->{mO}->getName . "c",
                                                 [4, (($self->{'h'} - $parent->{mGUI}{mFontSize}) / 2)],
                                                 [$self->{'w'}, $self->{'h'}],
                                                 '', $Value, 0);

    $parent->{mO}->addChild($self->{mO});
    $self->{mO}->show();
    $self->{mO}->addChild($self->{mCP});
    $self->{mCP}->show();

    return $self;
}

sub getValue { $_[0]->{value} }

sub setValue {
    my ($self, $v) = @_;

    $self->{value} = $v;
    $self->{mCP}->setCaption($v);
}

sub in {
    my ($self, $mx, $my, $px, $py) = @_;
    return !($mx >= $self->{'x'} + $px && $my >= $self->{'y'} + $py)
      || !($mx <= $self->{'x'} + $px + $self->{'w'} && $my <= $self->{'y'} + $py + $self->{'h'});
}



1;
