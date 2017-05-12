#!/usr/bin/perl -w

###############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Tests cell formatting in the Spreadsheet::WriteExcelXML::Format module.
#
# reverse('©'), May 2004, John McNamara, jmcnamara@cpan.org
#


use strict;

use Spreadsheet::WriteExcelXML;
use Test::More tests => 193;




my @tests1 = (  # Cell alignment properties

                # Horizontal properties
                [[],
                  '<Alignment/>'                                            ],

                [['align', 'top'],
                  '<Alignment ss:Vertical="Top"/>'                          ],

                [['align', 'vcenter'],
                  '<Alignment ss:Vertical="Center"/>'                       ],

                [['align', 'bottom'],
                  '<Alignment ss:Vertical="Bottom"/>'                       ],

                [['align', 'vjustify'],
                  '<Alignment ss:Vertical="Justify"/>'                      ],

                [['align', 'vdistributed'],
                  '<Alignment ss:Vertical="Distributed"/>'                  ],


                # Horizontal properties
                [['align', 'left'],
                  '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom"/>'  ],

                [['align', 'left', 'indent', 1],
                  '<Alignment ss:Horizontal="Left" ss:Vertical="Bottom" ' .
                                                  'ss:Indent="1"/>'         ],

                [['align', 'center'],
                  '<Alignment ss:Horizontal="Center" ss:Vertical="Bottom"/>'],

                [['align', 'right'],
                  '<Alignment ss:Horizontal="Right" ss:Vertical="Bottom"/>' ],

                [['align', 'right', 'indent', 1],
                  '<Alignment ss:Horizontal="Right" ss:Vertical="Bottom" ' .
                                                   'ss:Indent="1"/>'        ],

                [['align', 'fill'],
                  '<Alignment ss:Horizontal="Fill" ss:Vertical="Bottom"/>'  ],

                [['align', 'justify'],
                  '<Alignment ss:Horizontal="Justify" ' .
                             'ss:Vertical="Bottom"/>'                       ],

                [['align', 'center_across'],
                  '<Alignment ss:Horizontal="CenterAcrossSelection" ' .
                             'ss:Vertical="Bottom"/>'   ],

                [['align', 'distributed', 'indent', 0],
                  '<Alignment ss:Horizontal="Distributed" ' .
                             'ss:Vertical="Bottom"/>'                       ],

                [['align', 'distributed', 'indent', 1],
                  '<Alignment ss:Horizontal="Distributed" ' .
                             'ss:Vertical="Bottom" ss:Indent="1"/>'         ],

                # TODO
                #    ss:Horizontal="JustifyDistributed" ss:Vertical="Bottom"


                # Other options
                [['text_wrap', 1],
                  '<Alignment ss:Vertical="Bottom" ss:WrapText="1"/>'       ],

                [['shrink', 1],
                  '<Alignment ss:Vertical="Bottom" ss:ShrinkToFit="1"/>'    ],

                [['reading_order', 1],
                  '<Alignment ss:Vertical="Bottom" ' .
                             'ss:ReadingOrder="LeftToRight"/>'              ],

                [['reading_order', 2],
                  '<Alignment ss:Vertical="Bottom" ' .
                             'ss:ReadingOrder="RightToLeft"/>'              ],

                [['text_vertical', 1],
                  '<Alignment ss:Vertical="Bottom" ss:VerticalText="1"/>'   ],

                [['rotation',  45],
                  '<Alignment ss:Vertical="Bottom" ss:Rotate="45"/>'        ],

                [['rotation', -45],
                  '<Alignment ss:Vertical="Bottom" ss:Rotate="-45"/>'       ],

                [['rotation',  90],
                  '<Alignment ss:Vertical="Bottom" ss:Rotate="90"/>'        ],

                [['rotation', -90],
                  '<Alignment ss:Vertical="Bottom" ss:Rotate="-90"/>'       ],

                [['rotation', 270],
                  '<Alignment ss:Vertical="Bottom" ss:VerticalText="1"/>'   ],


                # Tests for properties are mutually exclusive
                [[ 'rotation',  45, 'text_vertical', 1],
                  '<Alignment ss:Vertical="Bottom" ss:VerticalText="1"/>'   ],

                [['text_wrap', 1, 'shrink', 1],
                  '<Alignment ss:Vertical="Bottom" ss:WrapText="1"/>'       ],

                [['align', 'fill', 'shrink', 1],
                  '<Alignment ss:Horizontal="Fill" ss:Vertical="Bottom"/>'  ],

                [['align', 'justify', 'shrink', 1],
                  '<Alignment ss:Horizontal="Justify" ' .
                             'ss:Vertical="Bottom"/>'                       ],

                [['align', 'distributed', 'shrink', 1],
                  '<Alignment ss:Horizontal="Distributed" ' .
                             'ss:Vertical="Bottom"/>'                       ],
            );



