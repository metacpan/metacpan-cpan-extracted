#!/usr/bin/perl
package Term::ExtendedColor::Xresources::Colorscheme;
use strict;

BEGIN {
  use Exporter;
  use vars qw($VERSION @ISA @EXPORT_OK);

  $VERSION = '0.004';
  @ISA     = qw(Exporter);
  @EXPORT_OK = qw(
    get_colorscheme
    get_colorschemes
  );
}

use Term::ExtendedColor::Xresources qw(set_xterm_color);

my %colorschemes = (
  xterm     => {
    0   => '000000',
    1   => 'cd0000',
    2   => '00cd00',
    3   => 'cdcd00',
    4   => '0000cd',
    5   => 'cd00cd',
    6   => '00cdcd',
    7   => 'e5e5e5',
    8   => '4d4d4d',
    9   => 'ff0000',
    10  => '00ff00',
    11  => 'ffff00',
    12  => '0000ff',
    13  => 'ff00ff',
    14  => '00ffff',
    15  => 'aabac8',
  },
  woldrich  => {
    0   => '030303',
    1   => '1c1c1c',
    2   => 'ff4747',
    3   => 'ff6767',
    4   => '2b4626',
    5   => 'b03b31',
    6   => 'ff8f00',
    7   => 'bdf1ed',
    8   => '1165e9',
    9   => '5496ff',
    10  => 'aef7af',
    11  => 'b50077',
    12  => 'cb1c13',
    13  => '6be603',
    14  => 'ffffff',
    15  => 'aabac8',
  },
  matrix    => {
    0   => '121212',
    1   => '021e00',
    2   => '032d00',
    3   => '043c00',
    4   => '054b00',
    5   => '065a00',
    6   => '076900',
    7   => 'ffffff',
    8   => '098700',
    9   => '0a9600',
    10  => '0ba500',
    11  => '0cb400',
    12  => '0dc300',
    13  => '0ed200',
    14  => '0fe100',
    15  => 'aabac8',
  },

  purple    => {
    0   => '121212',
    1   => '300a97',
    2   => '430ac0',
    3   => '830abf',
    4   => '7b0ad2',
    5   => '370ad3',
    6   => '650a78',
    7   => 'ffffff',
    8   => '960ac9',
    9   => '5a0a8b',
    10  => '5d0ac8',
    11  => '8a0afa',
    12  => '7b0a73',
    13  => '8b0a25',
    14  => '500a98',
    15  => 'aabac8',
  },

  blue      => {
    0   => '121212',
    1   => '141fe1',
    2   => '1e2fd2',
    3   => '283fc3',
    4   => '324fb4',
    5   => '3c5fa5',
    6   => '466f96',
    7   => 'ffffff',
    8   => '5a8f78',
    9   => '649f69',
    10  => '6eaf5a',
    11  => '78bf4b',
    12  => '82cf3c',
    13  => '8cdf2d',
    14  => '96ef1e',
    15  => 'aabac8',
  },

  grey      => {
    0   => '121212',
    1   => '888888',
    2   => '444444',
    3   => '242424',
    4   => '2d2d2d',
    5   => '363636',
    6   => '3f3f3f',
    7   => 'ffffff',
    8   => '515151',
    9   => '5a5a5a',
    10  => '636363',
    11  => '6c6c6c',
    12  => '757575',
    13  => '7e7e7e',
    14  => '878787',
    15  => 'aabac8',

  },

  rasta     => {
    0   => '121212',
    1   => '3c8d0a',
    2   => '8f0d0a',
    3   => '33810a',
    4   => '349e0a',
    5   => '12a10a',
    6   => '729a0a',
    7   => 'ffffff',
    8   => '104770',
    9   => 'b3410a',
    10  => 'f0120a',
    11  => 'b63e0a',
    12  => '774c0a',
    13  => '5d450a',
    14  => '56540a',
    15  => 'aabac8',
  },

  breeze    => {
    0   => '121212',
    1   => '1043c1',
    2   => '1865a2',
    3   => '208783',
    4   => '28a964',
    5   => '30cb45',
    6   => '38ed26',
    7   => 'ffffff',
    8   => '49210e',
    9   => '51412c',
    10  => '59614a',
    11  => '618168',
    12  => '69a186',
    13  => '71c1a4',
    14  => '79e1c2',
    15  => 'aabac8',
  },

  freakcode => {
    0  => '000000',
    1  => 'ff6565',
    2  => '93d44f',
    3  => 'eab93d',
    4  => '204a87',
    5  => 'ce5c00',
    6  => '89b6e2',
    7  => 'cccccc',
    8  => '555753',
    9  => 'ff8d8d',
    10 => 'c8e7a8',
    11 => 'ffc123',
    12 => '3465a4',
    13 => 'f57900',
    14 => '46a4ff',
    15 => 'ffffff',
  },

  leosolaris => {
    0  => '000000',
    1  => 'a80000',
    2  => '00a800',
    3  => 'a85400',
    4  => '0000a8',
    5  => 'a800a8',
    6  => '00a8a8',
    7  => 'a8a8a8',
    8  => '545054',
    9  => 'f85450',
    10 => '50fc50',
    11 => 'f2fc50',
    12 => '5054f8',
    13 => 'f854f8',
    14 => '50fcf8',
    15 => 'f8fcf8',
  },

  smurnjiff => {
    0  => '2e3436',
    8  => '555753',
    1  => 'cc0000',
    9  => 'ef2929',
    2  => '00ff00',
    10 => '66ff66',
    3  => 'c4a000',
    11 => 'fc394f',
    4  => '3456a4',
    12 => '729fcf',
    5  => '75507b',
    13 => 'ad7fa8',
    6  => '418179',
    14 => '34e2e2',
    7  => 'd3d7cf',
    15 => 'eeeeec',
  },

  calcandcoffee => {
    0  => 262729,
    1  => 'f92671',
    10 => 'a6e22e',
    11 => 'fd971f',
    12 => '66d9ef',
    13 => '9e6ffe',
    14 => 'a3babf',
    15 => 'f8f8f2',
    2  => 'a6e22e',
    3  => 'fd971f',
    4  => '66d9ef',
    5  => '9e6ffe',
    6  => '5e7175',
    7  => 'f8f8f2',
    8  => 554444,
    9  => 'f92671'
  },
  daisuke2 => {
    0 => '000000',
    1 => 'ff6565',
    10 => 'c8e7a8',
    11 => 'ffc123',
    12 => '3465a4',
    13 => 'f57900',
    14 => '46a4ff',
    15 => 'ffffff',
    2 => '93d44f',
    3 => 'eab93d',
    4 => '204a87',
    5 => 'ce5c00',
    6 => '89b6e2',
    7 => 'cccccc',
    8 => 555753,
    9 => 'ff8d8d'
  },
  digerati => {
    0 => 303030,
    1 => 'c03000',
    10 => 'a6cd07',
    11 => 'b5c865',
    12 => '4a7781',
    13 => 'ff3b77',
    14 => '4bb5c1',
    15 => 'e2e2e5',
    2 => 'b1d631',
    3 => 'fecf35',
    4 => 426870,
    5 => '6d506d',
    6 => '4bb5c1',
    7 => 'e2e2e5',
    8 => '5f5f5f',
    9 => 'ff3a78'
  },
  longbow => {
    0 => 222222,
    1 => '9e5641',
    10 => 'c4df90',
    11 => 'ffe080',
    12 => 'b8ddea',
    13 => 'c18fcb',
    14 => '6bc1d0',
    15 => 'cdcdcd',
    2 => '6c7e55',
    3 => 'caaf2b',
    4 => '7fb8d8',
    5 => '956d9d',
    6 => '4c8ea1',
    7 => 808080,
    8 => 454545,
    9 => 'cc896d'
  },
  rasi => {
    0 => 101010,
    1 => 'f13a21',
    10 => 'ffc005',
    11 => '93ff00',
    12 => '0071ff',
    13 => 'ef0051',
    14 => '4bb8fd',
    15 => 'ffffff',
    2 => '93f91d',
    3 => 'ffd00a',
    4 => '004f9e',
    5 => 'ec0048',
    6 => '2aa7e7',
    7 => 'ffffff',
    8 => '1d202f',
    9 => 'ffffff'
  },
  reasons => {
    0 => '1b1d1e',
    1 => 'f92672',
    10 => 'beed5f',
    11 => 'e6db74',
    12 => '66d9ef',
    13 => '9e6ffe',
    14 => 'a3babf',
    15 => 'f8f8f2',
    2 => 'a6e22e',
    3 => 'fd971f',
    4 => '66d9ef',
    5 => '9e6ffe',
    6 => '5e7175',
    7 => 'ccccc6',
    8 => 505354,
    9 => 'ff669d'
  },
  square => {
    0 => 171717,
    1 => 'ea6868',
    10 => '9ead72',
    11 => 'e7db52',
    12 => '66d9ef',
    13 => 'ad7fa8',
    14 => 'a3babf',
    15 => 'e2e2e2',
    2 => 'b6e77d',
    3 => 'dbbb4b',
    4 => '66d9ef',
    5 => '75507b',
    6 => '5e7175',
    7 => 'f2f2f2',
    8 => 554444,
    9 => 'ff7272'
  },
  supertrain => {
    0 => '1c1c1c',
    1 => 'd81860',
    10 => 'bde077',
    11 => 'ffe863',
    12 => 'aaccbb',
    13 => 'bb4466',
    14 => 'a3babf',
    15 => '6c887a',
    2 => 'b7ce42',
    3 => 'fea63c',
    4 => '66aabb',
    5 => 'b7416e',
    6 => '5e7175',
    7 => 'ddeedd',
    8 => '4d4d4d',
    9 => 'f00060'
  },
  tango => {
    0 => '2e3436',
    1 => 'cc0000',
    10 => '8ae234',
    11 => 'fce94f',
    12 => '729fcf',
    13 => 'ad7fa8',
    14 => '00f5e9',
    15 => 'eeeeec',
    2 => '4e9a06',
    3 => 'c4a000',
    4 => '00afff',
    5 => '75507b',
    6 => '0b939b',
    7 => 'd3d7cf',
    8 => 555753,
    9 => 'ef2929'
  },
  tangoesque => {
    0 => '000000',
    1 => 'ff6565',
    10 => 'c8e7a8',
    11 => 'ffc123',
    12 => '3465a4',
    13 => 'f57900',
    14 => '46a4ff',
    15 => 'ffffff',
    2 => '93d44f',
    3 => 'eab93d',
    4 => '204a87',
    5 => 'ce5c00',
    6 => '89b6e2',
    7 => 'cccccc',
    8 => 555753,
    9 => 'ff8d8d'
  },
  taters => {
    0 => '1c1c1c',
    1 => 'd81860',
    10 => 'bde077',
    11 => 'ffe863',
    12 => 'aaccbb',
    13 => 'bb4466',
    14 => 'a3babf',
    15 => '6c887a',
    2 => 'b7ce42',
    3 => 'fea63c',
    4 => '66aabb',
    5 => 'b7416e',
    6 => '5e7175',
    7 => 'ddeedd',
    8 => '4d4d4d',
    9 => 'f00060'
  },
  thayer => {
    0 => '1b1d1e',
    1 => 'f92672',
    10 => 'b6e354',
    11 => 'feed6c',
    12 => '8cedff',
    13 => '9e6ffe',
    14 => '899ca1',
    15 => 'f8f8f2',
    2 => '82b414',
    3 => 'fd971f',
    4 => '56c2d6',
    5 => '8c54fe',
    6 => 465457,
    7 => 'ccccc6',
    8 => 505354,
    9 => 'ff5995'
  },
  b52 => {
    0 => '1b1d1e',
    1 => 'f92672',
    10 => 'beed5f',
    11 => 'e6db74',
    12 => '66d9ef',
    13 => '9e6ffe',
    14 => 'a3babf',
    15 => 'f8f8f2',
    2 => 'a6e22e',
    3 => 'fd971f',
    4 => '66d9ef',
    5 => '9e6ffe',
    6 => '5e7175',
    7 => 'ccccc6',
    8 => 505354,
    9 => 'ff669d'
  },
  c00kiez => {
    0 => 222222,
    1 => 'f60606',
    10 => '93ff00',
    11 => 'ffbf00',
    12 => '0071ff',
    13 => 'b18cfe',
    14 => 'a3babf',
    15 => 'ffffff',
    2 => '72f91d',
    3 => 'ff971f',
    4 => '44a7ee',
    5 => '9e6ffe',
    6 => '5e7175',
    7 => 'ffffff',
    8 => 454545,
    9 => 'f60606'
  },
  drkwolf => {
    0 => 222222,
    1 => 'ea6868',
    10 => 'afd78a',
    11 => 'ffa75d',
    12 => '67cde9',
    13 => 'ecaee9',
    14 => '36fffc',
    15 => 'ffffff',
    2 => 'abcb8d',
    3 => 'e8ae5b',
    4 => '71c5f4',
    5 => 'e2baf1',
    6 => '21f1ea',
    7 => 'f1f1f1',
    8 => 554444,
    9 => 'ff7272'
  },
  'freakcode' => {
    0 => '000000',
    1 => 'ff6565',
    10 => 'c8e7a8',
    11 => 'ffc123',
    12 => '3465a4',
    13 => 'f57900',
    14 => '46a4ff',
    15 => 'ffffff',
    2 => '93d44f',
    3 => 'eab93d',
    4 => '204a87',
    5 => 'ce5c00',
    6 => '89b6e2',
    7 => 'cccccc',
    8 => 555753,
    9 => 'ff8d8d'
  },
  jousi => {
    0 => 262729,
    1 => 'f90670',
    10 => 'd9ff6d',
    11 => 'e6db74',
    12 => '66a7ff',
    13 => 'b18cfe',
    14 => 'a3babf',
    15 => 'ffffff',
    2 => 'beed5f',
    3 => 'ff971f',
    4 => '44a7ee',
    5 => '9e6ffe',
    6 => '88c9ff',
    7 => 'ffffff',
    8 => '3f3f3f',
    9 => 'ff669d'
  },
  jstandler => {
    0 => '000000',
    1 => 'a80000',
    10 => 'ed254f',
    11 => 'ed254f',
    12 => '5054f8',
    13 => 'ed254f',
    14 => '50fcf8',
    15 => 'f8fcf8',
    2 => 'ed254f',
    3 => 'a85400',
    4 => '020202',
    5 => 'a800a8',
    6 => '00a8a8',
    7 => 'a8a8a8',
    8 => 545054,
    9 => 'f85450'
  },
  'leosolaris' => {
    0 => '000000',
    1 => 'a80000',
    10 => '50fc50',
    11 => 'f2fc50',
    12 => '5054f8',
    13 => 'f854f8',
    14 => '50fcf8',
    15 => 'f8fcf8',
    2 => '00a800',
    3 => 'a85400',
    4 => '0000a8',
    5 => 'a800a8',
    6 => '00a8a8',
    7 => 'a8a8a8',
    8 => 545054,
    9 => 'f85450'
  },
  librec00kiez => {
    0 => 222222,
    1 => 'c5000b',
    10 => 'aecf00',
    11 => 'ff950e',
    12 => '0066cc',
    13 => 'd11793',
    14 => 'a3babf',
    15 => 'ffffff',
    2 => '579d1c',
    3 => 'ff420e',
    4 => '004586',
    5 => '9932cc',
    6 => '5e7175',
    7 => 'ffffff',
    8 => 454545,
    9 => 'ff0000'
  },
  mattikus => {
    0 => '1c1c1c',
    1 => 'd81860',
    10 => 'bde077',
    11 => 'ffe863',
    12 => 'aaccbb',
    13 => 'bb4466',
    14 => 'a3babf',
    15 => '6c887a',
    2 => 'b7ce42',
    3 => 'fea63c',
    4 => '66aabb',
    5 => 'b7416e',
    6 => '5e7175',
    7 => 'ddeedd',
    8 => '4d4d4d',
    9 => 'f00060'
  },
  mmso2 => {
    0 => '030303',
    1 => 'ff4747',
    10 => 'b2c470',
    11 => 'efbd5c',
    12 => '2a7cff',
    13 => 'bd6cce',
    14 => '7fc4a4',
    15 => 'ffffff',
    2 => 'a8e134',
    3 => 'ffb400',
    4 => '0066ee',
    5 => 'd237ad',
    6 => '18dfb0',
    7 => 'dedede',
    8 => '1c1c1c',
    9 => 'ff6767'
  },
  sicpsnake => {
    0 => 292929,
    1 => 'de6951',
    10 => '9dbf60',
    11 => 'ec8a25',
    12 => '5495dc',
    13 => 'e41f66',
    14 => '276cc2',
    15 => 'ffffff',
    2 => 'bcda55',
    3 => 'e2a564',
    4 => '2187f6',
    5 => '875c8d',
    6 => '4390b1',
    7 => 'd2d2d2',
    8 => '3d3d3d',
    9 => 'c56a47'
  },
  'smurnjiff' => {
    0 => '2e3436  ',
    1 => 'cc0000 ',
    10 => '66ff66 ',
    11 => 'fc394f ',
    12 => '729fcf ',
    13 => 'ad7fa8 ',
    14 => '34e2e2',
    15 => 'eeeeec ',
    2 => '00ff00 ',
    3 => 'c4a000 ',
    4 => '3456a4',
    5 => '75507b',
    6 => 418179,
    7 => 'd3d7cf ',
    8 => '555753 ',
    9 => 'ef2929 '
  },

  'square' => {
    0 => '2e3436',
    1 => 'cc0000',
    10 => '8ae234',
    11 => 'fce94f',
    12 => '729fcf',
    13 => 'ad7fa8',
    14 => '00f5e9',
    15 => 'eeeeec',
    2 => '4e9a06',
    3 => 'c4a000',
    4 => '3465a4',
    5 => '75507b',
    6 => '0b939b',
    7 => 'd3d7cf',
    8 => 555753,
    9 => 'ef2929'
  },

  whordijk => {
    0 => '1e2320',
    1 => 705050,
    10 => 'c3bf9f',
    11 => 'f0dfaf',
    12 => '94bff3',
    13 => 'ec93d3',
    14 => '93e0e3',
    15 => 'ffffff',
    2 => '60b48a',
    3 => 'dfaf8f',
    4 => 506070,
    5 => 'dc8cc3',
    6 => '8cd0d3',
    7 => 'dcdccc',
    8 => 709080,
    9 => 'dca3a3'
  },
);


