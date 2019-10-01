package PDF::Font;

our $VERSION = '1.46';

=head1 NAME

PDF::Font - Base font class for PDF::Create.

=head1 VERSION

Version 1.46

=cut

use 5.006;
use strict; use warnings;

use utf8;
use Carp qw(croak);
use Data::Dumper;
use JSON;
use File::Share ':all';

=encoding utf8

=head1 DESCRIPTION

Base font class to support font families approved by L<PDF::Create>. This is used
in the method C<init_widths()> inside the package L<PDF::Create::Page>.

=head1 SYNOPSIS

    use strict; use warnings;
    use PDF::Font;

    my $font = PDF::Font->new('Helvetica');
    my $char_widths = $font->char_width;
    print "Character width: ", $font->get_char_width(ord('A')), "\n";
    print "Character  name: ", $font->get_char_name(ord('A')) , "\n";

=head1 CONSTRUCTOR

Expects C<font_name> as the only parameter. It can be one of the following names:

=over 4

=item * Courier

=item * Courier-Bold

=item * Courier-BoldOblique

=item * Courier-Oblique

=item * Helvetica

=item * Helvetica-Bold

=item * Helvetica-BoldOblique

=item * Helvetica-Oblique

=item * Times-Bold

=item * Times-BoldItalic

=item * Times-Italic

=item * Times-Roman

=item * Symbol

=back

=cut

our $DEBUG = 0;
our $SUPPORTED_FONTS = {
    'Courier'               => 1,
    'Courier-Bold'          => 1,
    'Courier-BoldOblique'   => 1,
    'Courier-Oblique'       => 1,
    'Helvetica'             => 1,
    'Helvetica-Bold'        => 1,
    'Helvetica-BoldOblique' => 1,
    'Helvetica-Oblique'     => 1,
    'Times-Bold'            => 1,
    'Times-BoldItalic'      => 1,
    'Times-Italic'          => 1,
    'Times-Roman'           => 1,
    'Symbol'                => 1,
};

sub new {
    my ($class, $font_name) = @_;

    croak "Missing font name."
        unless defined $font_name;
    croak "Invalid font name [$font_name]."
        unless (exists $SUPPORTED_FONTS->{$font_name});

    my $self = { debug => $DEBUG, font_name => $font_name };
    bless $self, $class;

    $self->{char_width} = $self->_generate_char_width;
    $self->{charset}    = $self->_generate_charset;

    return $self;
}

=head1 METHODS

=head2 char_width()

Returns arrayref of all characters width (0..255).

=cut

sub char_width {
    my ($self) = @_;

    return $self->{char_width};
}

=head2 get_char_width($codepoint)

Returns the character width for the given C<$codepoint>.

=cut

sub get_char_width {
    my ($self, $codepoint) = @_;

    croak "Invalid codepoint [$codepoint] received."
        unless (exists $self->{charset}->{$codepoint});

    return $self->{charset}->{$codepoint}->{char_width};
}

=head2 get_char_name($codepoint)

Returns the character name for the given C<$codepoint>.

=cut

sub get_char_name {
    my ($self, $codepoint) = @_;

    croak "Invalid codepoint [$codepoint] received."
        unless (exists $self->{charset}->{$codepoint});

    return $self->{charset}->{$codepoint}->{name};
}

#
#
# PRIVATE METHODS

sub _generate_char_width {
    my ($self) = @_;

    my $name = sprintf("%s.json", lc($self->{font_name}));
    my $file = dist_file('PDF-Create', $name);
    my $data = _load_data($file);

    my $sorted_data = [ sort { $a->{codepoint} <=> $b->{codepoint} } @$data ];
    my $char_width  = [];
    foreach my $char (@$sorted_data) {
        push @$char_width, $char->{width};
    }

    return $char_width;
}