my @tests2 = (  # Border properties

                [['top' => 1],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['top' => 2],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="2"/>'                                 ],

                [['top' => 3],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Dash" ' .
                          'ss:Weight="1"/>'                                 ],

                [['top' => 4],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Dot" ' .
                          'ss:Weight="1"/>'                                 ],

                [['top' => 5],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="3"/>'                                 ],

                [['top' => 6],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Double" ' .
                          'ss:Weight="3"/>'                                 ],

                [['top' => 7],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous"/>'                     ],

                [['top' => 8],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Dash" ' .
                          'ss:Weight="2"/>'                                 ],

                [['top' => 9],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="DashDot" ' .
                          'ss:Weight="1"/>'                                 ],

                [['top' => 10],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="DashDot" ' .
                          'ss:Weight="2"/>'                                 ],

                [['top' => 11],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="DashDotDot" ' .
                          'ss:Weight="1"/>'                                 ],

                [['top' => 12],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="DashDotDot" ' .
                          'ss:Weight="2"/>'                                 ],

                [['top' => 13],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="SlantDashDot" ' .
                          'ss:Weight="2"/>'                                 ],

                # Other sides
                [['bottom' => 1],
                  '<Border ss:Position="Bottom" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['left' => 1],
                  '<Border ss:Position="Left" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['right' => 1],
                  '<Border ss:Position="Right" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                # With Color
                [['top' => 1, 'border_color' => 'red'],
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FF0000"/>'                            ],

                # Diagonal borders
                [['diag_type' => 1, 'diag_border' => 1],
                  '<Border ss:Position="DiagonalLeft" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['diag_type' => 2, 'diag_border' => 1],
                  '<Border ss:Position="DiagonalRight" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['diag_type' => 1, 'diag_border' => 1, 'diag_color' =>'red'],
                  '<Border ss:Position="DiagonalLeft" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FF0000"/>'                            ],

                [['diag_type' => 2, 'diag_border' => 1, 'diag_color' =>'red'],
                  '<Border ss:Position="DiagonalRight" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FF0000"/>'                            ],

                # Diagonal borders
                [['diag_type' => 1],
                  '<Border ss:Position="DiagonalLeft" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

            );


my @tests2b = (  # Multiple border properties


                [['border' => 1],
                  '<Border ss:Position="Bottom" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>' .
                  '<Border ss:Position="Left" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>' .
                  '<Border ss:Position="Right" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>' .
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['border' => 1, 'bottom_color' => 'red',
                                 'left_color'   => 'blue',
                                 'right_color'  => 'yellow',
                                 'top_color'    => 'green',],
                  '<Border ss:Position="Bottom" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FF0000"/>' .
                  '<Border ss:Position="Left" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#0000FF"/>' .
                  '<Border ss:Position="Right" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FFFF00"/>' .
                  '<Border ss:Position="Top" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#008000"/>'                            ],

                # Diagonal borders
                [['diag_type' => 3, 'diag_border' => 1],
                  '<Border ss:Position="DiagonalLeft" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>' .
                  '<Border ss:Position="DiagonalRight" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1"/>'                                 ],

                [['diag_type' => 3, 'diag_border' => 1, 'diag_color' =>'red'],
                  '<Border ss:Position="DiagonalLeft" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FF0000"/>' .
                  '<Border ss:Position="DiagonalRight" ' .
                          'ss:LineStyle="Continuous" ' .
                          'ss:Weight="1" ' .
                          'ss:Color="#FF0000"/>'                            ],

            );


my @tests3 = (  # Font properties

                [[],
                  '<Font/>'                                                 ],

                [['color' => 'red'],
                  '<Font ss:Color="#FF0000"/>'                              ],

                [['bold'  => 1        ],
                  '<Font ss:Bold="1"/>'                                     ],

                [['bold'  => 100],
                  '<Font ss:Bold="1"/>'                                     ],

                [['italic'  => 1],
                  '<Font ss:Italic="1"/>'                                   ],

                [['underline'  => 1],
                  '<Font ss:Underline="Single"/>'                           ],

                [['underline'  => 2],
                  '<Font ss:Underline="Double"/>'                           ],

                [['underline'  => 33],
                  '<Font ss:Underline="SingleAccounting"/>'                 ],

                [['font_strikeout'  => 1],
                  '<Font ss:StrikeThrough="1"/>'                            ],

                [['font_script'  => 1],
                  '<Font ss:VerticalAlign="Superscript"/>'                  ],

                [['font_script'  => 2],
                  '<Font ss:VerticalAlign="Subscript"/>'                    ],

                [['font_outline'  => 1],
                  '<Font ss:Outline="1"/>'                                  ],

                [['font_shadow'  => 1],
                  '<Font ss:Shadow="1"/>'                                   ],

                [['font_family'  => 'Swiss'],
                  '<Font x:Family="Swiss"/>'                                ],

                [['font_charset'  => 'Test'],
                  '<Font x:CharSet="Test"/>'                                ],

                [['font'  => 'Arial Black'],
                  '<Font ss:FontName="Arial Black"/>'                       ],

                [['size' => 12],
                  '<Font ss:Size="12"/>'                                    ],

                [['font'  => 'Arial Black', 'size' => 12],
                  '<Font ss:FontName="Arial Black" ss:Size="12"/>'          ],

                [['font'  => 'Arial Black', 'size' => 12],
                  '<Font ss:FontName="Arial Black" ss:Size="12"/>'          ],

            );


my @tests4 = (  # Interiors properties

                [[],
                  '<Interior/>'                                             ],

                # No pattern. Foreground color only
                [['fg_color' => 'red'],
                  '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'       ],

                # No pattern. Background color only
                [['bg_color' => 'red'],
                  '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'       ],

                # No pattern. bg color takes precedence over fg color
                [['bg_color' => 'red', 'fg_color' => 'green',],
                  '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'       ],

                # Solid pattern only
                [['pattern' => 1],
                  '<Interior/>'                                             ],

                # Non-solid pattern only
                [['pattern' => 2],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="Gray50" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                # Solid pattern. Background color only
                [['bg_color' => 'red', 'pattern' => 1],
                  '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'       ],

                # Solid pattern. Foreground color only
                [['fg_color' => 'red', 'pattern' => 1],
                  '<Interior ss:Color="#FF0000" ss:Pattern="Solid"/>'       ],

                # Explicit example
                [['bg_color' => 'yellow',
                  'fg_color' => 'red',
                  'pattern'  => 15],
                  '<Interior ss:Color="#FFFF00" '.
                            'ss:Pattern="ThinHorzCross" ' .
                            'ss:PatternColor="#FF0000"/>'                   ],


                # All non-solid patterns
                [['pattern' => 2],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="Gray50" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 3],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="Gray75" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 4],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="Gray25" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 5],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="HorzStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 6],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="VertStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 7],
                  '<Interior ss:Color="#FFFFFF" '.
                            'ss:Pattern="ReverseDiagStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 8],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="DiagStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 9],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="DiagCross" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 10],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="ThickDiagCross" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 11],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="ThinHorzStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 12],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="ThinVertStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 13],
                  '<Interior ss:Color="#FFFFFF" ' .
                            'ss:Pattern="ThinReverseDiagStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 14],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="ThinDiagStripe" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 15],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="ThinHorzCross" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 16],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="ThinDiagCross" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 17],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="Gray125" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                [['pattern' => 18],
                  '<Interior ss:Color="#FFFFFF" ss:Pattern="Gray0625" ' .
                            'ss:PatternColor="#000000"/>'                   ],

                # Out of range
                [['pattern' => 19],
                  '<Interior/>'                                             ],

            );


my @tests5 = (  # Number formats

                [[],
                  '<NumberFormat/>'                                         ],

                [['num_format' => 1],
                  '<NumberFormat ss:Format="0"/>'                           ],

                [['num_format' => 2],
                  '<NumberFormat ss:Format="Fixed"/>'                       ],

                [['num_format' => 3],
                  '<NumberFormat ss:Format="#,##0"/>'                       ],

                [['num_format' => 4],
                  '<NumberFormat ss:Format="Standard"/>'                    ],

                [['num_format' => 5],
                  '<NumberFormat ss:Format="$#,##0;\-$#,##0"/>'             ],

                [['num_format' => 6],
                  '<NumberFormat ss:Format="$#,##0;[Red]\-$#,##0"/>'        ],

                [['num_format' => 7],
                  '<NumberFormat ss:Format="$#,##0.00;\-$#,##0.00"/>'       ],

                [['num_format' => 8],
                  '<NumberFormat ss:Format="Currency"/>'                    ],

                [['num_format' => 9],
                  '<NumberFormat ss:Format="0%"/>'                          ],

                [['num_format' => 10],
                  '<NumberFormat ss:Format="Percent"/>'                     ],

                [['num_format' => 11],
                  '<NumberFormat ss:Format="Scientific"/>'                  ],

                [['num_format' => 12],
                  '<NumberFormat ss:Format="#\ ?/?"/>'                      ],

                [['num_format' => 13],
                  '<NumberFormat ss:Format="#\ ??/??"/>'                    ],

                [['num_format' => 14],
                  '<NumberFormat ss:Format="Short Date"/>'                  ],

                [['num_format' => 15],
                  '<NumberFormat ss:Format="Medium Date"/>'                 ],

                [['num_format' => 16],
                  '<NumberFormat ss:Format="dd\-mmm"/>'                     ],

                [['num_format' => 17],
                  '<NumberFormat ss:Format="mmm\-yy"/>'                     ],

                [['num_format' => 18],
                  '<NumberFormat ss:Format="Medium Time"/>'                 ],

                [['num_format' => 19],
                  '<NumberFormat ss:Format="Long Time"/>'                   ],

                [['num_format' => 20],
                  '<NumberFormat ss:Format="Short Time"/>'                  ],

                [['num_format' => 21],
                  '<NumberFormat ss:Format="hh:mm:ss"/>'                    ],

                [['num_format' => 22],
                  '<NumberFormat ss:Format="General Date"/>'                ],

                # Omitted internal international formats 23 .. 36

                [['num_format' => 37],
                  '<NumberFormat ss:Format="#,##0;\-#,##0"/>'               ],

                [['num_format' => 38],
                  '<NumberFormat ss:Format="#,##0;[Red]\-#,##0"/>'          ],

                [['num_format' => 39],
                  '<NumberFormat ss:Format="#,##0.00;\-#,##0.00"/>'         ],

                [['num_format' => 40],
                  '<NumberFormat ss:Format="#,##0.00;[Red]\-#,##0.00"/>'    ],

                [['num_format' => 41],
                  '<NumberFormat ss:Format="_-* #,##0_-;\-* #,##0_-;_-* ' .
                                           '&quot;-&quot;_-;_-@_-"/>'       ],

                [['num_format' => 42],
                  '<NumberFormat ss:Format="_-$* #,##0_-;\-$* #,##0_-;_-$* ' .
                                           '&quot;-&quot;_-;_-@_-"/>'       ],

                [['num_format' => 43],
                  '<NumberFormat ss:Format="_-* #,##0.00_-;\-* #,##0.00_-;_' .
                                           '-* &quot;-&quot;??_-;_-@_-"/>'  ],

                [['num_format' => 44],
                  '<NumberFormat ss:Format="_-$* #,##0.00_-;\-$* #,##0.00_-;'.
                                           '_-$* &quot;-&quot;??_-;_-@_-"/>'],

                [['num_format' => 45],
                  '<NumberFormat ss:Format="mm:ss"/>'                       ],

                [['num_format' => 46],
                  '<NumberFormat ss:Format="[h]:mm:ss"/>'                   ],

                [['num_format' => 47],
                  '<NumberFormat ss:Format="mm:ss.0"/>'                     ],

                [['num_format' => 48],
                  '<NumberFormat ss:Format="##0.0E+0"/>'                    ],

                [['num_format' => 49],
                  '<NumberFormat ss:Format="@"/>'                           ],


                # Use named explicit formats
                [['num_format' => 'General'],
                  '<NumberFormat ss:Format="General"/>'                     ],

                [['num_format' => 'General Number'],
                  '<NumberFormat ss:Format="General Number"/>'              ],

                [['num_format' => 'General Date'],
                  '<NumberFormat ss:Format="General Date"/>'                ],

                [['num_format' => 'Long Date'],
                  '<NumberFormat ss:Format="Long Date"/>'                   ],

                [['num_format' => 'Medium Date'],
                  '<NumberFormat ss:Format="Medium Date"/>'                 ],

                [['num_format' => 'Short Date'],
                  '<NumberFormat ss:Format="Short Date"/>'                  ],

                [['num_format' => 'Long Time'],
                  '<NumberFormat ss:Format="Long Time"/>'                   ],

                [['num_format' => 'Medium Time'],
                  '<NumberFormat ss:Format="Medium Time"/>'                 ],

                [['num_format' => 'Short Time'],
                  '<NumberFormat ss:Format="Short Time"/>'                  ],

                [['num_format' => 'Currency'],
                  '<NumberFormat ss:Format="Currency"/>'                    ],

                [['num_format' => 'Euro Currency'],
                  '<NumberFormat ss:Format="Euro Currency"/>'               ],

                [['num_format' => 'Fixed'],
                  '<NumberFormat ss:Format="Fixed"/>'                       ],

                [['num_format' => 'Standard'],
                  '<NumberFormat ss:Format="Standard"/>'                    ],

                [['num_format' => 'Percent'],
                  '<NumberFormat ss:Format="Percent"/>'                     ],

                [['num_format' => 'Scientific'],
                  '<NumberFormat ss:Format="Scientific"/>'                  ],

                [['num_format' => 'Yes/No'],
                  '<NumberFormat ss:Format="Yes/No"/>'                      ],

                [['num_format' => 'True/False'],
                  '<NumberFormat ss:Format="True/False"/>'                  ],

                [['num_format' => 'On/Off'],
                  '<NumberFormat ss:Format="On/Off"/>'                      ],

                # Use other explicit formats
                [['num_format' => 'mm:ss'],
                  '<NumberFormat ss:Format="mm:ss"/>'                       ],

                [['num_format' => '@'],
                  '<NumberFormat ss:Format="@"/>'                           ],

            );



my @tests6 = (  # Protection formats
                [[],
                  '<Protection/>'                                           ],

                [['hidden' => 1],
                  '<Protection x:HideFormula="1"/>'                         ],

                [['locked' => 0],
                  '<Protection ss:Protected="0"/>'                          ],

                [['hidden' => 1, 'locked' => 0],
                  '<Protection x:HideFormula="1" ss:Protected="0"/>'        ],

            );




my @tests7 = (  # Font color conversion test

                [ ["color" => "red"     ],  "ss:Color #FF0000"              ],
                [ ["color" => "purple"  ],  "ss:Color #800080"              ],
                [ ["color" => "lime"    ],  "ss:Color #00FF00"              ],
                [ ["color" => "blue"    ],  "ss:Color #0000FF"              ],
                [ ["color" => "yellow"  ],  "ss:Color #FFFF00"              ],
                [ ["color" => "silver"  ],  "ss:Color #C0C0C0"              ],
                [ ["color" => "magenta" ],  "ss:Color #FF00FF"              ],
                [ ["color" => "gray"    ],  "ss:Color #808080"              ],
                [ ["color" => "cyan"    ],  "ss:Color #00FFFF"              ],
                [ ["color" => "brown"   ],  "ss:Color #800000"              ],
                [ ["color" => "orange"  ],  "ss:Color #FF6600"              ],
                [ ["color" => "black"   ],  "ss:Color #000000"              ],
                [ ["color" => "green"   ],  "ss:Color #008000"              ],
                [ ["color" => "white"   ],  "ss:Color #FFFFFF"              ],
                [ ["color" => "navy"    ],  "ss:Color #000080"              ],


                [ ["color" => 10        ],  "ss:Color #FF0000"              ],
                [ ["color" => 20        ],  "ss:Color #800080"              ],
                [ ["color" => 11        ],  "ss:Color #00FF00"              ],
                [ ["color" => 12        ],  "ss:Color #0000FF"              ],
                [ ["color" => 13        ],  "ss:Color #FFFF00"              ],
                [ ["color" => 22        ],  "ss:Color #C0C0C0"              ],
                [ ["color" => 14        ],  "ss:Color #FF00FF"              ],
                [ ["color" => 23        ],  "ss:Color #808080"              ],
                [ ["color" => 15        ],  "ss:Color #00FFFF"              ],
                [ ["color" => 16        ],  "ss:Color #800000"              ],
                [ ["color" => 53        ],  "ss:Color #FF6600"              ],
                [ ["color" => 8         ],  "ss:Color #000000"              ],
                [ ["color" => 17        ],  "ss:Color #008000"              ],
                [ ["color" => 9         ],  "ss:Color #FFFFFF"              ],
                [ ["color" => 18        ],  "ss:Color #000080"              ],

             );

my $test_file = "temp_test_file.xml";
my $workbook  = Spreadsheet::WriteExcelXML->new($test_file);
   $workbook->{_filehandle} = undef; # Turn default print off during testing.

my $worksheet = $workbook->add_worksheet();

$workbook->close();
unlink $test_file;



###############################################################################
#
# 1. Run the tests for cell font properties.
#
for my $test_ref (@tests1) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my @attribs = $format->get_align_properties();

    is($workbook->_write_xml_element(0, 0, 0, 'Alignment', @attribs),
       $result, "Testing alignment:\t" . join " ", @test_data );
}


###############################################################################
#
# 2. Run the tests for cell border properties.
#
for my $test_ref (@tests2) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my ($aref)  = $format->get_border_properties();
    my @attribs = @$aref;

    is($workbook->_write_xml_element(0, 0, 0, 'Border', @attribs),
       $result, "Testing borders:\t" . join " ", @test_data );
}


###############################################################################
#
# 2b. Run the tests for multiple cell border properties.
#
for my $test_ref (@tests2b) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my $str  = '';
       $str .= $workbook->_write_xml_element(0, 0, 0, 'Border', @$_)
               for $format->get_border_properties();

    is($str, $result, "Testing borders:\t" . join " ", @test_data );
}


