package Physics::Etch::GDSII;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.01';

# ===========================================================================
# Minimal, dependency-free GDSII stream reader / writer.
#
# Supports the records needed to describe an IC mask layer and flatten a cell
# hierarchy into absolute polygons:
#   HEADER BGNLIB LIBNAME UNITS ENDLIB BGNSTR STRNAME ENDSTR
#   BOUNDARY PATH SREF AREF LAYER DATATYPE WIDTH XY ENDEL SNAME COLROW
#   STRANS MAG ANGLE PATHTYPE
#
# GDSII stores coordinates as signed 32-bit integers in "database units".
# UNITS gives (user_units_per_db_unit, meters_per_db_unit) as 8-byte reals.
# ===========================================================================

# record types
use constant {
    R_HEADER   => 0x00, R_BGNLIB => 0x01, R_LIBNAME => 0x02, R_UNITS => 0x03,
    R_ENDLIB   => 0x04, R_BGNSTR => 0x05, R_STRNAME => 0x06, R_ENDSTR => 0x07,
    R_BOUNDARY => 0x08, R_PATH   => 0x09, R_SREF    => 0x0A, R_AREF  => 0x0B,
    R_TEXT     => 0x0C, R_LAYER  => 0x0D, R_DATATYPE => 0x0E, R_WIDTH => 0x0F,
    R_XY       => 0x10, R_ENDEL  => 0x11, R_SNAME   => 0x12, R_COLROW => 0x13,
    R_STRANS   => 0x1A, R_MAG    => 0x1B, R_ANGLE   => 0x1C, R_PATHTYPE => 0x21,
};

# data types
use constant {
    D_NODATA => 0, D_BITARR => 1, D_INT2 => 2, D_INT4 => 3,
    D_REAL8  => 5, D_ASCII => 6,
};

# ---------------------------------------------------------------------------
# Constructor (used by both writer and reader)
# ---------------------------------------------------------------------------
sub new {
    my ( $class, %args ) = @_;
    my $self = {
        libname    => $args{libname}   // 'ETCH',
        user_unit  => $args{user_unit} // 1e-6,     # 1 user unit = 1 micron
        db_unit    => $args{db_unit}   // 1e-9,     # 1 db unit   = 1 nm
        structures => {},                            # name => { name, elements }
        order      => [],                            # structure insertion order
    };
    return bless $self, $class;
}

sub libname   { $_[0]->{libname} }
sub user_unit { $_[0]->{user_unit} }               # meters per user unit
sub db_unit   { $_[0]->{db_unit} }                 # meters per database unit

# db units per user unit (integer scale for coordinates)
sub _scale { $_[0]->{user_unit} / $_[0]->{db_unit} }

sub structures { keys %{ $_[0]->{structures} } }
sub structure  { $_[0]->{structures}{ $_[1] } }

# ===========================================================================
# Writer API
# ===========================================================================
sub add_structure {
    my ( $self, $name ) = @_;
    unless ( $self->{structures}{$name} ) {
        $self->{structures}{$name} = { name => $name, elements => [] };
        push @{ $self->{order} }, $name;
    }
    return $self;
}

# points given in USER units (e.g. microns); stored as db-unit integers
sub add_boundary {
    my ( $self, $struct, %a ) = @_;
    $self->add_structure($struct);
    my $scale = $self->_scale;
    my @xy = map { [ _round( $_->[0] * $scale ), _round( $_->[1] * $scale ) ] }
        @{ $a{points} };
    push @{ $self->{structures}{$struct}{elements} },
        {
        type     => 'boundary',
        layer    => $a{layer}    // 0,
        datatype => $a{datatype} // 0,
        xy       => \@xy,
        };
    return $self;
}

# convenience: axis-aligned rectangle from (x,y) width x height, user units
sub add_rectangle {
    my ( $self, $struct, %a ) = @_;
    my ( $x, $y, $w, $h ) = @a{qw(x y width height)};
    return $self->add_boundary(
        $struct,
        layer    => $a{layer},
        datatype => $a{datatype},
        points   => [ [ $x, $y ], [ $x + $w, $y ], [ $x + $w, $y + $h ],
            [ $x, $y + $h ], [ $x, $y ] ],
    );
}

sub add_sref {
    my ( $self, $struct, %a ) = @_;
    $self->add_structure($struct);
    my $scale = $self->_scale;
    push @{ $self->{structures}{$struct}{elements} },
        {
        type    => 'sref',
        sname   => $a{sname},
        xy      => [ [ _round( $a{x} * $scale ), _round( $a{y} * $scale ) ] ],
        reflect => $a{reflect} // 0,
        mag     => $a{mag}     // 1,
        angle   => $a{angle}   // 0,
        };
    return $self;
}

