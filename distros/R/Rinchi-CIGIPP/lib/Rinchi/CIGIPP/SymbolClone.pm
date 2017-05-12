#
# Rinchi Common Image Generator Interface for Perl
# Class Identifier: f78b105e-200e-11de-bdc3-001c25551abc
# Author: Brian M. Ames
#

package Rinchi::CIGIPP::SymbolClone;

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

Rinchi::CIGIPP::SymbolClone - Perl extension for the Common Image Generator 
Interface - Symbol Clone data packet.
 data packet.
=head1 SYNOPSIS

  use Rinchi::CIGIPP::SymbolClone;
  my $sym_clone = Rinchi::CIGIPP::SymbolClone->new();

  $packet_type = $sym_clone->packet_type();
  $packet_size = $sym_clone->packet_size();
  $symbol_ident = $sym_clone->symbol_ident(41795);
  $source_type = $sym_clone->source_type(Rinchi::CIGIPP->Symbol);
  $source_ident = $sym_clone->source_ident(42236);

=head1 DESCRIPTION

The Symbol Clone packet is used to create an exact copy of a symbol. The copy 
will inherit all attributes that were defined by the Symbol Text Definition, 
Symbol Circle Definition, Symbol Line Definition, or Symbol Clone packet that 
was used to create the original symbol. Any operations that are performed upon 
the copy (e.g., translation, rotation, or change of color) will not affect the 
original unless otherwise dictated by a hierarchical relationship.

Alternatively, the Symbol Clone packet can be used to instantiate an IG-defined 
symbol template (see Section 3.3.3). Operations performed on the symbol 
instance will not affect the template.

When a new symbol is created with a Symbol Clone packet, that symbol is hidden 
by default. The symbol will remain hidden until its state is changed with a 
Symbol Control packet.

=head2 EXPORT

None by default.

#==============================================================================

=item new $sym_clone = Rinchi::CIGIPP::SymbolClone->new()

Constructor for Rinchi::SymbolClone.

=cut

sub new {
  my $class = shift;
  $class = ref($class) || $class;

  my $self = {
    '_Buffer'                              => '',
    '_ClassIdent'                          => 'f78b105e-200e-11de-bdc3-001c25551abc',
    '_Pack'                                => 'CCSCCS',
    '_Swap1'                               => 'CCvCCv',
    '_Swap2'                               => 'CCnCCn',
    'packetType'                           => 33,
    'packetSize'                           => 8,
    'symbolIdent'                          => 0,
    '_bitfields1'                          => 0, # Includes bitfields unused59, and sourceType.
    'sourceType'                           => 0,
    '_unused60'                            => 0,
    'sourceIdent'                          => 0,
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

 $value = $sym_clone->packet_type();

Data Packet Identifier.

This attribute identifies this data packet as the Symbol Clone packet. The 
value of this attribute must be 33.

=cut

sub packet_type() {
  my ($self) = @_;
  return $self->{'packetType'};
}

#==============================================================================

=item sub packet_size()

 $value = $sym_clone->packet_size();

Data Packet Size.

This attribute indicates the number of bytes in this data packet. The value of 
this attribute must be 16.

=cut

sub packet_size() {
  my ($self) = @_;
  return $self->{'packetSize'};
}

#==============================================================================

=item sub symbol_ident([$newValue])

 $value = $sym_clone->symbol_ident($newValue);

Symbol ID.

This attribute specifies the identifier of the symbol that is being defined.

This identifier must be unique among all existing symbols. If a symbol with the 
specified identifier already exists, then that symbol and any children will be 
destroyed and a new symbol created.

=cut

sub symbol_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'symbolIdent'} = $nv;
  }
  return $self->{'symbolIdent'};
}

#==============================================================================

=item sub source_type([$newValue])

 $value = $sym_clone->source_type($newValue);

Source Type.

This attribute determines whether the new symbol will be a copy of an existing 
symbol or an instance of an IG-defined symbol template.

    Symbol           0
    SymbolTemplate   1

=cut

sub source_type() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    if (($nv==0) or ($nv==1)) {
      $self->{'sourceType'} = $nv;
      $self->{'_bitfields1'} |= $nv &0x01;
    } else {
      carp "source_type must be 0 (Symbol), or 1 (SymbolTemplate).";
    }
  }
  return ($self->{'_bitfields1'} & 0x01);
}

#==============================================================================

=item sub source_ident([$newValue])

 $value = $sym_clone->source_ident($newValue);

Source ID.

This attribute identifies the symbol to be copied or the symbol template to be 
instantiated.
If Source Type is set to Symbol (0), then this attribute will specify the 
identifier of the symbol to be copied.

If Source Type is set to Symbol Template (1), then this attribute will specify 
the identifier of the symbol template to be instantiated.

If the specified source does not exist, then the packet will be ignored.

=cut

sub source_ident() {
  my ($self,$nv) = @_;
  if (defined($nv)) {
    $self->{'sourceIdent'} = $nv;
  }
  return $self->{'sourceIdent'};
}

#==========================================================================

=item sub pack()

 $value = $sym_clone->pack();

Returns the packed data packet.

=cut

sub pack($) {
  my $self = shift ;
  
  $self->{'_Buffer'} = CORE::pack($self->{'_Pack'},
        $self->{'packetType'},
        $self->{'packetSize'},
        $self->{'symbolIdent'},
        $self->{'_bitfields1'},    # Includes bitfields unused59, and sourceType.
        $self->{'_unused60'},
        $self->{'sourceIdent'},
      );

  return $self->{'_Buffer'};
}

#==========================================================================

=item sub unpack()

 $value = $sym_clone->unpack();

Unpacks the packed data packet.

=cut

sub unpack($) {
  my $self = shift @_;
  
  if (@_) {
     $self->{'_Buffer'} = shift @_;
  }
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Pack'},$self->{'_Buffer'});
  $self->{'packetType'}                          = $a;
  $self->{'packetSize'}                          = $b;
  $self->{'symbolIdent'}                         = $c;
  $self->{'_bitfields1'}                         = $d; # Includes bitfields unused59, and sourceType.
  $self->{'_unused60'}                           = $e;
  $self->{'sourceIdent'}                         = $f;

  $self->{'sourceType'}                          = $self->source_type();

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
  my ($a,$b,$c,$d,$e,$f) = CORE::unpack($self->{'_Swap1'},$self->{'_Buffer'});

  $self->{'_Buffer'} = CORE::pack($self->{'_Swap2'},$a,$b,$c,$d,$e,$f);
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
