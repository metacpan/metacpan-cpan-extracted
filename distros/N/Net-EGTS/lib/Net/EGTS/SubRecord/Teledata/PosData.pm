use utf8;

package Net::EGTS::SubRecord::Teledata::PosData;
use Mouse;
extends qw(Net::EGTS::SubRecord);

use Carp;

use Net::EGTS::Util     qw(usize time2new str2time lat2mod lon2mod dumper_bitstring);
use Net::EGTS::Codes;

=head1 NAME

Net::EGTS::SubRecord::Teledata::PosData - subrecord containing telemetry data.

=head1 SEE ALSO

L<https://zakonbase.ru/content/part/1191925?print=1>

=cut

# Navigation Time
has NTM         => is => 'rw', isa => 'UINT', default => sub{ time2new };
# Latitude
has LAT         => is => 'rw', isa => 'UINT';
# Longitude
has LONG        => is => 'rw', isa => 'UINT';

# Flags:
# altitude exists
has ALTE        => is => 'rw', isa => 'BIT1', default => 0;
# east/west
has LOHS        => is => 'rw', isa => 'BIT1';
# south/nord
has LAHS        => is => 'rw', isa => 'BIT1';
# move
has MV          =>
    is          => 'rw',
    isa         => 'BIT1',
    lazy        => 1,
    builder     => sub { $_[0]->SPD_LO || $_[0]->SPD_HI ? 0x1 : 0x0 },
;
# from storage
has BB          => is => 'rw', isa => 'BIT1', default => 0;
# coordinate system
has CS          => is => 'rw', isa => 'BIT1', default => 0;
# 2d/3d
has FIX         => is => 'rw', isa => 'BIT1', default => 1;
# valid
has VLD         => is => 'rw', isa => 'BIT1', default => 1;

# Speed (lower bits)
has SPD_LO      => is => 'rw', isa => 'BYTE', default => 0;
# Direction the Highest bit
has DIRH        => is => 'rw', isa => 'BIT1', default => 0;
# Altitude Sign
has ALTS        => is => 'rw', isa => 'BIT1', default => 0;
# Speed (highest bits)
has SPD_HI      => is => 'rw', isa => 'BIT6', default => 0;

# Direction
has DIR         => is => 'rw', isa => 'BYTE', default => 0;
# Odometer
has ODM         => is => 'rw', isa => 'BINARY3', default => 0x000;
# Digital Inputs
has DIN         => is => 'rw', isa => 'BIT8', default => 0b00000000;
# Source
has SRC         => is => 'rw', isa => 'BYTE', default => EGTS_SRCD_TIMER;

# Optional:
# Altitude
has ALT         => is => 'rw', isa => 'Maybe[BINARY3]';
# Source Data
has SRCD        => is => 'rw', isa => 'Maybe[SHORT]';

after 'decode' => sub {
    my ($self) = @_;
    die 'SubRecord not EGTS_SR_POS_DATA type'
        unless $self->SRT == EGTS_SR_POS_DATA;

    my $bin = $self->SRD;
    $self->NTM( $self->nip(\$bin => 'L') );
    $self->LAT( $self->nip(\$bin => 'L') );
    $self->LONG($self->nip(\$bin => 'L') );

    my $flags = $self->nip(\$bin => 'C');
    $self->ALTE( ($flags & 0b10000000) >> 7 );
    $self->LOHS( ($flags & 0b01000000) >> 6 );
    $self->LAHS( ($flags & 0b00100000) >> 5 );
    $self->MV(   ($flags & 0b00010000) >> 4 );
    $self->BB(   ($flags & 0b00001000) >> 3 );
    $self->CS(   ($flags & 0b00000100) >> 2 );
    $self->FIX(  ($flags & 0b00000010) >> 1 );
    $self->VLD(  ($flags & 0b00000001)      );

    $self->SPD_LO( $self->nip(\$bin => 'C') );

    my $stupid = $self->nip(\$bin => 'C');
    $self->DIRH( ($stupid & 0b10000000) >> 7 );
    $self->ALTS( ($stupid & 0b01000000) >> 6 );
    $self->SPD_HI($stupid & 0b00111111 );

    $self->DIR( $self->nip(\$bin => 'C') );
    $self->ODM( $self->nip(\$bin => 'a3') );
    $self->DIN( $self->nip(\$bin => 'C') );
    $self->SRC( $self->nip(\$bin => 'C') );

    $self->ALT( $self->nip(\$bin => 'a3') ) if $self->ALTE;
    $self->SRCD($self->nip(\$bin => 'S' => length($bin)) );
};


