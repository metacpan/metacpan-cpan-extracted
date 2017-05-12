package Spreadsheet::CSV;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Fcntl();
use Spreadsheet::ParseExcel();
use Text::CSV_XS();
use Archive::Zip();
use XML::Parser();
use English qw( -no_match_vars );
use Compress::Zlib();
use Carp();
use IO::File();
use charnames ':full';

sub _MAGIC_NUMBER_BUFFER_SIZE { return 2 }      # for .zip and .gz files
sub _GRANDPARENT_INDEX        { return -2 }
sub _PARENT_INDEX             { return -1 }
sub _EXCEL_COLUMN_RADIX       { return 26 }
sub _BUFFER_SIZE              { return 4096 }

our $VERSION = '0.20';

sub new {
    my ( $class, $params ) = @_;
    my $self = {};
    if ( defined $params->{worksheet_name} ) {
        $self->{worksheet_name} = $params->{worksheet_name};
    }
    elsif ( defined $params->{worksheet_number} ) {
        if ( $params->{worksheet_number} =~ /^\d+$/smx ) {
            $self->{worksheet_number} = $params->{worksheet_number};
        }
        else {
            Carp::croak('worksheet_number parameter is not a number');
        }
    }
    else {
        $self->{worksheet_number} = 1;
    }
    delete $params->{worksheet_number};
    delete $params->{worksheet_name};
    $self->{csv} = Text::CSV_XS->new( { binary => 1 } );
    bless $self, $class;
    return $self;
}

sub getline {
    my ( $self, $handle ) = @_;
    if ( ( defined $self->{handle} ) && ( $self->{handle} eq $handle ) ) {
    }
    else {
        $self->{eof} = q[];
        if ( $self->_setup_handle($handle) ) {
        }
        else {
            return;
        }
    }
    my $row = $self->{cells}->[ $self->{row_index}++ ];
    if ( !defined $row ) {
        $self->{eof} = 1;
    }
    return $row;
}

sub eof {
    my ($self) = @_;
    return $self->{eof};
}

sub error_diag {
    my ($self) = @_;
    return $self->{_ERROR_DIAG};
}

sub _stuff_input_into_tmp_file {
    my ( $self, $input_handle ) = @_;
    seek $input_handle, 0, Fcntl::SEEK_SET()
      or
      Carp::croak("Failed to seek to start of filehandle:$EXTENDED_OS_ERROR");
    my $handle = IO::File->new_tmpfile()
      or Carp::croak("Failed to create temporary file:$EXTENDED_OS_ERROR");
    my $result;
    while ( $result = read $input_handle, my $buffer, _BUFFER_SIZE() ) {
        print {$handle} $buffer
          or
          Carp::croak("Failed to write to temporary file:$EXTENDED_OS_ERROR");
    }
    defined $result
      or Carp::croak "Failed to read from input file:$EXTENDED_OS_ERROR";
    seek $handle, 0, Fcntl::SEEK_SET()
      or
      Carp::croak("Failed to seek to start of filehandle:$EXTENDED_OS_ERROR");
    seek $input_handle, 0, Fcntl::SEEK_SET()
      or
      Carp::croak("Failed to seek to start of filehandle:$EXTENDED_OS_ERROR");
    return $handle;
}

sub _xls_parser {
    my ($self) = @_;
    my $parser = Spreadsheet::ParseExcel->new(
        CellHandler => sub {

            my ( $workbook, $sheet_index, $row, $col, $cell ) = @_;

            my $worksheet         = $workbook->worksheet($sheet_index);
            my $process_worksheet = 0;
            if (   ( defined $self->{worksheet_name} )
                && ( $self->{worksheet_name} eq $worksheet->get_name() ) )
            {
                $self->{xls_worksheet_found} = 1;
                $process_worksheet = 1;
            }
            elsif (( $self->{worksheet_number} )
                && ( ( $self->{worksheet_number} - 1 ) == $sheet_index ) )
            {
                $self->{xls_worksheet_found} = 1;
                $process_worksheet = 1;
            }
            if ($process_worksheet) {
                $self->{cells}->[$row]->[$col] = $cell->{_Value};
                $self->{cells}->[$row]->[$col] =~
                  s/\N{CARRIAGE RETURN}\N{LINE FEED}/\N{LINE FEED}/smxg;
                $self->{cells}->[$row]->[$col] =~
                  s/\N{LINE FEED}\N{CARRIAGE RETURN}/\N{LINE FEED}/smxg;
            }
        },
        NotSetCell => 1,
    );
    return $parser;
}

