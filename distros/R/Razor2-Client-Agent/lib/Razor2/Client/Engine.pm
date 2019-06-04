package Razor2::Client::Engine;

use strict;
use Digest::SHA1 qw(sha1_hex);
use Data::Dumper;
use Razor2::Signature::Ephemeral;
use Razor2::Engine::VR8;
use Razor2::Preproc::Manager;
use Razor2::String qw(hextobase64 makesis debugobj);

# meant to be inherited
#
sub new {
    return {};
}

sub supported_engines {

    my @a = qw( 4 8 );

    my $hr = {};
    foreach (@a) { $hr->{$_} = 1; }

    return wantarray ? @a : $hr;
}

sub compute_engine {
    my ( $self, $engine, @params ) = @_;

    return $self->vr4_signature(@params) if $engine == 4;
    return $self->vr8_signature(@params) if $engine == 8;

    $self->log( 1, "engine $engine not supported" );
    return;
}

#
# The following *_signature subroutines should be
# the same as the ones on the server
#

#
# VR4 Engine - Ephemereal signatures of decoded body content
#
sub vr4_signature {
    my ( $self, $text, $ep4 ) = @_;
    my ( $seed, $separator ) = split /-/, $ep4, 2;

    return $self->log( 1, "vr4_signature: Bad ep4: $ep4" ) unless ( $seed && $separator );

    my $ehash = new Razor2::Signature::Ephemeral( seed => $seed, separator => $separator );
    my $digest = $ehash->hexdigest($$text);

    my $sig = hextobase64($digest);
    $self->log( 11, "engine 4 computing on " . length($$text) . ", sig=$sig" );
    return $sig;
}

sub vr8_signature {
    my ( $self, $text ) = @_;
    my $vr8 = Razor2::Engine::VR8->new();

    my $sigs = $vr8->signature($text);

    return $sigs;
}

1;