before 'encode' => sub {
    my ($self) = @_;
    use bytes;

    die 'SubRecord not EGTS_SR_POS_DATA type'
        unless $self->SRT == EGTS_SR_POS_DATA;

    # Pack stupid bits economy
    my $stupid = $self->SPD_HI;
    $stupid = ($stupid | 0b10000000) if $self->DIRH;
    $stupid = ($stupid | 0b01000000) if $self->ALTS;

    my $bin = '';
    $bin .= pack 'L'    => $self->NTM;
    $bin .= pack 'L'    => $self->LAT;
    $bin .= pack 'L'    => $self->LONG;
    $bin .= pack 'B8'   => sprintf(
        '%b%b%b%b%b%b%b%b',
        $self->ALTE, $self->LOHS, $self->LAHS, $self->MV,
        $self->BB, $self->CS, $self->FIX, $self->VLD
    );
    $bin .= pack 'C'    => $self->SPD_LO;
    $bin .= pack 'C'    => $stupid;
    $bin .= pack 'C'    => $self->DIR;
    $bin .= pack 'a3'   => substr(pack("L", $self->ODM), 0, 3);
    $bin .= pack 'B8'   => $self->DIN;
    $bin .= pack 'C'    => $self->SRC;
    $bin .= pack 'a3'   => substr(pack("L", $self->ALT), 0, 3)
        if $self->ALTE;
    $bin .= pack 'S'    => $self->SRCD
        if defined $self->SRCD;

    $self->SRD( $bin );
};

around BUILDARGS => sub {
    my $orig    = shift;
    my $class   = shift;

    # simple scalar decoding support
    my $bin   = @_ % 2 ? shift : undef;
    my %opts  = @_;

    # Simple helpers for real data:
    if( defined( my $time = delete $opts{time} ) ) {
        $opts{NTM}  = time2new str2time $time;
    }

    if( defined( my $lat = delete $opts{latitude} ) ) {
        $opts{LAT}  = lat2mod $lat;
        $opts{LAHS} = $lat > 0 ? 0x0 : 0x1
    }

    if( defined( my $lon = delete $opts{longitude} ) ) {
        $opts{LONG} = lon2mod $lon;
        $opts{LOHS} = $lon > 0 ? 0x0 : 0x1
    }

    if( defined( my $direction = delete $opts{direction} ) ) {
        if( $direction > 255 ) {
            $opts{DIRH} = 1;
            $opts{DIR}  = $direction - 256;
        } else {
            $opts{DIRH} = 0;
            $opts{DIR}  = $direction;
        }
    }

    if( defined( my $dist = delete $opts{dist} ) ) {
        $opts{ODM} = int(($dist // 0) * 10);
    }

    if( defined( my $avg_speed = delete $opts{avg_speed} ) ) {
        # Speed rounded to 0.1
        my $SPD     = int(($avg_speed // 0) * 10);

        $opts{SPD_LO} = ($SPD & 0x000000ff);
        $opts{SPD_HI} = ($SPD & 0x0000ff00) >> 8;
    }

    if( defined( my $order = delete $opts{order} ) ) {
        $opts{DIN} = $order ? 0b10000000 : 0b00000000;
    }

    return $class->$orig( bin => $bin, %opts, SRT => EGTS_SR_POS_DATA ) if $bin;
    return $class->$orig(              %opts, SRT => EGTS_SR_POS_DATA );
};

augment as_debug => sub {
    my ($self) = @_;
    use bytes;

    my @bytes = ((unpack('B*', $self->SRD)) =~ m{.{8}}g);

    my @str;
    push @str => sprintf('NTM:    %s %s %s %s', splice @bytes, 0 => usize('L'));
    push @str => sprintf('LAT:    %s %s %s %s', splice @bytes, 0 => usize('L'));
    push @str => sprintf('LONG:   %s %s %s %s', splice @bytes, 0 => usize('L'));

    push @str => sprintf('FLAGS:  %s',          splice @bytes, 0 => usize('C'));

    push @str => sprintf('SPD_LO: %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('SPD_HI: %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('DIR:    %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('ODM:    %s %s %s',    splice @bytes, 0 => 3);
    push @str => sprintf('DIN:    %s',          splice @bytes, 0 => usize('C'));
    push @str => sprintf('SRC:    %s',          splice @bytes, 0 => usize('C'));

    push @str => sprintf('ALT:    %s %s %s',    splice @bytes, 0 => 3)
        if $self->ALTE;
    push @str => sprintf('SRCD:   %s %s',       splice @bytes, 0 => usize('S'))
        if @bytes;

    return @str;
};

__PACKAGE__->meta->make_immutable();
