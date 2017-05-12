#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78aeac0-200e-11de-bdb5-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ViewDefinition;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Rinchi::CIGI::AtmosphereControl ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';

# Preloaded methods go here.

=head1 NAME

Rinchi::CIGIPP::ViewDefinition - Perl extension for the Common Image Generator 
Interface - View Definition data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ViewDefinition;
  my $view_def = Rinchi::CIGIPP::ViewDefinition->new();

  $packet_type = $view_def->packet_type();
  $packet_size = $view_def->packet_size();
  $view_ident = $view_def->view_ident(6573);
  $group_ident = $view_def->group_ident(45);
  $mirror_mode = $view_def->mirror_mode(Rinchi::CIGIPP->None);
  $bottom_enable = $view_def->bottom_enable(Rinchi::CIGIPP->Disable);
  $top_enable = $view_def->top_enable(Rinchi::CIGIPP->Disable);
  $right_enable = $view_def->right_enable(Rinchi::CIGIPP->Disable);
  $left_enable = $view_def->left_enable(Rinchi::CIGIPP->Disable);
  $far_enable = $view_def->far_enable(Rinchi::CIGIPP->Disable);
  $near_enable = $view_def->near_enable(Rinchi::CIGIPP->Disable);
  $view_type = $view_def->view_type(2);
  $reorder = $view_def->reorder(Rinchi::CIGIPP->NoReorder);
  $projection_type = $view_def->projection_type(Rinchi::CIGIPP->Perspective);
  $pixel_replication_mode = $view_def->pixel_replication_mode(Rinchi::CIGIPP->None);
  $near = $view_def->near(36.544);
  $far = $view_def->far(79.657);
  $left = $view_def->left(8.335);
  $right = $view_def->right(1.447);
  $top = $view_def->top(12.453);
  $bottom = $view_def->bottom(36.497);

=head1 DESCRIPTION

The View Definition packet allows the Host to override the IG's default 
configuration for a view. This packet is used to specify the projection type, 
to define the size of the viewing volume, and to assign the view to a view 
group. Refer to Section 3.2 of the CIGI ICD for details on these view characteristics.

=head2 EXPORT

None by default.

#==============================================================================

=item new $view_def = Rinchi::CIGIPP::ViewDefinition->new()

Constructor for Rinchi::ViewDefinition.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78aeac0-200e-11de-bdb5-001c25551abc',
    '_Pack'                                => 'CCSCCCCffffff',
    '_Swap1'                               => 'CCvCCCCVVVVVV',
    '_Swap2'                               => 'CCnCCCCNNNNNN',
    'packetType'                           => 21,
    'packetSize'                           => 32,
    'viewIdent'                            => 0,
    'groupIdent'                           => 0,
    '_bitfields1'                          => 0, # Includes bitfields mirrorMode, bottomEnable, topEnable, rightEnable, leftEnable, farEnable, and nearEnable.
    'mirrorMode'                           => 0,
    'bottomEnable'                         => 0,
    'topEnable'                            => 0,
    'rightEnable'                          => 0,
    'leftEnable'                           => 0,
    'farEnable'                            => 0,
    'nearEnable'                           => 0,
    '_bitfields2'                          => 0, # Includes bitfields viewType, reorder, projectionType, and pixelReplicationMode.
    'viewType'                             => 0,
    'reorder'                              => 0,
    'projectionType'                       => 0,
    'pixelReplicationMode'                 => 0,
    '_unused34'                            => 0,
    'near'                                 => 0,
    'far'                                  => 0,
    'left'                                 => 0,
    'right'                                => 0,
    'top'                                  => 0,
    'bottom'                               => 0,
  };

  if (@_) {
    if (ref($_[0]) eq 'ARRAY') {
      $self->{'_Buffer'} = $_[0][0];
    } elsif (ref($_[0]) eq 'HASH') {
      foreach my $attr (keys %{$_[0]}) {
        $self->{"_$attr"} = $_[0]->{$attr} unless ($attr =~ /^_/);
      }
    }        
  }

  bless($self,$class);
  return $self;
}

#==============================================================================

=item sub packet_type()

 $value = $view_def->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the View Definition packet. The 
value of this attribute must be 21.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $view_def->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 32.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub view_ident([$newValue])

 $value = $view_def->view_ident($newValue);

View ID.

This attribute specifies the view to which the data in this packet will be applied.

=cut

sub view_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'viewIdent'} = $nv;
  }
  return $self->{'viewIdent'};
}

#==============================================================================

=item sub group_ident([$newValue])

 $value = $view_def->group_ident($newValue);

Group ID.

This attribute specifies the group to which the view is to be assigned. If this 
value is zero (0), the view is not assigned to a group.

=cut

sub group_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'groupIdent'} = $nv;
  }
  return $self->{'groupIdent'};
}

#==============================================================================

=item sub mirror_mode([$newValue])

 $value = $view_def->mirror_mode($newValue);

Mirror Mode.

This attribute specifies the mirroring function to be performed on the view. 
This feature is typically used to replicate the view of a mirrored surface such 
as a rear view mirror.

    None                    0
    Horizontal              1
    Vertical                2
    HorizontalAndVertical   3