sub _setup_handle {
    my ( $self, $input_handle ) = @_;
    my $magic_bytes = $self->_sniff_magic_bytes($input_handle);
    my $handle      = $self->_stuff_input_into_tmp_file($input_handle);
    my $parser      = $self->_xls_parser();
    if ( $magic_bytes =~ /^PK/smx ) {
        if ( defined $self->_setup_zip($handle) ) {
            $self->{handle} = $input_handle;
        }
        else {
            return;
        }
    }
    elsif ( $magic_bytes =~ /^\037\213/smx ) {
        if ( $self->_setup_compress_zlib_spreadsheet($handle) ) {
            $self->{handle} = $input_handle;
        }
        else {
            return;
        }
    }
    elsif ( ( defined $parser ) && ( my $workbook = $parser->parse($handle) ) )
    {
        if ( $self->_setup_xls_spreadsheet($workbook) ) {
            $self->{handle} = $input_handle;
        }
        elsif ( !$self->{xls_worksheet_found} ) {
            $self->{_ERROR_DIAG} = 'ENOENT - Worksheet '
              . (
                defined $self->{worksheet_name}
                ? $self->{worksheet_name}
                : $self->{worksheet_number}
              ) . ' not found';
            return;
        }
        else {
            return;
        }
    }
    else {
        $handle = $self->_stuff_input_into_tmp_file($input_handle);
        if (!$self->_check_file_utf8($input_handle)) {
		    $self->{_ERROR_DIAG} = 'CSV - Failed to parse as CSV';
		    return;
	}
        binmode $handle, ':encoding(UTF-8)';
        $self->{cells} = [];
        my $parsed_ok;
        eval {
            while ( my $row = $self->{csv}->getline($handle) ) {
                push @{ $self->{cells} }, $row;
            }
            $parsed_ok = 1;
        } or do {
            $self->{_ERROR_DIAG} = 'CSV - Failed to parse as CSV';
            return;
        };
        if ( ($parsed_ok) && ( $self->{csv}->eof() ) ) {
            $self->{content_type} = 'text/csv';      # according to RFC 4180
            $self->{type}         = 'csv';
            $self->{row_index}    = 0;
            $self->{handle}       = $input_handle;
        }
        else {
            $self->{_ERROR_DIAG} = 'CSV - Failed to parse as CSV:'
              . ( 0 + $self->{csv}->error_diag() );
            return;
        }
    }
    return $self;
}

sub _check_file_utf8 {
	my ($self, $handle) = @_;
	while(my $line = <$handle>) {
		if (!utf8::decode(my $text = $line)) {
			return;
		}
	}
	return 1;
}

sub _setup_zip {
    my ( $self, $handle ) = @_;
    my $zip = Archive::Zip->new();
    Archive::Zip::setErrorHandler( sub { chomp $_[0]; die "$_[0]\n"; } );
    my $result;
    my $zip_error = 'Corrupt ZIP file';
    eval { $result = $zip->readFromFileHandle($handle); }
      or do { chomp $EVAL_ERROR; $zip_error = $EVAL_ERROR };
    if ( ( defined $result ) && ( $result == Archive::Zip::AZ_OK() ) ) {
    }
    else {
        $self->{_ERROR_DIAG} = "ZIP - $zip_error";
        return;
    }

    if ( $self->_parse_archive_zip_spreadsheet($zip) ) {
        return 1;
    }
    else {
        return;
    }
}

sub _sniff_magic_bytes {
    my ( $self, $handle ) = @_;
    seek $handle, 0, Fcntl::SEEK_SET()
      or
      Carp::croak("Failed to seek to start of filehandle:$EXTENDED_OS_ERROR");
    defined read $handle, my $magic_bytes, _MAGIC_NUMBER_BUFFER_SIZE()
      or Carp::croak("Failed to read from filehandle:$EXTENDED_OS_ERROR");
    seek $handle, 0, Fcntl::SEEK_SET()
      or
      Carp::croak("Failed to seek to start of filehandle:$EXTENDED_OS_ERROR");
    return $magic_bytes;
}

