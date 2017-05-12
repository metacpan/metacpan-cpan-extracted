package RGB2HSI;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(rgb2hsi);

our $VERSION = 0.012;

sub rgb2hsi {
    my ($R, $G, $B) = @_;
    my ($H, $S, $I) = (0,0,0);

    my $min = 1e-6;

    $I = (my $i = $R+$G+$B) / 3.0;

    # gray colors
    if ($R == $G && $G == $B){
        $S = 0;
        $H = 0;
    }else{
        my ($r,$g,$b) = (($R/$i), ($G/$i), ($B/$i));

        $H = &rgb_hue($R,$G,$B);

        if ($r <= $g && $r <= $b){
            $S = 1- 3 * $r
        }elsif ($g <= $r && $g <= $b){
            $S = 1- 3 * $g
        }else{
            $S = 1- 3 * $b;
        }
    }
    return ($H, $S, $I);
}

sub rgb_hue
{
    my ($r, $g, $b)= @_;
    my ($h, $s);

    my $min= &_min($r, $g, $b);
    my $max= &_max($r, $g, $b);

    my $delta = $max - $min;

    return 0 if ( $delta == 0 );

    if( $r == $max )
    {
        $h = ( $g - $b ) / $delta;
    }
    elsif ( $g == $max )
    {
        $h = 2 + ( $b - $r ) / $delta;
    }
    else # if $b == $max
    {
        $h = 4 + ( $r - $g ) / $delta;
    }

    $h *= 60;
    if( $h < 0 ) { $h += 360; }
    return $h;
}

sub _min { my $min = shift(@_); foreach my $v (@_) { if ($v <= $min) { $min = $v; } }; return $min; }
sub _max { my $max = shift(@_); foreach my $v (@_) { if ($v >= $max) { $max = $v; } }; return $max; }


1;

__END__

=pod

=encoding utf-8

=head1 NAME

RGB2HSI

=head1 VERSION

version 0.1

=head1 SYNOPSIS

    use RGB2HSI;

    # this may die on input higher than 1
    my ($h, $s, $i) = rgb2hsi( 0.704, 0.187, 0.896  )

    # $h is between 0 and 360
    # $s is saturation between 0 and 1
    # $i is intensity between 0 and 1

=head1 DESCRIPTION

Convert RGB colors float (0..1) to HSI using this method:

Suppose R, G, and B are the red, green, and blue values of a color. The HSI intensity is given by the equation

    I = (R + G + B)/3.

Now let m be the minimum value among R, G, and B. The HSI saturation value of a color is given by the equation

    S = 1 - m/I    if I > 0, or
    S = 0            if I = 0


You can use IUP::ColorDlg to convert RGB to HSI (HEX too) but it's too big to install if you only need RGB2HSI !

=head1 NAME

RGB2HSI - Convert RGB color to HSI (hue saturation intensity) color-space

=head1 AUTHOR

Renato Cron <renato@aware.com.br>

=head1 COPYRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


