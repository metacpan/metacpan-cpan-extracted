package SVG::QRCode;
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT_OK = qw|plot_qrcode|;

use Text::QRCode;

our $VERSION = '0.02';

my %defaults = (
  casesensitive => 0,
  darkcolor     => 'black',
  level         => 'M',
  lightcolor    => 'white',
  margin        => 10,
  size          => 5,
  version       => 0,
);

# functions

sub plot_qrcode ($text, $params = {}) {
  return __PACKAGE__->new($params)->plot($text);
}

# constructor

sub new ($class, $params = {}) {
  for (keys %defaults) {
    $params->{$_} ||= $defaults{$_};
  }

  my $self = {param => $params};
  return bless $self, $class;
}

# methods

sub param ($self, $name, $newvalue = undef) {
  if (defined $newvalue) {
    $self->{param}{$name} = $newvalue || $defaults{$name};
    delete $self->{plotter};
    return $self;
  } else {
    return $self->{param}{$name};
  }
}

sub plot ($self, $text) {
  my %p = %{$self->{param}};

  $self->{plotter} ||= Text::QRCode->new(%p);
  my $qrcode = $self->{plotter}->plot($text);

  my $elements  = @$qrcode;
  my $dimension = $elements * $p{size} + 2 * $p{margin};

  my (@dots, $is_dot);
  for my $y (0 .. $elements - 1) {
    $is_dot = 0;
    for my $x (0 .. $elements - 1) {
      if ($qrcode->[$y][$x] eq '*') {
        if ($is_dot) {
          $dots[-1]{width} += $p{size};
        } else {
          $is_dot = 1;
          push @dots,
            {
            x      => $p{margin} + $p{size} * $x,
            y      => $p{margin} + $p{size} * $y,
            width  => $p{size},
            height => $p{size},
            };
        }
      } else {
        $is_dot = 0;
      }
    }
  }

  my @svg = (
    qq|<svg width="$dimension" height="$dimension" xmlns="http://www.w3.org/2000/svg">|,
    qq|  <rect width="100%" height="100%" fill="$p{lightcolor}"/>|,
  );
  for my $dot (@dots) {
    push @svg,
      qq|  <rect x="$dot->{x}" y="$dot->{y}" width="$dot->{width}" height="$dot->{height}" fill="$p{darkcolor}"/>|;
  }
  push @svg, '</svg>';

  return join "\n", @svg;
}

1;

=encoding utf8

=head1 NAME

SVG::QRCode - Generate SVG based QR Code

=head1 SYNOPSIS

    use SVG::QRCode;

    my $qrcode = SVG::QRCode->new(
      {
        casesensitive => 0,
        darkcolor     => 'black',
        level         => 'M',
        lightcolor    => 'white',
        margin        => 10,
        size          => 5,
        version       => 0,
      }
    );
    my $svg  = $qrcode->plot('https://perldoc.pl');
    my $svg2 = $qrcode->param(darkcolor => 'red')->plot('https://perldoc.pl');

    # export function
    use SVG::QRCode 'plot_qrcode';

    my $svg = plot_qrcode('https://perldoc.pl', \%params);

=head1 DESCRIPTION

L<SVG::QRCode> generates QR Codes as SVG images.

=head1 FUNCTIONS

=head2 plot_qrcode

    use SVG::QRCode 'plot_qrcode';

    my $svg = plot_qrcode($text, \%params);

Creates a QR Code using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new
    
    $qrcode = SVG::QRCode->new(\%params);

Creates a new QR Code plotter. Accepted parameters are:

=over 4

=item casesensitive

If your application is case-sensitive using 8-bit characters, set to C<1>. Default C<0>.

=item darkcolor

Color of the dots. Default C<'black'>.

=item level

Error correction level, one of C<'L'> (low), C<'M'> (medium), C<'Q'> (quartile), C<'H'> (high). Default C<'M'>.

=item lightcolor

Color of the background. Default C<'white'>.

=item margin

Margin around the code. Default C<10>.

=item size

Size of the dots. Default C<5>.

=item version

Symbol version from C<1> to C<40>. C<0> will adapt the version to the required capacity. Default C<0>.

=back

=head1 METHODS

=head2 param

    my $value = $svg->param($name);
    $svg = $svg->param($name, $newvalue);
    $svg = $svg->param($name, '');          # set to default

Getter and setter for the parameters.
    
=head2 plot

    my $svg = $qrcode->plot($text);

Creates a QR Code.

=head1 SEE ALSO

L<Text::QRCode>.

=head1 AUTHOR & COPYRIGHT

Copyright (C) 2019, Tekki (Rolf Stöckli).

This program is free software, you can redistribute it and/or modify it under the terms of the Artistic License version 2.0.

=cut
