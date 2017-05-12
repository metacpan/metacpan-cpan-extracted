# vim: ts=8 sw=8 tw=0 ai nu noet
#
# (C) Daniel Kasak: dan@entropy.homelinux.org ...
#  ... with contributions from Bill Hess and Cosimo Streppone
#      ( see the changelog for details )
#
# See COPYRIGHT file for full license
#
# See 'man PDF::ReportWriter' for full documentation

use strict;

no warnings;

package PDF::ReportWriter;

use PDF::API2;
use Image::Size;

use Carp;

use constant mm         => 72/25.4;             # 25.4 mm in an inch, 72 points in an inch
use constant in         => 72;                  # 72 points in an inch

use constant A4_x       => 210 * mm;            # x points in an A4 page ( 595.2755 )
use constant A4_y       => 297 * mm;            # y points in an A4 page ( 841.8897 )

use constant letter_x   => 8.5 * in;            # x points in a letter page
use constant letter_y   => 11 * in;             # y points in a letter page

use constant bsize_x    => 11 * in;             # x points in a B size page
use constant bsize_y    => 17 * in;             # y points in a B size page

use constant legal_x    => 11 * in;             # x points in a legal page
use constant legal_y    => 14 * in;             # y points in a legal page

use constant TRUE       => 1;
use constant FALSE      => 0;

BEGIN {
    $PDF::ReportWriter::VERSION = '1.5';
}

sub new {
    
    my ( $class, $options ) = @_;
    
    # Create new object
    my $self = {};
    bless $self, $class;
    
    # Initialize object state
    $self->parse_options($options);
    
    return $self;
}

