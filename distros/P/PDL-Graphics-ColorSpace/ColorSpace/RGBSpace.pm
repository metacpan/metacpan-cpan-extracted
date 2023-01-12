package PDL::Graphics::ColorSpace::RGBSpace;

use strict;
use warnings;
use PDL::LiteF;
use Carp;

=head1 NAME

PDL::Graphics::ColorSpace::RGBSpace -- defines RGB space conversion parameters and white points.

=head1 DESCRIPTION

Sourced from Graphics::ColorObject (Izvorski & Reibenschuh, 2005).

=head1 Usage

    use Data::Dumper;
    print Dumper $PDL::Graphics::ColorSpace::RGBSpace::RGB_SPACE;
    print Dumper $PDL::Graphics::ColorSpace::RGBSpace::WHITE_POINT;

=cut

our $WHITE_POINT = {
          'D50' => [
                     '0.34567',
                     '0.3585'
                   ],
          'A' => [
                   '0.44757',
                   '0.40745'
                 ],
          'D75' => [
                     '0.29902',
                     '0.31485'
                   ],
          'D55' => [
                     '0.33242',
                     '0.34743'
                   ],
          'D65' => [
                     '0.312713',
                     '0.329016'
                   ],
          'E' => [
                   '0.333333',
                   '0.333333'
                 ],
          'B' => [
                   '0.34842',
                   '0.35161'
                 ],
          'F11' => [
                     '0.38054',
                     '0.37691'
                   ],
          'F2' => [
                    '0.37207',
                    '0.37512'
                  ],
          'C' => [
                   '0.310063',
                   '0.316158'
                 ],
          'D93' => [
                     '0.2848',
                     '0.2932'
                   ],
          'F7' => [
                    '0.31285',
                    '0.32918'
                  ]
};

