package SWISH::Filters::ppt2txt;
use strict;
use vars qw( $VERSION @ISA );
$VERSION = '0.191';
@ISA = ('SWISH::Filters::Base');

sub new {
    my $class = shift;
    my $self  = bless {
        mimetypes => [qr!application/vnd.ms-powerpoint!],
        priority => 45,    # lower than html filter
    }, $class;

    # check for helpers
    return $self->set_programs('catppt');

}

sub filter {
    my ( $self, $doc ) = @_;

    my $content = $self->run_catppt( $doc->fetch_filename ) || return;

    # update the document's content type
    $doc->set_content_type('text/plain');

    # return the document
    return \$content;
}
1;

__END__

=head1 NAME

SWISH::Filters::ppt2txt - convert PowerPoint docs to text using catppt

=head1 DESCRIPTION

This is a plug-in module that uses the C<catppt> program to convert MS PowerPoint documents
to text for indexing by Swish-e.  C<catppt> is part of the C<catdoc> package
and can be downloaded from:

    http://www.45.free.net/~vitus/software/catdoc/

The program C<catppt> must be installed and in your PATH.

=head1 BUGS

This filter does not specify input or output character encodings.

A minor optimization during spidering (i.e. when docs are in memory instead of on disk)
would be to use open2() call to let catdoc read from stdin instead of from a file.

=head1 AUTHOR

Peter Karman perl@peknet.com

=head1 SEE ALSO

L<SWISH::Filter>