#
# render_report( $xml, $data_arrayref )
#
# $xml can be either an xml file or any kind of object that
# supports `load()' and `get_data()'
#
# Take report definition, add report data and
# shake well. Your report is ready.
#
sub render_report
{
    
    # Use P::R::Report to handle xml report loading
    require PDF::ReportWriter::Report;
    
    my ( $self, $xml, $data_records ) = @_;
    my $report;
    my $config;
    my $data;
    
    # First parameter can be a report xml filename
    # or PDF::ReportWriter::Report object. Check and load the report profile
    if( ! $xml ) {
        die "Specify an xml report file or PDF::ReportWriter::Report object!";
    }
    
    # $xml is a filename?
    if ( ! ref $xml ) {
        
        # Try loading the report definition file
        unless( $report = PDF::ReportWriter::Report->new({ report => $xml }) ) {
            # Can't load xml report file
            die qq(Can't load xml report file $xml);
         }
    
    # $xml is a PDF::ReportWriter::Report or something that can `load()'?
    } elsif( $xml->can('load') ) {
        
         $report = $xml;
    }
    
    # Try loading the XML report profile and see if something breaks
    eval {
        $config = $report->load();
        #use Data::Dumper;
        #print Dumper($config);
    };
    
    # Report error to user
    if( $@ )
    {
        die qq(Can't load xml report profile from $xml object: $@);
    }

    # Ok, profile "definition" data structure is our hash
    # of main report options
    $self->parse_options( $config->{definition} );
    
    # Profile "data" structure is our hash to be passed
    # render_data() function.
    $data = $config->{data};
    
    # Store report object for later use (resave to xml)
    $self->{__report} = $report;
    
    # If we already have report data, we are done
    if( ! defined $data_records ) {
        
        # Report object's `get_data()' method can be used to populate report data
        # with name of data source to use
        if( $report->can('get_data') ) {
            # XXX Change `detail' in `report', or `main' ??
            $data_records = $report->get_data('detail');
        }
    }
    
    # "data" hash structure must be filled with real records
    $data->{data_array} = $data_records;
    
    # Store "data" section for later use (save to xml)
    $self->{data} =                            # XXX Remove?
    $self->{__report}->{data} = $data;
    
    # Fire!
    $self->render_data( $data) ;
    
}

#
# Returns the current page object (PDF::API2::Page) we are working on
#
sub current_page
{
    my $self = $_[0];
    my $page_list = $self->{pages};

    if( ref $page_list eq 'ARRAY' && scalar @$page_list )
    {
        return $page_list->[ $#$page_list ];
    }
    else
    {
        return undef;
    }
}

sub report
{
    my $self = $_[0];
    return $self->{__report};
}

sub parse_options
{
    
    my ( $self, $opt ) = @_;
    
    # Create a new PDF document if needed
    $self->{pdf} ||= PDF::API2->new;
    
    if ( ! defined $opt )
    {
        return( $self );
    }
    
    # Check for old margin settings and translate to new ones
    if ( exists $opt->{y_margin} ) {
        $opt->{upper_margin} = $opt->{y_margin};
        $opt->{lower_margin} = $opt->{y_margin};
        delete $opt->{y_margin};
    }
    
    if ( exists $opt->{x_margin} ) {
        $opt->{left_margin} = $opt->{x_margin};
        $opt->{right_margin} = $opt->{x_margin};
        delete $opt->{x_margin};
    }
    
    # Store options in the __report member that we will use
    # to export to XML format
    $self->{__report}->{definition} = $opt;
    
    # XXX
    # Store some option keys into main object
    # Now this is necessary for all code to work correctly
    #
    for ( qw( destination upper_margin lower_margin left_margin right_margin debug template ) ) {
        $self->{$_} = $opt->{$_}
    }

    if ( $opt->{paper} eq "A4" ) {
        
        $self->{page_width} = A4_x;
        $self->{page_height} = A4_y;
        
    } elsif ( $opt->{paper} eq "Letter" || $opt->{paper} eq "letter" ) {
        
        $self->{page_width} = letter_x;
        $self->{page_height} = letter_y;
        
    } elsif ( $opt->{paper} eq "bsize" || $opt->{paper} eq "Bsize" ) {
        
        $self->{page_width} = bsize_x;
        $self->{page_height} = bsize_y;
        
    } elsif ( $opt->{paper} eq "Legal" || $opt->{paper} eq "legal" ) {
        
        $self->{page_width} = legal_x;
        $self->{page_height} = legal_y;
        
    # Parse user defined format `150 x 120 mm', or `29.7 x 21.0 cm', or `500X300'
    # Default unit is `mm' unless specified. Accepted units: `mm', `in'
    } elsif ( $opt->{paper} =~ /^\s*([\d\.]+)\s*[xX]\s*([\d\.]+)\s*(\w*)$/ ) {
        
        my $unit = lc($3) || 'mm';
        $self->{page_width}  = $1;
        $self->{page_height} = $2;
        
        if ( $unit eq 'mm' ) {
            $self->{page_width}  *= &mm;
            $self->{page_height} *= &mm;
        } elsif( $unit eq 'in' ) {
            $self->{page_width}  *= &in;
            $self->{page_height} *= &in;
        } else {
            die 'Unsupported measure unit: ' . $unit . "\n";
        }
        
    } else {
        die "Unsupported paper format: " . $opt->{paper} . "\n";
    }
    
    # Swap width/height in case of landscape orientation
    if( exists $opt->{orientation} && $opt->{orientation} ) {
        
        if( $opt->{orientation} eq 'landscape' ) {
            ($self->{page_width},  $self->{page_height}) =
            ($self->{page_height}, $self->{page_width});
        } elsif( $opt->{orientation} ne 'portrait' ) {
            die 'Unsupported orientation: ' . $opt->{orientation} . "\n"; 
        }
    }
    
    #
    # Now initialize object
    #
    
    # Set some info stuff
    my $localtime = localtime time;
    
    $self->{pdf}->info(
                        Author          => $opt->{info}->{Author},
                        CreationDate    => $localtime,
                        # Should we allow a different creator?
                        Creator         => $opt->{info}->{Creator} || "PDF::ReportWriter $PDF::ReportWriter::VERSION",
                        Keywords        => $opt->{info}->{Keywords},
                        ModDate         => $localtime,
                        Subject         => $opt->{info}->{Subject},
                        Title           => $opt->{info}->{Title}
                      );
    
    # Add requested fonts
    $opt->{font_list} ||= $opt->{font} || [ 'Helvetica' ];
    
    for my $font ( @{$opt->{font_list}} ) {
        
        # Roman fonts are easy
        $self->{fonts}->{$font}->{Roman} = $self->{pdf}->corefont(          $font,                  -encoding => 'latin1');
        # The rest are f'n ridiculous. Adobe either didn't think about this, or are just stoopid
        if ($font eq 'Courier') {
            $self->{fonts}->{$font}->{Bold} = $self->{pdf}->corefont(       "Courier-Bold",         -encoding => 'latin1');
            $self->{fonts}->{$font}->{Italic} = $self->{pdf}->corefont(     "Courier-Oblique",      -encoding => 'latin1');
            $self->{fonts}->{$font}->{BoldItalic} = $self->{pdf}->corefont( "Courier-BoldOblique",  -encoding => 'latin1');
        }
        if ($font eq 'Helvetica') {
            $self->{fonts}->{$font}->{Bold} = $self->{pdf}->corefont(       "Helvetica-Bold",       -encoding => 'latin1');
            $self->{fonts}->{$font}->{Italic} = $self->{pdf}->corefont(     "Helvetica-Oblique",    -encoding => 'latin1');
            $self->{fonts}->{$font}->{BoldItalic} = $self->{pdf}->corefont( "Helvetica-BoldOblique",-encoding => 'latin1');
        }
        if ($font eq 'Times') {
            $self->{fonts}->{$font}->{Bold} = $self->{pdf}->corefont(       "Times-Bold",           -encoding => 'latin1');
            $self->{fonts}->{$font}->{Italic} = $self->{pdf}->corefont(     "Times-Italic",         -encoding => 'latin1');
            $self->{fonts}->{$font}->{BoldItalic} = $self->{pdf}->corefont( "Times-BoldItalic",     -encoding => 'latin1');
        }
    }
    
    # Default report font size to 12 in case a default hasn't been supplied
    $self->{default_font_size} = $opt->{default_font_size} || 12;
    $self->{default_font}      = $opt->{default_font}      || 'Helvetica';
    
    # Mark date/time of document generation
    $self->{__generationtime} = $localtime;
    
    return( $self );
    
}

sub setup_cell_definitions {
    
    my ( $self, $cell_array, $type, $group, $group_type ) = @_;
    
    my $x = $self->{left_margin};
    my $row = 0;
    my $cell_counter = 0;
    
    for my $cell ( @{$cell_array} ) {
        
        # Support multi-line row definitions
        if ( $x >= $self->{page_width} - $self->{right_margin} ) {
            $row ++;
            $x = $self->{left_margin};
        }
        
        $cell->{row} = $row;
        
        # The cell's left-hand border position
        $cell->{x_border} = $x;
        
        # The cell's font size - user defined by cell, or from the report default
        if ( ! $cell->{font_size} ) {
            $cell->{font_size} = $self->{default_font_size};
        }
        
        # The cell's text whitespace ( the minimum distance between the cell border and cell text )
        # Default to half the font size if not given
        if ( ! exists $cell->{text_whitespace} ) {
            $cell->{text_whitespace} = $cell->{font_size} >> 1;
        }
        
        # Calculate cell height depending on type, etc...
        $cell->{height} = $self->calculate_cell_height( $cell );
        
        # The cell's left-hand text position
        $cell->{x_text} = $x + $cell->{text_whitespace};
        
        # The cell's full width ( border to border )
        $cell->{full_width} = ( $self->{page_width} - ( $self->{left_margin} + $self->{right_margin} ) ) * $cell->{percent} / 100;
        
        # The cell's maximum width of text
        $cell->{text_width} = $cell->{full_width} - ( $cell->{text_whitespace} * 2 );
        
        # We also need to set the data-level or header/footer-level max_cell_height
        # This refers to the height of the actual cell ...
        #  ... ie ie it doesn't include upper_buffer and lower_buffer whitespace
        if ( $type eq "data" ) {
            if ( $cell->{height} > $self->{data}->{max_cell_height} ) {
                $self->{data}->{max_cell_height} = $cell->{height};
            }
            # Default to the data-level background if there is none defined for this cell
            # We don't do this for page headers / footers, because I don't think this
            # is appropriate default behaviour for these ( ie usually doesn't look good )
            if ( ! $cell->{background} ) {
                $cell->{background} = $self->{data}->{background};
            }
            # Populate the cell_mapping hash so we can easily get hold of fields via their name
            $self->{data}->{cell_mapping}->{ $cell->{name} } = $cell_counter;
        } elsif ( $type eq "field_headers" ) {
            if ( $cell->{height} > $self->{data}->{max_field_header_height} ) {
                $self->{data}->{max_field_header_height} = $cell->{height};
            }
            if ( ! $cell->{background} ) {
                $cell->{background} = $self->{data}->{headings}->{background};
            }
            $cell->{wrap_text} = TRUE;
        } elsif ( $type eq "page_header" ) {
            if ( $cell->{height} > $self->{data}->{page_header_max_cell_height} ) {
                $self->{data}->{page_header_max_cell_height} = $cell->{height};
            }
        } elsif ( $type eq "page_footer" ) {
            if ( $cell->{height} > $self->{data}->{page_footer_max_cell_height} ) {
                $self->{data}->{page_footer_max_cell_height} = $cell->{height};
            }
        } elsif ( $type eq "group" ) {
            
            if ( $cell->{height} > $group->{$group_type . "_max_cell_height"} ) {
                $group->{$group_type . "_max_cell_height"} = $cell->{height};
            }
            
            # For aggregate functions, we need the name of the group, which is used later
            # to retrieve the aggregate values ( which are stored against the group,
            # hence the need for the group name ). However when rendering a row,
            # we don't have access to the group *name*, so storing it in the 'text'
            # key is a nice way around this
            if ( exists $cell->{aggregate_source} ) {
                $cell->{text} = $group->{name};
            }
            
            # Initialise group aggregate results
            $cell->{group_results}->{$group->{name}} = 0;
            $cell->{grand_aggregate_result}->{$group->{name}} = 0;
            
        }
        
        # Set 'bold' key for legacy behaviour anything other than data cells and images
        if ( $type ne "data" && ! $cell->{image} && ! exists $cell->{bold} ) {
            $cell->{bold} = TRUE;
        }
        
        if ( $cell->{image} ) {
            
            # Default to a buffer of 1 to surround images,
            # otherwise they overlap cell borders
            if ( ! exists $cell->{image}->{buffer} ) {
                $cell->{image}->{buffer} = 1;
            }
            
            # Initialise the tmp hash that we store temporary image dimensions in later
            $cell->{image}->{tmp} = {};
            
        }
        
        # Convert old 'type' key to the new 'format' key
        # But *don't* do anything with types not listed here. Cosimo is using
        # this key for barcode stuff, and this is handled completely separately of number formatting
        
        if ( exists $cell->{type} ) {
            
            if ( $cell->{type} eq "currency" ) {
                
                carp( "\nEncountered a legacy type key with 'currency'.\n"
                    . " Converting to the new 'format' key.\n"
                    . " Please update your code accordingly\n" );
                
                $cell->{format} = {
                    currency            => TRUE,
                    decimal_places      => 2,
                    decimal_fill        => TRUE,
                    separate_thousands  => TRUE
                };
                
                delete $cell->{type};
                
            } elsif ( $cell->{type} eq "currency:no_fill" ) {
                
                carp( "\nEncountered a legacy type key with 'currency:nofill'.\n"
                    .  " Converting to the new 'format' key.\n"
                    .  " Please update your code accordingly\n\n" );
                
                $cell->{format} = {
                    currency            => TRUE,
                    decimal_places      => 2,
                    decimal_fill        => FALSE,
                    separate_thousands  => TRUE
                };
                
                delete $cell->{type};
                
            } elsif ( $cell->{type} eq "thousands_separated" ) {
                
                carp( "\nEncountered a legacy type key with 'thousands_separated'.\n"
                    .  " Converting to the new 'format' key.\n"
                    .  " Please update your code accordingly\n\n" );
                
                $cell->{format} = {
                  separate_thousands  => TRUE
                };
                
                delete $cell->{type};
                
            }
            
        }
        
        # Move along to the next position
        $x += $cell->{full_width};
        
        $cell_counter ++;
        
    }
    
    # Set up upper_buffer and lower_buffer values on groups
    if ( $type eq 'group' ) {
        if ( ! exists $group->{$group_type . '_upper_buffer'} ) {
            # Default to 0 - legacy behaviour
            $group->{$group_type . '_upper_buffer'} = 0;
        }
        if ( ! exists $group->{$group_type . '_lower_buffer'} ) {
            # Default to 0 - legacy behaviour
            $group->{$group_type . '_lower_buffer'} = 0;
        }
    }
    
    # Set up data-level upper_buffer and lower_buffer values
    if ( $type eq 'data' ) {
        if ( ! exists $self->{data}->{upper_buffer} ) {
            # Default to 0, which was the previous behaviour
            $self->{data}->{upper_buffer} = 0;
        }
        if ( ! exists $self->{data}->{lower_buffer} ) {
            # Default to 0, which was the previous behaviour
            $self->{data}->{lower_buffer} = 0;
        }
    }
    
    # Set up field_header upper_buffer and lower_buffer values
    if ( $type eq 'field_headers' ) {
        if ( ! exists $self->{data}->{field_headers_upper_buffer} ) {
            $self->{data}->{field_headers_upper_buffer} = 0;
        }
    }
    
}

sub render_data {
    
    my ( $self, $data ) = @_;
    
    $self->{data} = $data;
    
    $self->{data}->{cell_height} = 0;
    
    # Complete field definitions ...
    # ... calculate the position of each cell's borders and text positioning
    
    # Create a default background object if $self->{cell_borders} is set ( ie legacy support )
    if ( $self->{data}->{cell_borders} ) {
        $self->{data}->{background} = {
                                            border  => "grey"
                                      };
    }
    
    # Normal cells
    $self->setup_cell_definitions( $self->{data}->{fields}, "data" );
    
    # Field headers
    if ( ! $self->{data}->{no_field_headers} ) {
        # Construct the field_headers definition if required ...
        #  ... ie provide legacy behaviour if no field_headers array provided
        if ( ! $self->{data}->{field_headers} ) {
            foreach my $field ( @{$self->{data}->{fields}} ) {
                push @{$self->{data}->{field_headers}},
                {
                    name                => $field->{name},
                    percent             => $field->{percent},
                    bold                => TRUE,
                    font_size           => $field->{font_size},
                    text_whitespace     => $field->{text_whitespace},
                    align               => $field->{header_align},
                    colour              => $field->{header_colour}
                };
            }
        }
        # And now continue with the normal setup ...
        $self->setup_cell_definitions( $self->{data}->{field_headers}, "field_headers" );
    }
    
    # Page headers
    if ( $self->{data}->{page}->{header} ) {
        $self->setup_cell_definitions( $self->{data}->{page}->{header}, "page_header" );
    }
    
    # Page footers
    if ( $self->{data}->{page}->{footer} ) {
        
        $self->setup_cell_definitions( $self->{data}->{page}->{footer}, "page_footer" );
        
    } elsif ( ! $self->{data}->{page}->{footer} && ! $self->{data}->{page}->{footerless} ) {
        
        # Set a default page footer if we haven't been explicitely told not to
        $self->{data}->{cell_height} = 12; # Default text_whitespace of font size * .5
        
        $self->{data}->{page}->{footer} = [
            {
                percent         => 50,
                font_size       => 8,
                text            => "Rendered on \%TIME\%",
                align           => 'left',
                bold            => FALSE
            },
            {
                percent         => 50,
                font_size       => 8,
                text            => "Page \%PAGE\% of \%PAGES\%",
                align           => 'right',
                bold            => FALSE
            }
        ];
                                          
        $self->setup_cell_definitions( $self->{data}->{page}->{footer}, 'page_footer' );
    }
    
    # Groups
    for my $group ( @{$self->{data}->{groups}} ) {
        
        for my $group_type ( qw / header footer / ) {
            if ( $group->{$group_type} ) {
                $self->setup_cell_definitions( $group->{$group_type}, 'group', $group, $group_type );
            }
        }
        # Set all group values to a special character so we recognise that we are entering
        # a new value for each of them ... particularly the GrandTotal group
        $group->{value} = '!';
        
        # Set the data_column of the GrandTotals group so the user doesn't have to specify it
        
        next unless $group->{name} eq 'GrandTotals';
        
        # Check that there is at least one record in the data array, or this assignment triggers
        # an error about undefined ARRAY reference...
        
        my $data_ref = $self->{data}->{data_array};
        if (
            ref ( $data_ref )      eq 'ARRAY'
             && ref ( $data_ref->[0] ) eq 'ARRAY'
        ) {
            $group->{data_column} = scalar ( @{( $data_ref->[0] )} );
        }
    }
    
    # Create an array for the group header queue ( otherwise new_page() won't work so well )
    $self->{group_header_queue} = [];
    
    # Create a new page if we have none ( ie at the start of the report )
    if ( ! $self->{pages} ) {
        $self->new_page;
    }
    
    # Calculate the y space needed for page footers
    my $size_calculation = $self->calculate_y_needed(
        {
            cells               => $self->{data}->{page}->{footer},
            max_cell_height     => $self->{data}->{page_footer_max_cell_height}
        }
    );
    
    $self->{page_footer_and_margin} = $size_calculation->{current_height} + $self->{lower_margin};
    
    my $row_counter = 0;
    
    # Reset the 'need_data_header' flag - if there aren't any groups, this won't we reset
    $self->{need_data_header} = TRUE;
    
    # Main loop
    for my $row ( @{$self->{data}->{data_array}} ) {
        
        # Assemble the Group Header queue ... firstly assuming we *don't* require
        # a page break due to a lack of remaining paper. assemble_group_header_queue()
        # returns whether any of the new groups encounted have requested a page break
        
        my $want_new_page = $self->assemble_group_header_queue(
            $row,
            $row_counter,
            FALSE
        );
        
        if ( ! $want_new_page ) {
            
            # If none of the groups specifically requested a page break, check
            # whether everything will fit on the page
            
            my $size_calculation = $self->calculate_y_needed(
                {
                    cells               => $self->{data}->{fields},
                    max_cell_height     => $self->{data}->{max_cell_height},
                    row                 => $row
                }
            );
            
            if ( $self->{y} - ( $size_calculation->{y_needed} + $self->{page_footer_and_margin} ) < 0 ) {
                
                # Our 1st set of queued headers & 1 row of data spills over the page.
                # We need to re-create the group header queue, and force $want_new_page
                # so that assemble_group_header_queue() knows this and adds all headers
                # that we need ( ie so we pick up reprinting headers that may not have been
                # added in the first pass because it wasn't known at the time that we were
                # taking a new page
                
                # First though, we have to reset the group values in all currently queued headers,
                # so they get re-detected on the 2nd pass
                foreach my $queued_group ( @{$self->{group_header_queue}} ) {
                    
                    # Loop through our groups to find the one with the corresponding name
                    # TODO We need to create a group_mapping hash so this is not required
                    foreach my $group ( @{$self->{data}->{groups}} ) {
                        if ( $group->{name} eq $queued_group->{group}->{name} ) {
                            $group->{value} = "!";
                        }
                    }
                    
                }
                
                $self->{group_header_queue} = undef;
                
                $want_new_page = $self->assemble_group_header_queue(
                    $row,
                    $row_counter,
                    TRUE
                );
                
            }
            
        }
        
        # We're using $row_counter here to detect whether we've actually printed
        # any data yet or not - we don't want to page break on the 1st page ...
        if ( $want_new_page && $row_counter ) {
            $self->new_page;
        }

        $self->render_row(
            $self->{data}->{fields},
            $row,
            'data',
            $self->{data}->{max_cell_height},
            $self->{data}->{upper_buffer},
            $self->{data}->{lower_buffer}
        );
        
        # Reset the need_data_header flag after rendering a data row ...
        #  ... this gets reset when entering a new group
        $self->{need_data_header} = FALSE;
        
        $row_counter ++;
        
    }
    
    # The final group footers will not have been triggered ( only happens when we get a *new* group ), so we do them now
    foreach my $group ( reverse @{$self->{data}->{groups}} ) {
        if ( $group->{footer} ) {
            $self->group_footer($group);
        }
    }
    
    # Move down some more at the end of this pass
    $self->{y} -= $self->{data}->{max_cell_height};
    
}

sub assemble_group_header_queue {
    
    my ( $self, $row, $row_counter, $want_new_page ) = @_;
     
    foreach my $group ( reverse @{$self->{data}->{groups}} ) {
        
        # If we've entered a new group value, * OR *
        #   - We're rendering gruop heavers because a new page has been triggered
        #       ( $want_new_page is already set - by a lower-level group ) * AND *
        #   - This group has the 'reprinting_header' key set
        
        #if ( $want_new_page && $group->{reprinting_header} ) {
            
        if ( ( $group->{value} ne $$row[$group->{data_column}] ) || ( $want_new_page && $group->{reprinting_header} ) ) {
            
            # Remember to page break if we've been told to
            if ( $group->{page_break} ) {
                $want_new_page = TRUE;
            }
            
            # Only do a group footer if we have a ( non-zero ) value in $row_counter
            #  ( ie if we've rendered at least 1 row of data so far )
            # * AND * $want_new_page is NOT set
            # If $want_new_page IS set, then this is our 2nd run through here, and we've already
            # printed group footers
            
            if ( $row_counter && $group->{footer} && ! $want_new_page ) {
                $self->group_footer($group);
            }
            
            # Queue headers for rendering in the data cycle
            # ... prevents rendering a header before the last group footer is done
            if ( $group->{header} ) {
                push
                    @{$self->{group_header_queue}},
                    {
                        group => $group,
                        value => $$row[$group->{data_column}]
                    };
            }
            
            $self->{need_data_header} = TRUE; # Remember that we need to render a data header afterwoods
            
            # If we're entering a new group, reset group totals
            if ( $group->{value} ne $$row[$group->{data_column}] ) {
                for my $field ( @{ $self->{data}->{fields} } ) {
                    $field->{group_results}->{$group->{name}} = 0;
                }
            }
            
            # Store new group value
            $group->{value} = $$row[$group->{data_column}];
            
        }
        
    }
    
    return $want_new_page;
    
}

sub fetch_group_results {
    
    my ( $self, $options ) = @_;
    
    # This is a convenience function that returns the group aggregate value
    # for a given cell / group combination
    
    # First do a little error checking
    if ( ! exists $self->{data}->{cell_mapping}->{ $options->{cell} } ) {
        carp( "\nPDF::ReportWriter::fetch_group_results called with an invalid cell: $options->{cell}\n\n" );
        return;
    }
    
    if ( ! exists $self->{data}->{fields}[ $self->{data}->{cell_mapping}->{ $options->{cell} } ]->{group_results}->{ $options->{group} } ) {
        caro( "\nPDF::ReportWriter::fetch_group_results called with an invalid group: $options->{group} ...\n"
            . " ... check that the cell $options->{cell} has an aggregate function defined, and that the group $options->{group} exists\n" );
        return;
    }
    
    return $self->{data}->{fields}[ $self->{data}->{cell_mapping}->{ $options->{cell} } ]->{group_results}->{ $options->{group} };
    
}

# Define a new page like the PDF template (if template is specified)
# or create a new page from scratch...
sub page_template
{
    
    my $self     = shift;
    my $pdf_tmpl = shift || $self->{template}; # TODO document page_template and optional override
    my $new_page;
    my $user_warned = 0;
    
    if(defined $pdf_tmpl && $pdf_tmpl)
    {
        
        # Try to open template page

        # TODO Cache this object to include a new page without
        #      repeated opening of template file
        if( my $pdf_doc = PDF::API2->open($pdf_tmpl) )
        {
            # Template opened, import first page
            $new_page = $self->{pdf}->importpage($pdf_doc, 1);
        }

        # Warn user in case of invalid template file
        unless($new_page || $user_warned)
        {
            warn "Defined page template $pdf_tmpl not valid. Creating empty page.";
            $user_warned = 1;
        }
        
    }
    
    # Generate an empty page if no valid page was extracted
    # from the template or there was no template...
    $self->{pdf} ||= PDF::API2->new();                     # XXX
    $new_page    ||= $self->{pdf}->page;
    
    return ($new_page);
    
}

sub new_page {
    
    my $self = shift;
    
    # Create a new page	and eventually apply pdf template
    my $page = $self->page_template;
    
    # Set page dimensions
    $page->mediabox( $self->{page_width}, $self->{page_height} );
    
    # Create a new txt object for the page
    $self->{txt} = $page->text;
    
    # Set y to the top of the page
    $self->{y} = $self->{page_height} - $self->{upper_margin};
    
    # Remember that we need to print a data header
    $self->{need_data_header} = TRUE;
    
    # Create a new gfx object for our lines
    $self->{line} = $page->gfx;
    
    # And a shape object for cell backgrounds and stuff
    # We *need* to call ->gfx with a *positive* value to make it render first ...
    #  ... otherwise it won't be the background - it will be the foreground!
    $self->{shape} = $page->gfx(1);
    
    # Append our page footer definition to an array - we store one per page, and render
    # them immediately prior to saving the PDF, so we can say "Page n of m" etc
    push @{$self->{page_footers}}, $self->{data}->{page}->{footer};
    
    # Push new page onto array of pages
    push @{$self->{pages}}, $page;
    
    # Render page header if defined
    if ( $self->{data}->{page}->{header} ) {
        $self->render_row(
            $self->{data}->{page}->{header},
            undef,
            'page_header',
            $self->{data}->{page_header_max_cell_height},
            0, # Page headers don't need
            0  # upper / lower buffers
            # TODO Should we should add upper / buffers to page headers?
         );
    }

    # Renderer any group headers that have been set as 'reprinting_header'
    # ( but not if the group has the special value ! which means that we haven't started yet,
    # and also not if we've got group headers already queued )
    for my $group ( @{$self->{data}->{groups}} ) {
            if ( ( ! $self->{group_header_queue} )
                    && ( $group->{reprinting_header} )
                    && ( $group->{value} ne "!" )
               ) {
                    $self->group_header( $group );
            }
    }
    
    return( $page );
    
}

sub group_header {
    
    # Renders a new group header
    
    my ( $self, $group ) = @_;
    
    if ( $group->{name} ne 'GrandTotals' ) {
        $self->{y} -= $group->{header_upper_buffer};
    }
    
    $self->render_row(
        $group->{header},
        $group->{value},
        'group_header',
        $group->{header_max_cell_height},
        $group->{header_upper_buffer},
        $group->{header_lower_buffer}
    );
    
    $self->{y} -= $group->{header_lower_buffer};
    
}

sub group_footer {
    
    # Renders a new group footer
    
    my ( $self, $group ) = @_;
    
    my $y_needed = $self->{page_footer_and_margin}
        + $group->{footer_max_cell_height}
        + $group->{footer_upper_buffer}
        + $group->{footer_lower_buffer};
    
    if ($y_needed <= $self->{page_height} && $self->{y} - $y_needed < 0) {
        $self->new_page;
    }
    
    $self->render_row(
                        $group->{footer},
                        $group->{value},
                        'group_footer',
                        $group->{footer_max_cell_height},
                        $group->{footer_upper_buffer},
                        $group->{footer_lower_buffer}
                     );
    
}

sub calculate_cell_height {
    
    # Tries to calculate cell height depending on different cell types and properties.
    my ( $self, $cell ) = @_;
    
    my $height = 0;

    # If cell is a barcode, height is given by its "zone" (height of the bars)
    if ( exists $cell->{barcode} ) {
        
        # TODO: This calculation should be done adding upper mending zone,
        #       lower mending zone, font size and bars height, but probably
        #       we don't have them here...
        
        $height = $cell->{zone} + 25;
        
    } elsif ( exists $cell->{text} ) {
        
        # This is a text cell. Pay attention to multiline strings
        my $txt_height = $cell->{font_size};
        
        # Ignore trailing CR/LF chars
        if ( $cell->{text} =~ /[\r\n][^\s]/o ) {
            
            # Multiply height of single line x number of lines
            # FIXME here count of lines is fast but unaccurate
            #$txt_height *= 1.2;
            $txt_height *= 1 + ( $cell->{text} =~ tr/\n/\n/ );
            
        }
        
        $height = $cell->{text_whitespace} + $txt_height;
        
    # Every other cell
    } else {
        
        $height = $cell->{text_whitespace} + $cell->{font_size};
        
    }
    
    return ( $height );
    
}

sub calculate_y_needed {
    
    my ( $self, $options ) = @_;
    
    # This function calculates the y-space needed to render a particular row,
    # and returns it to the caller in the form of:
    # {
    #    current_height  => $current_height,        # LEGACY!
    #    y_needed        => $y_needed,
    #    row_heights     => \@row_heights
    # };
    
    # Unpack options hash
    my $cells               = $options->{cells};
    my $max_cell_height     = $options->{max_cell_height};
    my $row                 = $options->{row};
    
    # We've just been passed the max_cell_height
    # This will be all we need if we are
    # only rendering single-line text
    
    # In the case of data render cycles,
    # the max_cell_height is taken from $self->{data}->{max_cell_height},
    # which is in turn set by setup_cell_definitions(),
    # which goes over each cell with calculate_cell_height()
    
    my $current_height      = $max_cell_height;
    
    # Search for an image in the current row
    # If one is encountered, adjust our $y_needed according to scaling definition
    
    my $counter = 0;
    my @row_heights;
    
    for my $cell ( @{$options->{cells}} ) {
        
        if ( $cell->{image} ) {
            
            # Use this to accumulate image temporary data
            my %imgdata;

            # Support dynamic images ( image path comes from data array )
            # Note: $options->{row} won't necessarily be a data array ...
            #  ... it will ONLY be an array if we're rendering a row of data
            
            if ( $cell->{image}->{dynamic} && ref $options->{row} eq "ARRAY" ) {
                $cell->{image}->{path} = $options->{row}->[$counter];
            }
            
            # TODO support use of images in memory instead of from files?
            # Is there actually a use for this? It's possible that images could come
            # from a database, or be created on-the-fly. Wait for someone to request
            # it, and then get them to implement it :)
            
            # Only do imgsize() calculation if this is a different path from last time ...
            if ( ( ! $imgdata{img_x} ) || ( $cell->{image}->{path} && $cell->{image}->{path} ne $cell->{image}->{previous_path} ) ) {
                (
                    $imgdata{img_x},
                    $imgdata{img_y},
                    $imgdata{img_type}
                ) = imgsize( $cell->{image}->{path} );
                # Remember that we've calculated 
                $cell->{image}->{previous_path} = $cell->{image}->{path};
            }
            
            # Deal with problems with image
            if ( ! $imgdata{img_x} ) {
                warn "Image $cell->{image}->{path} had zero width ... setting to 1\n";
                $imgdata{img_x} = 1;
            }
            
            if ( ! $imgdata{img_y} ) {
                warn "Image $cell->{image}->{path} had zero height ... setting to 1\n";
                $imgdata{img_y} = 1;
            }
            
            if ( $self->{debug} ) {
                print "Image $cell->{image}->{path} is $imgdata{img_x} x $imgdata{img_y}\n";
            }
            
            if ( $cell->{image}->{height} > 0 ) {
                
                # The user has defined an image height
                $imgdata{y_scale_ratio} = ( $cell->{image}->{height} - ( $cell->{image}->{buffer} << 1 ) ) / $imgdata{img_y};
                
            } elsif ( $cell->{image}->{scale_to_fit} ) {
                
                # We're scaling to fit the current cell
                $imgdata{y_scale_ratio} = ( $current_height - ( $cell->{image}->{buffer} << 1 ) ) / $imgdata{img_y};
                
            } else {
                
                # no scaling or hard-coded height defined
                
                # TODO Check with Cosimo: what's the << operator for here?
                #if ( ( $imgdata{img_y} + $cell->{image}->{buffer} << 1 ) > ( $self->{y} - $self->{page_footer_and_margin} ) ) {
                if ( $imgdata{img_y} > ( $self->{y} - $self->{page_footer_and_margin} - ( $cell->{image}->{buffer} * 2) ) ) {
                    #$imgdata{y_scale_ratio} = ( $imgdata{img_y} + $cell->{image}->{buffer} << 1 ) / ( $self->{y} - $self->{page_footer_and_margin} );
                    #$imgdata{y_scale_ratio} = ( $self->{y} - $self->{page_footer_and_margin} ) / ( $imgdata{img_y} + ( $cell->{image}->{buffer} *2 ) );
                    $imgdata{y_scale_ratio} = ( $self->{y} - $self->{page_footer_and_margin} - ( $cell->{image}->{buffer} * 2 ) ) / ( $imgdata{img_y} );
                } else {
                    $imgdata{y_scale_ratio} = 1;
                }
                
            };
            
            if ( $self->{debug} ) {
                print "Current height ( before adjusting for this image ) is $current_height\n";
                print "Y scale ratio = $imgdata{y_scale_ratio}\n";
            }
            
            # A this point, no matter what scaling, fixed size, or lack of
            # other instructions, we still have to test whether the image will fit
            # length-wise in the cell
            
            $imgdata{x_scale_ratio} = ( $cell->{full_width} - ( $cell->{image}->{buffer} * 2 ) ) / $imgdata{img_x};
            
            if ( $self->{debug} ) {
                print "X scale ratio = $imgdata{x_scale_ratio}\n";
            }
            
            # Choose the smallest of x & y scale ratios to ensure we'll fit both ways
            $imgdata{scale_ratio} = $imgdata{y_scale_ratio} < $imgdata{x_scale_ratio}
                ? $imgdata{y_scale_ratio}
                : $imgdata{x_scale_ratio};

            if ( $self->{debug} ) {
                print "Smallest scaling ratio is $imgdata{scale_ratio}\n";
            }
            
            # Set our new image dimensions based on this scale_ratio,
            # but *DON'T* overwrite the original dimensions ...
            #  ... we're caching these for later re-use
            $imgdata{this_img_x} = $imgdata{img_x} * $imgdata{scale_ratio};
            $imgdata{this_img_y} = $imgdata{img_y} * $imgdata{scale_ratio};
            $current_height = $imgdata{this_img_y} + ( $cell->{image}->{buffer} * 2 );

            if ( $self->{debug} ) {
                print "New dimensions:\n Image X: $imgdata{this_img_x}\n Image Y: $imgdata{this_img_y}\n";
                print " New height: $current_height\n";
            }
            
            # Store image data for future reference
            $cell->{image}->{tmp} = \%imgdata;
            
#        } elsif ( ( ref $row eq "ARRAY" ) || ( exists $cell->{text} ) ) {
        } else {
            
            my $text;
            
            # If $options->{row} has been passed ( and is an array ), we're in a data-rendering cycle
            
            if ( ref $row eq "ARRAY" ) {
                $text = $$row[$counter];
            } elsif ( $cell->{text} ) {
                $text = $cell->{text};
            } else {
                $text = $row;
            }
            
            # We need to set the font here so that wrap_text() can accurately calculate where to wrap
            $self->{txt}->font( $self->get_cell_font($cell), $cell->{font_size} );
            
            if ( $cell->{wrap_text} ) {
                $text = $self->wrap_text(
                    {
                        string          => $text,
                        text_width      => $cell->{text_width},
                        strip_breaks    => $cell->{strip_breaks}
                    }
                );
            }
            
            my $no_of_new_lines = $text =~ tr/\n/\n/;
            
            if ( $no_of_new_lines ) {
                $current_height = ( 1 + $no_of_new_lines ) * ( $cell->{font_size} + $cell->{text_whitespace} );
            }
            
        }
        
        # If there is *no* row height set yet, or if it's set but is lower than the current height,
        # set it to the current height
        if ( ( ! $row_heights[ $cell->{row} ] ) || ( $current_height > $row_heights[ $cell->{row} ] ) ) {
            $row_heights[ $cell->{row} ] = $current_height;
        }
        
        $counter ++;
        
    }
    
    # If we have queued group headers, calculate how much Y space they need
    
    # Note that at this point, $current_height is the height of the current row
    # We now introduce $y_needed, which is $current_height, PLUS the height of headers, buffers, etc
    
    my $y_needed = $current_height + $self->{data}->{upper_buffer} + $self->{data}->{lower_buffer};
    
    # TODO this will not work if there are *unscaled* images in the headers
    # Is it worth supporting this as well? Maybe.
    # Maybe later ...
    
    if ( $self->{group_header_queue} ) {
        for my $header ( @{$self->{group_header_queue}} ) {
            # For the headers, we take the header's max_cell_height,
            # then add the upper & lower buffers for the group header
            $y_needed += $header->{group}->{header_max_cell_height}
                + $header->{group}->{header_upper_buffer}
                + $header->{group}->{header_lower_buffer};
        }
        # And also the data header if it's turned on
        if ( ! $self->{data}->{no_field_headers} ) {
            $y_needed += $max_cell_height;
        }
    }
    
    return {
        current_height  => $current_height,
        y_needed        => $y_needed,
        row_heights     => \@row_heights
    };
    
}

sub render_row {
    
    my ( $self, $cells, $row, $type, $max_cell_height, $upper_buffer, $lower_buffer ) = @_;
    
    # $cells            - a hash of cell definitions
    # $row              - the current row to render
    # $type             - possible values are:
    #                       - header                - prints a row of field names
    #                       - data                  - prints a row of data
    #                       - group_header          - prints a row of group header
    #                       - group_footer          - prints a row of group footer
    #                       - page_header           - prints a page header
    #                       - page_footer           - prints a page footer
    # $max_cell_height  - the height of the *cell* ( not including buffers )
    # upper_buffer      - amount of whitespace to leave above this row
    # lower_buffer      - amount of whitespace to leave after this row
    
    # In the case of page footers, $row will be a hash with useful stuff like
    # page number, total pages, time, etc
    
    # Calculate the y space required, including queued group footers
    my $size_calculation = $self->calculate_y_needed(
        {
            cells           => $cells,
            max_cell_height => $max_cell_height,
            row             => $row
        }
    );
    
    # Page Footer / New Page / Page Header if necessary, otherwise move down by $current_height
    # ( But don't force a new page if we're rendering a page footer )
    
    # Check that total y space needed does not exceed page size.
    # In that case we cannot keep adding more pages, which causes
    # horrible out of memory errors
    
    # TODO Should this be taken into account in calculate_y_needed?
    $size_calculation->{y_needed} += $self->{page_footer_and_margin};

    if ( $type ne 'page_footer'
            && $size_calculation->{y_needed} <= $self->{page_height}
            && $self->{y} - $size_calculation->{y_needed} < 0
       )
    {
        $self->new_page;
    }

    # Trigger any group headers that we have queued, but ONLY if we're in a data cycle
    if ( $type eq "data" ) {
        while ( my $queued_headers = pop @{$self->{group_header_queue}} ) {
            $self->group_header( $queued_headers->{group}, $queued_headers->{value} );
        }
    }
    
    if ( $type eq "data" && $self->{need_data_header} && ! $self->{data}->{no_field_headers} ) {
        
        # If we are in field headers section, leave room as specified by options
        $self->{y} -= $self->{data}->{field_headers_upper_buffer};
        
        # Now render field headers row
        $self->render_row(
            $self->{data}->{field_headers},
            0,
            'header',
            $self->{data}->{max_field_header_height},
            $self->{data}->{field_header_upper_buffer},
            $self->{data}->{field_header_lower_buffer}
        );
        
    }
    
    # Move down for upper_buffer, and then for the current row height
#    $self->{y} -= $upper_buffer + $current_height;
    
    # Move down for upper_buffer, and then for the FIRST row height
    $self->{y} -= $upper_buffer;
    
    #
    # Render row
    #
    
    # Prepare options to be passed to *all* cell rendering methods
    my $options = {
                        current_row         => $row,
                        row_type            => $type,       # Row type (data, header, group, footer)
                        cell_counter        => 0,
                        cell_y_border       => $self->{y},
#                        cell_full_height    => $current_height,
                        page                => $self->{pages}->[ scalar( @{$self->{pages}} ) - 1 ],
                        page_no             => scalar( @{$self->{pages}} ) - 1
                  };
    
    my $this_row = -1; # Forces us to move down immediately
    
    for my $cell ( @{$cells} ) {
        
        # If we're entering a new line ( ie multi-line rows ),
        # then shift our Y position and set the new cell_full_height
        
        if ( $this_row != $cell->{row} ) {
            $self->{y} -= $size_calculation->{row_heights}[ $cell->{row} ];
            $options->{cell_full_height} = $size_calculation->{row_heights}[ $cell->{row} ];
            $this_row = $cell->{row};
        }
        
        $options->{cell} = $cell;
        
        # TODO Apparent we're not looking in 'text' key for hard-coded text any more. Add back ...
        if ( ref( $options->{current_row} ) eq 'ARRAY' ) {
            $options->{current_value} = $options->{current_row}->[ $options->{cell_counter} ];
        } else {
            $options->{current_value} = $options->{current_row};
        }
        
        #} else {
        #} else {
        #   warn 'Found notref value '.$options->{current_row};
        #   $options->{current_value} = $options->{current_row}->[ $options->{cell_counter} ];
        #   $options->{current_value} = $options->{current_row};
        #}
        
        $self->render_cell( $cell, $options );
        $options->{cell_counter}++;
        
    }
    
    # Move down for the lower_buffer
    $self->{y} -= $lower_buffer;
    
}

sub render_cell {
    
    my ( $self, $cell, $options ) = @_;
    
    my $type           = $options->{row_type};
    my $row            = $options->{current_row};
    my $current_height = $options->{cell_full_height};
    my $cell_counter   = $options->{cell_counter};

    # Render cell background ( an ellipse, box, or cell borders )
    if ( exists $cell->{background} ) {
        $self->render_cell_background( $cell, $options );
    }
    
    # Run custom render functions and see if they return anything
    if ( exists $cell->{custom_render_func} ) {
        
        # XXX Here to unify all the universal forces, the first parameter
        # should be the cell "object", then all the options, even if options
        # already contains a "cell" object
        my $func_return = $cell->{custom_render_func}( $options );
        
        if ( ref $func_return eq "HASH" ) {
            
            # We've received a return hash with instructions on what to do
            if ( exists $func_return->{render_text} ) {
                
                # We've been passed some text to render. Shove it into the current value and continue
                $options->{current_value} = $func_return->{render_text};
                
            } elsif ( exists $func_return->{render_image} ) {
                
                # We've been passed an image hash. Copy each key in the hash back into the cell and continue
                foreach my $key ( keys %{$func_return->{render_image}} ) {
                    $cell->{image}->{$key} = $$func_return->{render_image}->{$key};
                }
                
            } elsif ( exists $func_return->{rendering_done} && $func_return->{rendering_done} ) {
                
                return;
                
            } else {
                
                warn "A custom render function returned an unrecognised hash!\n";
                return;
                
            }
            
        } else {
            
            warn "A custom render function was executed, but it didn't provide a return hash!\n";
            return;
            
        }
    }
    
    if ( $cell->{image} ) {
        
        $self->render_cell_image( $cell, $options );
        
    } elsif ( $cell->{barcode} ) {
        
        # Barcode cell
        
        $self->render_cell_barcode( $cell, $options );
        
    } else {
        
        # Generic text cell rendering
        
        $self->render_cell_text( $cell, $options );
        
        # Now perform aggregate functions if defined
        
        if ( $type eq 'data' && $cell->{aggregate_function} ) {
            
            my $cell_value = $options->{current_value} || 0;
            my $group_res  = $cell->{group_results} ||= {};
            my $aggr_func  = $cell->{aggregate_function};
            
            if ( $aggr_func ) {
                
                if ( $aggr_func eq 'sum' ) {
                    
                    for my $group ( @{$self->{data}->{groups}} ) {
                        $group_res->{$group->{name}} += $cell_value;
                    }
                    
                    $cell->{grand_aggregate_result} += $cell_value;
                    
                } elsif ( $aggr_func eq 'count' ) {
                    
                    for my $group ( @{$self->{data}->{groups}} ) {
                            $group_res->{$group->{name}} ++;
                    }
                    
                    $cell->{grand_aggregate_result} ++;
                    
                } elsif ( $aggr_func eq 'max' ) {
                    
                    for my $group ( @{$self->{data}->{groups}} ) {
                        if( $cell_value > $group_res->{$group->{name}} ) {
                            $cell->{grand_aggregate_result} =
                            $group_res->{$group->{name}}    = $cell_value;
                        }
                    }
                    
                } elsif ( $aggr_func eq 'min' ) {
                    
                    for my $group ( @{$self->{data}->{groups}} ) {
                        if( $cell_value < $group_res->{$group->{name}} ) {
                            $cell->{grand_aggregate_result} =
                            $group_res->{$group->{name}}    = $cell_value;
                        }
                    }
                    
                }
                
                # TODO add an "avg" aggregate function? Should be simple.
                
            }
            
        }
        
    }
    
}

sub render_cell_background {
    
    my ( $self, $cell, $opt ) = @_;
    
    my $background;
    
    if ( $cell->{background_func} ) {
        if ( $self->{debug} ) {
            print "\nRunning background_func() \n";
        }
        
        $background = $cell->{background_func}($opt->{current_value}, $opt->{current_row}, $opt);
    }
    else {
    	$background = $cell->{background};
    }

    unless ( defined $background ) {
        return;
    }
    
    my $current_height = $opt->{cell_full_height};

    
    if ( $background->{shape} ) {
        
        if ( $background->{shape} eq "ellipse" ) {
            
            $self->{shape}->fillcolor( $background->{colour} );
            
            $self->{shape}->ellipse(
                $cell->{x_border} + ( $cell->{full_width} >> 1 ),       # x centre
                $self->{y} + ( $current_height >> 1 ),                  # y centre
                $cell->{full_width} >> 1,                               # length ( / 2 ... for some reason )
                $current_height >> 1                                    # height ( / 2 ... for some reason )
            );
            
            $self->{shape}->fill;
            
        } elsif ( $background->{shape} eq "box" ) {
            
            $self->{shape}->fillcolor( $background->{colour} );
            
            $self->{shape}->rect(
                    $cell->{x_border},                                  # left border
                    $self->{y},                                         # bottom border
                    $cell->{full_width},                                # length
                    $current_height                                     # height
            );
            
            $self->{shape}->fill;
            
        }
        
    }
    
    #
    # Now render cell background borders
    #
    if ( $background->{border} ) {
        
        # Cell Borders
        $self->{line}->strokecolor( $background->{border} );
        
        # TODO Move the regex setuff into setup_cell_definitions()
        # so we don't have to regex per cell, which is
        # apparently quite expensive
        
        # If the 'borders' key does not exist then draw all borders
        # to support code written before this was added.
        # A value of 'all' can also be used.
        if ( ( ! exists $background->{borders} ) || ( uc $background->{borders} eq 'ALL' ) )
        {
            $background->{borders} = "tblr";
        }
        
        # The 'borders' key looks for the following chars in the string
        #  t or T - Top Border Line
        #  b or B - Bottom Border Line
        #  l or L - Left Border Line
        #  r or R - Right Border Line
        
        my $cell_bb = $background->{borders};
        
        # Bottom Horz Line
        if ( $cell_bb =~ /[bB]/ ) {
            $self->{line}->move( $cell->{x_border}, $self->{y} );
            $self->{line}->line( $cell->{x_border} + $cell->{full_width}, $self->{y} );
            $self->{line}->stroke;
        }
        
        # Right Vert Line
        if ( $cell_bb =~ /[rR]/ ) {
            $self->{line}->move( $cell->{x_border} + $cell->{full_width}, $self->{y} );
            $self->{line}->line( $cell->{x_border} + $cell->{full_width}, $self->{y} + $current_height );
            $self->{line}->stroke;
        }

        # Top Horz Line
        if ( $cell_bb =~ /[tT]/ ) {
            $self->{line}->move( $cell->{x_border} + $cell->{full_width}, $self->{y} + $current_height );
            $self->{line}->line( $cell->{x_border}, $self->{y} + $current_height );
            $self->{line}->stroke;
        }

        # Left Vert Line
        if ( $cell_bb =~ /[lL]/ ) {
            $self->{line}->move( $cell->{x_border}, $self->{y} + $current_height );
            $self->{line}->line( $cell->{x_border}, $self->{y} );
            $self->{line}->stroke;
        }
        
    }
    
}

sub render_cell_barcode {

    my ( $self, $cell, $opt ) = @_;
    
    # PDF::API2 barcode options
    #
    # x, y => center of barcode position
    # type => 'code128', '2of5int', '3of9', 'ean13', 'code39'
    # code => what is written into barcode
    # extn => barcode extension, where applicable
    # umzn => upper mending zone (?)
    # lmzn => lower mending zone (?)
    # quzn => quiet zone (space between frame and barcode)
    # spcr => what to put between each char in the text
    # ofwt => overflow width
    # fnsz => font size for the text
    # text => optional text under the barcode
    # zone => height of the bars
    # scale=> 0 .. 1
    
    my $pdf = $self->{pdf};
    my $bcode = $self->get_cell_text($opt->{current_row}, $cell, $cell->{barcode});
    my $btype = 'xo_code128';
    
    # For EAN-13 barcodes, calculate check digit
    if ( $cell->{type} eq 'ean13' )
    {
            return unless eval { require GD::Barcode::EAN13 };
            $bcode .= '000000000000';
            $bcode  = substr( $bcode, 0, 12 );
            $bcode .= GD::Barcode::EAN13::calcEAN13CD($bcode);
        $btype = 'xo_ean13';
    }
    
    # Define font type
    my %bcode_opt = (
        -font=>$self->get_cell_font($cell),
        -fnsz=>$cell->{font_size} || $self->{default_font_size},
        -code=>$bcode,
        -text=>$bcode,
        -quzn=>exists $cell->{quiet_zone}         ? $cell->{quiet_zone}         :  2,
        -umzn=>exists $cell->{upper_mending_zone} ? $cell->{upper_mending_zone} :  4,
        -zone=>exists $cell->{zone}               ? $cell->{zone}               : 25,
        -lmzn=>exists $cell->{lower_mending_zone} ? $cell->{lower_mending_zone} : 12,
        -spcr=>' ',
        -ofwt=>0.1,
    );
    
    if( $cell->{type} eq 'code128' )
    {
        $bcode_opt{-ean}  = 0;
        # TODO Don't know what type to use here.
        #   `a' does not seem to handle lowercase chars.
        #   `c' is a mess.
        #   `b' seems the better...
        $bcode_opt{-type} = 'b';
    }
    
    if( $cell->{type} eq 'code39' )
    {
        print STDERR "code 39 code\n";
        $bcode_opt{-ean}  = 0;
        # TODO Don't know what type to use here.
        #   `a' does not seem to handle lowercase chars.
        #   `c' is a mess.
        #   `b' seems the better...
        $btype = 'xo_3of9';
    }
    
    my $bar   = $pdf->$btype(%bcode_opt);
    my $scale = exists $cell->{scale} ? $cell->{scale} : 1;
    my $x_pos = exists $cell->{x} ? $cell->{x} : $cell->{x_border};
    my $y_pos = exists $cell->{y} ? $cell->{y} : $self->{y};
    
    # Manage alignment (left, right or center)
    my $align = substr lc $cell->{align} || 'l', 0, 1;
    my $bar_width = $bar->width * $scale;
    if( $align eq 'r' ) {
        $x_pos -= $bar_width;
    } elsif( $align eq 'c' ) {
        $x_pos -= $bar_width >> 1;
    }
    
    # Position barcode with correct x,y and scale
    my $gfx = $opt->{page}->gfx;
    $gfx->formimage($bar, $x_pos, $y_pos, $scale);

}

sub render_cell_image {
    
    my( $self, $cell, $opt ) = @_;
    
    my $current_height = $opt->{cell_full_height};
    my $gfx = $opt->{page}->gfx;
    my $image;
    my $imgdata = $cell->{image}->{tmp};
    
    # TODO Add support for GD::Image images?
    # PDF::API2 supports using them directly.
    # We need another key - shouldn't re-use $cell->{image}->{path}
    # We also shouldn't run imgsize() on it, so we have to figure out
    # another way of getting the image size.
    # I haven't use GD before, but I've noted stuff here for people
    # who want GD::Image support ...
    
    # Try to know if installed version of PDF::API2 support the
    # image we are throwing in the PDF document, to avoid bombs
    # when calling image_* pdf methods.
    my %img_meth = (
        PNG=>'image_png',
        JPG=>'image_jpeg',
        TIF=>'image_tiff',
        GIF=>'image_gif',
        PNM=>'image_pnm',
    );
    
    eval {
    
        my $img_call = exists $img_meth{ $imgdata->{img_type} }
            ? $img_meth{ $imgdata->{img_type} }
            : undef;
    
        if( ! defined $img_call )
        {
            warn "\n * * * * * * * * * * * * * WARNING * * * * * * * * * * * * *\n";
            warn " Unknown image type: $imgdata->{img_type}\n";
            warn " NOT rendering this image.\n";
            warn " Please add support for PDF::ReportWriter and send patches :)\n\n";
            warn "\n * * * * * * * * * * * * * WARNING * * * * * * * * * * * * *\n\n";
        
            # Return now or errors are going to happen when putting an invalid image
            # object on PDF page gfx context
                die "Unrecognized image type";
        }
    
        # Check for PDF::API2 capabilities
        if( ! $self->{pdf}->can($img_call) )
        {
            my $ver = PDF::API2->VERSION();
            die "Your version of PDF::API2 module ($ver) doesn't support $$imgdata{img_type} images or image file is broken.";
        }
        else
        {
            # Finally try to include image in PDF file
            no strict 'refs';
            $image = $self->{pdf}->$img_call($cell->{image}->{path});
        }
    };
    
    # Check if some image processing error happened
    if( $@ )
    {
        warn 'Error in image ' . $cell->{image}->{path} . ' processing: '.$@;
        return();
    }
    
    # Relative or absolute positioning is handled here...
    my $img_x_pos = exists $cell->{x} ? $cell->{x} : $cell->{x_border};
    my $img_y_pos = exists $cell->{y} ? $cell->{y} : $self->{y};
    
    # Alignment
    if ( $cell->{align} && ( $cell->{align} eq 'centre' || $cell->{align} eq 'center' ) ) {
        $img_x_pos += ( ( $cell->{full_width} - $imgdata->{this_img_x} ) / 2 );
        $img_y_pos += ( ( $current_height - $imgdata->{this_img_y} ) / 2 );
    } elsif ( $cell->{align} && $cell->{align} eq 'right') {
        $img_x_pos += ( $cell->{full_width} - $imgdata->{this_img_x} ) - $cell->{image}->{buffer};
        $img_y_pos += ( ( $current_height - $imgdata->{this_img_y} ) / 2 );
    } else {
        $img_x_pos += $cell->{image}->{buffer};
        $img_y_pos += ( ( $current_height - $imgdata->{this_img_y} ) / 2 );
    };
    
    #warn 'image: '.$cell->{image}->{path}.' scale_ratio:'. $imgdata->{scale_ratio};
    
    # Place image onto PDF document's graphics context
    $gfx->image(
                    $image,                     # The image
                    $img_x_pos,                 # X
                    $img_y_pos,                 # Y
                    $imgdata->{scale_ratio}     # scale
               );

}

sub get_cell_font
{
    my ( $self, $cell ) = @_;
    my $font_type =
        ( exists $cell->{bold} && $cell->{bold} )
            ? ( exists $cell->{italic} && $cell->{italic} ) ? 'BoldItalic' : 'Bold'
            : ( exists $cell->{italic} && $cell->{italic} ) ? 'Italic' : 'Roman';
    my $font_name = $cell->{font} || $self->{default_font};
    return $self->{fonts}->{$font_name}->{$font_type};
}

sub render_cell_text {
    
    my ( $self, $cell, $opt ) = @_;
    
    my $row  = $opt->{current_row};
    my $type = $opt->{row_type};
    
    # Figure out what we're putting into the current cell and set the font and size
    # We currently default to Bold if we're doing a header
    # We also check for an specific font for this field, or fall back on the report default
    
    my $string;
    
    $self->{txt}->font( $self->get_cell_font($cell), $cell->{font_size} );
    
    if ($type eq 'header') {
        
        $string = $cell->{name};
        
    } elsif ( $type eq 'data' ) {
        
        #$string = $row->[$opt->{cell_counter}];
        $string = $opt->{current_value};
    
    } elsif ( $type eq 'group_header' ) {
    
        # Replaces the `?' char and manages text delimited cells
        $string = $self->get_cell_text( $row, $cell, $cell->{text} );
        
    } elsif ( $type eq 'group_footer' ) {
        
        if ( exists $cell->{aggregate_source} ) {
            my $aggr_field = $self->{data}->{fields}->[ $cell->{aggregate_source} ];
            if ($cell->{text} eq 'GrandTotals') {
                $string = $aggr_field->{grand_aggregate_result};
            } else {
                $string = $aggr_field->{group_results}->{$cell->{text}};
            }
        } else {
            $string = $cell->{text};
        }
        
        $string =~ s/\?/$row/g; # In the case of a group footer, the $row variable is the group value
        #$string = $self->get_cell_text($row, $cell, $string);
        
    } elsif ( $type =~ m/^page/ ) {
        
        # page_header or page_footer
        $string = $self->get_cell_text( $row, $cell, $cell->{text} );
    }
        
    if ( $cell->{colour_func} ) {
        if ( $self->{debug} ) {
            print "\nRunning colour_func() on data: " . $string . "\n";
        }
        $self->{txt}->fillcolor( $cell->{colour_func}( $string, $row, $opt ) || "black" );
    } else {
        $self->{txt}->fillcolor( $cell->{colour} || "black" );
    }
    
    # Formatting
    if ( $type ne 'header' && $cell->{format} ) {
        
        # The new ( v1.4 ) formatter hash
        $string = $self->format_number(
                                        $cell->{format},
                                        $string
                                      );
        
    } elsif ( $cell->{type} && $cell->{type} =~ /^custom:(.+)$/ ) {
        
        # Custom formatter, in the legacy 'type' key
        # Should this be renamed to 'format' too?
        
        # TODO Better develop custom cell type?
        # TODO How do we specify the custom formatter object?
        
        eval "require $1";
        if( $@ )
        {
            warn "Cell custom formatter class $1 was not found or had errors: $@";
        }
        
        my $formatter_obj = $1->new();
        $string = $formatter_obj->format({ cell => $cell, options => $opt, string => $string });
        
        
    }
    
    # Line height = font size + text whitespace
    # TODO Find a better way to calculate this (external property?)
    # I ( Dan ) am pretty sure this calculation is OK now
    my $line_height = $cell->{font_size} + $cell->{text_whitespace};
    
    # Wrap text
    if ( $cell->{wrap_text} ) {
        $string = $self->wrap_text(
                                    {
                                        string          => $string,
                                        text_width      => $cell->{text_width},
                                        strip_breaks    => $cell->{strip_breaks}
                                    }
                                  );
    }
    
    # Alignment and position
    my $y_pos = exists $cell->{y} ? $cell->{y} :
        $self->{y} + ( $cell->{text_whitespace} || 0 )      # The space needed for the 1st row
        + ( $string =~ tr/\n/\n/ * $line_height );          # The number of new-line characters
    
    my $align = exists $cell->{align} ? substr($cell->{align} || 'left', 0, 1) : 'l';
    
    # If cell is absolutely positioned (y), we should avoid automatic page break.
    # This is intuitive to do, I think...
    my $cell_abs_pos = exists $cell->{y};
    
    # Handle multiline text
    
    # Whatever the format (Dos/Unix/Mac/Amiga), this should correctly split rows
    # NOTE: This breaks rendering of blank lines
    # TODO Check with Cosimo why we're stripping blank rows
    #my @text_rows = split /[\r\n]+\s*/ => $string;
    
    my @text_rows = split /\n/, $string;
    
    for $string ( @text_rows ) {
        
        # Skip empty lines ... but NOT strings that eq "0"
        # We still want to be able to render the character 0
        # TODO Why are we doing this? Don't. It breaks rendering blank lines
        
        # next unless ( $string || $string eq "0" );
        
        # Skip strings with only whitespace
        # TODO Why is this here. It breaks rendering for strings that start with a space character
#        next if $string =~ /^\s+/;
        
        # Make sure the current string fits inside the current cell
        # Beware: if text_width < 0, there is something wrong with `percent' attribute.
        # Maybe it hasn't been set...
        
        if ( $cell->{text_width} > 0 ) {
            while ( $string && $self->{txt}->advancewidth( $string ) > $cell->{text_width}) { 
                chop($string);
            }
        }
        
        #if( $self->{debug} )
        #{
        #   print 'Text `', $string, '\' at (', $x_pos, ',' , $y_pos, ') align: '.$cell->{align}, "\n";
        #}
        
        # We have to do X alignment inside the multiline text loop here ...
        my $x_pos = exists $cell->{x} ? $cell->{x} : $cell->{x_text};
        
        if ( $align eq 'l' ) {
            
            # Default alignment if left-aligned
            $self->{txt}->translate( $x_pos, $y_pos );
            $self->{txt}->text( $string );
            
        } elsif ( $align eq 'c' || $type eq 'header' ) {
            
            # Calculate the width of the string, and move to the right so there's an
            # even gap at both sides, and render left-aligned from there
            
            my $string_width = $self->{txt}->advancewidth( $string );
            
            my $x_offset = $cell_abs_pos
                ? - ($string_width >> 1)
                : ( $cell->{text_width} - $string_width ) >> 1;
             
            $x_pos += $x_offset;
            $self->{txt}->translate( $x_pos, $y_pos );
            $self->{txt}->text( $string );
            
        } elsif ( $align eq 'r' ) {
            
            if( $cell_abs_pos ) {
                $x_pos -= $self->{txt}->advancewidth( $string ) >> 1;
            } else {
                $x_pos += $cell->{text_width};
            }
            
            $self->{txt}->translate( $x_pos, $y_pos );
            $self->{txt}->text_right($string);
            
        } elsif ( $align eq 'j' ) {
           
            # Justify text
            # This is largely taken from a brilliant example at: http://incompetech.com/gallimaufry/perl_api2_justify.html
            
            # Set up the control
            $self->{txt}->charspace( 0 );
            
            # Calculate the width at this default spacing 
            my $standard_width = $self->{txt}->advancewidth( $string );
            
            # Now the experiment
            $self->{txt}->charspace( 1 );
             
            my $experiment_width = $self->{txt}->advancewidth( $string );
            
            # SINCE 0 -> $nominal   AND   1 -> $experiment ... WTF was he on about here?
            if ( $standard_width ) {
                
                my $diff = $experiment_width - $standard_width;
                my $min  = $cell->{text_width} - $standard_width;
                my $target = $min / $diff;
                
                # TODO Provide a 'maxcharspace' option? How about a normal charspace option?
                # TODO Is there a more elegent way to do this?
                
                $target = 0 if ( $target > 1 ); # charspacing > 1 looks kinda dodgy, so don't bother with justifying in this case
                
                # Set the target charspace
                $self->{txt}->charspace( $target );
                
                # Render
                $self->{txt}->translate( $x_pos, $y_pos );
                $self->{txt}->text( $string );
                
                # Default back to 0 charspace
                $self->{txt}->charspace( 0 );
                
            }
           
        }
        
        # XXX Empirical result? Is there a text line_height information?
        $y_pos -= $line_height;
        
        # Run empty on page space? Make a page break
        # Dan's note: THIS SHOULD *NEVER* HAPPEN.
        # If it does, something is wrong with our y-space calculation
        if( $cell_abs_pos && $y_pos < $line_height ) {
            warn "* * * render_cell_text() is requesting a new page * * *\n";
            warn "* * * please check y-space calculate_y_needed()   * * *\n";
            warn "* * *             this MUST be a bug ...          * * *\n";
            $self->new_page();
        }
        
    }
    
}

sub wrap_text {
    
    # TODO FIXME This is incredibly slow.
    # Someone, please fix me ....
    
    my ( $self, $options ) = @_;
    
    my $string          = $options->{string};
    my $text_width      = $options->{text_width};
    
    if ( $text_width == 0 ) {
        return $string;
    }
    
    # Replace \r\n with \n
    $string =~ s/\r\n/\n/g;
    
    # Remove line breaks?
    if ( $options->{strip_breaks} ) {
        $string =~ s/\n//g;
    }
    
    my @wrapped_text;
    my @paragraphs = split /\n/, $string;
    
    # We want to maintain any existing line breaks,
    # and also add new line breaks if the text won't fit on 1 line
    
    foreach my $paragraph ( @paragraphs ) {
        
        # We need to do this to preserve blank lines ( it slips through the loop below )
        if ( $paragraph eq '' ) {
            push @wrapped_text, $paragraph;
        }
        
        while ( $paragraph ) {
            
            my $position    = 0;
            my $last_space  = 0;
            
            while (
                    ( $self->{txt}->advancewidth( substr( $paragraph, 0, $position ) ) < $text_width )
                        && ( $position < length( $paragraph ) )
            ) {
                if ( substr( $paragraph, $position, 1 ) eq " " ) {
                    $last_space = $position;
                }
                $position ++;
            }
            
            my $length;
            
            if ( $position == length( $paragraph ) ) {
                
                # This bit doesn't need wrapping. Take it all
                $length = $position;
                
            } else {
                
                # We didn't get to the end of the string, so this bit *does* need wrapping
                # Go back to the last space
                            
                $length = $last_space;
                
            }
            
            if ( $self->{debug} ) {
                print "PDF::ReportWriter::wrap_text returning line: " . substr( $paragraph, 0, $length ) . "\n\n";
            }
            
            push @wrapped_text, substr( $paragraph, 0, $length );
            
            $paragraph = substr( $paragraph, $length + 1, length( $paragraph ) - $length );
            
        }
        
    }
    
    return join "\n", @wrapped_text;
    
}

sub format_number {
    
    my ( $self, $options, $value ) = @_;
    
    # $options can contain the following:
    #  - currency               BOOLEAN
    #  - decimal_places         INT     ... or
    #  - decimals               INT
    #  - decimal_fill           BOOLEAN
    #  - separate_thousands     BOOLEAN
    #  - null_if_zero           BOOLEAN
    
    my $calc = $value;
    
    my $final;
    
    # Support for null_if_zero
    if ( exists $options->{null_if_zero} && $options->{null_if_zero} && $value == 0 ) {
        return undef;
    }
    
    my $decimals = exists $options->{decimal_places} ? $options->{decimal_places} : $options->{decimals};
    
    # Allow for our number of decimal places
    if ( $decimals ) {
        $calc *= 10 ** $decimals;
    }
    
    # Round
    $calc = int( $calc + .5 * ( $calc <=> 0 ) );
    
    # Get decimals back
    if ( $decimals ) {
        $calc /= 10 ** $decimals;
    }
    
    # Split whole and decimal parts
    my ( $whole, $decimal ) = split /\./, $calc;
    
    # Pad decimals
    if ( $options->{decimal_fill} ) {
        if ( defined $decimal ) {
            $decimal = $decimal . "0" x ( $decimals - length( $decimal ) );
        } else {
            $decimal = "0" x $decimals;
        }
    }
    
    # Separate thousands
    if ( $options->{separate_thousands} ) {
        # This BS comes from 'perldoc -q numbers'
        $whole =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
    }
    
    # Currency?
    if ( $options->{currency} ) {
        $final = '$';
    }
    
    # Don't put a decimal point if there are no decimals
    if ( defined $decimal ) {
        $final .= $whole . "." . $decimal;
    } else {
        $final .= $whole;
    }
    
    return $final;
    
}

sub render_footers
{
    my $self = $_[0];
    
    # If no pages defined, there are no footers to render
    if( ! exists $self->{pages} || ! ref $self->{pages} )
    {
        return;
    }
    
    my $total_pages = scalar@{$self->{pages}};
    
    # We first loop through all the pages and add footers to them
    for my $this_page_no ( 0 .. $total_pages - 1 ) {
        
        $self->{txt} = $self->{pages}[$this_page_no]->text;
        $self->{line} = $self->{pages}[$this_page_no]->gfx;
        $self->{shape} = $self->{pages}[$this_page_no]->gfx(1);
        
        my $localtime = localtime time;
        
        # Get the current_height of the footer - we have to move this much *above* the lower_margin,
        # as our render_row() will move this much down before rendering
        my $size_calculation = $self->calculate_y_needed(
                                                            {
                                                                cells           => $self->{page_footers}[$this_page_no],
                                                                max_cell_height => $self->{page_footer_max_cell_height}
                                                            }
                                                    );
        
        $self->{y} = $self->{lower_margin} + $size_calculation->{current_height};
        
        $self->render_row(
                            $self->{page_footers}[$this_page_no],
                            {
                                current_page    => $this_page_no + 1,
                                total_pages     => $total_pages,
                                current_time    => $localtime
                            },
                            'page_footer',
                            $self->{page_footer_max_cell_height},
                            0,
                            0
                         );
        
    }
    
}

sub stringify
{
    my $self = shift;
    my $pdf_stream;
    
    $self->render_footers();
    
    $pdf_stream = $self->{pdf}->stringify;
    $self->{pdf}->end;
    
    return($pdf_stream);
}

sub save {
    
    my $self = shift;
    my $ok   = 0;
    
    $self->render_footers();
    
    $ok = $self->{pdf}->saveas($self->{destination});
    $self->{pdf}->end();
    
    # TODO Check result of PDF::API2 saveas() and end() methods?
    return(1);
    
}

sub saveas {
    
    my $self = shift;
    my $file = shift;
    $self->{destination} = $file;
    $self->save();
    
}

#
# Spool a report to CUPS print queue for direct printing
#
# $self->print({
#     tempdir => '/tmp',
#     command => '/usr/bin/lpr.cups',
#     printer => 'myprinter',
# });
#
sub print {
    
    use File::Temp ();
    
    my $self = shift;
    my $opt  = shift;
    my @cups_locations = qw(/usr/bin/lpr.cups /usr/bin/lpr-cups /usr/bin/lpr);
    
    # Apply option defaults
    my $unlink_spool = exists $opt->{unlink} ? $opt->{unlink} : 1;
    $opt->{tempdir} ||= '/tmp';
    
    # Try to find a suitable cups command
    if( ! $opt->{command} )
    {
        my $cmd;
        do {
            last unless @cups_locations;
            $cmd = shift @cups_locations;
        } until ( -e $cmd && -x $cmd );
    
        if( ! $cmd )
        {
            warn 'Can\'t find a lpr/cups shell command to run!';
            return undef;
        }
    
        # Ok, found a cups/lpr command
        $opt->{command} = $cmd;
    }
    
    my $cups_cmd = $opt->{command};
    my $ok = my $err = 0;
    my $printer;
    
    # Add printer queue name if supplied
    if( $printer = $opt->{printer} )
    {
        $cups_cmd .= " -P $printer";
    }
    
    # Generate a temporary file to store pdf content
    my($temp_file, $temp_name) = File::Temp::tempfile('reportXXXXXXX', DIR=>$opt->{tempdir}, SUFFIX=>'.pdf');
    
    # Print all pdf stream to file
    if( $temp_file )
    {
            binmode $temp_file;
        $ok   = print $temp_file $self->stringify();
        $ok &&= close $temp_file;
    
        # Now spool this temp file
        if( $ok )
        {
            $cups_cmd .= ' ' . $temp_name;
    
            # Run spool command and get exit status
            my $exit = system($cups_cmd) && 0xFF;
            $ok = ($exit == 0);
    
            if( ! $ok )
            {
                # ERROR 1: FAILED spooling of report with CUPS
                $err = 1;
            }
    
            # OK: Report spooled correctly to CUPS printer
    
        }
        else
        {
            # ERROR 2: FAILED creation of report spool file
            $err = 2;
        }
    
        unlink $temp_name if $unlink_spool;
    }
    else
    {
        # ERROR 3: FAILED opening of a temporary spool file
        $err = 3;
    }
    
    return($err);
}

#
# Replaces `?' with current value and handles cells with delimiter and index
# Returns the final string value
#

{
    # Datasource strings regular expression
    # Example: `%customers[2,5]%'
    my $ds_regex = qr/%(\w+)\[(\d+),(\d+)\]%/o;
    
    sub get_cell_text {
        
        my ( $self, $row, $cell, $text ) = @_;
        
        my $string = $text || $cell->{text};
        
        # If string begins and ends with `%', this is a reference to an external datasource.
        # Example: `%mydata[m,n]%' means lookup the <datasource> tag with name `mydata',
        # try to load the records and return the n-th column of the m-th record.
        # Also multiple data strings are allowed in a text cell, as in
        # `Dear %customers[0,1]% %customers[0,2]%'
        
        while ( $string =~ $ds_regex ) {
            
            # Lookup from external datasource
            my $ds_name = $1;
            my $n_rec   = $2;
            my $n_col   = $3;
            my $ds_value= '';
            
            # TODO Here we must cache the results of `get_data' by
            #      data source name or we could reload many times
            #      the same data...
            if( my $data = $self->report->get_data( $ds_name ) ) {
                $ds_value = $data->[$n_rec]->[$n_col];
            }
            
            $string =~ s/$ds_regex/$ds_value/;
            
        }
        
        # In case row is a scalar, we are into group cell,
        # not data cell rendering.
        if ( ref $row eq 'HASH' ) {
            $string =~ s/\%PAGE\%/$row->{current_page}/;
            $string =~ s/\%PAGES\%/$row->{total_pages}/;
        } else {
            # In case of group headers/footers, $row is a single scalar
            if ( $cell->{delimiter} ) {
                # This assumes the delim is a non-alpha char like |,~,!, etc...
                my $delim = "\\" . $cell->{delimiter}; 
                my $row2 = ( split /$delim/, $row )[ $cell->{index} ];
                $string =~ s/\?/$row2/g;
            } else {
                $string =~ s/\?/$row/g;
            }
        }
        
        # __generationtime member is set at object initialization (parse_options)
        $string =~ s/\%TIME\%/$$self{__generationtime}/;
        
        return ( $string );
        
    }
    
}

1;

=head1 NAME

PDF::ReportWriter

=head1 DESCRIPTION

PDF::ReportWriter is designed to create high-quality business reports, for archiving or printing.

=head1 USAGE

The example below is purely as a reference inside this documentation to give you an idea of what goes
where. It is not intended as a working example - for a working example, see the demo application package,
distributed separately at http://entropy.homelinux.org/axis_not_evil

First we set up the top-level report definition and create a new PDF::ReportWriter object ...

$report = {

  destination        => "/home/dan/my_fantastic_report.pdf",
  paper              => "A4",
  orientation        => "portrait",
  template           => '/home/dan/my_page_template.pdf',
  font_list          => [ "Times" ],
  default_font       => "Times",
  default_font_size  => "10",
  x_margin           => 10 * mm,
  y_margin           => 10 * mm,
  info               => {
                            Author      => "Daniel Kasak",
                            Keywords    => "Fantastic, Amazing, Superb",
                            Subject     => "Stuff",
                            Title       => "My Fantastic Report"
                        }

};

my $pdf = PDF::ReportWriter->new( $report );

Next we define our page setup, with a page header ( we can also put a 'footer' object in here as well )

my $page = {

  header             => [
                                {
                                        percent        => 60,
                                        font_size      => 15,
                                        align          => "left",
                                        text           => "My Fantastic Report"
                                },
                                {
                                        percent        => 40,
                                        align          => "right",
                                        image          => {
                                                                  path          => "/home/dan/fantastic_stuff.png",
                                                                  scale_to_fit  => TRUE
                                                          }
                                }
                         ]

};

Define our fields - which will make up most of the report

my $fields = [

  {
     name               => "Date",                               # 'Date' will appear in field headers
     percent            => 35,                                   # The percentage of X-space the cell will occupy
     align              => "centre",                             # Content will be centred
     colour             => "blue",                               # Text will be blue
     font_size          => 12,                                   # Override the default_font_size with '12' for this cell
     header_colour      => "white"                               # Field headers will be rendered in white
  },
  {
     name               => "Item",
     percent            => 35,
     align              => "centre",
     header_colour      => "white",
  },
  {
     name               => "Appraisal",
     percent            => 30,
     align              => "centre",
     colour_func        => sub { red_if_fantastic(@_); },        # red_if_fantastic() will be called to calculate colour for this cell
     aggregate_function => "count"                               # Items will be counted, and the results stored against this cell
   }
   
];

I've defined a custom colour_func for the 'Appraisal' field, so here's the sub:

sub red_if_fantastic {

     my $data = shift;
     if ( $data eq "Fantastic" ) {
          return "red";
     } else {
          return "black";
     }

}

Define some groups ( or in this case, a single group )

my $groups = [
   
   {
      name           => "DateGroup",                             # Not particularly important - apart from the special group "GrandTotals"
      data_column    => 0,                                       # Which column to group on ( 'Date' in this case )
      header => [
      {
         percent           => 100,
         align             => "right",
         colour            => "white",
         background        => {                                  # Draw a background for this cell ...
                                   {
                                         shape     => "ellipse", # ... a filled ellipse ...
                                         colour    => "blue"     # ... and make it blue
                                   }
                              }
         text              => "Entries for ?"                    # ? will be replaced by the current group value ( ie the date )
      }
      footer => [
      {
         percent           => 70,
         align             => "right",
         text              => "Total entries for ?"
      },
      {
         percent           => 30,
         align             => "centre",
         aggregate_source  => 2                                  # Take figure from field 2 ( which has the aggregate_function on it )
      }
   }
   
];

We need a data array ...

my $data_array = $dbh->selectall_arrayref(
 "select Date, Item, Appraisal from Entries order by Date"
);

Note that you MUST order the data array, as above, if you want to use grouping.
PDF::ReportWriter doesn't do any ordering of data for you.

Now we put everything together ...

my $data = {
   
   background              => {                                  # Set up a default background for all cells ...
                                  border      => "grey"          # ... a grey border
                              },
   fields                  => $fields,
   groups                  => $groups,
   page                    => $page,
   data_array              => $data_array,
   headings                => {                                  # This is where we set up field header properties ( not a perfect idea, I know )
                                  background  => {
                                                     shape     => "box",
                                                     colour    => "darkgrey"
                                                 }
                              }
   
};

... and finally pass this into PDF::ReportWriter

$pdf->render_data( $data );

At this point, we can do something like assemble a *completely* new $data object,
and then run $pdf->render_data( $data ) again, or else we can just finish things off here:

$pdf->save;


=head1 CELL DEFINITIONS

PDF::ReportWriter renders all content the same way - in cells. Each cell is defined by a hash.
A report definition is basically a collection of cells, arranged at various levels in the report.

Each 'level' to be rendered is defined by an array of cells.
ie an array of cells for the data, an array of cells for the group header, and an array of cells for page footers.

Cell spacing is relative. You define a percentage for each cell, and the actual length of the cell is
calculated based on the page dimensions ( in the top-level report definition ).

A cell can have the following attributes

=head2 name

=over 4

The 'name' is used when rendering data headers, which happens whenever a new group or page is started.
It's not used for anything else - data must be arranged in the same order as the cells to 'line up' in
the right place.

You can disable rendering of field headers by setting no_field_headers in your data definition ( ie the
hash that you pass to the render() method ).

=back

=head2 percent

=over 4

The width of the cell, as a percentage of the total available width.
The actual width will depend on the paper definition ( size and orientation )
and the x_margin in your report_definition.

In most cases, a collection of cells should add up to 100%. For multi-line 'rows',
you can continue defining cells beyond 100% width, and these will spill over onto the next line.
See the section on MULTI-LINE ROWS, below.

=back

=head2 x

=over 4

The x position of the cell, expressed in points, where 1 mm = 72/25.4 points.

=back

=head2 y

=over 4

The y position of the cell, expressed in points, where 1 mm = 72/25.4 points.

=back

=head2 font

=over 4

The font to use. In most cases, you would set up a report-wide default_font.
Only use this setting to override the default.

=back

=head2 font_size

=over 4

The font size. Nothing special here...

=back

=head2 bold

=over 4

A boolean flag to indicate whether you want the text rendered in bold or not.

=back

=head2 colour

=over 4

No surprises here either.

=back

=head2 header_colour

=over 4

The colour to use for rendering data headers ( ie field names ).

=back

=head2 header_align

=over 4

The alignment of the data headers ( ie field names ). 
Possible values are "left", "right" and "centre" ( or now "center", also ).

=back

=head2 text

=over 4

The text to display in the cell ( ie if the cell is not rendering data, but static text ).

=back

=head2 wrap_text

=over 4

Turns on wrapping of text that exceeds the width of the cell.

=back

=head2 strip_breaks

=over 4

Strips line breaks out of text.

=back

=head2 image

=over 4

A hash with details of the image to render. See below for details.
If you try to use an image type that is not supported by your installed
version of PDF::API2, your image is skipped, and a warning is printed out.

=back

=head2 colour_func

=over 4

A user-defined sub that returns a colour. Your colour_func will be passed:

=head3 value

=over 4

The current cell value

=back

=head3 row

=over 4

an array reference containing the current row

=back

=head3 options

=over 4

a hash containing the current rendering options:

 {
   current_row          - the current row of data
   row_type             - the current row type (data, group_header, ...)
   current_value        - the current value of this cell
   cell                 - the cell definition ( get x position and width from this )
   cell_counter         - position of the current cell in the row ( 0 .. n - 1 )
   cell_y_border        - the bottom of the cell
   cell_full_height     - the height of the cell
   page                 - the current page ( a PDF::API2 page )
   page_no              - the current page number
 }

=back

Note that prior to version 1.4, we only passed the value.

=back

=head2 background_func

=over 4

A user-defined sub that returns a colour for the cell background. Your background_func will be passed:

=head3 value

=over 4

The current cell value

=back

=head3 row

=over 4

an array reference containing the current row

=back

=head3 options

=over 4

a hash containing the current rendering options:

 {
   current_row          - the current row of data
   row_type             - the current row type (data, group_header, ...)
   current_value        - the current value of this cell
   cell                 - the cell definition ( get x position and width from this )
   cell_counter         - position of the current cell in the row ( 0 .. n - 1 )
   cell_y_border        - the bottom of the cell
   cell_full_height     - the height of the cell
   page                 - the current page ( a PDF::API2 page )
   page_no              - the current page number
 }

=back

=head2 custom_render_func

=over 4

A user-define sub to replace the built-in text / image rendering functions
The sub will receive a hash of options:

 {
   current_row          - the current row of data
   row_type             - the current row type (data, group_header, ...)
   current_value        - the current value of this cell
   cell                 - the cell definition ( get x position and width from this )
   cell_counter         - position of the current cell in the row ( 0 .. n - 1 )
   cell_y_border        - the bottom of the cell
   cell_full_height     - the height of the cell
   page                 - the current page ( a PDF::API2 page )
 }

=back

=head2 align

=over 4

Possible values are "left", "right", "centre" ( or now "center", also ), and "justified"

=back

=head2 aggregate_function

=over 4

Possible values are "sum" and "count". Setting this attribute will make PDF::ReportWriter carry
out the selected function and store the results ( attached to the cell ) for later use in group footers.

=back

=head2 type ( LEGACY )

=over 4

Please see the 'format' key, below, for improved numeric / currency formatting.

This key turns on formatting of data.
The possible values currently are 'currency', 'currency:no_fill' and 'thousands_separated'.

There is also another special value that allows custom formatting of text cells: C<custom:{classname}>.
If you define the cell type as, for example, C<custom:my::formatter::class>, the cell text that
will be output is the return value of the following (pseudo) code:

	my $formatter_object = my::formatter::class->new();
	$formatter_object->format({
		cell    => { ... },                 # Cell object "properties"
		options => { ... },                 # Cell options
		string  => 'Original cell text',    # Cell actual content to be formatted
	});

An example of formatter class is the following:

	package formatter::greeter;
	use strict;

	sub new {
		bless \my $self
	}
	sub format {
		my $self = $_[0];
		my $args = $_[1];

		return 'Hello, ' . $args->{string};
	}

This class will greet anything it is specified in its cell.
Useful, eh?!  :-)

=back

=head2 format

=over 4

This key is a hash that controls numeric and currency formatting. Possible keys are:

 {
   currency             - a BOOLEAN that causes all value to have a dollar sign prepeneded to them
   decimal_places       - an INT that indicates how many decimal places to round values to
   decimal_fill         - a BOOLEAN that causes all decimal values to be filled to decimal_places places
   separate_thousands   - a BOOLEAN that turns on thousands separating ( ie with commas )
   null_if_zero         - a BOOLEAN that causes zero amounts to render nothing ( NULL )
 }

=back

=head2 background

=over 4

A hash containing details on how to render the background of the cell. See below.

=back

=head1 IMAGES

You can define images in any cell ( data, or group header / footer ).
The default behaviour is to render the image at its original size.
If the image won't fit horizontally, it is scaled down until it will.
Images can be aligned in the same way as other fields, with the 'align' key.

The images hash has the following keys:

=head2 path

=over 4

The full path to the image to render ( currently only supports png and jpg ).
You should either set the path, or set the 'dynamic' flag, below.

=back

=head2 dynamic

=over 4

A boolean flag to indicate that the full path to the image to use will be in the data array.
You should either set a hard-coded image path ( above ), or set this flag on.

=back

=head2 scale_to_fit

=over 4

A boolean value, indicating whether the image should be scaled to fit the current cell or not.
Whether this is set or not, scaling will still occur if the image is too wide for the cell.

=back

=head2 height

=over 4

You can hard-code a height value if you like. The image will be scaled to the given height value,
to the extent that it still fits length-wise in the cell.

=back

=head2 buffer

=over 4

A *minimum* white-space buffer ( in points ) to wrap the image in. This defaults to 1, which
ensures that the image doesn't render over part of the cell borders ( which looks bad ).

=back

=head1 BACKGROUNDS

You can define a background for any cell, including normal fields, group header & footers, etc.
For data headers ONLY, you must ( currently ) set them up per data set, instead of per field. In this case,
you add the background key to the 'headings' hash in the main data hash.

The background hash has the following keys:

=head2 shape

=over 4

Current options are 'box' or 'ellipse'. 'ellipse' is good for group headers.
'box' is good for data headers or 'normal' cell backgrounds. If you use an 'ellipse',
it tends to look better if the text is centred. More shapes are needed.
A 'round_box', with nice rounded edges, would be great. Send patches. 

=back

=head2 colour

=over 4

The colour to use to fill the background's shape. Keep in mind with data headers ( the automatic
headers that appear at the top of each data set ), that you set the *foreground* colour via the
field's 'header_colour' key, as there are ( currently ) no explicit definitions for data headers.

=back

=head2 border

=over 4

The colour ( if any ) to use to render the cell's border. If this is set, the border will be a rectangle,
around the very outside of the cell. You can have a shaped background and a border rendererd in the
same cell.

=over 4

=head2 borders

If you have set the border key ( above ), you can also define which borders to render by setting
the borders key with the 1st letter(s) of the border to render, from the possible list of:

 l   ( left border )
 r   ( right border )
 t   ( top border )
 b   ( bottom border )
 all ( all borders ) - this is also the default if no 'borders' key is encountered

eg you would set borders = "tlr" to have all borders except the bottom ( b ) border

Upper-case letters will also work.

=back

=back

=head1 BARCODES

You can define barcodes in any cell ( data, or group header / footer ).
The default barcode type is B<code128>. The available types are B<code128> and
B<code39>.

The barcode hash has the following keys:

=over 4

=item type

Type of the barcode, either B<code128> or B<code39>. Support for other barcode types
should be fairly simple, but currently is not there. No default. 

=item x, y

As in text cells.

=item scale

Defines a zoom scale for barcode, where 1.0 means scale 1:1.

=item align

Defines the alignment of the barcode object. Should be C<left> (or C<l>),
C<center> (or C<c>), or C<right> (or C<r>). This should work as expected either
if you specify absolute x,y coordinates or not.

=item font_size

Defines the font size of the clear text that appears below the bars.
If not present, takes report C<default_font_size> property.

=item font

Defines the font face of the clear text that appears below the bars.
If not present, takes report C<default_font> property.

=item zone

Regulates the height of the barcode lines.

=item upper_mending_zone, lower_mending_zone

Space below and above barcode bars? I tried experimenting a bit, but
didn't properly understand what C<upper_mending_zone> does.
C<lower_mending_zone> is the height of the barcode extensions toward the
lower end, where clear text is printed.
I don't know how to explain these better...

=item quiet_zone

Empty space around the barcode bars? Try to experiment yourself.

=back

=head1 GROUP DEFINITIONS

Grouping is achieved by defining a column in the data array to use as a group value. When a new group
value is encountered, a group footer ( if defined ) is rendered, and a new group header ( if defined )
is rendered. At present, the simple group aggregate functions 'count' and 'sum' are supported - see the
cell definition section for details on how to chose a column to perform aggregate functions on, and below
for how to retrieve the aggregate value in a footer. You can perform one aggregate function on each column
in your data array.

As of version 0.9, support has been added for splitting data from a single field ( ie the group value
from the data_column above ) into multiple cells. To do this, simply pack your data into the column
identified by data_column, and separate the fields with a delimiter. Then in your group definition,
set up the cells with the special keys 'delimiter' and 'index' ( see below ) to identify how to
delimit the data, and which column to use for the cell once the data is split. Many thanks to
Bill Hess for this patch :)

Groups have the following attributes:

=head2 name

=over 4

The name is used to identify which value to use in rendering aggregate functions ( see aggregate_source, below ).
Also, a special name, "GrandTotals" will cause PDF::ReportWriter to fetch *Grand* totals instead of group totals.

=back

=head2 page_break

=over 4

Set this to TRUE if you want to cause a page break when entering a new group value.

=back

=head2 data_column

=over 4

The data_column refers to the column ( starting at 0 ) of the data_array that you want to group on.

=back

=head2 reprinting_header

=over 4

If this is set, the group header will be reprinted on each new page

=back

=head2 header_upper_buffer / header_lower_buffer / footer_upper_buffer / footer_lower_buffer

=over 4

These 4 keys set the respective buffers ( ie whitespace ) that separates the group
headers / footers from things above ( upper ) and below ( lower ) them. If you don't specify any
buffers, default values will be set to emulate legacy behaviour.

=back

=head2 header / footer

=over 4

Group headers and footers are defined in a similar way to field definitions ( and rendered by the same code ).
The difference is that the cell definition is contained in the 'header' and 'footer' hashes, ie the header and
footer hashes resemble a field hash. Consequently, most attributes that work for field cells also work for
group cells. Additional attributes in the header and footer hashes are:

=back

=head2 aggregate_source ( footers only )

=over 4

This is used to indicate which column to retrieve the results of an aggregate_function from
( see cell definition section ).

=back

=head2 delimiter ( headers only )

=over 4

This optional key is used in conjunction with the 'index' key ( below ) and defines the
delimiter character used to separate 'fields' in a single column of data.

=back

=head2 index ( headers only )

=over 4

This option key is used inconjunction with the 'delimiter' key ( above ), and defines the
'column' inside the delimited data column to use for the current cell.

=back

=head1 REPORT DEFINITION

Possible attributes for the report defintion are:

=head2 destination

=over 4

The path to the destination ( the pdf that you want to create ).

=back

=head2 paper

=over 4

Supported types are:

=over 4

 - A4
 - Letter
 - bsize
 - legal

=back

=back

=head2 orientation

=over 4

portrait or landscape

=back

=head2 template

=over 4

Path to a single page PDF file to be used as template for new pages of the report.
If PDF is multipage, only first page will be extracted and used.
All content in PDF template will be included in every page of the final report.
Be sure to avoid overlapping PDF template content and report content.

=back

=head2 font_list

=over 4

An array of font names ( from the corefonts supported by PDF::API2 ) to set up.
When you include a font 'family', a range of fonts ( roman, italic, bold, etc ) are created.

=back

=head2 default_font

=over 4

The name of the font type ( from the above list ) to use as a default ( ie if one isn't set up for a cell ).

=back

=head2 default_font_size

=over 4

The default font size to use if one isn't set up for a cell.
This is no longer required and defaults to 12 if one is not given.

=back

=head2 x_margin

=over 4

The amount of space ( left and right ) to leave as a margin for the report.

=back

=head2 y_margin

=over 4

The amount of space ( top and bottom ) to leave as a margin for the report.

=back

=head1 DATA DEFINITION

The data definition wraps up most of the previous definitions, apart from the report definition.
You can now safely replace the entire data definition after a render() operation, allowing you
to define different 'sections' of a report. After replacing the data definition, you simply
render() with a new data array.

Attributes for the data definition:

=head2 cell_borders

=over 4

Whether to render cell borders or not. This is a legacy option - not that there's any
pressing need to remove it - but this is a precursor to background->{border} support,
which can be defined per-cell. Setting cell_borders in the data definition will cause
all data cells to be filled out with: background->{border} set to grey.

=back

=head2 upper_buffer / lower_buffer

=over 4

These 2 keys set the respective buffers ( ie whitespace ) that separates each row of data
from things above ( upper ) and below ( lower ) them. If you don't specify any
buffers, default values of zero will be set to emulate legacy behaviour.

=back

=head2 no_field_headers

=over 4

Set to disable rendering field headers when beginning a new page or group.

=back

=head2 fields

=over 4

This is your field definition hash, from above.

=back

=head2 groups

=over 4

This is your group definition hash, from above.

=back

=head2 data_array

=over 4

This is the data to render.
You *MUST* sort the data yourself. If you are grouping by A, then B and you want all data
sorted by C, then make sure you sort by A, B, C. We currently don't do *any* sorting of data,
as I only intended this module to be used in conjunction with a database server, and database
servers are perfect for sorting data :)

=back

=head2 page

=over 4

This is a hash describing page headers and footers - see below.

=back

=head1 PAGE DEFINITION

The page definition is a hash describing page headers and footers. Possible keys are:

=head2 header

=head2 footer

Each of these keys is an array of cell definitions. Unique to the page *footer* is the ability
to define the following special tags:

=over 4

%TIME%

%PAGE%

%PAGES%

=back

These will be replaced with the relevant data when rendered.

If you don't specify a page footer, one will be supplied for you. This is to provide maximum
compatibility with previous versions, which had page footers hard-coded. If you want to supress
this behaviour, then set a value for $self->{data}->{page}->{footerless}

=head1 MULTI-LINE ROWS

=over 4

You can define 'multi-line' rows of cell definitions by simply appending all subsequent lines
to the array of cell definitions. When PDF::ReportWriter sees a cell with a percentage that would
push the combined percentage beyond 100%, a new-line is assumed.

=back

=back

=head1 METHODS

=head2 new ( report_definition )

=over 4

Object constructor. Pass the report definition in.

=back

=head2 render_data ( data_definition )

=over 4

Renders the data passed in.

You can call 'render_data' as many times as you want, with different data and definitions.
If you want do call render_data multiple times, though, be aware that you will have to destroy
$report->{data}->{field_headers} if you expect new field headers to be automatically generated
from your cells ( ie if you don't provide your own field_headers, which is probably normally
the case ). Otherwise if you don't destroy $report->{data}->{field_headers} and you don't provide
your own, you will get the field headers from the last render_data() operation.

=back

=head2 render_report ( xml [, data ] )

=over 4

Should be used when dealing with xml format reports. One call to rule them all.
The first argument can be either an xml filename or a C<PDF::ReportWriter::Report>
object. The 2nd argument is the real data to be used in your report.
Example of usage for first case (xml file):

	my $rw = PDF::ReportWriter->new();
	my @data = (
		[2004, 'Income',               1000.000 ],
		[2004, 'Expenses',              500.000 ],
		[2005, 'Income',               5000.000 ],
		[2005, 'Expenses',              600.000 ],
		[2006, 'Income (projection)',  9999.000 ],
		[2006, 'Expenses (projection),  900.000 ],
	);
	$rw->render_report('./account.xml', \@data);
	
	# Save to disk
	$rw->save();

	# or get a scalar with all pdf document
	my $pdf_doc = $rw->stringify();

For an example of xml report file, take a look at C<examples>
folder in the PDF::ReportWriter distribution or to
C<PDF::ReportWriter::Examples> documentation.

The alternative form allows for more flexibility. You can pass a
C<PDF::ReportWriter::Report> basic object with a report profile
already loaded. Example:

	my $rw = PDF::ReportWriter->new();
	my $rp = PDF::ReportWriter::Report->new('./account.xml');
	# ... Assume @data as before ...
	$rw->render_report($rp, \@data);
	$rw->save();

If you desire the maximum flexibility, you can also pass B<any> object
in the world that supports C<load()> and C<get_data()> methods, where
C<load()> should return a B<complete report profile> (TO BE CONTINUED),
and C<get_data()> should return an arrayref with all actual records that
you want your report to include, as returned by DBI's C<selectall_arrayref()>
method.

As with C<render_data>, you can call C<render_report> as many times as you want.
The PDF file will grow as necessary. There is only one problem in rendering
of header sections when re-calling C<render_report>.

=back

=head2 fetch_group_results( { cell => "cell_name", group => "group_name" } )

=over 4

This is a convenience function that allows you to retrieve current aggregate values.
Pass a hash with the items 'cell' ( the name of the cell with the aggregate function ) and
'group' ( the group level you want results from ). A good place to use this function is in
conjunction with a cell's custom_render_func(). For example, you might create a
custom_render_func to do some calculations on running totals, and use fetch_group_results() to
get access to those running totals.

=back

=head2 new_page

=over 4

Creates a new page, which in turn calls ->page_template ( see below ).

=back

=head2 page_template ( [ path_to_template ] )

=over 4

This function creates a new page ( and is in fact called by ->new_page ).<
If called with no arguements, it will either use default template, or if there is none,
it will simply create a blank page. Alternatively, you can pass it the path to a PDF
to use as a template for the new page ( the 1st page of the PDF that you pass will
be used ).

=back
 
=head2 save

=over 4

Saves the pdf file ( in the location specified in the report definition ).

=back

=head2 saveas ( newfile )

=over 4

Saves the pdf file in the location specified by C<newfile> string and
overrides default report C<destination> property.

=back

=head2 stringify

=over 4

Returns the pdf document as a scalar.

=back

=head2 print ( options )

=over 4

Tries to print the report pdf file to a CUPS print queue. For now, it only works
with CUPS, though you can supply several options to drive the print job as you like.
Allowed options, to be specified as an hash reference, with their default values,
are the following:

=over 4

=item command

The command to be launched to spool the pdf report (C</usr/bin/lpr.cups>).

=item printer

Name of CUPS printer to print to (no default). If not specified,
takes your system default printer.

=item tempdir

Temporary directory where to put the spool file (C</tmp>).

=item unlink

If true, deletes the temporary spool file (C<true>).

=back

=back

=head1 EXAMPLES

=over 4

Check out the C<examples> folder in the main PDF::ReportWriter distribution that
contains a simple demonstration of results that can be achieved.

=back

=head1 AUTHORS

=over 4

 Dan <dan@entropy.homelinux.org>
 Cosimo Streppone <cosimo@cpan.org>

=back

=head1 BUGS

=over 4

I think you must be mistaken.

=back

=head1 ISSUES

=over 4

In the last release of PDF::ReportWriter, I complained bitterly about printing PDFs from Linux.
I am very happy to be able to say that this situation has improved significantly. Using the
latest versions of evince and poppler ( v0.5.1 ), I am now getting *perfect* results when
printing. If you are having issues printing, I suggest updating to the above.

=back

=head1 Other cool things you should know about:

=over 4

This module is part of an umbrella project, 'Axis Not Evil', which aims to make
Rapid Application Development of database apps using open-source tools a reality.
The project includes:

 Gtk2::Ex::DBI                 - forms
 Gtk2::Ex::Datasheet::DBI      - datasheets
 PDF::ReportWriter             - reports

All the above modules are available via cpan, or for more information, screenshots, etc, see:
http://entropy.homelinux.org/axis

=back

=head1 Crank ON!

=cut
