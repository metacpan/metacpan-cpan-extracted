package Pcore::Util::IDN::PP;

use Pcore -const, -export => [qw[domain_to_ascii domain_to_utf8]];

# punycode directly stolen from the Mojo::Util (c)

const our $PC_BASE         => 36;
const our $PC_TMIN         => 1;
const our $PC_TMAX         => 26;
const our $PC_SKEW         => 38;
const our $PC_DAMP         => 700;
const our $PC_INITIAL_BIAS => 72;
const our $PC_INITIAL_N    => 128;

sub domain_to_ascii ($domain) {
    $domain = lc join q[.], map { /[^\x00-\x7f]/sm ? 'xn--' . to_punycode($_) : $_ } split /[.]/sm, $domain, -1;

    utf8::downgrade($domain);

    return $domain;
}

sub domain_to_utf8 ($domain) {
    $domain = lc join q[.], map { /\Axn--(.+)\z/sm ? from_punycode($1) : $_ } split /[.]/sm, $domain, -1;

    utf8::upgrade($domain);

    return $domain;
}

# direct translation of RFC 3492
sub to_punycode ($output) {
    use integer;

    my $n = $PC_INITIAL_N;

    my $delta = 0;

    my $bias = $PC_INITIAL_BIAS;

    # Extract basic code points
    my $len = length $output;

    my @input = map {ord} split //sm, $output;

    my @chars = sort grep { $_ >= $PC_INITIAL_N } @input;

    $output =~ s/[^\x00-\x7f]+//smg;

    my $h = my $basic = length $output;

    $output .= "\x2d" if $basic > 0;

    for my $m (@chars) {
        next if $m < $n;

        $delta += ( $m - $n ) * ( $h + 1 );

        $n = $m;

        for ( my $i = 0; $i < $len; $i++ ) {
            my $c = $input[$i];

            if ( $c < $n ) {
                $delta++;
            }
            elsif ( $c == $n ) {
                my $q = $delta;

                # Base to infinity in steps of base
                for ( my $k = $PC_BASE; 1; $k += $PC_BASE ) {
                    my $t = $k - $bias;

                    $t = $t < $PC_TMIN ? $PC_TMIN : $t > $PC_TMAX ? $PC_TMAX : $t;

                    last if $q < $t;

                    my $o = $t + ( ( $q - $t ) % ( $PC_BASE - $t ) );

                    $output .= chr $o + ( $o < 26 ? 0x61 : 0x30 - 26 );

                    $q = ( $q - $t ) / ( $PC_BASE - $t );
                }

                $output .= chr $q + ( $q < 26 ? 0x61 : 0x30 - 26 );

                $bias = _adapt( $delta, $h + 1, $h == $basic );

                $delta = 0;

                $h++;
            }
        }

        $delta++;

        $n++;
    }

    return $output;
}

# direct translation of RFC 3492
sub from_punycode ($input) {
    use integer;

    my $n = $PC_INITIAL_N;

    my $i = 0;

    my $bias = $PC_INITIAL_BIAS;

    my @output;

    # Consume all code points before the last delimiter
    push @output, split //sm, $1 if $input =~ s/(.*)\x2d//sm;

    while ( $input ne q[] ) {
        my $oldi = $i;

        my $w = 1;

        # Base to infinity in steps of base
        for ( my $k = $PC_BASE; 1; $k += $PC_BASE ) {
            my $digit = ord substr $input, 0, 1, q[];

            $digit = $digit < 0x40 ? $digit + ( 26 - 0x30 ) : ( $digit & 0x1f ) - 1;

            $i += $digit * $w;

            my $t = $k - $bias;

            $t = $t < $PC_TMIN ? $PC_TMIN : $t > $PC_TMAX ? $PC_TMAX : $t;

            last if $digit < $t;

            $w *= $PC_BASE - $t;
        }

        $bias = _adapt( $i - $oldi, @output + 1, $oldi == 0 );

        $n += $i / ( @output + 1 );

        $i = $i % ( @output + 1 );

        splice @output, $i++, 0, chr $n;
    }

    return join q[], @output;
}

sub _adapt ( $delta, $numpoints, $firsttime ) {
    use integer;

    $delta = $firsttime ? $delta / $PC_DAMP : $delta / 2;

    $delta += $delta / $numpoints;

    my $k = 0;

    while ( $delta > ( ( $PC_BASE - $PC_TMIN ) * $PC_TMAX ) / 2 ) {
        $delta /= $PC_BASE - $PC_TMIN;

        $k += $PC_BASE;
    }

    return $k + ( ( ( $PC_BASE - $PC_TMIN + 1 ) * $delta ) / ( $delta + $PC_SKEW ) );
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 116                  | RegularExpressions::ProhibitCaptureWithoutTest - Capture variable used outside conditional                     |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 52                   | ValuesAndExpressions::ProhibitEscapedCharacters - Numeric escapes in interpolated string                       |
## |------+----------------------+----------------------------------------------------------------------------------------------------------------|
## |    2 | 61, 71, 124          | ControlStructures::ProhibitCStyleForLoops - C-style "for" loop used                                            |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::IDN::PP

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
