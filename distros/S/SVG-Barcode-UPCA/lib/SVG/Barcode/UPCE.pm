package SVG::Barcode::UPCE;
$SVG::Barcode::UPCE::VERSION = '0.9';
use parent 'SVG::Barcode';
use strict;
use warnings;
use utf8;
use v5.24;
use feature 'signatures';
no warnings 'experimental::signatures';

use POSIX 'fmax';
use Exporter 'import';
our @EXPORT_OK = qw|plot_upce|;

use GD::Barcode::UPCE;

use constant DEFAULTS => {
  lineheight => 50,
  linewidth  => 1,
  quietzone  => 9,  # UPCE needs an explicit quiet zone left and right
  textsize   => 10,
};

SVG::Barcode::_param(__PACKAGE__, $_, DEFAULTS->{$_}) for keys DEFAULTS->%*;

# functions

sub plot_upce ($text, %params) {
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
  $self->{plotter} ||= GD::Barcode::UPCE->new($text)
    or die "Cannot create GD::Barcode::UPCE plotter: " . $GD::Barcode::UPCE::errStr;

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

  # The full barcode string is 95 modules wide.
  # The text is split into 3 parts:
  # - 1st digit (system character)
  # - next 5 digits
  # - last 5 digits + check digit

  my ($sys_char, $middle_digits, $check_digit) =
    $escaped =~ m/^(\d)(\d{6})(\d)$/;

  my $y1 = $y_offset; # Position below the shortest bars
  $self->{vbheight} = fmax $self->{vbheight}, $y1 + $size; # Ensure height accounts for text

  # System character (1st digit)
  my $x_sys = $margin; # Just inside the margin
  push $self->{elements}->@*, qq|  <text x="$x_sys" y="$y1" font-size="$size" fill="$color">$sys_char</text>|;

  # Middle 6 digits
  my $x_left = $margin + $qz + (40 * $width) - (length($middle_digits) * $size / 2);
  push $self->{elements}->@*, qq|  <text x="$x_left" y="$y1" font-size="$size" fill="$color">$middle_digits</text>|;

  # Check digit (last digit)
  my $x_check = $margin + $qz + 55; # Approximately just inside the margin
  push $self->{elements}->@*, qq|  <text x="$x_check" y="$y1" font-size="$size" fill="$color">$check_digit</text>|;
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

SVG::Barcode::UPCE

=head1 VERSION

version 0.9

=head1 SYNOPSIS

    use SVG::Barcode::UPCE;

    my $upce = SVG::Barcode::UPCE->new;
    my $svg     = $upce->plot('012345678905');

    $upce->linewidth;     # 1
    $upce->lineheight;    # 50
    $upce->textsize;      # 10
                             # from SVG::Barcode:
    $upce->foreground;    # black
    $upce->background;    # white
    $upce->margin;        # 2
    $upce->id;
    $upce->class;
    $upce->width;
    $upce->height;
    $upce->scale;

    my %params = (
      lineheight => 40,
      textsize   => 0,
    );
    $upce = SVG::Barcode::UPCE->new(%params);

    # use as function
    use SVG::Barcode::UPCE 'plot_upce';

    my $svg = plot_upce('012345678905', %params);

=head1 DESCRIPTION

L<SVG::Barcode::UPCE> is a generator for SVG based UPCE barcodes.

=head1 NAME

SVG::Barcode::UPCE - Generator for SVG based UPCE barcodes

=head1 FUNCTIONS

=head2 plot_upce

    use SVG::Barcode::UPCE 'plot_upce';

    $svg = plot_upce($text, %params);

Returns a UPCE barcode using the provided text and parameters.

=head1 CONSTRUCTOR

=head2 new

    $upce = SVG::Barcode::UPCE->new;             # create with defaults
    $upce = SVG::Barcode::UPCE->new(\%params);

Creates a new UPCE plotter. Inherited from L<SVG::Barcode|SVG::Barcode/new>.

=head1 METHODS

=head2 plot

Creates a SVG code. Inherited from L<SVG::Barcode|SVG::Barcode/plot>.

=head1 PARAMETERS

Inherited from L<SVG::Barcode>:
L<background|SVG::Barcode/background>,
L<class|SVG::Barcode/class>,
L<foreground|SVG::Barcode/foreground>,
L<height|SVG::Barcode/height>,
L<id|SVG::Barcode/id>,
L<margin|SVG::Barcode/margin>,
L<scale|SVG::Barcode/scale>,
L<width|SVG::Barcode/width>.

=head2 lineheight

    $value   = $upce->lineheight;
    $upce = $upce->lineheight($newvalue);
    $upce = $upce->lineheight('');          # 30

Getter and setter for the height of a line. Default C<30>.

=head2 linewidth

    $value   = $upce->linewidth;
    $upce = $upce->linewidth($newvalue);
    $upce = $upce->linewidth('');          # 1

Getter and setter for the width of a single line. Default C<1>.

=head2 textsize

    $value   = $upce->textsize;
    $upce = $upce->textsize($newvalue);
    $upce = $upce->textsize('');          # 10

Getter and setter for the size of the text a the bottom. C<0> hides the text. Default C<10>.

=head1 AUTHOR & COPYRIGHT

Derived from SVG::Barcode::Code128 © 2019–2020 by Tekki (Rolf Stöckli).

© 2025 by bwarden (Brett T. Warden).

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=head1 SEE ALSO

L<SVG::Barcode>, L<GD::Barcode::UPCE>.

=head1 AUTHOR

bwarden

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by bwarden@cpan.org.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
