#!/usr/bin/perl -wl

###############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Tests formula translation in the Spreadsheet::WriteExcelXML::Worksheet
# module.
#
# reverse('©'), May 2004, John McNamara, jmcnamara@cpan.org
#

use strict;

use Spreadsheet::WriteExcelXML::Worksheet;
use Test::More tests => 71;



# Test input and target output
my @tests = (
                # Tests for string escaping
                [ 0, 0, ''                  => ''                   ],
                [ 0, 0, '""'                => '""'                 ],
                [ 0, 0, '""""'              => '""""'               ],
                [ 0, 0, '""&""&""&""'       => '""&""&""&""'        ],
                [ 0, 0, ' "foo" & "bar" '   => ' "foo" & "bar" '    ],
                [ 0, 0, 'test("foo","bar")' => 'test("foo","bar")'  ],
                [ 0, 0, '" \'\' "'          => '" \'\' "'           ],

                # Tests for cell in the same row
                [ 0, 0, 'G1'                => 'RC[6]'              ],
                [ 0, 0, 'G$1'               => 'R1C[6]'             ],
                [ 0, 0, '$G1'               => 'RC7'                ],
                [ 0, 0, '$G$1'              => 'R1C7'               ],

                # Tests for cell in a previous row
                [ 1, 0, 'G1'                => 'R[-1]C[6]'          ],
                [ 1, 0, 'G$1'               => 'R1C[6]'             ],
                [ 1, 0, '$G1'               => 'R[-1]C7'            ],
                [ 1, 0, '$G$1'              => 'R1C7'               ],

                # Tests for cell in a subsequent row
                [ 2, 0, 'G4'                => 'R[1]C[6]'           ],
                [ 2, 0, 'G$4'               => 'R4C[6]'             ],
                [ 2, 0, '$G4'               => 'R[1]C7'             ],
                [ 2, 0, '$G$4'              => 'R4C7'               ],

                # Tests for cell in the same column
                [ 3, 0, 'A9'                => 'R[5]C'              ],
                [ 3, 0, 'A$9'               => 'R9C'                ],
                [ 3, 0, '$A9'               => 'R[5]C1'             ],
                [ 3, 0, '$A$9'              => 'R9C1'               ],

                # Tests for cell in a subsequent column
                [ 4, 0, 'B9'                => 'R[4]C[1]'           ],
                [ 4, 0, 'B$9'               => 'R9C[1]'             ],
                [ 4, 0, '$B9'               => 'R[4]C2'             ],
                [ 4, 0, '$B$9'              => 'R9C2'               ],

                # Tests for cell in a previous column
                [ 4, 2, 'B9'                => 'R[4]C[-1]'          ],
                [ 4, 2, 'B$9'               => 'R9C[-1]'            ],
                [ 4, 2, '$B9'               => 'R[4]C2'             ],
                [ 4, 2, '$B$9'              => 'R9C2'               ],

                # Tests for false matches in function names
                [ 0, 0, '=LOG10(G10)'       => '=LOG10(R[9]C[6])'   ],
                [ 0, 0, '=LOG10(LOG10)'     => '=LOG10(R[9]C[8508])'],
                [ 1, 0, '=ATAN2(AN2,1)'     => '=ATAN2(RC[39],1)'   ],
                [ 2, 0, '=DAYS360(S360,S360)' =>
                        '=DAYS360(R[357]C[18],R[357]C[18])'         ],

                # Test false column range match after range conversion
                [ 5, 1, "=B1:I1"            => "=R[-5]C:R[-5]C[7]"  ],
                [ 1, 1, "=SUM(Data!B2:B9)"  => "=SUM(Data!RC:R[7]C)"],
                [ 0, 0, "=Sheet2!A1:A1"     => "=Sheet2!RC:RC"      ],


                # Test for ranges
                [ 0, 0, '=D7:F11'           => '=R[6]C[3]:R[10]C[5]'],
                [ 1, 0, '=D$7:F$11'         => '=R7C[3]:R11C[5]'    ],
                [ 2, 0, '=$D7:$F11'         => '=R[4]C4:R[8]C6'     ],
                [ 3, 0, '=$D$7:$F$11'       => '=R7C4:R11C6'        ],
                [ 4, 0, '=D:D'              => '=C[3]'              ],
                [ 5, 0, '=20:20'            => '=R[14]'             ],
                [ 6, 0, '=D:Z'              => '=C[3]:C[25]'        ],
                [ 7, 0, '=20:120'           => '=R[12]:R[112]'      ],
                [ 8, 0, '=$D:$D'            => '=C4'                ],
                [ 9, 0, '=$20:$20'          => '=R20'               ],
                [10, 0, '=$D:$Z'            => '=C4:C26'            ],
                [11, 0, '=$20:$120'         => '=R20:R120'          ],
                [19, 0, '=SUM(20:20)'       => '=SUM(R)'            ],


                # Test for false matches in worksheet references

                # Worksheet names that look like A1 cell references
                [ 0, 0, "='A1'!A1"          => "=A1!RC"             ],
                [ 1, 0, "='AB A1 CC'!A1"    => "='AB A1 CC'!R[-1]C" ],
                [ 2, 0, "='A100'!A100"      => "=A100!R[97]C"       ],
                [ 3, 0, "='IV10'!IV:IV"     => "=IV10!C[255]"       ],
                [ 4, 0, "=IW10!IV:IV"       => "=IW10!C[255]"       ],
                [ 5, 0, "=A1C!A1"           => "=A1C!R[-5]C"        ],
                [ 6, 0, "=A1_A1!A1"         => "=A1_A1!R[-6]C"      ],

                # Worksheet names that contain special characters
                [ 7, 0, "='!'!A1"           => "='!'!R[-7]C"        ],
                [ 8, 0, "='\"\"'!A1"        => "='\"\"'!R[-8]C"     ],

                # Worksheet names that look like R1C1 cell references
                [ 9, 0, "='C'!A1"           => "='C'!R[-9]C"        ],
                [10, 0, "='R'!A1"           => "='R'!R[-10]C"       ],
                [11, 0, "='R4C'!A1"         => "='R4C'!R[-11]C"     ],
                [12, 0, "='RC9'!A1"         => "='RC9'!R[-12]C"     ],
                [13, 0, "='R4C9'!A1"        => "='R4C9'!R[-13]C"    ],
                [14, 0, "='R5C300'!A1"      => "='R5C300'!R[-14]C"  ],
                [15, 0, "=xR4C9!A1"         => "=xR4C9!R[-15]C"     ],
                [16, 0, "='R[4]C[9]'!A1"    => "='R[4]C[9]'!R[-16]C"],
                [17, 0, "=She.et!A1"        => "=She.et!R[-17]C"    ],
                [18, 0, "=Sheet.!A1"        => "=Sheet.!R[-18]C"    ],
                [19, 0, "='.Sheet'!A1"      => "='.Sheet'!R[-19]C"  ],


             );




my $worksheet = Spreadsheet::WriteExcelXML::Worksheet->new();

###############################################################################
#
# Run the tests.
#
for my $test_ref (@tests) {

    my $row    = $test_ref->[0];
    my $col    = $test_ref->[1];
    my $input  = $test_ref->[2];
    my $result = $test_ref->[3];

    is($worksheet->_convert_formula($row, $col, $input), $result,
       "Testing formula:    " . join " ", @$test_ref);
}



__END__