=cut

sub mirror_mode() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3)) {
      $self->{'mirrorMode'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 6) &0xC0;
    } else {
      carp "mirror_mode must be 0 (None), 1 (Horizontal), 2 (Vertical), or 3 (HorizontalAndVertical).";
    }
  }
  return (($self->{'_bitfields1'} & 0xC0) >> 6);
}

#==============================================================================

=item sub bottom_enable([$newValue])

 $value = $view_def->bottom_enable($newValue);

Bottom Enable.

This attribute specifies whether the bottom half-angle of the view frustum will 
be set according to the value of the Bottom attribute within this packet. If 
this attribute is set to Disable (0), the Bottom attribute will be ignored.

    Disable   0
    Enable    1

=cut

sub bottom_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'bottomEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 5) &0x20;
    } else {
      carp "bottom_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x20) >> 5);
}

#==============================================================================

=item sub top_enable([$newValue])

 $value = $view_def->top_enable($newValue);

Top Enable.

This attribute specifies whether the top half-angle of the view frustum will be 
set according to the value of the Top attribute within this packet. If this 
attribute is set to Disable (0), the Top attribute will be ignored.

    Disable   0
    Enable    1

=cut

sub top_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'topEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 4) &0x10;
    } else {
      carp "top_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x10) >> 4);
}

#==============================================================================

=item sub right_enable([$newValue])

 $value = $view_def->right_enable($newValue);

Right Enable.

This attribute specifies whether the right half-angle of the view frustum will 
be set according to the value of the Right attribute within this packet. If 
this attribute is set to Disable (0), the Right attribute will be ignored.

    Disable   0
    Enable    1

=cut

sub right_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'rightEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x08;
    } else {
      carp "right_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x08) >> 3);
}

#==============================================================================

=item sub left_enable([$newValue])

 $value = $view_def->left_enable($newValue);

Left Enable.

This attribute specifies whether the left half-angle of the view frustum will 
be set according to the value of the Left attribute within this packet. If this 
attribute is set to Disable (0), the Left attribute will be ignored.

    Disable   0
    Enable    1

=cut

sub left_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'leftEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 2) &0x04;
    } else {
      carp "left_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x04) >> 2);
}

#==============================================================================

=item sub far_enable([$newValue])

 $value = $view_def->far_enable($newValue);

Far Enable.

This attribute specifies whether the far clipping plane will be set to the 
value of the Far attribute within this packet. If this attribute is set to 
Disable (0), the Far attribute will be ignored.

    Disable   0
    Enable    1

=cut

sub far_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'farEnable'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 1) &0x02;
    } else {
      carp "far_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x02) >> 1);
}

#==============================================================================

=item sub near_enable([$newValue])

 $value = $view_def->near_enable($newValue);

Near Enable.

This attribute specifies whether the near clipping plane will be set to the 
value of the Near attribute within this packet. If this attribute is set to 
Disable (0), the Near attribute will be ignored.

    Disable   0
    Enable    1

=cut

sub near_enable() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'nearEnable'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "near_enable must be 0 (Disable), or 1 (Enable).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub view_type([$newValue])

 $value = $view_def->view_type($newValue);

View Type.

This attribute specifies an IG-defined type for the indicated view. For 
example, a Host might switch a view type from out-the-window to IR for a given channel.

=cut

sub view_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if ($nv>=0 and $nv<=7 and int($nv) == $nv) {
      $self->{'viewType'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 5) &0xE0;
    } else {
      carp "view_type must be an integer 0-7.";
    }
  }
  return (($self->{'_bitfields2'} & 0xE0) >> 5);
}

#==============================================================================

=item sub reorder([$newValue])

 $value = $view_def->reorder($newValue);

Reorder.

This attribute specifies whether the view should be moved to the top of any 
overlapping views. In cases where multiple overlapping views are moved to the 
top, the last view specified gets priority.

    NoReorder    0
    BringToTop   1

=cut

sub reorder() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'reorder'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 4) &0x10;
    } else {
      carp "reorder must be 0 (NoReorder), or 1 (BringToTop).";
    }
  }
  return (($self->{'_bitfields2'} & 0x10) >> 4);
}

#==============================================================================

=item sub projection_type([$newValue])

 $value = $view_def->projection_type($newValue);

Projection Type.

This attribute specifies whether the view projection should be perspective or 
orthographic parallel.

    Perspective            0
    OrthographicParallel   1

=cut

sub projection_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'projectionType'} = $nv;
      $self->{'_bitfields2'} |= ($nv << 3) &0x08;
    } else {
      carp "projection_type must be 0 (Perspective), or 1 (OrthographicParallel).";
    }
  }
  return (($self->{'_bitfields2'} & 0x08) >> 3);
}

#==============================================================================

=item sub pixel_replication_mode([$newValue])

 $value = $view_def->pixel_replication_mode($newValue);

Pixel Replication Mode.

This attribute specifies the pixel replication function to be performed on the 
view. This feature is typically used in sensor applications to perform 
electronic zooming (i.e., pixel and line doubling).

    None           0
    Replicate1x2   1
    Replicate2x1   2
    Replicate2x2   3

