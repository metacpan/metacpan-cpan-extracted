package Physics::Electrodeposition::GDSII;

use strict;
use warnings;

our $VERSION = '1.00';

#=============================================================================
# Physics::Electrodeposition::GDSII
#
# A dependency-free reader / writer / flattener for GDSII (Calma Stream) layout
# files, adequate for extracting the photoresist / plating-mask geometry that a
# through-mask or damascene electrodeposition model needs.
#
# It understands the records that matter for area / pattern-density extraction:
#   HEADER BGNLIB LIBNAME UNITS BGNSTR STRNAME ENDSTR
#   BOUNDARY BOX PATH LAYER DATATYPE XY WIDTH ENDEL
#   SREF AREF SNAME STRANS MAG ANGLE COLROW ENDLIB
#
# Hierarchy (SREF / AREF) is flattened with full 2-D affine transforms
# (translation, rotation, reflection, magnification, arrays).
#
# All returned coordinates are in MICROMETRES.
#=============================================================================

# ---- GDSII record types we care about --------------------------------------
use constant {
    R_HEADER   => 0x00, R_BGNLIB => 0x01, R_LIBNAME => 0x02, R_UNITS => 0x03,
    R_ENDLIB   => 0x04, R_BGNSTR => 0x05, R_STRNAME => 0x06, R_ENDSTR => 0x07,
    R_BOUNDARY => 0x08, R_PATH   => 0x09, R_SREF    => 0x0a, R_AREF  => 0x0b,
    R_TEXT     => 0x0c, R_LAYER  => 0x0d, R_DATATYPE=> 0x0e, R_WIDTH => 0x0f,
    R_XY       => 0x10, R_ENDEL  => 0x11, R_SNAME   => 0x12, R_COLROW=> 0x13,
    R_STRANS   => 0x1a, R_MAG    => 0x1b, R_ANGLE   => 0x1c,
    R_BOX      => 0x2d, R_BOXTYPE=> 0x2e,
};

#=============================================================================
# Constructor / reader
#=============================================================================
sub new {
    my ($class, %args) = @_;
    my $self = {
        meters_per_dbu => 1e-9,     # database unit in metres (default 1 nm)
        user_per_dbu   => 1e-3,     # database unit in user units
        structures     => {},       # name => [ elements ]
        order          => [],       # structure names in file order
    };
    bless $self, $class;
    $self->read($args{file}) if $args{file};
    return $self;
}

# database unit size in micrometres
sub _dbu_um { my $s = shift; return $s->{meters_per_dbu} * 1e6; }