sub _handle_workbook_type_zips {
    my ( $self, $zip ) = @_;
    my $shared_strings = $self->_xlsx_shared_strings($zip);
    if ( !defined $shared_strings ) {
        return;
    }
    my $worksheet_path = $self->_xlsx_worksheet_path($zip);
    if (   ( defined $worksheet_path )
        && ( my $worksheet = $zip->memberNamed($worksheet_path) ) )
    {
        $self->{'content_type'} =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
        $self->{type}      = 'xlsx';
        $self->{zip}       = $zip;
        $self->{row_index} = 0;
        my $content = $worksheet->contents();
        my $cells =
          $self->_xlsx_cells( $content, $shared_strings, $worksheet_path );
        if ( defined $cells ) {
            $self->{cells} = $cells;
            return 1;
        }
        else {
            return;
        }
    }
    elsif ( defined $worksheet_path ) {
        $self->{_ERROR_DIAG} =
          q[ZIP - Missing '] . $worksheet_path . q[' file in .xlsx file];
        return;
    }
    else {
        return;
    }
}

sub _handle_mimetype_type_zips {
    my ( $self, $zip ) = @_;
    my $member = $zip->memberNamed('mimetype');
    my $content_type;
    delete $self->{type};
    if ( defined $member ) {
        $content_type = $member->contents();
        if ( $content_type eq 'application/vnd.oasis.opendocument.spreadsheet' )
        {
            $self->{type} = 'ods';
        }
        elsif ( $content_type eq 'application/vnd.sun.xml.calc' ) {
            $self->{type} = 'sxc';
        }
        elsif ( $content_type eq 'application/x-kspread' ) {
            $self->{type} = 'ksp';
        }
    }
    if ( ( $self->{type} ) && ( $self->{type} eq 'ksp' ) ) {
        $self->{content_type} = $content_type;
        my $maindoc_member = $zip->memberNamed('maindoc.xml');
        if ( defined $maindoc_member ) {
            $self->{zip}       = $zip;
            $self->{row_index} = 0;
            my $maindoc_data = $maindoc_member->contents();
            my $cells        = $self->_ksp_cells($maindoc_data);
            if ( defined $cells ) {
                $self->{cells} = $cells;
                return 1;
            }
            else {
                return;
            }
        }
        else {
            $self->{_ERROR_DIAG} =
                q[ZIP - Missing 'content.xml' file in .]
              . ( lc $self->{type} )
              . q[ file];
            return;
        }
    }
    elsif ( $self->{type} ) {
        $self->{content_type} = $content_type;
        my $content_member = $zip->memberNamed('content.xml');
        if ( defined $content_member ) {
            $self->{zip}       = $zip;
            $self->{row_index} = 0;
            my $content_data = $content_member->contents();
            my $cells        = $self->_ods_cells($content_data);
            if ( defined $cells ) {
                $self->{cells} = $cells;
                return 1;
            }
            else {
                return;
            }
        }
        else {
            $self->{_ERROR_DIAG} =
                q[ZIP - Missing 'content.xml' file in .]
              . ( lc $self->{type} )
              . q[ file];
            return;
        }
    }
    else {
        $self->{_ERROR_DIAG} =
q[ZIP - mimetype file does not contain any known MIME Types in OpenOffice document];
        return;
    }
}

sub _parse_archive_zip_spreadsheet {
    my ( $self, $zip ) = @_;
    if ( $zip->memberNamed('xl/workbook.xml') ) {
        if ( !defined $self->_handle_workbook_type_zips($zip) ) {
            return;
        }
    }
    elsif ( $zip->memberNamed('mimetype') ) {
        if ( !defined $self->_handle_mimetype_type_zips($zip) ) {
            return;
        }
    }
    else {
        $self->{_ERROR_DIAG} =
          q[ZIP - Missing any identifiable spreadsheet file in ZIP archive];
        return;
    }
    return 1;
}

sub _setup_compress_zlib_spreadsheet {
    my ( $self, $handle ) = @_;
    seek $handle, 0, Fcntl::SEEK_SET()
      or
      Carp::croak("Failed to seek to start of filehandle:$EXTENDED_OS_ERROR");

    my $contents;
    my $gzip_error = 'Corrupt GZIP';
    my $result     = 0;
    eval {
        my $gz = Compress::Zlib::gzopen( $handle, 'rb' )
          or die "Cannot open handle: $Compress::Zlib::gzerrno\n";

        while ( $gz->gzread( my $uncompressed ) > 0 ) {
            $contents .= $uncompressed;
        }
        if ( $gz->gzerror() != Compress::Zlib::Z_STREAM_END() ) {
            die "Failed to read from handle:$Compress::Zlib::gzerrno\n";
        }
        $gz->gzclose()
          and die "Failed to close compression:$Compress::Zlib::gzerrno\n";
        $result = 1;
    } or do {
        chomp $EVAL_ERROR;
        if ($EVAL_ERROR) {
            $gzip_error = $EVAL_ERROR;
        }
    };
    if ( $result == 0 ) {
        $self->{_ERROR_DIAG} = q[GZIP - ] . $gzip_error;
        return;
    }
    $self->{content_type} = 'application/x-gnumeric';
    $self->{type}         = 'gnumeric';
    $self->{row_index}    = 0;
    my $cells = $self->_gnumeric_cells($contents);
    if ( defined $cells ) {
        $self->{cells} = $cells;
    }
    else {
        return;
    }
    return 1;
}

