package RFID::Libnfc::Tag::ISO14443A_106;

use strict;

use base qw(RFID::Libnfc::Tag);
use RFID::Libnfc::Constants;

our $VERSION = "0.13";

sub init {
    my ($self) = @_;
    $self->{_keys} = [];
    $self->{_nai} = $self->{_nti}->nai;
    return $self;
}

sub type {
    my $self = shift;
    my $type;
    my $pti;
    if (ref($self) and UNIVERSAL::isa($self, "RFID::Libnfc::Tag::ISO14443A_106")) { # instance method
        $type = $self->{_type};
        $pti = $self->{_nai};
    } else { # instance method. expecting $pti as argument
        $pti = shift->nai; 
    }
    unless ($type) {
        $type =  
            ($pti->btSak==0x00)?"ULTRA":
            ($pti->btSak==0x08)?"Classic::1K":
            ($pti->btSak==0x09)?"Classic::MINI":
            ($pti->btSak==0x18)?"Classic::4K":
            ($pti->btSak==0x20)?"DESFIRE":
            ($pti->btSak==0x28)?"JCOP30":
            ($pti->btSak==0x38)?"JCOP40":
            ($pti->btSak==0x88)?"OYSTER":
            ($pti->btSak==0x98)?"GEMPLUS MPCOS":
            "unknown";
    }
    return $type;
}

sub atqa {
    my $self = shift;
    unless ($self->{_atqa}) {
        #$self->{_atqa} = [ $self->{_nai}->abtAtqa1, $self->{_nai}->abtAtqa2 ];
        $self->{_atqa} = [ unpack("CC", $self->{_nai}->abtAtqa) ];
    }
    return $self->{_atqa};
}

sub uid {
    my $self = shift;
    unless ($self->{_uid}) {
        my $uidLen = $self->{_nai}->szUidLen;
        if ($uidLen) {
            $self->{_uid} = [ unpack("C".$uidLen, $self->{_nai}->abtUid) ];
        }
    }
    return $self->{_uid};
}

sub btsak {
    my $self = shift;
    unless ($self->{_btsak}) {
        $self->{_btsak} = $self->{_nai}->btSak;
    }
    return $self->{_btsak};
}

sub ats {
    my $self = shift;
    unless ($self->{_ats}) {
        if ($self->{_nai}->uiAtsLen) {
            my $atsLen = $self->{_nai}->uiAtsLen;
            my $self->{_ats} = [ unpack("C".$atsLen, $self->{_nai}->abtAts) ];
        }
    }
    return $self->{_ats};
}

sub dump_info {
    my $self = shift;
    if ($self->uid) {
        printf ("Uid:\t". "%02x " x scalar(@{$self->uid}). "\n", @{$self->uid});
    } else {
        printf ("Uid:\tunknown\n");
    }
    printf ("Type:\t%s\n", $self->type || "unknown");
    if ($self->atqa && scalar(@{$self->atqa})) {
        printf ("Atqa:\t%02x %02x\n", @{$self->atqa});
    } else {
        printf ("Atqa:\tunknown\n");
    }
    printf ("BtSak:\t%02x\n", $self->btsak);
    if ($self->ats) {
        printf ("Ats:\t". "%02x " x scalar(@{$self->ats}) ."\n", @{$self->ats});
    }
}

sub ping {
    my $self = shift;
    # try reading sector 0 to see if the tag is alive
    return $self->read_block(0)?1:0;
}

# XXX - doesn't work
sub crc {
    my ($self, $data) = @_;
    my $bt;
    my $ofx = 0;
    my $len = length($data);
    my $wCrc = pack("N", 0x6363);
    while ($ofx < $len) {
        $bt = unpack("x${ofx}C", $data);
        $bt = ($bt^($wCrc & 0x00ff));
        $bt = ($bt^($bt << 4));
        $wCrc = ($wCrc >> 8)^($bt << 8)^($bt << 3)^($bt >> 4);
        $ofx++;
    }
    return $wCrc;
}

1;
__END__
=head1 NAME

RFID::Libnfc::Tag - base class for ISO14443A_106 compliant tags.
You won't never use this module direcctly but all the logic 
common to all ISO14443A_106 tags should be placed here 
(and inherited by all specific tag-implementations)

=head1 SYNOPSIS

  use RFID::Libnfc;

  $tag = $r->connectTag(IM_ISO14443A_106);

=head1 DESCRIPTION

  Base class for ISO14443A_106 compliant tags

=head2 EXPORT

None by default.

=head2 Exportable functions

=head1 METHODS

=over

=item * type

returns the specific tag type actually hooked (as string)

can be any of: 

* ULTRA 1K MINI 4K DESFIRE JCOP30 JCOP40 OYSTER GEMPLUS MPCOS *

(NOTE: only 4K and ULTRA are actually implemented)

=item * atqa ( )

Returns an arrayref containing the 2 atqa bytes 

=item * uid ( )

Returns an arrayref containing all uid bytes

=item * btsak ( )

Returns the btsak byte (which is used to determine the tag type)

=item * ats ( )

=item * dump_info ( )

Prints out all know information on the hooked tag

=item * ping ( )

Return 1 if the tag is still reachable , 0 otherwise

=item * crc ( )

Compute the crc as required by ISO14443A_106 standard

=item * error ( )


=back

=head1 SEE ALSO

RFID::Libnfc::Tag::ISO14443A_106::ULTRA RFID::Libnfc::Tag::ISO14443A_106::4K
RFID::Libnfc::Tag::ISO14443A_106 RFID::Libnfc::Constants RFID::Libnfc 

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

