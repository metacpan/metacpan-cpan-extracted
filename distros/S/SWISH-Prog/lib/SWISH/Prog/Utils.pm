package SWISH::Prog::Utils;
use strict;
use warnings;
use Carp;
use Data::Dump qw( dump );
use File::Basename;
use Search::Tools::XML;

our $VERSION = '0.75';

=pod

=head1 NAME

SWISH::Prog::Utils - utility variables and methods

=head1 SYNOPSIS

 use SWISH::Prog::Utils;
 
 # use the utils
 
=head1 DESCRIPTION

This class provides commonly used variables and methods
shared by many classes in the SWISH::Prog project.

=head1 VARIABLES

=over

=item $ExtRE

Regular expression of common file type extensions.

=item %ParserTypes

Hash of MIME types to their equivalent parser.

=back

=cut

our $ExtRE       = qr{\.(\w+)(\.gz)?$}io;
our %ParserTypes = (

    # mime                  parser type
    'text/html'          => 'HTML*',
    'text/xml'           => 'XML*',
    'application/xml'    => 'XML*',
    'text/plain'         => 'TXT*',
    'application/pdf'    => 'HTML*',
    'application/msword' => 'HTML*',
    'audio/mpeg'         => 'XML*',
    'default'            => 'HTML*',
);

our $DefaultExtension = 'html';

# cache to avoid hitting MIME::Type each time
my %ext2mime = (
    doc  => 'application/msword',
    pdf  => 'application/pdf',
    ppt  => 'application/vnd.ms-powerpoint',
    html => 'text/html',
    htm  => 'text/html',
    txt  => 'text/plain',
    text => 'text/plain',
    xml  => 'application/xml',
    mp3  => 'audio/mpeg',
    gz   => 'application/x-gzip',
    xls  => 'application/vnd.ms-excel',
    zip  => 'application/zip',
    json => 'application/json',
    yml  => 'application/x-yaml',

);

# prime the cache with some typical defaults that MIME::Type won't match.
$ext2mime{'php'} = 'text/html';

eval { require MIME::Types };
my $mime_types;
if ( !$@ ) {
    $mime_types = MIME::Types->new;
}
my $XML = Search::Tools::XML->new;

=head1 METHODS

=head2 mime_type( I<url> [, I<ext> ] )

Returns MIME type for I<url>. If I<ext> is used, that is checked against
MIME::Types. Otherwise the I<url> is parsed for an extension using 
path_parts() and then fed to MIME::Types.

=cut

sub mime_type {
    my $self = shift;
    my $url  = shift or return;
    my $ext  = lc( shift || ( $self->path_parts($url) )[2] );
    $ext =~ s/^\.//;
    $ext ||= $DefaultExtension;

    #warn "$url => $ext";
    if ( !exists $ext2mime{$ext} and $mime_types ) {

        # cache the mime type as a string
        # to avoid the MIME::Type::type() stringification
        my $mime = $mime_types->mimeTypeOf($url) or return;
        $ext2mime{$ext} = $mime . "";
    }
    return $ext2mime{$ext};
}

=head2 parser_for( I<url> )

Returns the SWISH parser type for I<url>. This can be
configured via the C<%ParserTypes> class variable.

=cut

sub parser_for {
    my $self   = shift;
    my $url    = shift or croak "url required";
    my $mime   = $self->mime_type($url);
    my $parser = $ParserTypes{$mime} || $ParserTypes{'default'};
    return $parser;
}

=head2 path_parts( I<url> [, I<regex> ] )

Returns array of I<path>, I<file> and I<extension> using the
File::Basename module. If I<regex> is missing or false,
uses $ExtRE.

=cut

sub path_parts {
    my $self = shift;
    my $url  = shift;
    my $re   = shift || $ExtRE;

    # TODO build regex from ->config
    my ( $file, $path, $ext ) = fileparse( $url, $re );
    return ( $path, $file, $ext );
}

=head2 perl_to_xml( I<ref>, I<root_element> [, I<strip_plural> ] )

Similar to the XML::Simple XMLout() feature, perl_to_xml()
will take a Perl data structure I<ref> and convert it to XML,
using I<root_element> as the top-level element.

As of version 0.38 this method is now part of Search::Tools
and included here simply as a backcompat feature.

=cut

sub perl_to_xml {
    my $self = shift;
    return $XML->perl_to_xml(@_);
}

=head2 write_log( I<args> )

Logging method. By default writes to stderr via warn().

I<args> is a key/value pair hash, with keys B<uri> and B<msg>.

=cut

sub write_log {
    my $self = shift;
    my %args = @_;
    my $uri  = delete $args{uri} or croak "uri required";
    my $msg  = delete $args{msg} or croak "msg required";
    warn sprintf( "[%s][%s] %s [%s]\n", scalar localtime(), $$, $uri, $msg );
}

=head2 write_log_line([I<char>, I<width>])

Writes I<char> x I<width> to stderr, to provide some visual separation when viewing logs.
I<char> defaults to C<-> and I<width> to C<80>.

=cut

sub write_log_line {
    my $self  = shift;
    my $char  = shift || '-';
    my $width = shift || 80;
    warn $char x $width, "\n";
}

1;

__END__

=head1 AUTHOR

Peter Karman, E<lt>perl@peknet.comE<gt>

=head1 BUGS

Please report any bugs or feature requests to C<bug-swish-prog at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=SWISH-Prog>.  
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc SWISH::Prog


You can also look for information at:

=over 4

=item * Mailing list

L<http://lists.swish-e.org/listinfo/users>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=SWISH-Prog>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/SWISH-Prog>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/SWISH-Prog>

=item * Search CPAN

L<http://search.cpan.org/dist/SWISH-Prog/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2009 by Peter Karman

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

L<http://swish-e.org/>