sub _setup_xls_spreadsheet {
    my ( $self, $workbook ) = @_;
    my $worksheet;
    if ( defined $self->{worksheet_name} ) {
        $worksheet = $workbook->worksheet( $self->{worksheet_name} );
    }
    elsif ( $self->{worksheet_number} ) {
        $worksheet = $workbook->worksheet( $self->{worksheet_number} - 1 );
    }
    if ( !defined $worksheet ) {
        return;
    }
    $self->{content_type} = 'application/vnd.ms-excel';
    $self->{type}         = 'xls';
    $self->{row_index}    = 0;
    return 1;
}

sub _process_worksheet {
    my ( $self, $current_worksheet_name, $current_worksheet_index ) = @_;
    my $process_worksheet = 0;
    if (   ( defined $self->{worksheet_name} )
        && ( $self->{worksheet_name} eq $current_worksheet_name ) )
    {
        $process_worksheet = 1;
    }
    elsif (( $self->{worksheet_number} )
        && ( ( $self->{worksheet_number} - 1 ) == $current_worksheet_index ) )
    {
        $process_worksheet = 1;
    }
    return $process_worksheet;
}

sub _ksp_cells {
    my ( $self, $maindoc_content ) = @_;
    my $cells;
    my $current_worksheet_name;
    my $parameter_stack;
    my $element_stack;
    my $worksheet_count;
    my $process_worksheet = 0;
    my $xml               = XML::Parser->new(
        Handlers => {
            Entity => sub {
                die
"XML Entities have been detected and rejected in the XML, due to security concerns\n";
            },
            Start => sub {
                my ( $expat, $element_name, %element_parameters ) = @_;
                push @{$element_stack},   $element_name;
                push @{$parameter_stack}, \%element_parameters;
                if ( $element_name eq 'table' ) {
                    if ( defined $worksheet_count ) {
                        $worksheet_count += 1;
                    }
                    else {
                        $worksheet_count = 0;
                    }
                    $process_worksheet =
                      $self->_process_worksheet( $element_parameters{name},
                        $worksheet_count );
                }
            },
            End => sub {
                my ( $expat, $element_name ) = @_;
                pop @{$parameter_stack};
                if ( $element_name ne pop @{$element_stack} ) {
                    Carp::croak(
                        'Internal confusion in processing XML elements');
                }
            },
            Char => sub {
                my ( $expat, $content ) = @_;
                if ($process_worksheet) {
                    if ( ( defined $element_stack->[ _GRANDPARENT_INDEX() ] )
                        && (
                            $element_stack->[ _GRANDPARENT_INDEX() ] eq 'cell' )
                        && ( $element_stack->[ _PARENT_INDEX() ] eq 'text' ) )
                    {
                        $cells->[ $parameter_stack->[ _GRANDPARENT_INDEX() ]
                          ->{row} - 1 ]
                          ->[ $parameter_stack->[ _GRANDPARENT_INDEX() ]
                          ->{column} - 1 ] .= $content;
                    }
                }
              }
        }
    );
    eval { $xml->parse($maindoc_content); } or do {
        chomp $EVAL_ERROR;
        $EVAL_ERROR =~ s/^\s*//smx;
        $self->{_ERROR_DIAG} = "XML - Invalid XML in maindoc.xml:$EVAL_ERROR";
        return;
    };
    if ( defined $cells ) {
        return $cells;
    }
    else {
        $self->{_ERROR_DIAG} = 'ENOENT - Worksheet '
          . (
            defined $self->{worksheet_name}
            ? $self->{worksheet_name}
            : $self->{worksheet_number}
          ) . ' not found';
        return;
    }
}