sub _generate_charset {
    my ($self) = @_;

    my $charset    = {};
    my $char_width = $self->{char_width};

    my $supported_characters = _supported_characters();
    foreach my $index (0..$#$char_width) {
        if ($self->{debug}) {
            print "Code Point [$index]: ", $supported_characters->[$index]->{code_point};
            print "Width: ", $char_width->[$index], "\n";
        }
        $supported_characters->[$index]->{char_width} = $char_width->[$index];
        $charset->{$supported_characters->[$index]->{code_point}} = $supported_characters->[$index];
    }

    return $charset;
}

sub _load_data {
    my ($file) = @_;

    open(my $fh, $file);
    local $/;
    my $json = <$fh>;
    my $data = from_json($json);
    close($fh);

    return $data;
}

sub _supported_characters {

    return [
        # Control Codes: C0
        { code_point =>   0, name => 'Null character NUL'                          },
        { code_point =>   1, name => 'Start of Heading SOH'                        },
        { code_point =>   2, name => 'Start of Text STX'                           },
        { code_point =>   3, name => 'End-of-text character ETX'                   },
        { code_point =>   4, name => 'End-of-transmission character EOT'           },
        { code_point =>   5, name => 'Enquiry character ENQ'                       },
        { code_point =>   6, name => 'Acknowledge character ACK'                   },
        { code_point =>   7, name => 'Bell character BEL'                          },
        { code_point =>   8, name => 'Backspace BS'                                },
        { code_point =>   9, name => 'Horizontal tab HT'                           },
        { code_point =>  10, name => 'Line feed LF'                                },
        { code_point =>  11, name => 'Vertical tab VT'                             },
        { code_point =>  12, name => 'Form feed FF'                                },
        { code_point =>  13, name => 'Carriage return CR'                          },
        { code_point =>  14, name => 'Shift Out SO'                                },
        { code_point =>  15, name => 'Shift In SI'                                 },
        { code_point =>  16, name => 'Data Link Escape DLE'                        },
        { code_point =>  17, name => 'Device Control 1 DC1'                        },
        { code_point =>  18, name => 'Device Control 2 DC2'                        },
        { code_point =>  19, name => 'Device Control 3 DC3'                        },
        { code_point =>  20, name => 'Device Control 4 DC4'                        },
        { code_point =>  21, name => 'Negative-acknowledge character NAK'          },
        { code_point =>  22, name => 'Synchronous Idle SYN'                        },
        { code_point =>  23, name => 'End of Transmission Block ETB'               },
        { code_point =>  24, name => 'Cancel character CAN'                        },
        { code_point =>  25, name => 'End of Medium EM'                            },
        { code_point =>  26, name => 'Substitute character SUB'                    },
        { code_point =>  27, name => 'Escape character ESC'                        },
        { code_point =>  28, name => 'File Separator FS'                           },
        { code_point =>  29, name => 'Group Separator GS'                          },
        { code_point =>  30, name => 'Record Separator RS'                         },
        { code_point =>  31, name => 'Unit Separator US'                           },

        # ASCII Punctuation & Symbols
        { code_point =>  32, name => 'Space'                                       },
        { code_point =>  33, name => 'Exclamation'                                 },
        { code_point =>  34, name => 'Quotation mark'                              },
        { code_point =>  35, name => 'Number sign, Hashtag, Octothorpe, Sharp'     },
        { code_point =>  36, name => 'Dollar sign'                                 },
        { code_point =>  37, name => 'Percent sign'                                },
        { code_point =>  38, name => 'Ampersand'                                   },
        { code_point =>  39, name => 'Apostrophe'                                  },
        { code_point =>  40, name => 'Left parenthesis'                            },
        { code_point =>  41, name => 'Right parenthesis'                           },
        { code_point =>  42, name => 'Asterisk'                                    },
        { code_point =>  43, name => 'Plus sign'                                   },
        { code_point =>  44, name => 'Comma'                                       },
        { code_point =>  45, name => 'Hyphen-minus'                                },
        { code_point =>  46, name => 'Full stop'                                   },
        { code_point =>  47, name => 'Slash (Solidus)'                             },
        # ASCII Digits
        { code_point =>  48, name => 'Digit Zero'                                  },
        { code_point =>  49, name => 'Digit One'                                   },
        { code_point =>  50, name => 'Digit Two'                                   },
        { code_point =>  51, name => 'Digit Three'                                 },
        { code_point =>  52, name => 'Digit Four'                                  },
        { code_point =>  53, name => 'Digit Five'                                  },
        { code_point =>  54, name => 'Digit Six'                                   },
        { code_point =>  55, name => 'Digit Seven'                                 },
        { code_point =>  56, name => 'Digit Eight'                                 },
        { code_point =>  57, name => 'Digit Nine'                                  },
        # ASCII Punctuation & Symbols
        { code_point =>  58, name => 'Colon'                                       },
        { code_point =>  59, name => 'Semicolon'                                   },
        { code_point =>  60, name => 'Less-than sign'                              },
        { code_point =>  61, name => 'Equal sign'                                  },
        { code_point =>  62, name => 'Greater-than sign'                           },
        { code_point =>  63, name => 'Question mark'                               },
        { code_point =>  64, name => 'At sign'                                     },
        # Latin Alphabet: Uppercase
        { code_point =>  65, name => 'Latin Capital letter A'                      },
        { code_point =>  66, name => 'Latin Capital letter B'                      },
        { code_point =>  67, name => 'Latin Capital letter C'                      },
        { code_point =>  68, name => 'Latin Capital letter D'                      },
        { code_point =>  69, name => 'Latin Capital letter E'                      },
        { code_point =>  70, name => 'Latin Capital letter F'                      },
        { code_point =>  71, name => 'Latin Capital letter G'                      },
        { code_point =>  72, name => 'Latin Capital letter H'                      },
        { code_point =>  73, name => 'Latin Capital letter I'                      },
        { code_point =>  74, name => 'Latin Capital letter J'                      },
        { code_point =>  75, name => 'Latin Capital letter K'                      },
        { code_point =>  76, name => 'Latin Capital letter L'                      },
        { code_point =>  77, name => 'Latin Capital letter M'                      },
        { code_point =>  78, name => 'Latin Capital letter N'                      },
        { code_point =>  79, name => 'Latin Capital letter O'                      },
        { code_point =>  80, name => 'Latin Capital letter P'                      },
        { code_point =>  81, name => 'Latin Capital letter Q'                      },
        { code_point =>  82, name => 'Latin Capital letter R'                      },
        { code_point =>  83, name => 'Latin Capital letter S'                      },
        { code_point =>  84, name => 'Latin Capital letter T'                      },
        { code_point =>  85, name => 'Latin Capital letter U'                      },
        { code_point =>  86, name => 'Latin Capital letter V'                      },
        { code_point =>  87, name => 'Latin Capital letter W'                      },
        { code_point =>  88, name => 'Latin Capital letter X'                      },
        { code_point =>  89, name => 'Latin Capital letter Y'                      },
        { code_point =>  90, name => 'Latin Capital letter Z'                      },
        # ASCII Punctuation & Symbols
        { code_point =>  91, name => 'Left Square Bracket'                         },
        { code_point =>  92, name => 'Backlash'                                    },
        { code_point =>  93, name => 'Right Square Bracket'                        },
        { code_point =>  94, name => 'Circumflex'                                  },
        { code_point =>  95, name => 'Low line'                                    },
        { code_point =>  96, name => 'Grave'                                       },
        # Latin Alphabet: Smallcase
        { code_point =>  97, name => 'Latin Small letter a'                        },
        { code_point =>  98, name => 'Latin Small letter b'                        },
        { code_point =>  99, name => 'Latin Small letter c'                        },
        { code_point => 100, name => 'Latin Small letter d'                        },
        { code_point => 101, name => 'Latin Small letter e'                        },
        { code_point => 102, name => 'Latin Small letter f'                        },
        { code_point => 103, name => 'Latin Small letter g'                        },
        { code_point => 104, name => 'Latin Small letter h'                        },
        { code_point => 105, name => 'Latin Small letter i'                        },
        { code_point => 106, name => 'Latin Small letter j'                        },
        { code_point => 107, name => 'Latin Small letter k'                        },
        { code_point => 108, name => 'Latin Small letter l'                        },
        { code_point => 109, name => 'Latin Small letter m'                        },
        { code_point => 110, name => 'Latin Small letter n'                        },
        { code_point => 111, name => 'Latin Small letter o'                        },
        { code_point => 112, name => 'Latin Small letter p'                        },
        { code_point => 113, name => 'Latin Small letter q'                        },
        { code_point => 114, name => 'Latin Small letter r'                        },
        { code_point => 115, name => 'Latin Small letter s'                        },
        { code_point => 116, name => 'Latin Small letter t'                        },
        { code_point => 117, name => 'Latin Small letter u'                        },
        { code_point => 118, name => 'Latin Small letter v'                        },
        { code_point => 119, name => 'Latin Small letter w'                        },
        { code_point => 120, name => 'Latin Small letter x'                        },
        { code_point => 121, name => 'Latin Small letter y'                        },
        { code_point => 122, name => 'Latin Small letter z'                        },
        # ASCII Punctuation & Symbols
        { code_point => 123, name => 'Left Curly Bracket'                          },
        { code_point => 124, name => 'Vertical bar'                                },
        { code_point => 125, name => 'Right Curly Bracket'                         },
        { code_point => 126, name => 'Tilde'                                       },
        # Control Codes: C1
        { code_point => 127, name => 'Delete DEL'                                  },
        { code_point => 128, name => 'Padding Character PAD'                       },
        { code_point => 129, name => 'High Octet Preset HOP'                       },
        { code_point => 130, name => 'Break Permitted Here BPH'                    },
        { code_point => 131, name => 'No Break Here NBH'                           },
        { code_point => 132, name => 'Index IND'                                   },
        { code_point => 133, name => 'Next Line NEL'                               },
        { code_point => 134, name => 'Start of Selected Area SSA'                  },
        { code_point => 135, name => 'End of Selected Area ESA'                    },
        { code_point => 136, name => 'Character Tabulation Set HTS'                },
        { code_point => 137, name => 'Character Tabulation with Justification HTJ' },
        { code_point => 138, name => 'Line Tabulation Set VTS'                     },
        { code_point => 139, name => 'Partial Line Forward PLD'                    },
        { code_point => 140, name => 'Partial Line Backward PLU'                   },
        { code_point => 141, name => 'Reverse Line Feed RI'                        },
        { code_point => 142, name => 'Single-Shift Two SS2'                        },
        { code_point => 143, name => 'Single-Shift Three SS3'                      },
        { code_point => 144, name => 'Device Control String DCS'                   },
        { code_point => 145, name => 'Private Use 1 PU1'                           },
        { code_point => 146, name => 'Private Use 2 PU2'                           },
        { code_point => 147, name => 'Set Transmit State STS'                      },
        { code_point => 148, name => 'Cancel character CCH'                        },
        { code_point => 149, name => 'Message Waiting MW'                          },
        { code_point => 150, name => 'Start of Protected Area SPA'                 },
        { code_point => 151, name => 'End of Protected Area EPA'                   },
        { code_point => 152, name => 'Start of String SOS'                         },
        { code_point => 153, name => 'Single Graphic Character Introducer SGCI'    },
        { code_point => 154, name => 'Single Character Intro Introducer SCI'       },
        { code_point => 155, name => 'Control Sequence Introducer CSI'             },
        { code_point => 156, name => 'String Terminator ST'                        },
        { code_point => 157, name => 'Operating System Command OSC'                },
        { code_point => 158, name => 'Private Message PM'                          },
        { code_point => 159, name => 'Application Program Command APC'             },

        # Latin-1 Punctuation & Symbols
        { code_point => 160, name => 'Non-breaking space'                          },
        { code_point => 161, name => 'Inverted Exclamation Mark'                   },
        { code_point => 162, name => 'Cent sign'                                   },
        { code_point => 163, name => 'Pound sign'                                  },
        { code_point => 164, name => 'Currency sign'                               },
        { code_point => 165, name => 'Yen sign'                                    },
        { code_point => 166, name => 'Broken bar'                                  },
        { code_point => 167, name => 'Section sign'                                },
        { code_point => 168, name => 'Diaeresis (Umlaut)'                          },
        { code_point => 169, name => 'Copyright sign'                              },
        { code_point => 170, name => 'Feminine Ordinal Indicator'                  },
        { code_point => 171, name => 'Left-pointing double angle quotation mark'   },
        { code_point => 172, name => 'Not sign'                                    },
        { code_point => 173, name => 'Soft hyphen'                                 },
        { code_point => 174, name => 'Registered sign'                             },
        { code_point => 175, name => 'Macron'                                      },
        { code_point => 176, name => 'Degree symbol'                               },
        { code_point => 177, name => 'Plus-minus sign'                             },
        { code_point => 178, name => 'Superscript two'                             },
        { code_point => 179, name => 'Superscript three'                           },
        { code_point => 180, name => 'Acute accent'                                },
        { code_point => 181, name => 'Micro sign'                                  },
        { code_point => 182, name => 'Pilcrow sign'                                },
        { code_point => 183, name => 'Middle dot'                                  },
        { code_point => 184, name => 'Cedilla'                                     },
        { code_point => 185, name => 'Superscript one'                             },
        { code_point => 186, name => 'Masculine ordinal indicator'                 },
        { code_point => 187, name => 'Right-pointing double angle quotation mark'  },
        { code_point => 188, name => 'Vulgar fraction one quarter'                 },
        { code_point => 189, name => 'Vulgar fraction one half'                    },
        { code_point => 190, name => 'Vulgar fraction three quarters'              },
        { code_point => 191, name => 'Inverted Question Mark'                      },
        # Latin-1 Letter: Uppercase
        { code_point => 192, name => 'Latin Capital Letter A with grave'           },
        { code_point => 193, name => 'Latin Capital letter A with acute'           },
        { code_point => 194, name => 'Latin Capital letter A with circumflex'      },
        { code_point => 195, name => 'Latin Capital letter A with tilde'           },
        { code_point => 196, name => 'Latin Capital letter A with diaeresis'       },
        { code_point => 197, name => 'Latin Capital letter A with ring above'      },
        { code_point => 198, name => 'Latin Capital letter Æ'                      },
        { code_point => 199, name => 'Latin Capital letter C with cedilla'         },
        { code_point => 200, name => 'Latin Capital letter E with grave'           },
        { code_point => 201, name => 'Latin Capital letter E with acute'           },
        { code_point => 202, name => 'Latin Capital letter E with circumflex'      },
        { code_point => 203, name => 'Latin Capital letter E with diaeresis'       },
        { code_point => 204, name => 'Latin Capital letter I with grave'           },
        { code_point => 205, name => 'Latin Capital letter I with acute'           },
        { code_point => 206, name => 'Latin Capital letter I with circumflex'      },
        { code_point => 207, name => 'Latin Capital letter I with diaeresis'       },
        { code_point => 208, name => 'Latin Capital letter Eth'                    },
        { code_point => 209, name => 'Latin Capital letter N with tilde'           },
        { code_point => 210, name => 'Latin Capital letter O with grave'           },
        { code_point => 211, name => 'Latin Capital letter O with acute'           },
        { code_point => 212, name => 'Latin Capital letter O with circumflex'      },
        { code_point => 213, name => 'Latin Capital letter O with tilde'           },
        { code_point => 214, name => 'Latin Capital letter O with diaeresis'       },
        # Latin-1: Math
        { code_point => 215, name => 'Multiplication sign'                         },
        # Latin-1 Letter: Uppercase
        { code_point => 216, name => 'Latin Capital letter O with stroke'          },
        { code_point => 217, name => 'Latin Capital letter U with grave'           },
        { code_point => 218, name => 'Latin Capital letter U with acute'           },
        { code_point => 219, name => 'Latin Capital Letter U with circumflex'      },
        { code_point => 220, name => 'Latin Capital Letter U with diaeresis'       },
        { code_point => 221, name => 'Latin Capital Letter Y with acute'           },
        { code_point => 222, name => 'Latin Capital Letter Thorn'                  },
        # Latin-1 Letter: Lowercase
        { code_point => 223, name => 'Latin Small Letter sharp'                    },
        { code_point => 224, name => 'Latin Small Letter A with grave'             },
        { code_point => 225, name => 'Latin Small Letter A with acute'             },
        { code_point => 226, name => 'Latin Small Letter A with circumflex'        },
        { code_point => 227, name => 'Latin Small Letter A with tilde'             },
        { code_point => 228, name => 'Latin Small Letter A with diaeresis'         },
        { code_point => 229, name => 'Latin Small Letter A with ring above'        },
        { code_point => 230, name => 'Latin Small Letter Æ'                        },
        { code_point => 231, name => 'Latin Small Letter C with cedilla'           },
        { code_point => 232, name => 'Latin Small Letter E with grave'             },
        { code_point => 233, name => 'Latin Small Letter E with acute'             },
        { code_point => 234, name => 'Latin Small Letter E with circumflex'        },
        { code_point => 235, name => 'Latin Small Letter E with diaeresis'         },
        { code_point => 236, name => 'Latin Small Letter I with grave'             },
        { code_point => 237, name => 'Latin Small Letter I with acute'             },
        { code_point => 238, name => 'Latin Small Letter I with circumflex'        },
        { code_point => 239, name => 'Latin Small Letter I with diaeresis'         },
        { code_point => 240, name => 'Latin Small Letter Eth'                      },
        { code_point => 241, name => 'Latin Small Letter N with tilde'             },
        { code_point => 242, name => 'Latin Small Letter O with grave'             },
        { code_point => 243, name => 'Latin Small Letter O with acute'             },
        { code_point => 244, name => 'Latin Small Letter O with circumflex'        },
        { code_point => 245, name => 'Latin Small Letter O with tilde'             },
        { code_point => 246, name => 'Latin Small Letter O with diaeresis'         },
        # Latin-1: Math
        { code_point => 247, name => 'Division sign'                               },
        # Latin-1 Letter: Lowercase
        { code_point => 248, name => 'Latin Small Letter O with stroke'            },
        { code_point => 249, name => 'Latin Small Letter U with grave'             },
        { code_point => 250, name => 'Latin Small Letter U with acute'             },
        { code_point => 251, name => 'Latin Small Letter U with circumflex'        },
        { code_point => 252, name => 'Latin Small Letter U with diaeresis'         },
        { code_point => 253, name => 'Latin Small Letter Y with acute'             },
        { code_point => 254, name => 'Latin Small Letter Thorn'                    },
        { code_point => 255, name => 'Latin Small Letter Y with diaeresis'         },
    ];
}

=head1 AUTHORS

Mohammad S Anwar (MANWAR) C<< <mohammad.anwar at yahoo.com> >>

=head1 REPOSITORY

L<https://github.com/manwar/pdf-create>

=head1 COPYRIGHT

Copyright 1999-2001,Fabien Tassin.All rights reserved.It may be used and modified
freely, but I do  request that this copyright notice remain attached to the file.
You may modify this module as you wish,but if you redistribute a modified version
, please attach a note listing the modifications you have made.

Copyright 2007 Markus Baertschi

Copyright 2010 Gary Lieberman

=head1 LICENSE

This is free software; you can redistribute it and / or modify it under the same
terms as Perl 5.6.0.

=cut

1; # End of PDF::Font
