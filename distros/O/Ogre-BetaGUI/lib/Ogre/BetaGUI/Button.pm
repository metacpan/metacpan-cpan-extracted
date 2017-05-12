package Ogre::BetaGUI::Button;

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
    my ($pkg, $Dimensions, $Material, $Text, $callback, $parent) = @_;

    my $self = bless {
        'x'      => $Dimensions->[0],  # x
        'y'      => $Dimensions->[1],  # y
        'w'      => $Dimensions->[2],  # z
        'h'      => $Dimensions->[3],  # w
        mO       => undef,       # OverlayContainer *
        mCP      => undef,       # OverlayContainer * (caption)
        mmn      => $Material,   # material name normal
        mma      => $Material,   # material name active
        callback => $callback,   # BetaGUI::Callback
    }, $pkg;

    my $ma = Ogre::MaterialManager->getSingletonPtr->getByName($self->{mmn} . ".active");
    $self->{mma} .= ".active" if defined $ma;

    $self->{mO} = $parent->{mGUI}->createOverlay($parent->{mO}->getName . "b" . $parent->{mGUI}{bc},
                                                 [$self->{'x'}, $self->{'y'}],
                                                 [$self->{'w'}, $self->{'h'}],
                                                 $Material, '', 0);
    $parent->{mGUI}{bc}++;
    $self->{mCP} = $parent->{mGUI}->createOverlay($self->{mO}->getName . "c",
                                                 [4, (($self->{'h'} - $parent->{mGUI}{mFontSize}) / 2)],
                                                 [$self->{'w'}, $self->{'h'}],
                                                 '', $Text, 0);

    $parent->{mO}->addChild($self->{mO});
    $self->{mO}->show();
    $self->{mO}->addChild($self->{mCP});
    $self->{mCP}->show();

    return $self;
}

sub DESTROY {
    my ($self) = @_;

    # I have problems all the time with DESTROY in Perl....
#    $self->{mO}->getParent->removeChild($self->{mO}->getName)
#      if defined $self->{mO};
#    $self->{mCP}->getParent->removeChild($self->{mCP}->getName)
#      if defined $self->{mCP};
}

sub activate {
    my ($self, $a) = @_;

    $self->{mO}->setMaterialName($self->{mmn}) if !$a && $self->{mmn} ne '';

    $self->{mO}->setMaterialName($self->{mma}) if  $a && $self->{mma} ne '';
}

sub in {
    my ($self, $mx, $my, $px, $py) = @_;
    return !($mx >= $self->{'x'} + $px && $my >= $self->{'y'} + $py)
      || !($mx <= $self->{'x'} + $px + $self->{'w'} && $my <= $self->{'y'} + $py + $self->{'h'});
}



1;