sub _ods_cells {
    my ( $self, $ods_content ) = @_;
    my $cells;
    my $current_row;
    my $current_column_number;
    my $element_stack;
    my $process_worksheet = 0;
    my $worksheet_count;
    my $xml = XML::Parser->new(
        Handlers => {
            Entity => sub {
                die
"XML Entities have been detected and rejected in the XML, due to security concerns\n";
            },
            Start => sub {
                my ( $expat, $element_name, %element_parameters ) = @_;
                push @{$element_stack}, $element_name;
                my ( $prefix, $suffix ) = split /:/smx, $element_name;
                if ( $prefix eq 'table' ) {
                    if ( $suffix eq 'table-row' ) {
                        $current_row           = [];
                        $current_column_number = 0 - 1;
                    }
                    elsif ( $suffix eq 'table' ) {
                        if ( defined $worksheet_count ) {
                            $worksheet_count += 1;
                        }
                        else {
                            $worksheet_count = 0;
                        }
                        $process_worksheet =
                          $self->_process_worksheet(
                            $element_parameters{'table:name'},
                            $worksheet_count );
                    }
                    elsif ( $suffix eq 'table-cell' ) {
                        $current_column_number += 1;
                    }
                }
                elsif ( $prefix eq 'text' ) {
                    if ( $suffix eq 'p' ) {
                        if ( ( defined $current_row )
                            && (
                                defined $current_row->[$current_column_number] )
                          )
                        {
                            $current_row->[$current_column_number] .= "\n";
                        }
                    }
                    elsif ( $suffix eq 's' ) {
                        if ( ( defined $current_row )
                            && (
                                defined $current_row->[$current_column_number] )
                          )
                        {
                            $current_row->[$current_column_number] .= q[ ];
                        }
                    }
                }
            },
            End => sub {
                my ( $expat, $element_name ) = @_;
                if ( $element_name ne pop @{$element_stack} ) {
                    Carp::croak(
                        'Internal confusion in processing XML elements');
                }
                if ( $element_name eq 'table:table-row' ) {
                    if ( @{$current_row} ) {
                        push @{$cells}, $current_row;
                    }
                }
                elsif ( $element_name eq 'table:table' ) {
                    $process_worksheet = 0;
                }
            },
            Char => sub {
                my ( $expat, $content ) = @_;
                if ($process_worksheet) {
                    if ( $element_stack->[_PARENT_INDEX] eq 'text:p' ) {
                        if ( $element_stack->[ _GRANDPARENT_INDEX() ] eq
                            'table:table-cell' )
                        {
                            if (
                                defined $current_row->[$current_column_number] )
                            {
                                $current_row->[$current_column_number] .=
                                  $content;
                            }
                            else {
                                $current_row->[$current_column_number] =
                                  $content;
                            }
                        }
                    }
                }
              }
        }
    );
    eval { $xml->parse($ods_content); } or do {
        chomp $EVAL_ERROR;
        $EVAL_ERROR =~ s/^\s*//smx;
        $self->{_ERROR_DIAG} = "XML - Invalid XML in content.xml:$EVAL_ERROR";
        return;
    };
    if ( defined $cells ) {
        return $cells;
    }
    else {
        $self->{_ERROR_DIAG} = 'ENOENT - Worksheet '
          . (
            defined $self->{worksheet_name}
            ? $self->{worksheet_name}
            : $self->{worksheet_number}
          ) . ' not found';
        return;
    }
}