#-----------------------------------------------------------------------------
# read($path) - parse a GDSII stream file
#-----------------------------------------------------------------------------
sub read {
    my ($self, $path) = @_;
    open(my $fh, '<:raw', $path) or die "GDSII: cannot open $path: $!";
    local $/; my $buf = <$fh>; close $fh;

    my $len = length $buf;
    my $pos = 0;
    my ($cur_struct, $cur_elem);

    while ($pos + 4 <= $len) {
        my $reclen  = unpack('n', substr($buf, $pos, 2));
        my $rectype = unpack('C', substr($buf, $pos + 2, 1));
        my $dtype   = unpack('C', substr($buf, $pos + 3, 1));
        last if $reclen < 4;                       # padding / EOF
        my $data = substr($buf, $pos + 4, $reclen - 4);
        $pos += $reclen;

        if    ($rectype == R_UNITS) {
            my $upd = _real8(substr($data, 0, 8));  # user units per dbu
            my $mpd = _real8(substr($data, 8, 8));  # metres per dbu
            $self->{user_per_dbu}   = $upd if $upd;
            $self->{meters_per_dbu} = $mpd if $mpd;
        }
        elsif ($rectype == R_BGNSTR) { $cur_struct = undef; }
        elsif ($rectype == R_STRNAME) {
            $cur_struct = _ascii($data);
            $self->{structures}{$cur_struct} = [];
            push @{$self->{order}}, $cur_struct;
        }
        elsif ($rectype == R_ENDSTR) { $cur_struct = undef; }
        elsif ($rectype == R_BOUNDARY || $rectype == R_BOX) {
            $cur_elem = { type => 'boundary', layer => 0, datatype => 0, xy => [] };
            push @{$self->{structures}{$cur_struct}}, $cur_elem if $cur_struct;
        }
        elsif ($rectype == R_PATH) {
            $cur_elem = { type => 'path', layer => 0, datatype => 0, width => 0, xy => [] };
            push @{$self->{structures}{$cur_struct}}, $cur_elem if $cur_struct;
        }
        elsif ($rectype == R_SREF) {
            $cur_elem = { type => 'sref', sname => '', strans => 0, mag => 1,
                          angle => 0, xy => [] };
            push @{$self->{structures}{$cur_struct}}, $cur_elem if $cur_struct;
        }
        elsif ($rectype == R_AREF) {
            $cur_elem = { type => 'aref', sname => '', strans => 0, mag => 1,
                          angle => 0, cols => 1, rows => 1, xy => [] };
            push @{$self->{structures}{$cur_struct}}, $cur_elem if $cur_struct;
        }
        elsif ($rectype == R_TEXT) { $cur_elem = { type => 'text', xy => [] }; }
        elsif ($rectype == R_LAYER)    { $cur_elem->{layer}    = _int2($data) if $cur_elem; }
        elsif ($rectype == R_DATATYPE || $rectype == R_BOXTYPE) {
            $cur_elem->{datatype} = _int2($data) if $cur_elem;
        }
        elsif ($rectype == R_WIDTH)    { $cur_elem->{width} = _int4($data) if $cur_elem; }
        elsif ($rectype == R_SNAME)    { $cur_elem->{sname} = _ascii($data) if $cur_elem; }
        elsif ($rectype == R_STRANS)   { $cur_elem->{strans}= _int2($data) if $cur_elem; }
        elsif ($rectype == R_MAG)      { $cur_elem->{mag}   = _real8(substr($data,0,8)) if $cur_elem; }
        elsif ($rectype == R_ANGLE)    { $cur_elem->{angle} = _real8(substr($data,0,8)) if $cur_elem; }
        elsif ($rectype == R_COLROW) {
            if ($cur_elem) {
                $cur_elem->{cols} = _int2(substr($data, 0, 2));
                $cur_elem->{rows} = _int2(substr($data, 2, 2));
            }
        }
        elsif ($rectype == R_XY) {
            my $n = int(length($data) / 4);
            my @v = unpack("l>$n", $data);           # signed 4-byte big-endian
            my @pts;
            for (my $i = 0; $i + 1 < @v; $i += 2) {
                push @pts, [ $v[$i], $v[$i + 1] ];   # keep in raw DBU here
            }
            $cur_elem->{xy} = \@pts if $cur_elem;
        }
        elsif ($rectype == R_ENDEL)  { $cur_elem = undef; }
        elsif ($rectype == R_ENDLIB) { last; }
    }
    return $self;
}

#=============================================================================
# Flattening: expand hierarchy to world-space boundary polygons (micrometres)
#=============================================================================

# Return top-level structures (defined but never referenced by SREF/AREF).
sub top_structures {
    my $self = shift;
    my %ref;
    for my $name (@{$self->{order}}) {
        for my $el (@{$self->{structures}{$name}}) {
            $ref{$el->{sname}} = 1 if ($el->{type} eq 'sref' || $el->{type} eq 'aref');
        }
    }
    return grep { !$ref{$_} } @{$self->{order}};
}

# polygons([$cellname]) -> arrayref of { layer, datatype, pts => [[x,y]..] } in um
sub polygons {
    my ($self, $cell) = @_;
    my @tops = defined $cell ? ($cell) : $self->top_structures;
    @tops = @{$self->{order}} unless @tops;      # fall back to everything
    my @out;
    my $ident = [1, 0, 0, 1, 0, 0];              # a,b,c,d,e,f affine
    for my $t (@tops) {
        $self->_flatten($t, $ident, \@out, {});
    }
    return \@out;
}

