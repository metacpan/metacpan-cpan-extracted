#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78ac504-200e-11de-bda7-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::ShortArticulatedPartControl;

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

Rinchi::CIGIPP::ShortArticulatedPartControl - Perl extension for the Common 
Image Generator Interface - Short Articulated Part Control data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::ShortArticulatedPartControl;
  my $sap_ctl = Rinchi::CIGIPP::ShortArticulatedPartControl->new();

  $packet_type = $sap_ctl->packet_type();
  $packet_size = $sap_ctl->packet_size();
  $entity_ident = $sap_ctl->entity_ident(15419);
  $articulated_part_ident1 = $sap_ctl->articulated_part_ident1(124);
  $articulated_part_ident2 = $sap_ctl->articulated_part_ident2(21);
  $articulated_part_enable2 = $sap_ctl->articulated_part_enable2(Rinchi::CIGIPP->Enable);
  $articulated_part_enable1 = $sap_ctl->articulated_part_enable1(Rinchi::CIGIPP->Disable);
  $dof_select2 = $sap_ctl->dof_select2(Rinchi::CIGIPP->NotUsed);
  $dof_select1 = $sap_ctl->dof_select1(Rinchi::CIGIPP->XOffset);
  $degree_of_freedom1 = $sap_ctl->degree_of_freedom1(2.007);
  $degree_of_freedom2 = $sap_ctl->degree_of_freedom2(49.352);

=head1 DESCRIPTION

The Short Articulated Part Control packet is provided as a lower-bandwidth 
alternative to the Articulated Part Control packet. It can be used when 
manipulation of only one or two degrees of freedom of a submodel is necessary.

This packet allows for up to two articulations. The articulations may be 
applied to a single articulated part or two separate ones belonging to the same 
entity. The articulated part or parts are specified by the Articulated Part ID 
1 and Articulated Part ID 2 attributes. Two floating-point degree-of-freedom 
attributes, DOF 1 and DOF 2, specify offsets or angular positions for the 
specified articulated parts. The DOF Select 1 and DOF Select 2 attributes 
specify which degree of freedom each of these floating-point attributes 
represents.
Note: If DOF Select 1 and DOF Select 2 refer to the same degree of freedom for 
the same articulated part, then DOF 2 (i.e., the "last-in" value) takes 
priority over DOF 1.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sap_ctl = Rinchi::CIGIPP::ShortArticulatedPartControl->new()

Constructor for Rinchi::ShortArticulatedPartControl.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78ac504-200e-11de-bda7-001c25551abc',
    '_Pack'                                => 'CCSCCCCff',
    '_Swap1'                               => 'CCvCCCCVV',
    '_Swap2'                               => 'CCnCCCCNN',
    'packetType'                           => 7,
    'packetSize'                           => 16,
    'entityIdent'                          => 0,
    'articulatedPartIdent1'                => 0,
    'articulatedPartIdent2'                => 0,
    '_bitfields1'                          => 0, # Includes bitfields articulatedPartEnable2, articulatedPartEnable1, dofSelect2, and dofSelect1.
    'articulatedPartEnable2'               => 0,
    'articulatedPartEnable1'               => 0,
    'dofSelect2'                           => 0,
    'dofSelect1'                           => 0,
    '_unused9'                             => 0,
    'degreeOfFreedom1'                     => 0,
    'degreeOfFreedom2'                     => 0,
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

 $value = $sap_ctl->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Short Articulated Part 
Control packet. The value of this attribute must be 7.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sap_ctl->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub entity_ident([$newValue])

 $value = $sap_ctl->entity_ident($newValue);

Entity ID.

This attribute specifies the entity to which the articulated part(s) belongs.

=cut

sub entity_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'entityIdent'} = $nv;
  }
  return $self->{'entityIdent'};
}

#==============================================================================

=item sub articulated_part_ident1([$newValue])

 $value = $sap_ctl->articulated_part_ident1($newValue);

Articulated Part ID 1.

This attribute specifies one of up to two articulated parts to which the data 
in this packet should be applied. When used with the Entity ID attribute, this 
attribute uniquely identifies a particular articulated part within the scene 
graph.
The value of this attribute may be equal to that of Articulated Part ID 2.

=cut

sub articulated_part_ident1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'articulatedPartIdent1'} = $nv;
  }
  return $self->{'articulatedPartIdent1'};
}

#==============================================================================

=item sub articulated_part_ident2([$newValue])

 $value = $sap_ctl->articulated_part_ident2($newValue);

Articulated Part ID 2.

This attribute specifies one of up to two articulated parts to which the data 
in this packet should be applied. When used with the Entity ID attribute, this 
attribute uniquely identifies a particular articulated part within the scene 
graph.
The value of this attribute may be equal to that of Articulated Part ID 1.

=cut

sub articulated_part_ident2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'articulatedPartIdent2'} = $nv;
  }
  return $self->{'articulatedPartIdent2'};
}

#==============================================================================

=item sub articulated_part_enable2([$newValue])

 $value = $sap_ctl->articulated_part_enable2($newValue);

Articulated Part Enable 2.

This attribute determines whether the articulated part submodel specified by 
Articulated Part ID 2 should be enabled or disabled within the scene graph. If 
this attribute is set to Disable (0), the part is removed from the scene; if 
the attribute is set to Enable (1), the part is included in the scene.

    Disable   0
    Enable    1

=cut

sub articulated_part_enable2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'articulatedPartEnable2'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 7) &0x80;
    } else {
      carp "articulated_part_enable2 must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x80) >> 7);
}