sub _gnumeric_cells {
    my ( $self, $gnumeric_content ) = @_;
    my $cells;
    my $current_row_number;
    my $current_column_number;
    my $current_worksheet_name;
    my $current_sheet_cells;
    my $element_stack;
    my $process_worksheet = 0;
    my $worksheet_count;
    my $xml = XML::Parser->new(
        Handlers => {
            Entity => sub {
                die
"XML Entities have been detected and rejected in the XML, due to security concerns\n";
            },
            Start => sub {
                my ( $expat, $element_name, %element_parameters ) = @_;
                push @{$element_stack}, $element_name;
                if ( $element_name eq 'gnm:Cell' ) {
                    $current_row_number    = $element_parameters{Row};
                    $current_column_number = $element_parameters{Col};
                }
                elsif ( $element_name eq 'gnm:Sheet' ) {
                    $current_sheet_cells = [];
                }
            },
            End => sub {
                my ( $expat, $element_name ) = @_;
                if ( $element_name ne pop @{$element_stack} ) {
                    Carp::croak(
                        'Internal confusion in processing XML elements');
                }
                elsif ( $element_name eq 'gnm:Sheet' ) {
                    if ( defined $worksheet_count ) {
                        $worksheet_count += 1;
                    }
                    else {
                        $worksheet_count = 0;
                    }
                    if (
                        $self->_process_worksheet(
                            $current_worksheet_name, $worksheet_count
                        )
                      )
                    {
                        $cells = $current_sheet_cells;
                    }
                }
            },
            Char => sub {
                my ( $expat, $content ) = @_;
                if ( $element_stack->[ _PARENT_INDEX() ] eq 'gnm:Name' ) {
                    if ( $element_stack->[ _GRANDPARENT_INDEX() ] eq
                        'gnm:Sheet' )
                    {
                        $current_worksheet_name = $content;
                    }
                }
                if ( $element_stack->[ _PARENT_INDEX() ] eq 'gnm:Cell' ) {
                    if ( $content eq "\N{LINE FEED}" ) {
                        $current_sheet_cells->[$current_row_number]
                          ->[$current_column_number] .=
                          $expat->original_string();
                    }
                    else {
                        $current_sheet_cells->[$current_row_number]
                          ->[$current_column_number] .= $content;
                    }
                }
              }
        }
    );
    eval { $xml->parse($gnumeric_content); } or do {
        chomp $EVAL_ERROR;
        $EVAL_ERROR =~ s/^\s*//smx;
        $self->{_ERROR_DIAG} =
          "XML - Invalid XML in gzipped gnumeric file:$EVAL_ERROR";
        return;
    };
    if ( defined $cells ) {
        return $cells;
    }
    else {
        $self->{_ERROR_DIAG} = 'ENOENT - Worksheet '
          . (
            defined $self->{worksheet_name}
            ? $self->{worksheet_name}
            : $self->{worksheet_number}
          ) . ' not found';
        return;
    }
}

sub _xlsx_shared_strings {
    my ( $self, $zip ) = @_;
    my $member = $zip->memberNamed('xl/sharedStrings.xml');
    if ( !$member ) {
        $self->{_ERROR_DIAG} = q[ZIP - Missing 'xl/sharedStrings.xml' file];
        return;
    }
    my $shared_string_content = $member->contents();
    my $element_stack;
    my $current_index;
    my $shared_strings = {};
    my $xml            = XML::Parser->new(
        Handlers => {
            Entity => sub {
                die
"XML Entities have been detected and rejected in the XML, due to security concerns\n";
            },
            Start => sub {
                my ( $expat, $element_name, %element_parameters ) = @_;
                push @{$element_stack}, $element_name;
                if ( $element_name eq 'sst' ) {
                }
                elsif ( $element_name eq 'si' ) {
                    if ( defined $current_index ) {
                        $current_index += 1;
                    }
                    else {
                        $current_index = 0;
                    }
                }
                elsif ( $element_name eq 't' ) {
                }
            },
            End => sub {
                my ( $expat, $element_name ) = @_;
                if ( $element_name ne pop @{$element_stack} ) {
                    Carp::croak(
                        'Internal confusion in processing XML elements');
                }
            },
            Char => sub {
                my ( $expat, $content ) = @_;
                $content =~ s/_x000D_//smxg;
                if ( defined $shared_strings->{$current_index} ) {
                    $shared_strings->{$current_index} .= $content;
                }
                else {
                    $shared_strings->{$current_index} = $content;
                }
              }
        }
    );
    eval { $xml->parse($shared_string_content); } or do {
        chomp $EVAL_ERROR;
        $EVAL_ERROR =~ s/^\s*//smx;
        $self->{_ERROR_DIAG} =
          "XML - Invalid XML in sharedStrings.xml:$EVAL_ERROR";
        return;
    };
    return $shared_strings;
}

