package RFID::Libnfc::Reader;

use 5.008008;
use strict;
use warnings;
use Carp;

use RFID::Libnfc qw(nfc_connect nfc_disconnect nfc_initiator_init nfc_configure);
use RFID::Libnfc::Tag;
use RFID::Libnfc::Constants;

our $VERSION = '0.13';

sub new {
    my ($class, %args) = @_;
    my $self = bless {%args}, $class;
    $self->{_pdi} = nfc_connect();
    croak "No device" unless $self->{_pdi};
    return $self;
}

sub init {
    my $self = shift;
    if (nfc_initiator_init($self->{_pdi})) {
        return $self;
    }
    return undef;
}

sub name {
    my $self = shift;
    unless($self->{_name}) {
        $self->{_name} = $self->{_pdi}->acName;
    }
    return $self->{_name};
}

sub connect {
    return RFID::Libnfc::Tag->new(@_);
}

sub pdi {
    my $self = shift;
    return $self->{_pdi};
}

# just an accessor
sub print_hex {
    my $self = shift;
        RFID::Libnfc::print_hex(@_);
}

sub DESTROY {
    my $self = shift;
    nfc_disconnect($self->{_pdi})
        if ($self->{_pdi});
}

1;
__END__
=head1 NAME

RFID::Libnfc::Reader - Access libnfc-compatible tag readers

=head1 SYNOPSIS

  use RFID::Libnfc;

  $r = RFID::Libnfc::Reader->new();
  if ($r->init()) {
    printf ("Reader: %s\n", $r->name);
  }

  $tag = $r->connectTag(IM_ISO14443A_106);

=head1 DESCRIPTION

  This reader class allows to access RFID tags 
  (actually only mifare ones have been implemented/tested)
  readable from any libnfc-compatible reader

=head2 EXPORT

None by default.

=head2 Exportable functions

=head1 METHODS

=over

=item * name ( )

returns the name of the current reader

for ex.
$name = $r->name

=item * connect ( TAGFAMILY, BLOCKING )

tries to connect a tag and returns a new ready-to-use RFID::Libnfc::Tag object 
or undef if no tag is found.
If blocking is TRUE, connect won't return untill a tag is found in the field

for ex.
$tag = $r->connect( ISO14443A_106 )

NOTE: ISO14443A_106 is the only type actually implemented/supported

=item * pdi ( )

returns the underlying reader descriptor (to be used with the RFID::Libnfc procedural api)
$pdi = $r->pdi

=back

=head1 SEE ALSO

RFID::Libnfc RFID::Libnfc::Constants RFID::Libnfc::Tag 

< check also documentation for libnfc c library [ http://www.libnfc.org/documentation/introduction ] >

=head1 AUTHOR

xant

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2011 by xant <xant@cpan.org>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