our $RGB_SPACE = {
          'BruceRGB' => {
                          'gamma' => '2.2',
                          'm' => pdl([
                                   [
                                     '0.467384242424242',
                                     '0.240995',
                                     '0.0219086363636363'
                                   ],
                                   [
                                     '0.294454030769231',
                                     '0.683554',
                                     '0.0736135076923076'
                                   ],
                                   [
                                     '0.18863',
                                     '0.075452',
                                     '0.993451333333334'
                                   ]
                                 ]),
                          'white_point' => $WHITE_POINT->{'D65'},
                        },
          'Adobe RGB (1998)' => {
                                  'gamma' => '2.2',
                                  'm' => pdl([
                                           [
                                             '0.576700121212121',
                                             '0.297361',
                                             '0.0270328181818181'
                                           ],
                                           [
                                             '0.185555704225352',
                                             '0.627355',
                                             '0.0706878873239437'
                                           ],
                                           [
                                             '0.1882125',
                                             '0.075285',
                                             '0.9912525'
                                           ]
                                         ]),
                                  'white_point' => $WHITE_POINT->{'D65'},
                                },
          'WideGamut' => {
                           'gamma' => '2.2',
                           'm' => pdl([
                                    [
                                      '0.716103566037736',
                                      '0.258187',
                                      '0'
                                    ],
                                    [
                                      '0.100929624697337',
                                      '0.724938',
                                      '0.0517812857142858'
                                    ],
                                    [
                                      '0.1471875',
                                      '0.016875',
                                      '0.7734375'
                                    ]
                                  ]),
                           'white_point' => $WHITE_POINT->{'D50'},
                         },
          'NTSC' => {
                      'gamma' => '2.2',
                      'm' => pdl([
                               [
                                 '0.606733727272727',
                                 '0.298839',
                                 '-1e-16'
                               ],
                               [
                                 '0.173563816901409',
                                 '0.586811',
                                 '0.0661195492957747'
                               ],
                               [
                                 '0.2001125',
                                 '0.11435',
                                 '1.1149125'
                               ]
                             ]),
                      'white_point' => $WHITE_POINT->{'C'},
                    },
          'Ekta Space PS5' => {
                                'gamma' => '2.2',
                                'm' => pdl([
                                         [
                                           '0.59389231147541',
                                           '0.260629',
                                           '0'
                                         ],
                                         [
                                           '0.272979942857143',
                                           '0.734946',
                                           '0.0419969142857143'
                                         ],
                                         [
                                           '0.09735',
                                           '0.004425',
                                           '0.783225'
                                         ]
                                       ]),
                                'white_point' => $WHITE_POINT->{'D50'},
                              },
          'PAL/SECAM' => {
                           'gamma' => '2.2',
                           'm' => pdl([
                                    [
                                      '0.430586181818182',
                                      '0.222021',
                                      '0.0201837272727273'
                                    ],
                                    [
                                      '0.341545083333333',
                                      '0.706645',
                                      '0.129551583333333'
                                    ],
                                    [
                                      '0.178335',
                                      '0.071334',
                                      '0.939231'
                                    ]
                                  ]),
                           'white_point' => $WHITE_POINT->{'D65'},
                         },
          'Apple RGB' => {
                           'gamma' => '1.8',
                           'm' => pdl([
                                    [
                                      '0.449694852941176',
                                      '0.244634',
                                      '0.0251829117647059'
                                    ],
                                    [
                                      '0.316251294117647',
                                      '0.672034',
                                      '0.141183613445378'
                                    ],
                                    [
                                      '0.184520857142857',
                                      '0.083332',
                                      '0.922604285714286'
                                    ]
                                  ]),
                           'white_point' => $WHITE_POINT->{'D65'},
                         },
          'sRGB' => {
                      'gamma' => '-1',     # mark it for special case
                      'm' => pdl([
                               [
                                 '0.412423757575757',
                                 '0.212656',
                                 '0.0193323636363636'
                               ],
                               [
                                 '0.357579',
                                 '0.715158',
                                 '0.119193'
                               ],
                               [
                                 '0.180465',
                                 '0.072186',
                                 '0.950449'
                               ]
                             ]),
                      'white_point' => $WHITE_POINT->{'D65'},
                    },
          'lsRGB' => {
                      'gamma' => 1.0,
                      'm' => pdl([
                               [
                                 '0.412423757575757',
                                 '0.212656',
                                 '0.0193323636363636'
                               ],
                               [
                                 '0.357579',
                                 '0.715158',
                                 '0.119193'
                               ],
                               [
                                 '0.180465',
                                 '0.072186',
                                 '0.950449'
                               ]
                             ]),
                      'white_point' => $WHITE_POINT->{'D65'},
                    },
          'ColorMatch' => {
                            'gamma' => '1.8',
                            'm' => pdl([
                                     [
                                       '0.509343882352941',
                                       '0.274884',
                                       '0.0242544705882353'
                                     ],
                                     [
                                       '0.320907338842975',
                                       '0.658132',
                                       '0.108782148760331'
                                     ],
                                     [
                                       '0.13397',
                                       '0.066985',
                                       '0.692178333333333'
                                     ]
                                   ]),
                            'white_point' => $WHITE_POINT->{'D50'},
                          },
          'SMPTE-C' => {
                         'gamma' => '2.2',
                         'm' => pdl([
                                  [
                                    '0.393555441176471',
                                    '0.212395',
                                    '0.0187407352941176'
                                  ],
                                  [
                                    '0.365252420168067',
                                    '0.701049',
                                    '0.111932193277311'
                                  ],
                                  [
                                    '0.191659714285714',
                                    '0.086556',
                                    '0.958298571428571'
                                  ]
                                ]),
                         'white_point' => $WHITE_POINT->{'D65'},
                       },
          'CIE' => {
                     'gamma' => '2.2',
                     'm' => pdl([
                              [
                                '0.488716754716981',
                                '0.176204',
                                '0'
                              ],
                              [
                                '0.310680460251046',
                                '0.812985',
                                '0.0102048326359833'
                              ],
                              [
                                '0.200604111111111',
                                '0.010811',
                                '0.989807111111111'
                              ]
                            ]),
                     'white_point' => $WHITE_POINT->{'E'},
                   },
          'ProPhoto' => {
                          'gamma' => '1.8',
                          'm' => pdl([
                                   [
                                     '0.797674285714286',
                                     '0.28804',
                                     '0'
                                   ],
                                   [
                                     '0.135191683008091',
                                     '0.711874',
                                     '0'
                                   ],
                                   [
                                     '0.031476',
                                     '8.6e-05',
                                     '0.828438'
                                   ]
                                 ]),
                          'white_point' => $WHITE_POINT->{'D50'},
                        },
          'BestRGB' => {
                         'gamma' => '2.2',
                         'm' => pdl([
                                  [
                                    '0.632670026008293',
                                    '0.228457',
                                    '0'
                                  ],
                                  [
                                    '0.204555716129032',
                                    '0.737352',
                                    '0.0095142193548387'
                                  ],
                                  [
                                    '0.126995142857143',
                                    '0.034191',
                                    '0.815699571428571'
                                  ]
                                ]),
                         'white_point' => $WHITE_POINT->{'D50'},
                       },
          'DonRGB4' => {
                         'gamma' => '2.2',
                         'm' => pdl([
                                  [
                                    '0.645772',
                                    '0.27835',
                                    '0.0037113333333334'
                                  ],
                                  [
                                    '0.193351045751634',
                                    '0.68797',
                                    '0.0179861437908497'
                                  ],
                                  [
                                    '0.125097142857143',
                                    '0.03368',
                                    '0.803508571428572'
                                  ]
                                ]),
                         'white_point' => $WHITE_POINT->{'D50'},
                       },
          'Beta RGB' => {
                          'gamma' => '2.2',
                          'm' => pdl([
                                   [
                                     '0.67125463496144',
                                     '0.303273',
                                     '1e-16'
                                   ],
                                   [
                                     '0.1745833659118',
                                     '0.663786',
                                     '0.0407009558998808'
                                   ],
                                   [
                                     '0.11838171875',
                                     '0.032941',
                                     '0.784501144886363'
                                   ]
                                 ]),
                          'white_point' => $WHITE_POINT->{'D50'},
                        },
          'ECI' => {
                     'gamma' => '1.8',
                     'm' => pdl([
                              [
                                '0.650204545454545',
                                '0.32025',
                                '-1e-16'
                              ],
                              [
                                '0.178077338028169',
                                '0.602071',
                                '0.067838985915493'
                              ],
                              [
                                '0.13593825',
                                '0.077679',
                                '0.75737025'
                              ]
                            ]),
                     'white_point' => $WHITE_POINT->{'D50'},
                   },
};
$RGB_SPACE->{$_}{white_point} = PDL->topdl($RGB_SPACE->{$_}{white_point}),
$RGB_SPACE->{$_}{mstar} = $RGB_SPACE->{$_}{m}->inv
  for keys %$RGB_SPACE;