sub _xlsx_worksheet_path {
    my ( $self, $zip ) = @_;
    my $member = $zip->memberNamed('xl/workbook.xml');
    if ( !$member ) {
        $self->{_ERROR_DIAG} = q[ZIP - Missing 'xl/workbook.xml' file];
        return;
    }
    my $content = $member->contents();
    my $worksheet_number;
    my $sheets = [];
    my $worksheet_count;
    my $xml = XML::Parser->new(
        Handlers => {
            Entity => sub {
                die
"XML Entities have been detected and rejected in the XML, due to security concerns\n";
            },
            Start => sub {
                my ( $expat, $element_name, %element_parameters ) = @_;
                if ( $element_name eq 'sheet' ) {
                    push @{$sheets}, \%element_parameters;
                    if ( !defined $worksheet_number ) {
                        if ( defined $worksheet_count ) {
                            $worksheet_count += 1;
                        }
                        else {
                            $worksheet_count = 0;
                        }
                        if (
                               ( defined $self->{worksheet_name} )
                            && ( defined $element_parameters{name} )
                            && ( $self->{worksheet_name} eq
                                $element_parameters{name} )
                          )
                        {
                            $worksheet_number = $worksheet_count + 1;
                        }
                        elsif (
                            ( $self->{worksheet_number} )
                            && ( ( $self->{worksheet_number} - 1 ) ==
                                $worksheet_count )
                          )
                        {
                            $worksheet_number = $worksheet_count + 1;
                        }
                    }
                }
              }
        }
    );
    eval { $xml->parse($content); } or do {
        chomp $EVAL_ERROR;
        $EVAL_ERROR =~ s/^\s*//smx;
        $self->{_ERROR_DIAG} =
          "XML - Invalid XML in xl/workbook.xml:$EVAL_ERROR";
        return;
    };
    if ( !defined $worksheet_number ) {
        $self->{_ERROR_DIAG} = 'ENOENT - Worksheet '
          . (
            defined $self->{worksheet_name}
            ? $self->{worksheet_name}
            : $self->{worksheet_number}
          ) . ' not found';
        return;
    }
    return 'xl/worksheets/sheet' . $worksheet_number . '.xml';
}

