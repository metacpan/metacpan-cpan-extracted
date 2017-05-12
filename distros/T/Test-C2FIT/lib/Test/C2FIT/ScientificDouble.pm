# Copyright (c) 2002 Cunningham & Cunningham, Inc.
# Released under the terms of the GNU General Public License version 2 or later.
#
# Warning: not (yet) a general number usable in all calculations.
#
# Perl port by Martin Busik <martin.busik@busik.de>
#
package Test::C2FIT::ScientificDouble;

sub new {
    my $pkg       = shift;
    my $value     = shift;
    my $precision = precision($value);
    $pkg = ref($pkg) if ref($pkg);
    my $self = bless { value => $value, precision => $precision }, $pkg;
    return $self;
}

sub equals {
    my ( $self, $b ) = @_;
    return $self->compareTo($b) == 0;
}

sub toString {
    my $self = shift;
    return $self->{value};
}

sub precision {
    my $value = shift;
    $value =~ s/^\s+//;
    $value =~ s/\s+$//;

    my $bound = tweak($value);
    return abs( $bound - $value );
}

sub tweak {
    my $s   = shift;
    my $pos = index( lc($s), "e" );

    if ( $pos >= 0 ) {
        return tweak( substr( $s, 0, $pos ) ) . substr( $s, $pos );
    }
    if ( index( $s, "." ) >= 0 ) {
        return $s . "5";
    }
    return $s . ".5";
}

sub compareTo {
    my ( $self, $otherObj ) = @_;
    my $value = $self->{value};
    my $other = $otherObj->{value};

    my $diff = $value - $other;

    # warn "COMPARE TO: $value $other $self->{precision}\n";
    return -1 if $diff < -$self->{precision};
    return 1  if $diff > $self->{precision};

    # java code without perl equivalent:
    #   if (Double.isNaN(value) && Double.isNaN(other)) return 0;
    #   if (Double.isNaN(value)) return 1;
    #   if (Double.isNaN(other)) return -1;

    return 0;
}

1;
