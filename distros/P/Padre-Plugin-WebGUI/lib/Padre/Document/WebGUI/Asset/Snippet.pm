package Padre::Document::WebGUI::Asset::Snippet;
BEGIN {
  $Padre::Document::WebGUI::Asset::Snippet::VERSION = '1.002';
}

# ABSTRACT: Padre::Document::WebGUI::Asset::Snippet subclass representing a WebGUI Snippet

use strict;
use warnings;
use Padre::Logger;
use Padre::Document::WebGUI::Asset;

our @ISA = 'Padre::Document::WebGUI::Asset';


sub lexer {
    my $self     = shift;
    my $mimetype = $self->asset->{mimetype};
    TRACE("Snippet mimetype: $mimetype") if DEBUG;
    Padre::MimeTypes->get_lexer( $mimetype || 'text/html' );
}


1;

__END__
=pod

=head1 NAME

Padre::Document::WebGUI::Asset::Snippet - Padre::Document::WebGUI::Asset::Snippet subclass representing a WebGUI Snippet

=head1 VERSION

version 1.002

=head1 METHODS

=head2 lexer

Snippets know what their mime type is

=head2 TRACE

=head1 AUTHOR

Patrick Donelan <pdonelan@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Patrick Donelan.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

