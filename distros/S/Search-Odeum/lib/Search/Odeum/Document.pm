package Search::Odeum::Document;

use strict;

sub new {
    my($class, $uri) = @_;
    $class->xs_new($uri);
}

sub attr {
    my($class, $key, $value) = @_;
    if (defined $value) {
        $class->addattr($key, $value);
    }
    $class->getattr($key);
}


1;

__END__

=head1 NAME

Search::Odeum::Document - Perl interface to the Odeum inverted index API.

=head1 SYNOPSIS

  use Search::Odeum;
  my $doc = Search::Odeum::Document->new('http://www.example.com/');

=head1 DESCRIPTION

Search::Odeum::Document represents a Odeum document data structure.

=head1 METHODS

=over 4

=item Search::Odeum::Document->new(I<$uri>)

Create new Search::Odeum::Document instance.
I<$uri> specifies the URI of a document.

=item attr(I<$key>, I<$value>)

set or get an attribute to a document.
I<$key> specifies the name of an attribute. I<$value> specifies the value of attribute.
if I<$valuve> is omitted the stored attribute value will be returned.

=item addword(I<$normal>, I<$asis>)

add a word to the document.
I<$noraml> specifies the noramlized form of word. I<$asis> specifies the appearance form of word.
Search::Odeum does not provide the method to extract words from text and normalize it.

=item id

get the ID of document.

=item uri

get the URI of document.

=back

=head1 SEE ALSO

http://qdbm.sourceforge.net/

=head1 AUTHOR

Tomohiro IKEBE, E<lt>ikebe@shebang.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Tomohiro IKEBE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut
