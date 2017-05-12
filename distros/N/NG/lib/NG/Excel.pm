package Excel;

use strict;
use warnings;
use base qw(Object);
use Array;
use Spreadsheet::WriteExcel;
use Excel::Cell;
use Excel::Sheet;

sub new {
    my ( $pkg, $sheet_arr ) = @_;
    return bless $sheet_arr, $pkg;
}

sub sheet {
    my ( $self, $sheet_num ) = @_;
    return $self->[ $sheet_num - 1 ];
}

sub sheets { return Array->new( @{ +shift } ); }

sub save {
    my ( $self, $to_file ) = @_;
    unlink $to_file if -e $to_file;
    my $workbook = Spreadsheet::WriteExcel->new($to_file);
    $self->sheets->each(
        sub {
            my ( $sheet, $i ) = @_;
            my $worksheet = $workbook->add_worksheet( $sheet->name );
            my @col_width = ();
            for my $col ( 1 .. $sheet->col_count ) {
                for my $row ( 1 .. $sheet->row_count ) {
                    my $cell = $sheet->get( $row, $col );
                    if ($cell) {
                        if ( $cell->width > ( $col_width[$col] or 0 ) ) {
                            $col_width[$col] = $cell->width;
                        }
                        my $value  = $cell->value;
                        my $format = $workbook->add_format();
                        $workbook->set_custom_color(
                            40,
                            '#'
                              . uc(
                                sprintf( "%.6x",
                                    $cell->{border_bottom}->{color} )
                              )
                        );
                        $workbook->set_custom_color(
                            41,
                            '#'
                              . uc(
                                sprintf(
                                    "%.6x", $cell->{border_left}->{color}
                                )
                              )
                        );
                        $format->set_bottom(
                            Excel::Cell->english_to_num(
                                $cell->{border_bottom}->{width},
                                $cell->{border_bottom}->{style}
                            )
                        );
                        $format->set_bottom_color(40);
                        $format->set_left(
                            Excel::Cell->english_to_num(
                                $cell->{border_left}->{width},
                                $cell->{border_left}->{style}
                            )
                        );
                        $format->set_left_color(41);
                        $worksheet->write( $row - 1, $col - 1, $value,
                            $format );
                    }
                }
            }
            for ( my $i = 1 ; $i <= scalar(@col_width) ; $i++ ) {
                $worksheet->set_column( $i - 1, $i - 1, $col_width[$i] );
            }

        }
    );
}

1;