sub add_aref {
    my ( $self, $struct, %a ) = @_;
    $self->add_structure($struct);
    my $scale = $self->_scale;
    my ( $cols, $rows ) = ( $a{cols}, $a{rows} );
    # origin, col-axis point, row-axis point (user units)
    my @pts = map { [ _round( $_->[0] * $scale ), _round( $_->[1] * $scale ) ] }
        ( [ $a{x}, $a{y} ],
        [ $a{x} + $cols * $a{col_pitch}, $a{y} ],
        [ $a{x}, $a{y} + $rows * $a{row_pitch} ] );
    push @{ $self->{structures}{$struct}{elements} },
        {
        type    => 'aref',
        sname   => $a{sname},
        colrow  => [ $cols, $rows ],
        xy      => \@pts,
        reflect => $a{reflect} // 0,
        mag     => $a{mag}     // 1,
        angle   => $a{angle}   // 0,
        };
    return $self;
}

sub write {
    my ( $self, $file ) = @_;
    open my $fh, '>:raw', $file or croak "GDSII: cannot write '$file': $!";
    print {$fh} $self->_serialize;
    close $fh;
    return $self;
}

sub _serialize {
    my ($self) = @_;
    my $out = '';
    $out .= _rec( R_HEADER, D_INT2, 600 );                 # version 6
    $out .= _rec( R_BGNLIB, D_INT2, (0) x 12 );            # timestamps
    $out .= _rec( R_LIBNAME, D_ASCII, $self->{libname} );
    $out .= _rec( R_UNITS, D_REAL8,
        $self->{db_unit} / $self->{user_unit}, $self->{db_unit} );

    for my $name ( @{ $self->{order} } ) {
        my $s = $self->{structures}{$name};
        $out .= _rec( R_BGNSTR, D_INT2, (0) x 12 );
        $out .= _rec( R_STRNAME, D_ASCII, $name );
        for my $el ( @{ $s->{elements} } ) {
            $out .= $self->_serialize_element($el);
        }
        $out .= _rec( R_ENDSTR, D_NODATA );
    }
    $out .= _rec( R_ENDLIB, D_NODATA );
    return $out;
}

