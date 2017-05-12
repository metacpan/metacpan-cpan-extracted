package Search::Odeum;
use strict;
use warnings;
use base qw(Exporter);

use constant OD_OREADER => 1 << 0;
use constant OD_OWRITER => 1 << 1;
use constant OD_OCREAT => 1 << 2;
use constant OD_OTRUNC => 1 << 3;
use constant OD_ONOLCK => 1 << 4;
use constant OD_OLOCKNB => 1 << 5;

our @EXPORT = qw(OD_OREADER OD_OWRITER OD_OCREAT OD_OTRUNC OD_ONOLCK OD_OLOCKNB
);
our $VERSION;

BEGIN
{
    $VERSION = '0.02';
    if ($] > 5.006) {
        require XSLoader;
        XSLoader::load(__PACKAGE__, $VERSION);
    } else {
        require DynaLoader;
        @Senna::ISA = ('DynaLoader');
        __PACKAGE__->bootstrap();
    }
}

sub new {
    my($class, $name, $omode) = @_;
    $omode ||= OD_OREADER;
    $class->xs_new($name, $omode);
}

use Search::Odeum::Document;

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Search::Odeum - Perl interface to the Odeum inverted index API.

=head1 SYNOPSIS

Create inverted index and put your document.

  use Search::Odeum;
  
  my $od = Search::Odeum->new('index', OD_OWRITER|OD_OCREAT);
  my $doc = Search::Odeum::Document->new('http://www.example.com/');
  $doc->attr('title' => 'example.com');
  # ... break text into words.
  $doc->addword($normal, $asis);
  $od->put($doc);
  $od->close;

Search the inverted index to retrieve documents.

  use Search::Odeum;
  
  my $od = Search::Odeum->new('index', OD_OREADER);
  my $res = $od->search($word); # $res is-a Search::Odeum::Result
  while(my $doc = $res->next) {
      printf "%s\n", $doc->uri;
  }
  $od->close;

=head1 DESCRIPTION

Search::Odeum is an interface to the Odeum API.
Odeum is the inverted index API which is a part of qdbm database library.

=head1 METHODS

=over 4

=item Search::Odeum->new(I<$name>, I<$omode>)

Create new Search::Odeum instance.
I<$name> specifies the databse directory. I<$omode> specifies the open mode.

=item put(I<$doc>, I<$wmax>, I<$over>)

store a document into the database.
I<$doc> is a Search::Odeum::Document object.
I<$wmax> specifies the max number of words to be stored. the default is unlimited.
I<$over> specifies the duplicated document will be overwritten or not. the default behavior is true.

=item out(I<$uri>)

delete a document from database.
I<$uri> specifies the document URI string.

=item outbyid(I<$id>)

delete a document from database.
I<$id> specifies the document ID

=item get(I<$uri>)

retrieve a document from database.
I<$uri> specifies the document URI string.


=item getbyid(I<$id>)

retrieve a document from database.
I<$id> specifies the document ID

=item getidbyuri(I<$uri>)

retrieve a document ID by the document URI.
I<$uri> specifies the document URI string.

=item check(I<$id>)

check whether the specified document exists.
I<$id> specifies the document ID

=item search(I<$word>, I<$max>)

search inverted index.
I<$word> specifies the searching word. I<$max> specifies the max number of documents to be retrieved.
return value is a Search::Odeum::Result object.

=item searchdnum(I<$word>)

get the number of documents including a word. this method is faster than search.
I<$word> specifies the searching word.

=item query(I<$query>)

query a database using a small boolean query language.

=item sync

synchronize updated contents to the device.

=item optimize

optimize a database.

=item name

get the name of database.

=item fsiz

get the total size of database files.

=item bnum

get the total number of the elements of the bucket arrays in the inverted index

=item busenum

get the total number of the used elements of the bucket arrays in the inverted index

=item dnum

get the number of documents in database.

=item wnum

get the number of words in database.

=item writable

check whether a database is writable or not.

=item fatalerror

check whether a database has a fatal error or not.

=item inode

get the inode number of a database directory.

=item mtime

get the last modified time of a database.

=item close

close a database handle.

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