#==============================================================================

=item sub articulated_part_enable1([$newValue])

 $value = $sap_ctl->articulated_part_enable1($newValue);

Articulated Part Enable 1.

This attribute determines whether the articulated part submodel specified by 
Articulated Part ID 1 should be enabled or disabled within the scene graph. If 
this attribute is set to Disable (0), the part is removed from the scene; if 
the attribute is set to Enable (1), the part is included in the scene.

    Disable   0
    Enable    1

=cut

sub articulated_part_enable1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'articulatedPartEnable1'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 6) &0x40;
    } else {
      carp "articulated_part_enable1 must be 0 (Disable), or 1 (Enable).";
    }
  }
  return (($self->{'_bitfields1'} & 0x40) >> 6);
}

#==============================================================================

=item sub dof_select2([$newValue])

 $value = $sap_ctl->dof_select2($newValue);

DOF Select 2.

This attribute specifies the degree of freedom to which the value of DOF 2 is 
applied.
If this attribute is set to Not Used (0), both DOF 2 and Articulated Part 
Enable 2 are ignored.

    NotUsed   0
    XOffset   1
    YOffset   2
    ZOffset   3
    Yaw       4
    Pitch     5
    Roll      6

=cut

sub dof_select2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6)) {
      $self->{'dofSelect2'} = $nv;
      $self->{'_bitfields1'} |= ($nv << 3) &0x38;
    } else {
      carp "dof_select2 must be 0 (NotUsed), 1 (XOffset), 2 (YOffset), 3 (ZOffset), 4 (Yaw), 5 (Pitch), or 6 (Roll).";
    }
  }
  return (($self->{'_bitfields1'} & 0x38) >> 3);
}

#==============================================================================

=item sub dof_select1([$newValue])

 $value = $sap_ctl->dof_select1($newValue);

DOF Select 1.

This attribute specifies the degree of freedom to which the value of DOF 1 is 
applied.
If this attribute is set to Not Used (0), both DOF 1 and Articulated Part 
Enable 1 are ignored.

    NotUsed   0
    XOffset   1
    YOffset   2
    ZOffset   3
    Yaw       4
    Pitch     5
    Roll      6

=cut

sub dof_select1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1) or ($nv==2) or ($nv==3) or ($nv==4) or ($nv==5) or ($nv==6)) {
      $self->{'dofSelect1'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x07;
    } else {
      carp "dof_select1 must be 0 (NotUsed), 1 (XOffset), 2 (YOffset), 3 (ZOffset), 4 (Yaw), 5 (Pitch), or 6 (Roll).";
    }
  }
  return ($self->{'_bitfields1'} & 0x07);
}

#==============================================================================

=item sub degree_of_freedom1([$newValue])

 $value = $sap_ctl->degree_of_freedom1($newValue);

DOF 1.

This attribute specifies either an offset or an angular position for the part 
identified by Articulated Part ID 1.

The application of this value is determined by the DOF Select 1 attribute. If 
the attribute is set to X Offset (1), Y Offset (2), or Z Offset (3), then DOF 1 
specifies an offset in meters. If DOF Select 1 is set to Yaw (4), Pitch (5), or 
Roll (6), then DOF 1 specifies an angular position in degrees.

=cut

sub degree_of_freedom1() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'degreeOfFreedom1'} = $nv;
  }
  return $self->{'degreeOfFreedom1'};
}

#==============================================================================

=item sub degree_of_freedom2([$newValue])

 $value = $sap_ctl->degree_of_freedom2($newValue);

DOF 2.

This attribute specifies either an offset or an angular position for the part 
identified by Articulated Part ID 2.

The application of this value is determined by the DOF Select 2 attribute. If 
the attribute is set to X Offset (1), Y Offset (2), or Z Offset (3), then DOF 2 
specifies an offset in meters. If DOF Select 2 is set to Yaw (4), Pitch (5), or 
Roll (6), then DOF 2 specifies an angular position in degrees.

=cut

sub degree_of_freedom2() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'degreeOfFreedom2'} = $nv;
  }
  return $self->{'degreeOfFreedom2'};
}

#==========================================================================

=item sub pack()

 $value = $sap_ctl->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'entityIdent'},
        $self->{'articulatedPartIdent1'},
        $self->{'articulatedPartIdent2'},
        $self->{'_bitfields1'},    # Includes bitfields articulatedPartEnable2, articulatedPartEnable1, dofSelect2, and dofSelect1.
        $self->{'_unused9'},
        $self->{'degreeOfFreedom1'},
        $self->{'degreeOfFreedom2'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sap_ctl->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'entityIdent'}                         = $c;
  $self->{'articulatedPartIdent1'}               = $d;
  $self->{'articulatedPartIdent2'}               = $e;
  $self->{'_bitfields1'}                         = $f; # Includes bitfields articulatedPartEnable2, articulatedPartEnable1, dofSelect2, and dofSelect1.
  $self->{'_unused9'}                            = $g;
  $self->{'degreeOfFreedom1'}                    = $h;
  $self->{'degreeOfFreedom2'}                    = $i;

  $self->{'articulatedPartEnable2'}              = $self->articulated_part_enable2();
  $self->{'articulatedPartEnable1'}              = $self->articulated_part_enable1();
  $self->{'dofSelect2'}                          = $self->dof_select2();
  $self->{'dofSelect1'}                          = $self->dof_select1();

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
  my ($a,$b,$c,$d,$e,$f,$g,$h,$i) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f,$g,$h,$i);
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
