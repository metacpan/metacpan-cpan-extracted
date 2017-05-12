use Test::More tests => 1;
use Parse::ABNF;
use File::Spec qw();
use IO::File;

my $path = File::Spec->catfile('data', 'rfc3987.abnf');
my $text = do { local $/; IO::File->new('<' . $path)->getline };

# Try to avoid the usual newline madness...
$text =~ s/\x0d\x0a|\x0d|\x0a/\n/g;

my $gram = Parse::ABNF->new->parse($text);

my $expt = [
  {
    'value' => {
      'value' => [
        {
          'name' => 'scheme',
          'class' => 'Reference'
        },
        {
          'value' => ':',
          'class' => 'Literal'
        },
        {
          'name' => 'ihier-part',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '?',
                'class' => 'Literal'
              },
              {
                'name' => 'iquery',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '#',
                'class' => 'Literal'
              },
              {
                'name' => 'ifragment',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'IRI',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => [
            {
              'value' => '//',
              'class' => 'Literal'
            },
            {
              'name' => 'iauthority',
              'class' => 'Reference'
            },
            {
              'name' => 'ipath-abempty',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'name' => 'ipath-absolute',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-rootless',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-empty',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'ihier-part',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'IRI',
          'class' => 'Reference'
        },
        {
          'name' => 'irelative-ref',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'IRI-reference',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'scheme',
          'class' => 'Reference'
        },
        {
          'value' => ':',
          'class' => 'Literal'
        },
        {
          'name' => 'ihier-part',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '?',
                'class' => 'Literal'
              },
              {
                'name' => 'iquery',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'absolute-IRI',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'irelative-part',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '?',
                'class' => 'Literal'
              },
              {
                'name' => 'iquery',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '#',
                'class' => 'Literal'
              },
              {
                'name' => 'ifragment',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'irelative-ref',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => [
            {
              'value' => '//',
              'class' => 'Literal'
            },
            {
              'name' => 'iauthority',
              'class' => 'Reference'
            },
            {
              'name' => 'ipath-abempty',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'name' => 'ipath-absolute',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-noscheme',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-empty',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'irelative-part',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'name' => 'iuserinfo',
                'class' => 'Reference'
              },
              {
                'value' => '@',
                'class' => 'Literal'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        },
        {
          'name' => 'ihost',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => ':',
                'class' => 'Literal'
              },
              {
                'name' => 'port',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'iauthority',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'value' => [
          {
            'name' => 'iunreserved',
            'class' => 'Reference'
          },
          {
            'name' => 'pct-encoded',
            'class' => 'Reference'
          },
          {
            'name' => 'sub-delims',
            'class' => 'Reference'
          },
          {
            'value' => ':',
            'class' => 'Literal'
          }
        ],
        'class' => 'Choice'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'iuserinfo',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'IP-literal',
          'class' => 'Reference'
        },
        {
          'name' => 'IPv4address',
          'class' => 'Reference'
        },
        {
          'name' => 'ireg-name',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'ihost',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'value' => [
          {
            'name' => 'iunreserved',
            'class' => 'Reference'
          },
          {
            'name' => 'pct-encoded',
            'class' => 'Reference'
          },
          {
            'name' => 'sub-delims',
            'class' => 'Reference'
          }
        ],
        'class' => 'Choice'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'ireg-name',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'ipath-abempty',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-absolute',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-noscheme',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-rootless',
          'class' => 'Reference'
        },
        {
          'name' => 'ipath-empty',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'ipath',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'value' => [
          {
            'value' => '/',
            'class' => 'Literal'
          },
          {
            'name' => 'isegment',
            'class' => 'Reference'
          }
        ],
        'class' => 'Group'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'ipath-abempty',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => '/',
          'class' => 'Literal'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'name' => 'isegment-nz',
                'class' => 'Reference'
              },
              {
                'min' => 0,
                'value' => {
                  'value' => [
                    {
                      'value' => '/',
                      'class' => 'Literal'
                    },
                    {
                      'name' => 'isegment',
                      'class' => 'Reference'
                    }
                  ],
                  'class' => 'Group'
                },
                'max' => undef,
                'class' => 'Repetition'
              }
            ],
            'class' => 'Group'
          },
          'max' => 1,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'ipath-absolute',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'isegment-nz-nc',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '/',
                'class' => 'Literal'
              },
              {
                'name' => 'isegment',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => undef,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'ipath-noscheme',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'isegment-nz',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'value' => '/',
                'class' => 'Literal'
              },
              {
                'name' => 'isegment',
                'class' => 'Reference'
              }
            ],
            'class' => 'Group'
          },
          'max' => undef,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'ipath-rootless',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => '0',
      'value' => {
        'value' => 'ipchar',
        'class' => 'ProseValue'
      },
      'max' => '0',
      'class' => 'Repetition'
    },
    'name' => 'ipath-empty',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'name' => 'ipchar',
        'class' => 'Reference'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'isegment',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => '1',
      'value' => {
        'name' => 'ipchar',
        'class' => 'Reference'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'isegment-nz',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => '1',
      'value' => {
        'value' => [
          {
            'name' => 'iunreserved',
            'class' => 'Reference'
          },
          {
            'name' => 'pct-encoded',
            'class' => 'Reference'
          },
          {
            'name' => 'sub-delims',
            'class' => 'Reference'
          },
          {
            'value' => '@',
            'class' => 'Literal'
          }
        ],
        'class' => 'Choice'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'isegment-nz-nc',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'iunreserved',
          'class' => 'Reference'
        },
        {
          'name' => 'pct-encoded',
          'class' => 'Reference'
        },
        {
          'name' => 'sub-delims',
          'class' => 'Reference'
        },
        {
          'value' => ':',
          'class' => 'Literal'
        },
        {
          'value' => '@',
          'class' => 'Literal'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'ipchar',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'value' => [
          {
            'name' => 'ipchar',
            'class' => 'Reference'
          },
          {
            'name' => 'iprivate',
            'class' => 'Reference'
          },
          {
            'value' => '/',
            'class' => 'Literal'
          },
          {
            'value' => '?',
            'class' => 'Literal'
          }
        ],
        'class' => 'Choice'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'iquery',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'value' => [
          {
            'name' => 'ipchar',
            'class' => 'Reference'
          },
          {
            'value' => '/',
            'class' => 'Literal'
          },
          {
            'value' => '?',
            'class' => 'Literal'
          }
        ],
        'class' => 'Choice'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'ifragment',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'ALPHA',
          'class' => 'Reference'
        },
        {
          'name' => 'DIGIT',
          'class' => 'Reference'
        },
        {
          'value' => '-',
          'class' => 'Literal'
        },
        {
          'value' => '.',
          'class' => 'Literal'
        },
        {
          'value' => '_',
          'class' => 'Literal'
        },
        {
          'value' => '~',
          'class' => 'Literal'
        },
        {
          'name' => 'ucschar',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'iunreserved',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'min' => 'A0',
          'max' => 'D7FF',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'F900',
          'max' => 'FDCF',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'FDF0',
          'max' => 'FFEF',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '10000',
          'max' => '1FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '20000',
          'max' => '2FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '30000',
          'max' => '3FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '40000',
          'max' => '4FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '50000',
          'max' => '5FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '60000',
          'max' => '6FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '70000',
          'max' => '7FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '80000',
          'max' => '8FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '90000',
          'max' => '9FFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'A0000',
          'max' => 'AFFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'B0000',
          'max' => 'BFFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'C0000',
          'max' => 'CFFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'D0000',
          'max' => 'DFFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'E1000',
          'max' => 'EFFFD',
          'type' => 'hex',
          'class' => 'Range'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'ucschar',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'min' => 'E000',
          'max' => 'F8FF',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => 'F0000',
          'max' => 'FFFFD',
          'type' => 'hex',
          'class' => 'Range'
        },
        {
          'min' => '100000',
          'max' => '10FFFD',
          'type' => 'hex',
          'class' => 'Range'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'iprivate',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'ALPHA',
          'class' => 'Reference'
        },
        {
          'min' => 0,
          'value' => {
            'value' => [
              {
                'name' => 'ALPHA',
                'class' => 'Reference'
              },
              {
                'name' => 'DIGIT',
                'class' => 'Reference'
              },
              {
                'value' => '+',
                'class' => 'Literal'
              },
              {
                'value' => '-',
                'class' => 'Literal'
              },
              {
                'value' => '.',
                'class' => 'Literal'
              }
            ],
            'class' => 'Choice'
          },
          'max' => undef,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'scheme',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => 0,
      'value' => {
        'name' => 'DIGIT',
        'class' => 'Reference'
      },
      'max' => undef,
      'class' => 'Repetition'
    },
    'name' => 'port',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => '[',
          'class' => 'Literal'
        },
        {
          'value' => [
            {
              'name' => 'IPv6address',
              'class' => 'Reference'
            },
            {
              'name' => 'IPvFuture',
              'class' => 'Reference'
            }
          ],
          'class' => 'Choice'
        },
        {
          'value' => ']',
          'class' => 'Literal'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'IP-literal',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => 'v',
          'class' => 'Literal'
        },
        {
          'min' => '1',
          'value' => {
            'name' => 'HEXDIG',
            'class' => 'Reference'
          },
          'max' => undef,
          'class' => 'Repetition'
        },
        {
          'value' => '.',
          'class' => 'Literal'
        },
        {
          'min' => '1',
          'value' => {
            'value' => [
              {
                'name' => 'unreserved',
                'class' => 'Reference'
              },
              {
                'name' => 'sub-delims',
                'class' => 'Reference'
              },
              {
                'value' => ':',
                'class' => 'Literal'
              }
            ],
            'class' => 'Choice'
          },
          'max' => undef,
          'class' => 'Repetition'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'IPvFuture',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => [
            {
              'min' => '6',
              'value' => {
                'value' => [
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  },
                  {
                    'value' => ':',
                    'class' => 'Literal'
                  }
                ],
                'class' => 'Group'
              },
              'max' => '6',
              'class' => 'Repetition'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'min' => '5',
              'value' => {
                'value' => [
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  },
                  {
                    'value' => ':',
                    'class' => 'Literal'
                  }
                ],
                'class' => 'Group'
              },
              'max' => '5',
              'class' => 'Repetition'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'name' => 'h16',
                'class' => 'Reference'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'min' => '4',
              'value' => {
                'value' => [
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  },
                  {
                    'value' => ':',
                    'class' => 'Literal'
                  }
                ],
                'class' => 'Group'
              },
              'max' => '4',
              'class' => 'Repetition'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'value' => [
                  {
                    'min' => 0,
                    'value' => {
                      'value' => [
                        {
                          'name' => 'h16',
                          'class' => 'Reference'
                        },
                        {
                          'value' => ':',
                          'class' => 'Literal'
                        }
                      ],
                      'class' => 'Group'
                    },
                    'max' => '1',
                    'class' => 'Repetition'
                  },
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  }
                ],
                'class' => 'Group'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'min' => '3',
              'value' => {
                'value' => [
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  },
                  {
                    'value' => ':',
                    'class' => 'Literal'
                  }
                ],
                'class' => 'Group'
              },
              'max' => '3',
              'class' => 'Repetition'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'value' => [
                  {
                    'min' => 0,
                    'value' => {
                      'value' => [
                        {
                          'name' => 'h16',
                          'class' => 'Reference'
                        },
                        {
                          'value' => ':',
                          'class' => 'Literal'
                        }
                      ],
                      'class' => 'Group'
                    },
                    'max' => '2',
                    'class' => 'Repetition'
                  },
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  }
                ],
                'class' => 'Group'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'min' => '2',
              'value' => {
                'value' => [
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  },
                  {
                    'value' => ':',
                    'class' => 'Literal'
                  }
                ],
                'class' => 'Group'
              },
              'max' => '2',
              'class' => 'Repetition'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'value' => [
                  {
                    'min' => 0,
                    'value' => {
                      'value' => [
                        {
                          'name' => 'h16',
                          'class' => 'Reference'
                        },
                        {
                          'value' => ':',
                          'class' => 'Literal'
                        }
                      ],
                      'class' => 'Group'
                    },
                    'max' => '3',
                    'class' => 'Repetition'
                  },
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  }
                ],
                'class' => 'Group'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'name' => 'h16',
              'class' => 'Reference'
            },
            {
              'value' => ':',
              'class' => 'Literal'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'value' => [
                  {
                    'min' => 0,
                    'value' => {
                      'value' => [
                        {
                          'name' => 'h16',
                          'class' => 'Reference'
                        },
                        {
                          'value' => ':',
                          'class' => 'Literal'
                        }
                      ],
                      'class' => 'Group'
                    },
                    'max' => '4',
                    'class' => 'Repetition'
                  },
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  }
                ],
                'class' => 'Group'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'name' => 'ls32',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'value' => [
                  {
                    'min' => 0,
                    'value' => {
                      'value' => [
                        {
                          'name' => 'h16',
                          'class' => 'Reference'
                        },
                        {
                          'value' => ':',
                          'class' => 'Literal'
                        }
                      ],
                      'class' => 'Group'
                    },
                    'max' => '5',
                    'class' => 'Repetition'
                  },
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  }
                ],
                'class' => 'Group'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            },
            {
              'name' => 'h16',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'min' => 0,
              'value' => {
                'value' => [
                  {
                    'min' => 0,
                    'value' => {
                      'value' => [
                        {
                          'name' => 'h16',
                          'class' => 'Reference'
                        },
                        {
                          'value' => ':',
                          'class' => 'Literal'
                        }
                      ],
                      'class' => 'Group'
                    },
                    'max' => '6',
                    'class' => 'Repetition'
                  },
                  {
                    'name' => 'h16',
                    'class' => 'Reference'
                  }
                ],
                'class' => 'Group'
              },
              'max' => 1,
              'class' => 'Repetition'
            },
            {
              'value' => '::',
              'class' => 'Literal'
            }
          ],
          'class' => 'Group'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'IPv6address',
    'class' => 'Rule'
  },
  {
    'value' => {
      'min' => '1',
      'value' => {
        'name' => 'HEXDIG',
        'class' => 'Reference'
      },
      'max' => '4',
      'class' => 'Repetition'
    },
    'name' => 'h16',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => [
            {
              'name' => 'h16',
              'class' => 'Reference'
            },
            {
              'value' => ':',
              'class' => 'Literal'
            },
            {
              'name' => 'h16',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'name' => 'IPv4address',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'ls32',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'dec-octet',
          'class' => 'Reference'
        },
        {
          'value' => '.',
          'class' => 'Literal'
        },
        {
          'name' => 'dec-octet',
          'class' => 'Reference'
        },
        {
          'value' => '.',
          'class' => 'Literal'
        },
        {
          'name' => 'dec-octet',
          'class' => 'Reference'
        },
        {
          'value' => '.',
          'class' => 'Literal'
        },
        {
          'name' => 'dec-octet',
          'class' => 'Reference'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'IPv4address',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'DIGIT',
          'class' => 'Reference'
        },
        {
          'value' => [
            {
              'min' => '31',
              'max' => '39',
              'type' => 'hex',
              'class' => 'Range'
            },
            {
              'name' => 'DIGIT',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'value' => '1',
              'class' => 'Literal'
            },
            {
              'min' => '2',
              'value' => {
                'name' => 'DIGIT',
                'class' => 'Reference'
              },
              'max' => '2',
              'class' => 'Repetition'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'value' => '2',
              'class' => 'Literal'
            },
            {
              'min' => '30',
              'max' => '34',
              'type' => 'hex',
              'class' => 'Range'
            },
            {
              'name' => 'DIGIT',
              'class' => 'Reference'
            }
          ],
          'class' => 'Group'
        },
        {
          'value' => [
            {
              'value' => '25',
              'class' => 'Literal'
            },
            {
              'min' => '30',
              'max' => '35',
              'type' => 'hex',
              'class' => 'Range'
            }
          ],
          'class' => 'Group'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'dec-octet',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => '%',
          'class' => 'Literal'
        },
        {
          'name' => 'HEXDIG',
          'class' => 'Reference'
        },
        {
          'name' => 'HEXDIG',
          'class' => 'Reference'
        }
      ],
      'class' => 'Group'
    },
    'name' => 'pct-encoded',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'ALPHA',
          'class' => 'Reference'
        },
        {
          'name' => 'DIGIT',
          'class' => 'Reference'
        },
        {
          'value' => '-',
          'class' => 'Literal'
        },
        {
          'value' => '.',
          'class' => 'Literal'
        },
        {
          'value' => '_',
          'class' => 'Literal'
        },
        {
          'value' => '~',
          'class' => 'Literal'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'unreserved',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'name' => 'gen-delims',
          'class' => 'Reference'
        },
        {
          'name' => 'sub-delims',
          'class' => 'Reference'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'reserved',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => ':',
          'class' => 'Literal'
        },
        {
          'value' => '/',
          'class' => 'Literal'
        },
        {
          'value' => '?',
          'class' => 'Literal'
        },
        {
          'value' => '#',
          'class' => 'Literal'
        },
        {
          'value' => '[',
          'class' => 'Literal'
        },
        {
          'value' => ']',
          'class' => 'Literal'
        },
        {
          'value' => '@',
          'class' => 'Literal'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'gen-delims',
    'class' => 'Rule'
  },
  {
    'value' => {
      'value' => [
        {
          'value' => '!',
          'class' => 'Literal'
        },
        {
          'value' => '$',
          'class' => 'Literal'
        },
        {
          'value' => '&',
          'class' => 'Literal'
        },
        {
          'value' => '\'',
          'class' => 'Literal'
        },
        {
          'value' => '(',
          'class' => 'Literal'
        },
        {
          'value' => ')',
          'class' => 'Literal'
        },
        {
          'value' => '*',
          'class' => 'Literal'
        },
        {
          'value' => '+',
          'class' => 'Literal'
        },
        {
          'value' => ',',
          'class' => 'Literal'
        },
        {
          'value' => ';',
          'class' => 'Literal'
        },
        {
          'value' => '=',
          'class' => 'Literal'
        }
      ],
      'class' => 'Choice'
    },
    'name' => 'sub-delims',
    'class' => 'Rule'
  }
];

is_deeply($gram, $expt, "RFC 3987 grammar");