=cut

sub pixel_replication_mode() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3)) {
      $self->{'pixelReplicationMode'} = $nv;
      $self->{'_bitfields2'} |= $nv &0x07;
    } else {
      carp "pixel_replication_mode must be 0 (None), 1 (Replicate1x2), 2 (Replicate2x1), or 3 (Replicate2x2).";
    }
  }
  return ($self->{'_bitfields2'} & 0x07);
}

#==============================================================================

=item sub near([$newValue])

 $value = $view_def->near($newValue);

Near.

This attribute specifies the position of the view's near clipping plane. This 
distance is measured along the viewing vector from the eyepoint to the plane.

=cut

sub near() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'near'} = $nv;
  }
  return $self->{'near'};
}

#==============================================================================

=item sub far([$newValue])

 $value = $view_def->far($newValue);

Far.

This attribute specifies the position of the view's far clipping plane. This 
distance is measured along the viewing vector from the eyepoint to the plane.

=cut

sub far() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'far'} = $nv;
  }
  return $self->{'far'};
}

#==============================================================================

=item sub left([$newValue])

 $value = $view_def->left($newValue);

Left.

This attribute specifies the left half-angle of the view frustum. This value is 
the measure of the angle formed at the view eyepoint between the viewing vector 
and the frustum side.

=cut

sub left() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'left'} = $nv;
  }
  return $self->{'left'};
}

#==============================================================================

=item sub right([$newValue])

 $value = $view_def->right($newValue);

Right.

This attribute specifies the right half-angle of the view frustum. This value 
is the measure of the angle formed at the view eyepoint between the viewing 
vector and the frustum side.

=cut

sub right() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'right'} = $nv;
  }
  return $self->{'right'};
}

#==============================================================================

=item sub top([$newValue])

 $value = $view_def->top($newValue);

Top.

This attribute specifies the top half-angle of the view frustum. This value is 
the measure of the angle formed at the view eyepoint between the viewing vector 
and the frustum side.

=cut

sub top() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'top'} = $nv;
  }
  return $self->{'top'};
}

#==============================================================================

=item sub bottom([$newValue])

 $value = $view_def->bottom($newValue);

Bottom.

This attribute specifies the bottom half-angle of the view frustum. This value 
is the measure of the angle formed at the view eyepoint between the viewing 
vector and the frustum side.

=cut

sub bottom() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'bottom'} = $nv;
  }
  return $self->{'bottom'};
}

#==========================================================================

=item sub pack()

 $value = $view_def->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'viewIdent'},
        $self->{'groupIdent'},
        $self->{'_bitfields1'},    # Includes bitfields mirrorMode, bottomEnable, topEnable, rightEnable, leftEnable, farEnable, and nearEnable.
        $self->{'_bitfields2'},    # Includes bitfields viewType, reorder, projectionType, and pixelReplicationMode.
        $self->{'_unused34'},
        $self->{'near'},
        $self->{'far'},
        $self->{'left'},
        $self->{'right'},
        $self->{'top'},
        $self->{'bottom'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $view_def->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'viewIdent'}                           = $c;
  $self->{'groupIdent'}                          = $d;
  $self->{'_bitfields1'}                         = $e; # Includes bitfields mirrorMode, bottomEnable, topEnable, rightEnable, leftEnable, farEnable, and nearEnable.
  $self->{'_bitfields2'}                         = $f; # Includes bitfields viewType, reorder, projectionType, and pixelReplicationMode.
  $self->{'_unused34'}                           = $g;
  $self->{'near'}                                = $h;
  $self->{'far'}                                 = $i;
  $self->{'left'}                                = $j;
  $self->{'right'}                               = $k;
  $self->{'top'}                                 = $l;
  $self->{'bottom'}                              = $m;

  $self->{'mirrorMode'}                          = $self->mirror_mode();
  $self->{'bottomEnable'}                        = $self->bottom_enable();
  $self->{'topEnable'}                           = $self->top_enable();
  $self->{'rightEnable'}                         = $self->right_enable();
  $self->{'leftEnable'}                          = $self->left_enable();
  $self->{'farEnable'}                           = $self->far_enable();
  $self->{'nearEnable'}                          = $self->near_enable();
  $self->{'viewType'}                            = $self->view_type();
  $self->{'reorder'}                             = $self->reorder();
  $self->{'projectionType'}                      = $self->projection_type();
  $self->{'pixelReplicationMode'}                = $self->pixel_replication_mode();

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub byte_swap()

 $obj_name->byte_swap();

Byte swaps the packed data packet.

=cut

sub byte_swap($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  } else {
     $self->pack();
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i,$j,$k,$l,$m);
  $self->unpack();

  return $self->{'_Buffer'};
}

1;
__END__

=head1 SEE ALSO

Refer the the Common Image Generator Interface ICD which may be had at this URL:
L<http://cigi.sourceforge.net/specification.php>

=head1 AUTHOR

Brian M. Ames, E<lt>bmames@apk.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Brian M. Ames

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.


=cut
