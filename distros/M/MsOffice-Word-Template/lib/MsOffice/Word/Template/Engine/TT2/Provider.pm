package MsOffice::Word::Template::Engine::TT2::Provider;
use strict;
use warnings;
use base 'Template::Provider';

our $VERSION = '2.04';


sub _template_content {
  my ($self, $path) = @_;

  $path
    or return (undef, "No path specified to fetch content from ");

  # if the path is not a Microsoft Word document, let the parent class handle it
  $path =~ /\.do[ct][xm]?$/
    or return $self->SUPER::_template_content($path);

  # parse the subtemplate
  my $mod_date    = (stat($path))[9];
  my $subtemplate = MsOffice::Word::Template->new($path);
  my $doc_part    = $subtemplate->surgeon->part("document");
  my $data        = $subtemplate->engine->template_text_for_part($doc_part);

  # just keep the XML inside the document body
  $data =~ s{^.*?<w:body>(.*?)</w:body>.*}{$1}s;

  # comply with the Provider API (see below)
  return wantarray ? ( $data, undef, $mod_date )
                   : $data;
}

#------------------------------------------------------------------------
# _template_content($path)
#
# Fetches content pointed to by $path.
# Returns the content in scalar context.
# Returns ($data, $error, $mtime) in list context where
#   $data       - content
#   $error      - error string if there was an error, otherwise undef
#   $mtime      - last modified time from calling stat() on the path
#------------------------------------------------------------------------



1;

__END__

=encoding ISO-8859-1

=head1 NAME

MsOffice::Word::Template::Engine::TT2::Provider -- subclass of Template::Provider for loading .docx templates

=head1 DESCRIPTION

This subclass of L<Template::Provider> is called whenever a C<MsOffice::Word::Template> document
requires a C<.docx> subtemplate through the C<INSERT>, C<INCLUDE> or C<PROCESS> directives.

The subtemplate is parsed as usual, but only the inner document body is returned to the caller,
so that it can be inserted in a parent document.

=head1 AUTHOR

Laurent Dami, E<lt>dami AT cpan DOT org<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2024 by Laurent Dami.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