###############################################################################
#
# 3. Run the tests for cell font properties.
#
for my $test_ref (@tests3) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my @attribs = $format->get_font_properties();

    is($workbook->_write_xml_element(0, 0, 0, 'Font', @attribs),
       $result, "Testing fonts:\t" . join " ", @test_data );
}


###############################################################################
#
# 4. Run the tests for cell interior/pattern properties.
#
for my $test_ref (@tests4) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my @attribs = $format->get_interior_properties();

    is($workbook->_write_xml_element(0, 0, 0, 'Interior', @attribs),
       $result, "Testing interior:\t" . join " ", @test_data );
}


###############################################################################
#
# 5. Run the tests for cell font properties.
#
for my $test_ref (@tests5) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my @attribs = $format->get_num_format_properties();

    is($workbook->_write_xml_element(0, 0, 0, 'NumberFormat', @attribs),
       $result, "Testing interior:\t" . join " ", @test_data );
}


###############################################################################
#
# 6. Run the tests for cell protection properties.
#
for my $test_ref (@tests6) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    my @attribs = $format->get_protection_properties();

    is($workbook->_write_xml_element(0, 0, 0, 'Protection', @attribs),
       $result, "Testing interior:\t" . join " ", @test_data );
}


###############################################################################
#
# 7. Run the tests for colour conversions.
#
for my $test_ref (@tests7) {

    my $format = $workbook->add_format();


    my @test_data = @{$test_ref->[0]};
    my $result    =   $test_ref->[1];

    $format->set_properties(@test_data);

    is(join(" ", $format->get_font_properties()), $result,
       "Testing colors:\t" . join " ", @test_data );
}



__END__



