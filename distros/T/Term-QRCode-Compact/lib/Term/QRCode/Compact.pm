package Term::QRCode::Compact;
use 5.020;
use feature 'signatures';
no warnings 'experimental::signatures';
use utf8;

use Exporter 'import';
use Imager::QRCode;

our @EXPORT_OK = ('qr_code_as_text');

our $VERSION = '0.01';

=encoding utf8

=head1 NAME

Term::QRCode::Compact - create QR codes for display in the terminal

=head1 SYNOPSIS

  use Term::QRCode::Compact 'qr_code_as_text';
  print qr_code_as_text(text => 'https://metacpan.org/module/Term::QRCode::Compact');

  # Output:
  #
  #
  #  ██████████████  ████    ██████████  ██    ██████    ██████████████
  #  ██          ██    ██      ████      ████    ██      ██          ██
  #  ██  ██████  ██    ████████  ████  ██████████        ██  ██████  ██
  #  ██  ██████  ██  ██████        ██████  ██      ██    ██  ██████  ██
  #  ██  ██████  ██  ████      ██    ████  ██    ████    ██  ██████  ██
  #  ██          ██  ██  ██    ██  ██        ██          ██          ██
  #  ██████████████  ██  ██  ██  ██  ██  ██  ██  ██  ██  ██████████████
  #                  ██      ██  ██    ████████████  ██
  #  ██      ██  ██████    ██      ██████    ████████████████████    ██
  #  ██████          ██  ██          ██████  ██    ██  ██      ████
  #  ██          ████    ██  ████████    ██  ████████████      ██
  #          ████    ████    ████          ██████████                ██
  #      ██████████  ██    ██  ██  ████    ██  ████  ██  ██  ████  ██
  #  ██  ████  ██          ████  ██    ████████    ██  ██  ██
  #          ██  ██  ████  ██      ██    ██  ██████████████    ██████
  #  ██    ██  ██      ██  ██████  ████████    ██      ████
  #    ██  ████  ██  ██████████        ██  ████████  ██  ██  ████████
  #          ██    ██████  ██    ████    ██        ██  ██      ████
  #  ████  ████████  ████    ████████  ██      ██████  ██  ██  ██
  #      ██        ██  ██        ████  ██████  ██  ██████  ██      ██
  #    ████████████████  ██    ██        ██████████  ██████  ████
  #  ████  ██  ██      ██  ██████    ██    ██  ██          ██    ████
  #      ██████  ████████████  ████  ████████      ██  ████        ██
  #                ████  ████  ██      ██  ████████    ██  ████    ██
  #  ████  ██    ██  ████  ██  ██████  ██      ██  ████████████████████
  #                  ██  ██    ██  ██████          ████      ██  ████
  #  ██████████████  ██████  ████  ████  ██  ██  ██  ██  ██  ████  ██
  #  ██          ██    ██████  ██████      ██████    ██      ██      ██
  #  ██  ██████  ██  ████    ██████████      ██████  ████████████  ████
  #  ██  ██████  ██    ████    ██        ██████████████  ██████  ██
  #  ██  ██████  ██    ████  ██    ██  ████              ██████████
  #  ██          ██    ██      ██  ████████  ██████  ██  ██
  #  ██████████████  ██  ██████        ██  ████████  ████        ██  ██
  #

  use Term::QRCode::Compact 'qr_code_as_text';
  print qr_code_as_text(
      charset => 'ascii_1x1',
      text => 'Hello'
  );

  # Output

  ############################        ################    ############################
  ############################        ################    ############################
  ####                    ####                    ####    ####                    ####
  ####                    ####                    ####    ####                    ####
  ####    ############    ####    ####    ####    ####    ####    ############    ####
  ####    ############    ####    ####    ####    ####    ####    ############    ####
  ####    ############    ####    ####    ####            ####    ############    ####
  ####    ############    ####    ####    ####            ####    ############    ####
  ####    ############    ####    ########        ####    ####    ############    ####
  ####    ############    ####    ########        ####    ####    ############    ####
  ####                    ####    ########    ####        ####                    ####
  ####                    ####    ########    ####        ####                    ####
  ############################    ####    ####    ####    ############################
  ############################    ####    ####    ####    ############################
                                  ####    ####
                                  ####    ####
  ####    ####################        ####    ####        ####################
  ####    ####################        ####    ####        ####################
              ####                ####        ################        ########    ####
              ####                ####        ################        ########    ####
          ####################        ########    ####    ########    ############
          ####################        ########    ####    ########    ############
          ####        ####    ########    ####################        ########
          ####        ####    ########    ####################        ########
      ############        ####################    ####        ####                ####
      ############        ####################    ####        ####                ####
                                  ####            ####        ####    ####
                                  ####            ####        ####    ####
  ############################        ####    ####    ####        ####    ########
  ############################        ####    ####    ####        ####    ########
  ####                    ####    ####    ####                ####################
  ####                    ####    ####    ####                ####################
  ####    ############    ####    ####        ####    ####        ####        ####
  ####    ############    ####    ####        ####    ####        ####        ####
  ####    ############    ####    ########    ####################    ####
  ####    ############    ####    ########    ####################    ####
  ####    ############    ####    ########        ####    ########        ####
  ####    ############    ####    ########        ####    ########        ####
  ####                    ####        ####    ################    ############
  ####                    ####        ####    ################    ############
  ############################    ########        ####            ####        ####
  ############################    ########        ####            ####        ####

=cut

our %charset = (
    ascii => {
    #    ascii_1x1 => {
    #       xfactor => 1,
    #       yfactor => 1,
    #       charset => [ ' ', '#' ],
    #   },
        '2x1' => {
            xfactor => 1,
            yfactor => 1,
            charset => [ '  ', '##' ],
        },
    },
    utf8 => {
        '1x2' => {
            xfactor => 1,
            yfactor => 2,
            charset => [ ' ', '▀' ,
                        '▄', '█' ],
        },
    },
);

sub compress_lines( $lines, $xfactor, $yfactor, $charset ) {
    my $res;

    my $yofs = 0;

    while( $yofs < @$lines ) {
        my $xofs = 0;
        my $cols = @{$lines->[$yofs]};
        while ($xofs < $cols) {
            my $bits = 0;
            for my $l (0..$yfactor-1) {
                for my $c (0..$xfactor-1) {
                    my $bitpos = $l*$xfactor + $c;
                    #say sprintf '%02d x %02d %04b %d %04b', $xofs+$c, $yofs+$l, $bitpos, $lines->[$yofs+$l]->[$xofs+$c], $bits;

                    $bits += $lines->[$yofs+$l]->[$xofs+$c] << $bitpos;
                }
            }
            $res .= $charset->[ $bits ];
            $xofs += $xfactor
        };
        $yofs += $yfactor;
        $res .= "\n";
    }

    return $res
}

=head1 FUNCTIONS

=head2 C<qr_code_as_text>

  say qr_code_as_text( text => 'hello' );

Returns a string with newlines that represents
the QR-Code.

Options

=over 4

=item B<text>

The text to turn into a QR-Code

=item B<charset>

  charset => 'utf8',

The charset to use when rendering the QR-Code,
default is C<utf8>.

=item B<dimensions>

Optional

  dimensions => '1x2',

The number of pixels per returned character.
Currently for ASCII the dimensions the dimensions
are C<2x1> for ascii and C<2x1> for C<utf8>.

=back

=cut

sub qr_code_as_text( %options ) {
    $options{charset} //= 'utf8';

    my $qrcode = Imager::QRCode->new(
        size          => 2,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    );

    my $charset = $charset{ $options{ charset }};

    my $dimensions = $options{ dimensions };
    if( ! $dimensions ) {
        ($dimensions) = keys (%$charset);
    }
    $charset = $charset->{ $dimensions };

    my $img = $qrcode->plot($options{text});
    my $rows = $img->getheight;
    my $cols = $img->getwidth;
    my $res;
    my @lines;
    for my $row (0..$rows-1) {
        my $line = [];
        for my $col (0..$cols-1) {
            my $val = $img->getpixel( 'x' => $col, 'y' => $row );
            my $is_black = [$val->rgba]->[0] == 0 ? 1 : 0;
            push @$line, $is_black;
        }
        push @lines, $line;

    }
    return compress_lines( \@lines,
        $charset->{xfactor},
        $charset->{yfactor},
        $charset->{charset},
    );
}

1;

=head1 SEE ALSO

L<Text::QRCode> - needs an update to support C<.> in C<@INC>

L<Term::QRCode> - needs L<Text::QRCode>

=cut
