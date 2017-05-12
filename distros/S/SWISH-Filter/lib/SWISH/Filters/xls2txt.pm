package SWISH::Filters::xls2txt;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA = ('SWISH::Filters::Base');

sub new {
    my $class = shift;
    my $self  = bless {
        mimetypes => [ qr!application/vnd.ms-excel!, qr!application/excel!, ],
        priority  => 55,                             # higher than XLtoHTML
    }, $class;

    # check for helpers
    return $self->set_programs('xls2csv');

}

sub filter {
    my ( $self, $doc ) = @_;

    my $content = $self->run_xls2csv( $doc->fetch_filename ) || return;

    # update the document's content type
    $doc->set_content_type('text/plain');

    # return the document
    return \$content;
}
1;

__END__

=head1 NAME

SWISH::Filters::xls2txt - convert Excel docs to text using xls2csv

=head1 DESCRIPTION

This is a plug-in module that uses the C<xls2csv> program to convert MS Excel documents
to text for indexing by Swish-e.  C<xls2csv> is part of the C<catdoc> package
and can be downloaded from:

    http://www.45.free.net/~vitus/software/catdoc/

The program C<xls2csv> must be installed and in your PATH.

=head1 BUGS

This filter does not specify input or output character encodings.

A minor optimization during spidering (i.e. when docs are in memory instead of on disk)
would be to use open2() call to let catdoc read from stdin instead of from a file.

=head1 AUTHOR

Peter Karman perl@peknet.com

=head1 SEE ALSO

L<SWISH::Filter>