sub _xlsx_cells {
    my ( $self, $xlsx_content, $shared_strings, $worksheet_path ) = @_;
    my $cells = [];
    my $current_worksheet_name;
    my $current_sheet_cells = [];
    my $parameter_stack;
    my $element_stack;
    my $process_worksheet = 0;
    my $xml               = XML::Parser->new(
        Handlers => {
            Entity => sub {
                die
"XML Entities have been detected and rejected in the XML, due to security concerns\n";
            },
            Start => sub {
                my ( $expat, $element_name, %element_parameters ) = @_;
                push @{$element_stack},   $element_name;
                push @{$parameter_stack}, \%element_parameters;
            },
            End => sub {
                my ( $expat, $element_name ) = @_;
                pop @{$parameter_stack};
                if ( $element_name ne pop @{$element_stack} ) {
                    Carp::croak(
                        'Internal confusion in processing XML elements');
                }
            },
            Char => sub {
                my ( $expat, $content ) = @_;
                if (   ( $element_stack->[ _GRANDPARENT_INDEX() ] eq 'c' )
                    && ( $element_stack->[ _PARENT_INDEX() ] eq 'v' ) )
                {
                    my $cell_reference =
                      $parameter_stack->[ _GRANDPARENT_INDEX() ]->{r};
                    if ( $cell_reference =~ /^([[:upper:]]+)(\d+)$/smx ) {
                        my ( $column_designator, $row_number ) = ( $1, $2 - 1 );
                        my $column_number = 0;
                        my $letter_index  = 0;
                        foreach
                          my $letter ( reverse split //smx, $column_designator )
                        {
                            $column_number +=
                              ( ( ord uc $letter ) - ( ord 'A' ) ) *
                              ( _EXCEL_COLUMN_RADIX()**$letter_index );
                            $letter_index += 1;
                        }
                        if (
                            (
                                defined
                                $parameter_stack->[ _GRANDPARENT_INDEX() ]->{t}
                            )
                            && ( $parameter_stack->[ _GRANDPARENT_INDEX() ]->{t}
                                eq 's' )
                          )
                        {
                            $cells->[$row_number]->[$column_number] =
                              $shared_strings->{$content};
                        }
                        else {
                            $cells->[$row_number]->[$column_number] = $content;
                        }
                    }
                    else {
                        Carp::croak('Unable to determine cell reference');
                    }
                }
              }
        }
    );
    eval { $xml->parse($xlsx_content); } or do {
        chomp $EVAL_ERROR;
        $self->{_ERROR_DIAG} =
          "XML - Invalid XML in $worksheet_path:$EVAL_ERROR";
        return;
    };
    return $cells;
}

sub content_type {
    my ($self) = @_;
    return $self->{content_type};
}

sub suffix {
    my ($self) = @_;
    return $self->{type};
}

1;
__END__

=head1 NAME

Spreadsheet::CSV - Drop-in replacement for Text::CSV_XS with spreadsheet support

=head1 VERSION

Version 0.14

=head1 SYNOPSIS

 use Spreadsheet::CSV();
 use CGI();

 my $cgi = CGI->new();
 my $handle = $cgi->upload('UploadFile');
 my @rows;
 my $csv = Spreadsheet::CSV->new();
 while (my $row = $csv->getline ($handle)) {
     $row->[2] =~ m/pattern/ or next; # 3rd field should match
     push @rows, $row;
 }
 $csv->eof() or die $csv->error_diag();
 close $handle or die "Screaming:$!";

=head1 DESCRIPTION

Spreadsheet::CSV attempts to provide a drop-in replacement for Text::CSV_XS when reading in user-provided input files, such as via Email or Web.  This is currently only for reading documents and only via the $csv->getline interface documented above

=head1 SUBROUTINES/METHODS

=head2 new

(Class method) Returns a new instance of Spreadsheet::CSV.  It accepts all the parameters from Text::CSV_XS, as well as two additional ones.

 my $csv = Spreadsheet::CSV->new ({ attributes ... });

The following additional attributes are available:

=over 4

=item worksheet_name
X<worksheet_name>

The worksheet to read from for file handles containing spreadsheets.

=item worksheet_number
X<worksheet_number>

The worksheet to read from for file handles containing spreadsheets (starting from
1).  This option will only apply if the worksheet name has not been specified.  By
default worksheet_number will be '1' 

=back

=head2 getline
X<getline>

 $colref = $csv->getline ($io);

It reads a row from the IO object and parses this row into an array ref. This 
array ref is returned by the function or undef for failure.  If the IO object
points to a known spreadsheet file type, the first call to L</getline> will
convert the entire file into an in-memory list-of-lists before returning the first
row.

Accepted file types are currently

 * Microsoft Excel 97 - .xls
 * Microsoft Excel 2003 - .xlsx
 * OpenOffice - .ods and .sxc
 * Gnumeric - .gnumeric
 * Kspread - .ksp
 * CSV - .csv

Patches for support for other file types would be gratefully accepted.

When checking for CSV, the Text::CSV_XS module will be passed a filehandle containing
the same data as the input handle, but with ":encoding(UTF-8)" switched on.

=head2 eof
X<eof>

 $eof = $csv->eof ();

This method will return true (1) if the last call hit end of file, otherwise
it will return false (''). This is useful to see the difference between a 
failure and end of file

=head2 error_diag

 $error_str = $csv->error_diag ();

If (and only if) an error occurred, this function returns the diagnostics of that error.

=head2 content_type

 $content_type = $csv->content_type ();

After the $handle has been passed to getline, the content_type can be queried.  If 
$handle points to a recognised spreadsheet type, the appropriate content type will be
returned (such as 'application/vnd.ms-excel', otherwise, undef will be returned

=head2 suffix

 $suffix = $csv->suffix ();

After the $handle has been passed to getline, the file suffix can be queried.  If 
$handle points to a recognised spreadsheet type, the suffix will be returned (such as
'xls'), otherwise, undef will be returned

=head1 DIAGNOSTICS

If an error occurred, L</error_diag> can be used to get more
information on the cause of the failure.

=head1 CONFIGURATION AND ENVIRONMENT

Spreadsheet::CSV requires no configuration files or environment variables.

=head1 DEPENDENCIES

Spreadsheet::CSV requires the following non-core modules

 Spreadsheet::ParseExcel
 Text::CSV_XS
 Archive::Zip
 XML::Parser
 Compress::Zlib

and the following core modules

 Fcntl
 English
 Carp
 IO::File

=head1 AUTHOR

David Dick, C<< <ddick at cpan.org> >>

=head1 INCOMPATIBILITIES

The only spreadsheets supported at the moment are

 Microsoft Excel 97
 Microsoft Excel 2003
 OpenOffice
 Gnumeric
 KSpread
 CSV

=head1 BUGS AND LIMITATIONS

At the moment this library will read everything into RAM.  It relies on the system enforcing the reasonable limits
for file size, to allow these files to be read into RAM.  This may change in the future.

Spreadsheet::ParseExcel can lose precision when extracting floating point numbers

Please report any bugs or feature requests to C<bug-spreadsheet-csv at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-CSV>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can look for information at:

=over 4

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spreadsheet-CSV>

=item * Search CPAN

L<http://search.cpan.org/dist/Spreadsheet-CSV/>

=item * Request Tracker

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spreadsheet-CSV>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2013 David Dick.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.