# Recursively flatten $cell under affine transform $M into @$out.
sub _flatten {
    my ($self, $cell, $M, $out, $seen) = @_;
    return unless $self->{structures}{$cell};
    return if $seen->{$cell};                    # guard against cycles
    local $seen->{$cell} = 1;
    my $s = $self->_dbu_um;

    for my $el (@{$self->{structures}{$cell}}) {
        if ($el->{type} eq 'boundary') {
            my @pts = map { my ($x, $y) = @$_;
                            _apply($M, $x * $s, $y * $s) } @{$el->{xy}};
            push @$out, { layer => $el->{layer}, datatype => $el->{datatype},
                          pts => \@pts };
        }
        elsif ($el->{type} eq 'sref') {
            my ($ox, $oy) = @{ $el->{xy}[0] // [0, 0] };
            my $child = _compose($M, _elem_matrix($el, $ox * $s, $oy * $s));
            $self->_flatten($el->{sname}, $child, $out, $seen);
        }
        elsif ($el->{type} eq 'aref') {
            my $p = $el->{xy};
            next unless $p && @$p >= 3;
            my ($x0, $y0) = @{$p->[0]};
            my ($xc, $yc) = @{$p->[1]};
            my ($xr, $yr) = @{$p->[2]};
            my $cols = $el->{cols} || 1;
            my $rows = $el->{rows} || 1;
            my $cvx = ($xc - $x0) / $cols; my $cvy = ($yc - $y0) / $cols;
            my $rvx = ($xr - $x0) / $rows; my $rvy = ($yr - $y0) / $rows;
            for my $i (0 .. $cols - 1) {
                for my $k (0 .. $rows - 1) {
                    my $ox = ($x0 + $i * $cvx + $k * $rvx) * $s;
                    my $oy = ($y0 + $i * $cvy + $k * $rvy) * $s;
                    my $child = _compose($M, _elem_matrix($el, $ox, $oy));
                    $self->_flatten($el->{sname}, $child, $out, $seen);
                }
            }
        }
    }
}

# Build an affine matrix for an SREF/AREF element placed at (ox,oy) um.
sub _elem_matrix {
    my ($el, $ox, $oy) = @_;
    my $mag   = $el->{mag} || 1;
    my $ang   = ($el->{angle} || 0) * 3.14159265358979 / 180.0;
    my $refl  = ($el->{strans} & 0x8000) ? -1 : 1;   # reflect about x axis
    my $ca = cos($ang); my $sa = sin($ang);
    # scale (with reflection on y) then rotate then translate
    my $a =  $mag * $ca;              my $c = -$mag * $refl * $sa;
    my $b =  $mag * $sa;              my $d =  $mag * $refl * $ca;
    return [ $a, $b, $c, $d, $ox, $oy ];
}

# Compose two affine transforms M2 applied after M1 (M1 is outer/world).
sub _compose {
    my ($A, $B) = @_;   # world = A * (B * p)
    my ($a1,$b1,$c1,$d1,$e1,$f1) = @$A;
    my ($a2,$b2,$c2,$d2,$e2,$f2) = @$B;
    return [
        $a1*$a2 + $c1*$b2,          $b1*$a2 + $d1*$b2,
        $a1*$c2 + $c1*$d2,          $b1*$c2 + $d1*$d2,
        $a1*$e2 + $c1*$f2 + $e1,    $b1*$e2 + $d1*$f2 + $f1,
    ];
}

# Apply affine to a point.
sub _apply {
    my ($M, $x, $y) = @_;
    return [ $M->[0]*$x + $M->[2]*$y + $M->[4],
             $M->[1]*$x + $M->[3]*$y + $M->[5] ];
}

#=============================================================================
# Binary field decoders
#=============================================================================
sub _int2  { return unpack('s>', substr($_[0], 0, 2)); }
sub _int4  { return unpack('l>', substr($_[0], 0, 4)); }
sub _ascii { my $s = $_[0]; $s =~ s/\x00+$//; return $s; }

# Decode an 8-byte GDSII real (Excess-64, base-16 mantissa).
sub _real8 {
    my $bytes = shift;
    return 0 if length($bytes) < 8;
    my @c = unpack('C8', $bytes);
    my $sign = ($c[0] & 0x80) ? -1 : 1;
    my $exp  = ($c[0] & 0x7f) - 64;
    my $mant = 0;
    $mant = $mant * 256 + $c[$_] for 1 .. 7;       # 56-bit fraction
    return $sign * $mant / (2**56) * (16 ** $exp);
}

# Encode a number as an 8-byte GDSII real.
sub _to_real8 {
    my $v = shift;
    return pack('C8', 0,0,0,0,0,0,0,0) if $v == 0;
    my $sign = 0;
    if ($v < 0) { $sign = 0x80; $v = -$v; }
    my $exp = 0;
    while ($v >= 1)      { $v /= 16; $exp++; }
    while ($v < 1/16)    { $v *= 16; $exp--; }
    my $mant = int($v * (2**56) + 0.5);
    my $e = ($exp + 64) | $sign;
    my @b = ($e);
    for my $i (reverse 0 .. 6) { $b[1 + (6 - $i)] = ($mant >> (8 * $i)) & 0xff; }
    return pack('C8', @b);
}

#=============================================================================
# Minimal writer (BOUNDARY elements) - lets examples/tests be self-contained.
#=============================================================================
# write_boundaries($path, \@polys, %opts)
#   @polys : list of { layer, pts => [[x,y]..] } with coordinates in USER units
#            (micrometres by default).
#   opts   : user_unit (metres per user unit, default 1e-6 = micron),
#            dbu (metres per database unit, default 1e-9 = nm),
#            libname, sname.
sub write_boundaries {
    my ($class, $path, $polys, %o) = @_;
    my $user_unit = $o{user_unit} // 1e-6;         # metres per user unit (um)
    my $dbu       = $o{dbu}       // 1e-9;         # metres per db unit (nm)
    my $libname   = $o{libname}   // 'ECD_LIB';
    my $sname     = $o{sname}     // 'TOP';
    my $upd       = $dbu / $user_unit;             # user units per db unit
    my $scale     = $user_unit / $dbu;             # db units per user unit

    open(my $fh, '>:raw', $path) or die "GDSII: cannot write $path: $!";
    my @now = (localtime)[5,4,3,2,1,0]; $now[0] += 1900; $now[1] += 1;

    print $fh _rec(R_HEADER, 2, pack('s>', 600));
    print $fh _rec(R_BGNLIB, 2, pack('s>*', (@now) x 2));
    print $fh _rec(R_LIBNAME, 6, _pad($libname));
    print $fh _rec(R_UNITS, 5, _to_real8($upd) . _to_real8($dbu));

    print $fh _rec(R_BGNSTR, 2, pack('s>*', (@now) x 2));
    print $fh _rec(R_STRNAME, 6, _pad($sname));
    for my $p (@$polys) {
        my $layer = $p->{layer} // 0;
        my $dt    = $p->{datatype} // 0;
        my @pts   = @{$p->{pts}};
        push @pts, $pts[0] if @pts && ($pts[0][0] != $pts[-1][0] || $pts[0][1] != $pts[-1][1]);
        my @xy = map { ( int($_->[0]*$scale + ($_->[0]<0?-0.5:0.5)),
                         int($_->[1]*$scale + ($_->[1]<0?-0.5:0.5)) ) } @pts;
        print $fh _rec(R_BOUNDARY, 0, '');
        print $fh _rec(R_LAYER, 2, pack('s>', $layer));
        print $fh _rec(R_DATATYPE, 2, pack('s>', $dt));
        print $fh _rec(R_XY, 3, pack('l>*', @xy));
        print $fh _rec(R_ENDEL, 0, '');
    }
    print $fh _rec(R_ENDSTR, 0, '');
    print $fh _rec(R_ENDLIB, 0, '');
    close $fh;
    return 1;
}

sub _rec {
    my ($rectype, $dtype, $data) = @_;
    my $len = 4 + length($data);
    return pack('n', $len) . pack('C', $rectype) . pack('C', $dtype) . $data;
}
sub _pad { my $s = shift; $s .= "\x00" if length($s) % 2; return $s; }

1;

__END__

=head1 NAME

Physics::Electrodeposition::GDSII - Dependency-free GDSII (Calma Stream) reader,
writer and hierarchy flattener for electrodeposition pattern extraction.

=head1 SYNOPSIS

    use Physics::Electrodeposition::GDSII;

    my $gds  = Physics::Electrodeposition::GDSII->new(file => 'mask.gds');
    my $poly = $gds->polygons;                 # flattened, in micrometres
    for my $p (@$poly) {
        # $p->{layer}, $p->{datatype}, $p->{pts} = [ [x,y], ... ]
    }

    # write a simple pattern (coordinates in micrometres):
    Physics::Electrodeposition::GDSII->write_boundaries('out.gds', [
        { layer => 1, pts => [[0,0],[10,0],[10,10],[0,10]] },
    ]);

=head1 DESCRIPTION

Reads the subset of the GDSII stream format needed to recover a photoresist /
plating-mask geometry: units, structures, boundaries, boxes, and cell references
(SREF / AREF) which are flattened with full affine transforms. Returned polygon
coordinates are in micrometres. A minimal boundary writer is included so tests
and examples can synthesise patterns without external tooling.

=head1 METHODS

=over 4

=item new(file => $path)

Construct and (optionally) read a file.

=item read($path)

Parse a GDSII file into the object.

=item polygons([$cell])

Return an arrayref of flattened boundary polygons (micrometres). Defaults to the
top-level cell(s).

=item top_structures

List structures that are not referenced by any SREF/AREF.

=item write_boundaries($path, \@polys, %opts)

Write boundary polygons (user-unit micrometres) to a GDSII file.

=back

=cut
