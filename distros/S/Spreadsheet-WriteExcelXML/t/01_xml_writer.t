#!/usr/bin/perl -wl

###############################################################################
#
# A test for Spreadsheet::WriteExcelXML.
#
# Tests XML generation functions in the Spreadsheet::WriteExcelXML::XMLwriter
# module.
#
# reverse('©'), May 2004, John McNamara, jmcnamara@cpan.org
#


use strict;

use Spreadsheet::WriteExcelXML::XMLwriter;
use Test::More tests => 52;




my @tests1 = (  # Simple formatting tests

                # Tests for default indentation
                [ 0, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 1, 0, 0, 'Workbook' => "    <Workbook>"                   ],
                [ 2, 0, 0, 'Workbook' => "        <Workbook>"               ],

                # Tests for number of newlines
                [ 0, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 0, 1, 0, 'Workbook' => "<Workbook>\n"                     ],
                [ 0, 2, 0, 'Workbook' => "<Workbook>\n\n"                   ],
                [ 0, 3, 0, 'Workbook' => "<Workbook>\n\n\n"                 ],

                # Tests for list options
                [ 0, 0, 0, 'Release', 'version', '1.0',
                           "<Release version=\"1.0\">"                      ],
                [ 0, 0, 1, 'Release', 'version', '1.0',
                           "<Release version=\"1.0\">"                      ],
                [ 0, 0, 2, 'Release', 'version', '1.0',
                           "<Release\n    version=\"1.0\">"                 ],
                [ 0, 0, 0, 'Release', 'Major', '1.0', 'Minor', '1.0',
                           "<Release Major=\"1.0\" Minor=\"1.0\">"          ],
                [ 0, 0, 1, 'Release', 'Major', '1.0', 'Minor', '1.0',
                           "<Release\n    Major=\"1.0\"\n    Minor=\"1.0\">"],
                [ 0, 0, 2, 'Release', 'Major', '1.0', 'Minor', '1.0',
                           "<Release\n    Major=\"1.0\"\n    Minor=\"1.0\">"],

             );


my @tests2 = (
                # Tests for entity encoding. Apostrophe isn't encoded.
                [ ' & '     => " &amp; "                                    ],
                [ ' < '     => " &lt; "                                     ],
                [ ' > '     => " &gt; "                                     ],
                [ " ' "     => " ' "                                        ],
                [ ' " '     => " &quot; "                                   ],
                [ '<&"\'>'  => "&lt;&amp;&quot;'&gt;"                       ],
                [ '<test>'  => "&lt;test&gt;"                               ],
                [ "\n\n\n"  => "&#10;&#10;&#10;"                            ],


            );


my @tests3 = (
                # Tests for entities
                [ 0, 0, 0, 'xml',                '<?xml?>'                  ],
                [ 0, 0, 0, 'xml', 'vers', '1.0', '<?xml vers="1.0"?>'       ],
                [ 0, 0, 1, 'xml', 'vers', '1.0', '<?xml vers="1.0"?>'       ],
                [ 0, 0, 2, 'xml', 'vers', '1.0', "<?xml\n    vers=\"1.0\"?>"],

            );


my @tests4 = (
                # Tests for element closing
                [ 0, 0, 0, 'Workbook' => "</Workbook>"                      ],
                [ 1, 0, 0, 'Workbook' => "    </Workbook>"                  ],
                [ 0, 1, 0, 'Workbook' => "</Workbook>\n"                    ],

            );


my @tests5 = (
                # Tests for open and closed elements
                [ 0, 0, 0, 'Alignment' => "<Alignment/>"                    ],
                [ 1, 0, 0, 'Alignment' => "    <Alignment/>"                ],
                [ 0, 1, 0, 'Alignment' => "<Alignment/>\n"                  ],

            );


my @tests6 = (
                # Tests for XML values
                [ 'Hello'     => "Hello"                                    ],
                [ '"Hello"'   => "&quot;Hello&quot;"                        ],

            );

my @tests7 = (
                # Tests for un-encoded XML values
                [ 'Hello'     => "Hello"                                    ],
                [ '"Hello"'   => '"Hello"'                                  ],
                [ '<&"\'>'    => '<&"\'>'                                   ],

            );


my @tests8 = (
                # Tests for alternative indentation
                [ 0, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 1, 0, 0, 'Workbook' => "\t<Workbook>"                     ],
                [ 2, 0, 0, 'Workbook' => "\t\t<Workbook>"                   ],
                [ 0, 0, 2, 'Release', 'version', '1.0',
                           "<Release\n\tversion=\"1.0\">"                   ],
            );

