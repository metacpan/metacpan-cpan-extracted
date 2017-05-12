package Plucene::SearchEngine::Index::PDF;
use base 'Plucene::SearchEngine::Index::Base';
__PACKAGE__->register_handler("application/pdf", ".pdf");
use File::Temp qw/tmpnam/;

=head1 NAME

Plucene::SearchEngine::Index::PDF - Backend for parsing PDF

=head1 DESCRIPTION

This backend analyzes a PDF file for its textual content (using C<pdftotext>)
and turns any metadata found in the PDF into Plucene fields.

=cut

sub gather_data_from_file {
    my ($self, $filename) = @_;
    my $html = tmpnam();
    system("pdftotext", "-htmlmeta", $filename, $html);
    return unless -e $html;
    $self->Plucene::SearchEngine::Index::HTML::gather_data_from_file($html);
    unlink $html;
    return $self;
}

1;
