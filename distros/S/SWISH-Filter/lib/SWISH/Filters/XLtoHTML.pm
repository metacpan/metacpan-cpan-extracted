package SWISH::Filters::XLtoHTML;
use strict;
require File::Spec;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA = ('SWISH::Filters::Base');

sub new {
    my ($class) = @_;

    my $self
        = bless {
        mimetypes => [ qr!application/vnd.ms-excel!, qr!application/excel!, ],
        }, $class;

    return $self->use_modules(qw( Spreadsheet::ParseExcel ));

}

sub filter {
    my ( $self, $doc ) = @_;

    # We need a file name to pass to the conversion function
    my $file = $doc->fetch_filename;

    my ( $content_ref, $meta ) = $self->get_xls_content_ref( $file, $doc );

    return unless $content_ref;

    # update the document's content type
    $doc->set_content_type('text/html');

    # If filtered must return either a reference to the doc or a pathname.
    return ( \$content_ref, $meta );

}

sub get_xls_content_ref {
    my ( $self, $file, $doc ) = @_;

    my $oExcel = Spreadsheet::ParseExcel->new;
    return unless $oExcel;

    my $oBook = $oExcel->Parse($file) || return;
    my ( $iR, $iC, $oWkS, $oWkC, $ExcelWorkBook );

    # gather up all the workbook metadata
    my ( $vol, $dirs, $filename ) = File::Spec->splitpath( $oBook->{File} );

    my $user_meta = $doc->meta_data || {};

    my %meta = (
        Filename   => $filename,
        Version    => $oBook->{Version} || '',
        Author     => $oBook->{Author} || '',
        Sheetcount => $oBook->{SheetCount}
    );

    $meta{$_} = $user_meta->{$_} for keys %$user_meta;

    my $title = join( ' ',
        $oBook->{Worksheet}[0]->{Name},
        $filename, 'v.' . $meta{Version} );

    my $html = join( "\n",
        '<html>', '<head>',
        '<title>' . $self->escapeXML($title) . '</title>',
        $self->format_meta_headers( \%meta ), '</head>' );

    $html .= "\n";

    # Here we collect content from each worksheet
    for ( my $iSheet = 0; $iSheet < $oBook->{SheetCount}; $iSheet++ ) {

        # For each Worksheet do the following
        $oWkS = $oBook->{Worksheet}[$iSheet];

        # Name of the worksheet
        my $ExcelWorkSheet
            = "<h2>" . $self->escapeXML( $oWkS->{Name} ) . "</h2>\n";
        $ExcelWorkSheet .= "<table>\n";

        for (
            my $iR = $oWkS->{MinRow};
            defined $oWkS->{MaxRow} && $iR <= $oWkS->{MaxRow};
            $iR++
            )
        {

            # For each row do the following
            $ExcelWorkSheet .= "<tr>\n";

            for (
                my $iC = $oWkS->{MinCol};
                defined $oWkS->{MaxCol} && $iC <= $oWkS->{MaxCol};
                $iC++
                )
            {

                # For each cell do the following
                $oWkC = $oWkS->{Cells}[$iR][$iC];

                my $CellData = $self->escapeXML( $oWkC->Value ) if ($oWkC);
                $ExcelWorkSheet .= "\t<td>" . $CellData . "</td>\n"
                    if $CellData;
            }
            $ExcelWorkSheet .= "</tr>\n";

            # Our last duty
            $ExcelWorkBook .= $ExcelWorkSheet;
            $ExcelWorkSheet = "";
        }
        $ExcelWorkBook .= "</table>\n";
    }

    $html .= <<EOF;
<body>
$ExcelWorkBook
</body>
</html>
EOF

    # include title in meta for return
    $meta{title} = $title;

    return ( $html, \%meta );
}

__END__

=head1 NAME

SWISH::Filters::XLtoHTML - MS Excel to HTML filter module

=head1 DESCRIPTION

SWISH::Filters::XLtoHTML extracts data from MS Excel spreadsheets for indexing.

Depends on Spreadsheet::ParseExcel from CPAN.

=head1 SUPPORT

Please contact the Swish-e discussion list.
http://swish-e.org/

=cut