sub _serialize_element {
    my ( $self, $el ) = @_;
    my $out = '';
    my $t   = $el->{type};

    if ( $t eq 'boundary' || $t eq 'path' ) {
        $out .= _rec( $t eq 'boundary' ? R_BOUNDARY : R_PATH, D_NODATA );
        $out .= _rec( R_LAYER,    D_INT2, $el->{layer}    // 0 );
        $out .= _rec( R_DATATYPE, D_INT2, $el->{datatype} // 0 );
        $out .= _rec( R_WIDTH, D_INT4, $el->{width} ) if $el->{width};
        $out .= _rec( R_XY, D_INT4, map { @$_ } @{ $el->{xy} } );
        $out .= _rec( R_ENDEL, D_NODATA );
    }
    elsif ( $t eq 'sref' || $t eq 'aref' ) {
        $out .= _rec( $t eq 'sref' ? R_SREF : R_AREF, D_NODATA );
        $out .= _rec( R_SNAME, D_ASCII, $el->{sname} );
        if ( $el->{reflect} || $el->{mag} != 1 || $el->{angle} ) {
            $out .= _rec( R_STRANS, D_BITARR, $el->{reflect} ? 0x8000 : 0 );
            $out .= _rec( R_MAG,   D_REAL8, $el->{mag} )   if $el->{mag} != 1;
            $out .= _rec( R_ANGLE, D_REAL8, $el->{angle} ) if $el->{angle};
        }
        $out .= _rec( R_COLROW, D_INT2, @{ $el->{colrow} } ) if $t eq 'aref';
        $out .= _rec( R_XY, D_INT4, map { @$_ } @{ $el->{xy} } );
        $out .= _rec( R_ENDEL, D_NODATA );
    }
    return $out;
}

# ===========================================================================
# Reader API
# ===========================================================================
sub read {
    my ( $class, $file ) = @_;
    open my $fh, '<:raw', $file or croak "GDSII: cannot read '$file': $!";
    local $/;
    my $bytes = <$fh>;
    close $fh;
    return $class->parse($bytes);
}

sub parse {
    my ( $class, $bytes ) = @_;
    my $self = $class->new;
    $self->{structures} = {};
    $self->{order}      = [];

    my $pos    = 0;
    my $len    = length $bytes;
    my $cur_s;                 # current structure
    my $cur_e;                 # current element

    while ( $pos + 4 <= $len ) {
        my $rlen = unpack( 'n', substr( $bytes, $pos, 2 ) );
        last if $rlen < 4;
        my $rtype = unpack( 'C', substr( $bytes, $pos + 2, 1 ) );
        my $dtype = unpack( 'C', substr( $bytes, $pos + 3, 1 ) );
        my $data  = substr( $bytes, $pos + 4, $rlen - 4 );
        $pos += $rlen;

        if ( $rtype == R_LIBNAME ) { $self->{libname} = _unstr($data); }
        elsif ( $rtype == R_UNITS ) {
            my @r = _real8_decode_all($data);
            # r[0] = user units per db unit, r[1] = meters per db unit
            $self->{db_unit}   = $r[1];
            $self->{user_unit} = $r[1] / $r[0] if $r[0];
        }
        elsif ( $rtype == R_BGNSTR ) { $cur_s = undef; }
        elsif ( $rtype == R_STRNAME ) {
            my $name = _unstr($data);
            $self->add_structure($name);
            $cur_s = $self->{structures}{$name};
        }
        elsif ( $rtype == R_ENDSTR ) { $cur_s = undef; }
        elsif ( $rtype == R_BOUNDARY ) { $cur_e = { type => 'boundary', xy => [] }; }
        elsif ( $rtype == R_PATH )     { $cur_e = { type => 'path',     xy => [] }; }
        elsif ( $rtype == R_SREF )     { $cur_e = { type => 'sref', reflect => 0, mag => 1, angle => 0 }; }
        elsif ( $rtype == R_AREF )     { $cur_e = { type => 'aref', reflect => 0, mag => 1, angle => 0 }; }
        elsif ( $rtype == R_TEXT )     { $cur_e = { type => 'text' }; }
        elsif ( $rtype == R_LAYER )    { $cur_e->{layer}    = unpack( 's>', $data ) if $cur_e; }
        elsif ( $rtype == R_DATATYPE ) { $cur_e->{datatype} = unpack( 's>', $data ) if $cur_e; }
        elsif ( $rtype == R_WIDTH )    { $cur_e->{width}    = unpack( 'l>', $data ) if $cur_e; }
        elsif ( $rtype == R_SNAME )    { $cur_e->{sname}    = _unstr($data) if $cur_e; }
        elsif ( $rtype == R_COLROW )   { $cur_e->{colrow}   = [ unpack( 's>*', $data ) ] if $cur_e; }
        elsif ( $rtype == R_STRANS )   { $cur_e->{reflect}  = ( unpack( 'n', $data ) & 0x8000 ) ? 1 : 0 if $cur_e; }
        elsif ( $rtype == R_MAG )      { $cur_e->{mag}      = ( _real8_decode_all($data) )[0] if $cur_e; }
        elsif ( $rtype == R_ANGLE )    { $cur_e->{angle}    = ( _real8_decode_all($data) )[0] if $cur_e; }
        elsif ( $rtype == R_XY ) {
            my @v = unpack( 'l>*', $data );
            my @pts;
            push @pts, [ $v[$_], $v[ $_ + 1 ] ] for grep { $_ % 2 == 0 } 0 .. $#v;
            $cur_e->{xy} = \@pts if $cur_e;
        }
        elsif ( $rtype == R_ENDEL ) {
            push @{ $cur_s->{elements} }, $cur_e if $cur_s && $cur_e;
            $cur_e = undef;
        }
        elsif ( $rtype == R_ENDLIB ) { last; }
    }
    return $self;
}

# ===========================================================================
# Flatten hierarchy -> absolute polygons on a layer
#   returns list of arrayrefs of [x, y] points.
#   unit: 'db' (integers), 'm' (meters, default), 'um', 'nm'
# ===========================================================================
sub polygons {
    my ( $self, %a ) = @_;
    my $top   = $a{structure} // $self->_top_structure;
    my $layer = $a{layer};
    my $unit  = $a{unit} // 'm';

    croak "GDSII: no such structure '$top'" unless $self->{structures}{$top};

    my @db = $self->_collect( $top, [ 1, 0, 0, 1, 0, 0 ], {}, $layer );

    my $f =
          $unit eq 'db' ? 1
        : $unit eq 'm'  ? $self->{db_unit}
        : $unit eq 'um' ? $self->{db_unit} / 1e-6
        : $unit eq 'nm' ? $self->{db_unit} / 1e-9
        : croak "GDSII: unknown unit '$unit'";

    return map { [ map { [ $_->[0] * $f, $_->[1] * $f ] } @$_ ] } @db;
}

# recursive collection; transform t = [a,b,c,d,e,f] maps (x,y)->(a*x+c*y+e, b*x+d*y+f)
sub _collect {
    my ( $self, $sname, $t, $seen, $layer ) = @_;
    return () if $seen->{$sname}++;    # cycle guard
    my $s = $self->{structures}{$sname} or return ();
    my @out;

    for my $el ( @{ $s->{elements} } ) {
        if ( $el->{type} eq 'boundary' ) {
            next if defined $layer && ( $el->{layer} // 0 ) != $layer;
            push @out, [ map { [ _apply( $t, @$_ ) ] } @{ $el->{xy} } ];
        }
        elsif ( $el->{type} eq 'sref' ) {
            my $ct = _compose( $t,
                _placement( $el, $el->{xy}[0][0], $el->{xy}[0][1] ) );
            push @out, $self->_collect( $el->{sname}, $ct, { %$seen }, $layer );
        }
        elsif ( $el->{type} eq 'aref' ) {
            my ( $cols, $rows ) = @{ $el->{colrow} };
            my ( $p0, $p1, $p2 ) = @{ $el->{xy} };
            my $cvx = $cols ? ( $p1->[0] - $p0->[0] ) / $cols : 0;
            my $cvy = $cols ? ( $p1->[1] - $p0->[1] ) / $cols : 0;
            my $rvx = $rows ? ( $p2->[0] - $p0->[0] ) / $rows : 0;
            my $rvy = $rows ? ( $p2->[1] - $p0->[1] ) / $rows : 0;
            for my $i ( 0 .. $cols - 1 ) {
                for my $j ( 0 .. $rows - 1 ) {
                    my $ox = $p0->[0] + $i * $cvx + $j * $rvx;
                    my $oy = $p0->[1] + $i * $cvy + $j * $rvy;
                    my $ct = _compose( $t, _placement( $el, $ox, $oy ) );
                    push @out,
                        $self->_collect( $el->{sname}, $ct, { %$seen }, $layer );
                }
            }
        }
    }
    return @out;
}

# build a placement transform from strans/mag/angle + translation
sub _placement {
    my ( $el, $dx, $dy ) = @_;
    my $m   = $el->{mag}   // 1;
    my $ang = ( $el->{angle} // 0 ) * 3.14159265358979 / 180;
    my $c   = cos $ang;
    my $s   = sin $ang;
    my $ry  = $el->{reflect} ? -1 : 1;          # reflect about x-axis first
    # combined: reflect(y) -> scale(m) -> rotate(ang) -> translate
    # matrix [a,b,c,d,e,f]: x' = a*x + c*y + e ; y' = b*x + d*y + f
    my $a = $m * $c;
    my $b = $m * $s;
    my $cc = -$m * $s * $ry;
    my $d  = $m * $c * $ry;
    return [ $a, $b, $cc, $d, $dx, $dy ];
}

sub _compose {
    my ( $t, $u ) = @_;    # apply u then t: result = t o u
    my ( $a1, $b1, $c1, $d1, $e1, $f1 ) = @$t;
    my ( $a2, $b2, $c2, $d2, $e2, $f2 ) = @$u;
    return [
        $a1 * $a2 + $c1 * $b2,
        $b1 * $a2 + $d1 * $b2,
        $a1 * $c2 + $c1 * $d2,
        $b1 * $c2 + $d1 * $d2,
        $a1 * $e2 + $c1 * $f2 + $e1,
        $b1 * $e2 + $d1 * $f2 + $f1,
    ];
}

sub _apply {
    my ( $t, $x, $y ) = @_;
    return ( $t->[0] * $x + $t->[2] * $y + $t->[4],
        $t->[1] * $x + $t->[3] * $y + $t->[5] );
}

sub _top_structure {
    my ($self) = @_;
    # a top cell is one never referenced by another; if several, pick the one
    # with the most elements (the richest layout cell).
    my %ref;
    for my $s ( values %{ $self->{structures} } ) {
        for my $el ( @{ $s->{elements} } ) {
            $ref{ $el->{sname} } = 1 if $el->{sname};
        }
    }
    my @tops = grep { !$ref{$_} } @{ $self->{order} };
    return $self->{order}[-1] unless @tops;
    my ($best) = sort {
        scalar( @{ $self->{structures}{$b}{elements} } )
            <=> scalar( @{ $self->{structures}{$a}{elements} } )
    } @tops;
    return $best;
}

# ===========================================================================
# Low-level helpers
# ===========================================================================
sub _round { my $x = shift; return int( $x + ( $x >= 0 ? 0.5 : -0.5 ) ); }

sub _unstr { my $s = shift; $s =~ s/\x00+$//; return $s; }

# build one record (auto-pads to even length)
sub _rec {
    my ( $rtype, $dtype, @data ) = @_;
    my $payload = '';
    if ( $dtype == D_INT2 || $dtype == D_BITARR ) {
        $payload = pack( 's>*', @data );
    }
    elsif ( $dtype == D_INT4 ) {
        $payload = pack( 'l>*', @data );
    }
    elsif ( $dtype == D_REAL8 ) {
        $payload = join '', map { _real8_encode($_) } @data;
    }
    elsif ( $dtype == D_ASCII ) {
        $payload = $data[0] // '';
        $payload .= "\x00" if length($payload) % 2;
    }
    my $rlen = 4 + length $payload;
    return pack( 'n', $rlen ) . pack( 'C', $rtype ) . pack( 'C', $dtype ) . $payload;
}

# --- GDSII 8-byte real  (sign + 7-bit excess-64 base-16 exp + 56-bit mantissa)
sub _real8_decode_all {
    my ($data) = @_;
    my @out;
    for ( my $i = 0; $i + 8 <= length $data; $i += 8 ) {
        push @out, _real8_decode( substr( $data, $i, 8 ) );
    }
    return @out;
}

sub _real8_decode {
    my ($b) = @_;
    my @c    = unpack( 'C8', $b );
    my $sign = ( $c[0] & 0x80 ) ? -1 : 1;
    my $exp  = ( $c[0] & 0x7f ) - 64;
    my $mant = 0;
    $mant = $mant * 256 + $c[$_] for 1 .. 7;
    return $sign * $mant / ( 2**56 ) * ( 16**$exp );
}

sub _real8_encode {
    my ($v) = @_;
    return "\x00" x 8 if $v == 0;
    my $sign = 0;
    if ( $v < 0 ) { $sign = 0x80; $v = -$v; }
    my $exp = 64;
    while ( $v >= 1 )      { $v /= 16; $exp++; }
    while ( $v < 1 / 16 )  { $v *= 16; $exp--; }
    my $mant = int( $v * ( 2**56 ) + 0.5 );
    if ( $mant >= 2**56 ) { $mant /= 16; $exp++; }    # rounding carry
    $exp = 0   if $exp < 0;
    $exp = 127 if $exp > 127;
    my @bytes = ( $sign | ( $exp & 0x7f ) );
    for my $i ( reverse 0 .. 6 ) {
        my $shift = 2**( 8 * $i );
        my $byte  = int( $mant / $shift ) % 256;
        push @bytes, $byte;
    }
    return pack( 'C8', @bytes );
}

1;

__END__

=head1 NAME

Physics::Etch::GDSII - minimal GDSII stream reader / writer

=head1 SYNOPSIS

    use Physics::Etch::GDSII;

    # write a layout (coordinates in user units, default micron)
    my $g = Physics::Etch::GDSII->new( libname => 'MASK' );
    $g->add_rectangle( 'TOP', layer => 1, x => 0, y => 0,
                       width => 2, height => 10 );          # a 2 um line
    $g->add_sref( 'TOP', sname => 'CELL', x => 20, y => 0, angle => 90 );
    $g->write('mask.gds');

    # read it back and flatten to absolute polygons on layer 1 (meters)
    my $in    = Physics::Etch::GDSII->read('mask.gds');
    my @polys = $in->polygons( layer => 1, unit => 'um' );

=head1 DESCRIPTION

A self-contained GDSII implementation (no CPAN dependency). It handles the
records required to describe mask geometry and can flatten C<SREF>/C<AREF> cell
hierarchies - applying reflection, magnification, rotation and translation -
into a flat list of polygons on a chosen layer. Includes the non-IEEE GDSII
8-byte real codec used by the C<UNITS> record.

Polygon coordinates can be returned in database units (C<db>), meters (C<m>,
default), microns (C<um>) or nanometres (C<nm>).

=cut
