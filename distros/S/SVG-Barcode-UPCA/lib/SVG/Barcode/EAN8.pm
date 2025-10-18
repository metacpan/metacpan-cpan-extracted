package SVG::Barcode::EAN8;
$SVG::Barcode::EAN8::VERSION = '0.9';
use parent 'SVG::Barcode';
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use POSIX 'fmax';
use Exporter 'import';
our @EXPORT_OK = qw|plot_ean8|;

use GD::Barcode::EAN8;

use constant DEFAULTS => {
  lineheight => 50,
  linewidth  => 1,
  quietzone  => 7,    # EAN8 needs a 7-module quiet zone left and right
  textsize   => 10,
};

SVG::Barcode::_param(__PACKAGE__, $_, DEFAULTS->{$_}) for keys DEFAULTS->%*;

# functions

sub plot_ean8 ($text, %params) {
  return __PACKAGE__->new(%params)->plot($text);
}

# internal methods

# Add support for taller lines (typically at the sides and middle)
sub _plot_1d ($self, $code, $sign, $signlong) {
  my @line;
  my $width    = $self->{linewidth};
  my $height   = $self->{lineheight};
  my $add_line = sub {
    if (@line) {
      $self->_rect(@line);
      @line = ();
    }
  };
  for my $x (0 .. $#$code) {
    if ($code->[$x] eq $sign) {
      if (@line) {
        $line[2] += $width;
      } else {
        @line = ($x * $width, 0, $width, $height);
      }
    } elsif ($code->[$x] eq $signlong) {
      # Make a slightly taller line
      if (@line) {
        $line[2] += $width;
      } else {
        @line = ($x * $width, 0, $width, $height * 1.1);
      }
    } else {
      $add_line->();
    }
  }
  $add_line->();
}

sub _plot ($self, $text) {
  $self->{plotter} ||= GD::Barcode::EAN8->new($text)
    or die "Cannot create GD::Barcode::EAN8 plotter: " . $GD::Barcode::EAN8::errStr;

  my @code = split //, $self->{plotter}->barcode();
  $self->_plot_1d(\@code, '1', 'G');
  $self->_plot_text($self->{plotter}->{text});
}

# We have to add the quiet zones on the sides
sub _rect ($self, $x, $y, $width, $height, $color = $self->{foreground}) {
  my $x1 = $x + $self->{margin} + $self->{quietzone};
  my $y1 = $y + $self->{margin};
  $self->{vbwidth}  = fmax($self->{vbwidth},  $x1 + $width + $self->{quietzone});
  $self->{vbheight} = fmax($self->{vbheight}, $y1 + $height);
  push $self->{elements}->@*,
    qq|  <rect x="$x1" y="$y1" width="$width" height="$height" fill="$color"/>|;
  return $self;
}

# Handle aligning the text below the barcode
# TODO: find a better way to calculate the positions relative to the bars
sub _text ($self, $text, $x_offset, $y_offset, $size, $color = $self->{foreground}) {
  return $self if $size == 0;

  my $escaped = $self->_xml_escape($text);
  my $margin  = $self->{margin};
  my $qz      = $self->{quietzone};
  my $width   = $self->{linewidth};

  # EAN-8 text is split into two groups of 4 digits.
  my ($left_digits, $right_digits) = $escaped =~ m/^(\d{4})(\d{4})$/;

  my $y1 = $y_offset;    # Position below the shortest bars
  $self->{vbheight} = fmax $self->{vbheight}, $y1 + $size;    # Ensure height accounts for text

  # Left 4 digits (centered over left half of barcode)
  # Barcode: 3 (start) + 28 (left) + 5 (center) + 28 (right) + 3 (end) = 67 modules
  # Left text is centered in the 28 modules of the left data block.
  # Center of left block is at module 3 (start) + 14 (half of 28) = 17
  my $x_left = $margin + $qz + (17 * $width);
  push $self->{elements}->@*,
    qq|  <text x="$x_left" y="$y1" font-size="$size" fill="$color" text-anchor="middle">$left_digits</text>|;

  # Right 4 digits (centered over right half of barcode)
  # Center of right block is at module 3+28+5 (start+left+center) + 14 (half of 28) = 50
  my $x_right = $margin + $qz + (50 * $width);
  push $self->{elements}->@*,
    qq|  <text x="$x_right" y="$y1" font-size="$size" fill="$color" text-anchor="middle">$right_digits</text>|;

  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SVG::Barcode::EAN8

=head1 VERSION

version 0.9

=head1 SYNOPSIS

    use SVG::Barcode::EAN8;

    my $ean8 = SVG::Barcode::EAN8->new;
    my $svg     = $ean8->plot('12345670');

    # use as function
    use SVG::Barcode::EAN8 'plot_ean8';

    my $svg = plot_ean8('12345670', %params);

=head1 DESCRIPTION

L<SVG::Barcode::EAN8> is a generator for SVG based EAN8 barcodes. It uses
L<GD::Barcode::EAN8> to create the barcode data.

=head1 NAME

SVG::Barcode::EAN8 - Generator for SVG based EAN8 barcodes

=head1 FUNCTIONS

=head2 plot_ean8

    use SVG::Barcode::EAN8 'plot_ean8';

    $svg = plot_ean8($text, %params);

Returns an EAN8 barcode using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

Creates a new EAN8 plotter. Inherited from L<SVG::Barcode|SVG::Barcode/new>.

=head1 METHODS

=head2 plot

Creates a SVG code. Inherited from L<SVG::Barcode|SVG::Barcode/plot>.

=head1 PARAMETERS

This module uses the same parameters as L<SVG::Barcode::UPCA>.

=head1 AUTHOR & COPYRIGHT

© 2025 by bwarden (Brett T. Warden).

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=head1 SEE ALSO

L<SVG::Barcode>, L<GD::Barcode::EAN8>.

=cut

=head1 AUTHOR

bwarden

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by bwarden@cpan.org.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