my @tests9 = (
                # Tests for alternative indentation
                [ 0, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 1, 0, 0, 'Workbook' => " <Workbook>"                      ],
                [ 2, 0, 0, 'Workbook' => "  <Workbook>"                     ],
                [ 0, 0, 2, 'Release', 'version', '1.0',
                           "<Release\n version=\"1.0\">"                    ],
            );


my @tests10 = (
                # Tests for alternative indentation
                [ 0, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 1, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 2, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 0, 0, 2, 'Release', 'version', '1.0',
                           "<Release version=\"1.0\">"                     ],
            );


my @tests11 = (
                # Tests for alternative indentation
                [ 0, 0, 0, 'Workbook' => "<Workbook>"                       ],
                [ 1, 0, 0, 'Workbook' => "    <Workbook>"                   ],
                [ 2, 0, 0, 'Workbook' => "        <Workbook>"               ],
                [ 0, 0, 2, 'Release', 'version', '1.0',
                           "<Release\n    version=\"1.0\">"                 ],
            );




my $writer = Spreadsheet::WriteExcelXML::XMLwriter->new();


###############################################################################
#
# 1. Run the tests for formatting.
#
for my $test_ref (@tests1) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_write_xml_start_tag(@test_data), $result,
       "Testing formatting:\t" . join " ", encode_escapes(@$test_ref));
}


###############################################################################
#
# 2. Run the tests for  entity encoding.
#
for my $test_ref (@tests2) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_encode_xml_escapes(@test_data), $result,
       "Testing encoding:\t" . join "\t", encode_escapes(@$test_ref));
}


###############################################################################
#
# 3. Run the tests for entity.
#
for my $test_ref (@tests3) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_write_xml_directive(@test_data), $result,
       "Testing XML entities:\t" . join " ", encode_escapes(@$test_ref));
}


###############################################################################
#
# 4. Run the tests for element closing.
#
for my $test_ref (@tests4) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_write_xml_end_tag(@test_data), $result,
       "Testing closing:\t" . join " ", encode_escapes(@$test_ref));
}


###############################################################################
#
# 5. Run the tests for single element.
#
for my $test_ref (@tests5) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_write_xml_element(@test_data), $result,
       "Testing single elems:\t" . join " ", encode_escapes(@$test_ref));
}

###############################################################################
#
# 6. Run the tests for XML quoting.
#
for my $test_ref (@tests6) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_write_xml_content(@test_data), $result,
       "Testing quoting:\t" . join "\t", encode_escapes(@$test_ref));
}

###############################################################################
#
# 7. Run the  tests for un-encoded XML value.
#
for my $test_ref (@tests7) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    is($writer->_write_xml_unencoded_content(@test_data), $result,
       "Testing un-encoded:\t" . join "\t", encode_escapes(@$test_ref));
}


###############################################################################
#
# 8. Run tests for alternative indentation (1).
#
for my $test_ref (@tests8) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    $writer->set_indentation("\t");

    is($writer->_write_xml_start_tag(@test_data), $result,
       "Testing indent:\t" . join " ", encode_escapes(@$test_ref));
}


###############################################################################
#
# 9. Run tests for alternative indentation (2).
#
for my $test_ref (@tests9) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    $writer->set_indentation(" ");

    is($writer->_write_xml_start_tag(@test_data), $result,
       "Testing indent:\t" . join " ", encode_escapes(@$test_ref));
}


###############################################################################
#
# 10. Run tests for alternative indentation (3).
#
for my $test_ref (@tests10) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    $writer->set_indentation("");

    is($writer->_write_xml_start_tag(@test_data), $result,
       "Testing indent:\t" . join " ", encode_escapes(@$test_ref));
}


###############################################################################
#
# 11. Run tests for indentation reset.
#
for my $test_ref (@tests11) {

    my @test_data = @$test_ref;
    my $result    = pop @test_data;

    $writer->set_indentation(); # Reset indentation to default

    is($writer->_write_xml_start_tag(@test_data), $result,
       "Testing indent:\t" . join " ", encode_escapes(@$test_ref));
}



###############################################################################
#
# Encode escapes to make them visible in the test output.
#
sub encode_escapes {
    my @data = @_;

    for (@data) {
        s/\t/\\t/g;
        s/\n/\\n/g;
        s/ /./g;
    }

    return @data;
}


__END__