# aliases
$RGB_SPACE->{Adobe} = $RGB_SPACE->{'Adobe RGB (1998)'};
$RGB_SPACE->{'601'}   = $RGB_SPACE->{NTSC};
$RGB_SPACE->{Apple} = $RGB_SPACE->{'Apple RGB'};
$RGB_SPACE->{'CIE ITU'} = $RGB_SPACE->{'PAL/SECAM'};
$RGB_SPACE->{PAL} = $RGB_SPACE->{'PAL/SECAM'};
$RGB_SPACE->{'709'} = $RGB_SPACE->{sRGB};
$RGB_SPACE->{SMPTE} = $RGB_SPACE->{'SMPTE-C'};
$RGB_SPACE->{'CIE Rec 709'} = $RGB_SPACE->{sRGB};
$RGB_SPACE->{'CIE Rec 601'} = $RGB_SPACE->{NTSC};

my @NEED_KEYS = grep $_ ne 'mstar', keys %{ $RGB_SPACE->{sRGB} };
sub add_rgb_space {
	my ($new_space) = @_;
	my @dup = grep $RGB_SPACE->{$_}, sort keys %$new_space;
	croak "Already existing RGB space definition with names @dup" if @dup;
	while (my ($name, $profile) = each %$new_space) {
		carp "Missing definition for custom RGB space $name: $_"
		    for grep !defined $profile->{$_}, @NEED_KEYS;
		my $copy = {%$profile};
		$copy->{m} = PDL->topdl($copy->{m});
		$copy->{mstar} = $copy->{m}->inv if !exists $copy->{mstar};
		$copy->{mstar} = PDL->topdl($copy->{mstar});
		$copy->{white_point} = PDL->topdl($copy->{white_point});
		$RGB_SPACE->{$name} = $copy;
	}
}

sub get_space {
  my ($space) = @_;
  croak "Please specify RGB Space ('sRGB' for generic JPEG images)!"
    if !$space;
  my $spec = ref($space) ? $space : $RGB_SPACE->{$space};
}

1;