sub get_colorscheme {
  my $name = shift || 'xterm';

  my $res  = set_xterm_color( $colorschemes{$name} );

  return $res;

}

sub get_colorschemes { return keys %colorschemes; }



1;

__END__

=pod

=head1 NAME

Term::ExtendedColor::Xresources::Colorscheme - Colorschemes

=head1 SYNOPSIS

    use Term::ExtendedColor::Xresources qw(get_xterm_color set_xterm_color);
    use Term::ExtendedColor::Xresources::Colorscheme qw(get_colorscheme);

    my $colors = get_colorscheme('xterm');
    set_xterm_color($colors);

=head1 DESCRIPTION

B<Term::ExtendedColor::Xresources::Colorscheme> provides a lot of pre-defined
colorschemes for the terminal.

=head1 EXPORTS

None by default.

=head1 FUNCTIONS

=head2 get_colorscheme()

=over 4

=item Arguments:    $colorscheme

=item Return value: \%colorscheme

=back

Given a valid colorscheme name, return a hash reference where its keys are the
color indexes. Every index is mapped to a corresponding escape sequence that'll
change index color n when printed.

=head2 get_colorschemes()

=over 4

=item Arguments:      None

=item Return value:   @colorschemes

=back

Returns a list with all available colorschemes.

=head1 SEE ALSO

L<Term::ExtendedColor::Xresources>, L<Term::ExtendedColor>,
L<Term::ExtendedColor::TTY>

=head1 AUTHOR

  Magnus Woldrich
  CPAN ID: WOLDRICH
  magnus@trapd00r.se
  http://japh.se

=head1 CONTRIBUTORS

None required yet.

=head1 COPYRIGHT

Copyright 2010, 2011 the B<Term::ExtendedColor::Xresources::Colorscheme>
L</AUTHOR> and L</CONTRIBUTORS> as listed above.

=head1 LICENSE

This library is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut
