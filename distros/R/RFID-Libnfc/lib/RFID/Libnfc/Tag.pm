package RFID::Libnfc::Tag;

use strict;

use RFID::Libnfc qw(nfc_configure nfc_initiator_select_passive_target nfc_initiator_deselect_target);
use RFID::Libnfc::Constants;
use Data::Dumper;

our $VERSION = '0.13';

my %types = (
    scalar(IM_ISO14443A_106) => 'RFID::Libnfc::Tag::ISO14443A_106'
);

sub new {
    my ($class, $reader, $type, $blocking) = @_;

    die "Invalid parameters to @{[ __PACKAGE__ ]} constructor"
      unless ($reader 
        and ref($reader) 
        and UNIVERSAL::isa($reader, "RFID::Libnfc::Reader"));

    $type = IM_ISO14443A_106 unless($type); #defaults to IM_ISO14443A_106

    my $self = {};
    $self->{debug} = $reader->{debug};
    # Try to find the requested tag type
    $self->{_last_error} = "";
    $self->{reader} = $reader;
    nfc_configure($reader->pdi, NDO_ACTIVATE_FIELD, 0);
    # Let the reader only try once to find a tag
    nfc_configure($reader->pdi, NDO_INFINITE_SELECT, $blocking?1:0);
    nfc_configure($reader->pdi, NDO_HANDLE_CRC, 1);
    nfc_configure($reader->pdi, NDO_HANDLE_PARITY, 1);
    # Enable field so more power consuming cards can power themselves up
    nfc_configure($reader->pdi, NDO_ACTIVATE_FIELD, 1);

    $self->{_t} = RFID::Libnfc::Target->new();
    $self->{_t}->nm->nmt($type);
    $self->{_nti} = $self->{_t}->nti;
    if (!nfc_initiator_select_passive_target($reader->pdi, $self->{_t}->nm, 0, 0, $self->{_t}))
    {
        #warn "No tag was found";
        return undef;
    } else {
        print "Card:\t ".(split('::', $types{$type}))[2]." found\n" if $self->{debug};
    }

    if ($types{$type} && eval "require $types{$type};") {
        my $productType = $types{$type}->type($self->{_nti});
        if ($productType && eval "require $types{$type}::$productType;") {
            bless $self, "$types{$type}::$productType";
        } else {
            warn "Unsupported product type $types{$type}::$productType";
            return undef;
        }
    } else {
        warn "Unknown tag type $type";
        return undef;
    }

    $self->init;
    return $self;
}

sub error {
    my $self = shift;
    return $self->{_last_error};
}

sub reader {
    my $self = shift;
    return $self->{reader};
}

sub AUTOLOAD {
    our $AUTOLOAD;
    warn "$AUTOLOAD not implemented \n";
    return undef;
}

sub DESTROY {
    my $self = shift;
    nfc_initiator_deselect_target($self->reader->pdi);
}

# number of blocks on the tag
sub blocks {
    return 0;
}

# number of sectors on the tag
sub sectors {
    return 0;
}

1;
__END__
=head1 NAME

RFID::Libnfc::Tag - base class for specific tag implementations

=head1 SYNOPSIS

  use RFID::Libnfc;
  use RFID::Constants;

  $tag = $r->connectTag(IM_ISO14443A_106);

=head1 DESCRIPTION

  Base class for all specific tag implementations

=head2 EXPORT

None by default.

=head2 Exportable functions

=head1 METHODS

=over

=item * reader

returns the current reader object ( RFID::Libnfc::Reader )

=item * error ()

returns the underlying reader descriptor (to be used with the RFID::Libnfc procedural api)
$pdi = $r->pdi

=back

=head1 SEE ALSO

RFID::Libnfc::Tag::ISO14443A_106::ULTRA RFID::Libnfc::Tag::ISO14443A_106::4K
RFID::Libnfc::Tag::ISO14443A_106 RFID::Libnfc::Constants RFID::Libnfc 

** 
  check also documentation for libnfc c library 
  [ http://www.libnfc.org/documentation/introduction ] 

**

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
