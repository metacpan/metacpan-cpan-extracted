package Number::DataRate;
use strict;
use warnings;
use Regexp::Common;
use base qw(Class::Accessor::Faster);
our $VERSION = '0.31';

sub to_bytes_per_second {
    my ( $self, $value ) = @_;
    return $self->to_bits_per_second($value) / 8;
}

sub to_bits_per_second {
    my ( $self, $string ) = @_;

    #warn $value;
    $string =~ m{^
        ($RE{num}{real}{-sep => ',?'}) # value
        \s*                            # whitespace
        ([kMGT]i?)?                    # magnitude
        (bit|b|byte|B|Byte)            # unit
        (/sec|/s|ps|psec)              # /sec
    $}x;
    my ( $value, $magnitude, $unit, $psec ) = ( $1, $2, $3, $4 );
    return unless $psec;
    $value =~ s/,//g;
    $magnitude ||= '';

    #warn "$1 / $2 / $3 / $4";

    $value *= 8 if $unit eq 'B' || lc($unit) eq 'byte';

    $value *= 1_000                     if $magnitude eq 'k';
    $value *= 1024                      if $magnitude eq 'ki';
    $value *= 1_000_000                 if $magnitude eq 'M';
    $value *= 1024 * 1024               if $magnitude eq 'Mi';
    $value *= 1_000_000_000             if $magnitude eq 'G';
    $value *= 1024 * 1024 * 1024        if $magnitude eq 'Gi';
    $value *= 1_000_000_000_000         if $magnitude eq 'T';
    $value *= 1024 * 1024 * 1024 * 1024 if $magnitude eq 'Ti';
    return $value;
}

1;

__END__

=head1 NAME

Number::DataRate - Convert data rate to bits or bytes per second

=head1 SYNOPSIS

  # Bluetooth 2.0+EDR has a data rate of 3000 kbit/s, but what is that
  # in bits and bytes per second?
  use Number::DataRate;
  my $data_rate = Number::DataRate->new;
  my $bits_per_second = $data_rate->to_bits_per_second('3000 kbit/s');
  my $bytes_per_second = $data_rate->to_bytes_per_second('3000 kbit/s');

=head1 DESCRIPTION

This module convers data rate to bits or bytes per second. For far
more than you ever wanted to know about data rates, see Wikipedia:

  http://en.wikipedia.org/wiki/Data_rate_units

This module accepts a wide range of formats, for example:

  0.045 kbit/s
  0.045 kbps
  5.625Byte/s
  24,576 kbit/s
  54.0 Mbit/s
  6.4 Gbit/s
  1.28Tbit/s

=head1 AUTHOR

Leon Brocard <acme@astray.com>.

=head1 COPYRIGHT

Copyright (C) 2008, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.
