package QDBM_File;

use strict;

BEGIN {

    our $VERSION = "1.12";

    # Make package
    {
        package Tie::Hash;
    }

    # For DBM_Filter: Inheriting only, not load Tie::Hash
    our @ISA = qw(Tie::Hash);

    eval {
        require XSLoader;
    };

    if ($@) {
        require DynaLoader;
        push @ISA, qw(DynaLoader);
        __PACKAGE__->bootstrap($VERSION);
    }
    else {
        XSLoader::load(__PACKAGE__, $VERSION);
    }

}

# Borrowed from Tie::Hash

sub CLEAR {

    my $self = shift;
    my $key = $self->FIRSTKEY();
    my @keys;

    while (defined $key) {
        push @keys, $key;
        $key = $self->NEXTKEY($key);
    }

    foreach $key (@keys) {
        $self->DELETE($key);
    }

}

BEGIN {

    foreach my $pkg (
        'QDBM_File::Multiple',
        'QDBM_File::BTree',
        'QDBM_File::BTree::Multiple'
    )
    {
        no strict 'refs';
        push @{$pkg . '::ISA'}, qw(Tie::Hash);
        *{$pkg . '::CLEAR'} = \&CLEAR;
    }

}

package QDBM_File::InvertedIndex;

sub get_scores {
    my $self = shift;
    return wantarray
        ? $self->_get_scores(@_)
        : { $self->_get_scores(@_) };
}

sub create_document {
    shift;
    return QDBM_File::InvertedIndex::Document->new(@_);
}

package QDBM_File::InvertedIndex::Document;

sub get_scores {
    my $self = shift;
    return wantarray
        ? $self->_get_scores(@_)
        : { $self->_get_scores(@_) };
}

1;

__END__

=head1 NAME

QDBM_File - Tied access to Quick Database Manager

=head1 SYNOPSIS

    use QDBM_File;
    
    # hash db
    
    [$db =] tie %hash, "QDBM_File", $filename, [$flags, $mode, $buckets];
    
    [$db =] tie %hash, "QDBM_File::Multiple",
        $filename, [$flags, $mode, $buckets, $dirs];
    
    $hash{"abc"} = "1234";
    $value = $hash{"abc"};
    untie %hash;
    
    $db = QDBM_File->new($filename, [$flags, $mode, $buckets]);
    
    $db = QDBM_File::Multiple->new(
        $filename, [$flags, $mode, $buckets, $dirs]
    );
    
    $db->STORE("abc", "1234");
    $value = $db->FETCH("abc");
    undef $db;
    
    # b+ tree
    # $compare_sub example: sub { $_[0] cmp $_[1] }
    
    [$db =] tie %hash, "QDBM_File::BTree",
        $filename, [$flags, $mode, $compare_sub];
    
    [$db =] tie %hash, "QDBM_File::BTree::Multiple",
        $filename, [$flags, $mode, $compare_sub];
    
    $db = QDBM_File::BTree->new($filename, [$flags, $mode, $compare_sub]);
    
    $db = QDBM_File::BTree::Multiple->new(
        $filename, [$flags, $mode, $compare_sub]
    );
    
    # inverted index
    
    $db = QDBM_File::InvertedIndex->new($filename, [$flags]);
    
    # hash db, btree, inverted index common api
    
    $num  = $db->get_size();
    $name = $db->get_name();
    $num  = $db->get_mtime();
    $bool = $db->sync();
    $bool = $db->optimize([$buckets]);
    $bool = $db->init_iterator();
    $bool = $db->is_writable();
    $bool = $db->is_fatal_error();
    $msg  = $class->get_error();
    
    # hash db, btree common api
    
    $bool = $db->STORE($key, $value);
    $bool = $db->store_keep($key, $value);
    $bool = $db->store_cat($key, $value);
    $num  = $db->get_record_size($key);
    $num  = $db->count_records();
    $bool = $class->repair($filename);
    $bool = $db->export_db($filename);
    $bool = $db->import_db($filename);
    
    # hash db only
    
    $value = $db->FETCH($key, [$start, $offset]);
    $bool  = $db->set_align($align);
    $bool  = $db->set_fbp_size($size);
    $num   = $db->count_buckets();
    $num   = $db->count_used_buckets();
    
    # Large Object: QDBM_File::Multiple only
    
    $bool  = $db->store_lob($key, $value);
    $bool  = $db->store_keep_lob($key, $value);
    $bool  = $db->store_cat_lob($key, $value);
    $value = $db->fetch_lob($key);
    $bool  = $db->delete_lob($key);
    $bool  = $db->exists_lob($key);
    $num   = $db->count_lob_records();
    
    # btree only
    
    $bool   = $db->store_dup($key, $value);
    $bool   = $db->store_dupr($key, $value);
    $bool   = $db->store_list($key, @values);
    @values = $db->fetch_list($key);
    $bool   = $db->delete_list($key);
    
    $num    = $db->count_match_records($key);
    $num    = $db->count_leafs();
    $num    = $db->count_non_leafs();
    
    $bool   = $db->move_first();
    $bool   = $db->move_last();
    $bool   = $db->move_next();
    $bool   = $db->move_prev();
    $bool   = $db->move_forward($key);
    $bool   = $db->move_backword($key);
    
    $key    = $db->get_current_key();
    $value  = $db->get_current_value();
    $bool   = $db->store_current($value);
    $bool   = $db->store_after($value);
    $bool   = $db->store_before($value);
    $bool   = $db->delete_current($value);
    
    $bool   = $db->begin_transaction();
    $bool   = $db->commit();
    $bool   = $db->rollback();
    
    $db->set_tuning(
        $max_leaf_record,
        $max_non_leaf_index,
        $max_cache_leaf,
        $max_cache_non_leaf
    );
    
    # DBM_Filter
    
    $old_filter = $db->filter_store_key  ( sub { ... } );
    $old_filter = $db->filter_store_value( sub { ... } );
    $old_filter = $db->filter_fetch_key  ( sub { ... } );
    $old_filter = $db->filter_fetch_value( sub { ... } );
    
    # inverted index api
    
    $doc  = QDBM_File::InvertedIndex->create_document($uri);
    $bool = $db->store_document($doc, [$max_words, $is_overwrite]);
    
    $doc  = $db->get_document_by_uri($uri);
    $doc  = $db->get_document_by_id($id);
    $id   = $db->get_document_id($uri);
    $bool = $db->delete_document_by_uri($uri);
    $bool = $db->delete_document_by_id($id);
    $bool = $db->exists_document_by_uri($uri);
    $bool = $db->exists_document_by_id($id);
    
    $doc   = $db->get_next_document();
    @id    = $db->search_document($word, [$max]);
    $num   = $db->search_document_count($word);
    $bool  = QDBM_File::InvertedIndex->merge($filename, @filenames);
    %score = $db->get_scores($doc, $max);
    
    QDBM_File::InvertedIndex->set_tuning(
        $index_buckets,
        $inverted_index_division_num,
        $dirty_buffer_buckets,
        $dirty_buffer_size
    );
    
    $db->set_char_class($space, $delimiter, $glue);
    @appearance_words = $db->analyze_text($text);
    @appearance_words = QDBM_File::InvertedIndex->analyze_text($text);
    $normalized_word  = QDBM_File::InvertedIndex->normalize_word($word);
    @id = $db->query($query);
    
    # document api
    
    $doc = QDBM_File::InvertedIndex::Document->new($uri);
    $doc->set_attribute($name, $value);
    $value = $doc->get_attribute($name);
    $doc->add_word($normalized_word, $appearance_word);
    $uri = $doc->get_uri();
    $id  = $doc->get_id();
    @normalized_words = $doc->get_normalized_words();
    @appearance_words = $doc->get_appearance_words();
    %score = $doc->get_scores($max, [$db]);

=head1 DESCRIPTION

QDBM_File is a module which allows Perl programs to make use of the
facilities provided by the qdbm library. If you use this module, you
should read the qdbm manual pages.

Quick Database Manager is a high performance dbm library maintained by
Mikio Hirabayashi. QDBM_File provides various API, Depot, Curia, Villa,
Vista and Odeum. Documents are available at L<http://qdbm.sourceforge.net/>

=head1 HASH DATABASE

Hash database is basic file format of qdbm. It is equivalent to other
dbm modules functionality.

=head2 Example

This is a example of hash database.

    use Fcntl;
    use QDBM_File;
    
    my %hash;
    my $filename = "mydata";
    
    tie %hash, "QDBM_File", $filename, O_RDWR|O_CREAT, 0644 or die $!;
    
    $hash{"key"} = "value";   # store value
    my $value = $hash{"key"}; # fetch value
    untie %hash # close database

=head2 Methods

=over 4

=item TIEHASH

    tie %hash, "QDBM_File", $filename, $flags, $mode, $buckets;

Tie interface is similar to other dbm modules. Optional C<$flags> is opening
flags importable from L<Fcntl>, $mode is file permission. C<O_CREAT|O_RDWR>,
C<0644> are used if omitted. C<$buckets> specifies number of elements of the
bucket array. If omitted, C<-1> is used (qdbm default).

    tie %hash, "QDBM_File", "mydata", O_CREAT|O_RDWR, 0644, -1;
    tie %hash, "QDBM_File", "mydata"; # equivalent

=item QDBM_File-E<gt>new($filename, [$flags, $mode, $buckets])

OOP constructor of QDBM_File. Arguments are equivalent to tie interface.

    $db = QDBM_File->new("mydata", O_CREAT|O_RDWR, 0644, -1);

=item $db-E<gt>STORE($key, $value)

Store value to the database. Existing value is overwritten.

    tie %hash, "QDBM_File", "mydata";
    $hash{"abc"} = "1234"; # tied interface
    $db->STORE("abc", "1234"); # OOP interface

=item $db-E<gt>store_keep($key, $value)

Similar to C<STORE()>, existing value is kept.

    $db->store_keep("abc", "1234");
    $db->store_keep("abc", "5678"); # value is still 1234

=item $db-E<gt>store_cat($key, $value)

Similar to C<STORE()>, existing value is concatenated.

    $db->store_cat("abc", "1234");
    $db->store_cat("abc", "5678"); # value is 12345678

=item $db-E<gt>FETCH($key, [$start, $offset])

Fetch value from the database. It has optional arguments C<$start>, C<$offset>.
C<$start> specifies the start position to be read, C<$offset> specifies the max
size to be read.

    $hash{"abc"} = "defg";
    $value = $hash{"abc"};
    $value = $db->FETCH("abc");
    $value = $db->FETCH("abc", 1, 2); # "ef"

=item $db-E<gt>get_size()

Get file size of the database.

=item $db-E<gt>get_name()

Get name of the database.

=item $db-E<gt>get_mtime()

Get modified time of the database.

=item $db-E<gt>get_record_size($key)

Get size of the value.

=item $db-E<gt>count_records()

Get number of records of the database.

=item $db-E<gt>sync()

Write buffers immediately.

=item $db-E<gt>is_writable()

Return true if database is writable.

=item QDBM_File-E<gt>get_error()

Get last error message.

=item $db-E<gt>is_fatal_error()

Return true if database has a fatal error.

=item $db-E<gt>init_iterator()

Initialize iterator for C<keys()>, C<values()>, C<each()>.

=item $db-E<gt>optimize([$buckets])

Optimize the database file. C<$buckets> is number of elements of the bucket
array. Default is C<-1> (qdbm default).

=item QDBM_File-E<gt>repair($filename)

Repair broken database file.

=item $db-E<gt>export_db($filename)

Export database as endian independent file.

=item $db-E<gt>import_db($filename)

Import file exported by C<export_db()>.

=item $db-E<gt>set_align($align)

Set size of database alignment.

=item $db-E<gt>set_fbp_size($size)

Set size of free block pool. Default is C<16>.

=item $db-E<gt>count_buckets()

Get number of elements of the bucket array.

=item $db-E<gt>count_used_buckets()

Get number of elements of the used bucket array.

=back

=head1 MULTIPLE DIRECTORY DATABASE

QDBM_File::Multiple is extended hash database. Database files are stored in
multiple directories. API is the same as QDBM_File.

QDBM_File::Multiple also provides large object managing API. Large object
record is stored in individual files.

=head2 Methods

=over 4

=item TIEHASH

    tie %hash, "QDBM_File::Multiple", $filename, $flags, $mode, $buckets, $dirs;

QDBM_File::Multiple has optional argument C<$dirs>, specifies division number of
directory. Default is C<-1> (qdbm default).

=item $db-E<gt>store_lob($key, $value)

Store value to the database. Record is stored in individual files.

=item $db-E<gt>store_keep_lob($key, $value)

Similar to C<store_lob()>, existing value is kept.

=item $db-E<gt>store_cat_lob($key, $value)

Similar to C<store_lob()>, existing value is concatenated.

=item $db-E<gt>fetch_lob($key)

Fetch the large object from the database.

=item $db-E<gt>delete_lob($key)

Delete the large object record.

=item $db-E<gt>exists_lob($key)

Return true if the large object record exists.

=item $db-E<gt>count_lob_records()

Number of large object records of the database.

=back

=head1 BTREE DATABASE

QDBM_File::BTree allows to store data in sorted. It is possible to compare keys
by user defined subroutine.

=head2 Example

Thie is a example of b+ tree database.

    use Fcntl;
    use QDBM_File;
    
    my $filename = "mydata";
    my $compare = sub { $_[0] cmp $_[1] };
    
    my %hash;
    my $db = tie %hash, "QDBM_File::BTree",
        $filename, O_RDWR|O_CREAT, 0640, $compare or die $!;
    
    $hash{"def"} = "DEF";
    $hash{"abc"} = "ABC";
    $hash{"ghi"} = "GHI";
    
    print join " ", keys %hash; # abc def ghi

=head2 Methods

=over 4

=item TIEHASH

    tie %hash, "QDBM_File::BTree", $filename, $flags, $mode, $compare_sub;

QDBM_File::BTree has optional argument C<$compare_sub>, used for key comparison,
must return C<-1>, C<0> or C<1>. By default, lexical order is used.

    sub { $_[0] cmp $_[1] } # lexical order
    sub { $_[0] <=> $_[1] } # numerical order

=item $db-E<gt>store_list($key, @values)

Store values as list.

=item $db-E<gt>store_dup($key, $value)

Similar to C<STORE()>, duplication of keys is allowed and the specified value is
added as the last one.

=item $db-E<gt>store_dupr($key, $value)

Similar to C<STORE()>, duplication of keys is allowed and the specified value is
added as the first one.

=item $db-E<gt>fetch_list($key)

Fetch values as list.

=item $db-E<gt>delete_list($key)

Delete all records corresponding a key.

=item $db-E<gt>count_match_records($key)

Get number of records corresponding a key.

=item $db-E<gt>count_leafs()

Get number of the leaf nodes of b+ tree.

=item $db-E<gt>count_non_leafs()

Get number of the non-leaf nodes of b+ tree.

=item $db-E<gt>move_first()

Move the cursor to the first record.

=item $db-E<gt>move_last()

Move the cursor to the last record.

=item $db-E<gt>move_next()

Move the cursor to the next record.

=item $db-E<gt>move_prev()

Move the cursor to the previous record.

=item $db-E<gt>move_forward($key)

Set cursor to the first record of the same key and that the cursor is set to
the next substitute if completely matching record does not exist.

=item $db-E<gt>move_backword($key)

Set cursor to the last record of the same key and that the cursor is set to the
previous substitute if completely matching record does not exist.

=item $db-E<gt>get_current_key()

Get key of the record where the cursor is.

=item $db-E<gt>get_current_value()

Get value of the record where the cursor is.

=item $db-E<gt>store_current($value)

Overwrite the current record.

=item $db-E<gt>store_after($value)

Insert record after the current record.

=item $db-E<gt>store_before($value)

Insert record before the current record.

=item $db-E<gt>delete_current($value)

Delete the record where the cursor is.

=item $db-E<gt>begin_transaction()

Order to begin the transaction.

=item $db-E<gt>commit()

Order to commit the transaction.

=item $db-E<gt>rollback()

Order to abort the transaction.

=item $db->set_tuning

    $db->set_tuning(
        $max_leaf_record, $max_non_leaf_index,
        $max_cache_leaf,  $max_cache_non_leaf
    );

Set the tuning parameters for performance. C<$max_leaf_record> specifies the max
number of records in a leaf node of b+ tree. C<$max_non_leaf_index> specifies
the max number of indexes in a non-leaf node of b+ tree. C<$max_cache_leaf>
specifies the max number of caching leaf nodes. C<$max_cache_non_leaf> specifies
the max number of caching non-leaf nodes. The default setting is equivalent to
C<(49, 192, 1024, 512)>. Because tuning parameters are not saved in a database,
you should specify them every opening a database.

=back

=head1 MULTIPLE DIRECTORY BTREE DATABASE

QDBM_File::BTree::Multiple is multiple directory version of QDBM_File::BTree.
API is the same as QDBM_File::BTree.

=head1 INVERTED INDEX

QDBM_File::InvertedIndex provides inverted index API. Inverted index is a data
structure to retrieve a list of some documents that include one of words which
were extracted from a population of documents.
See L<http://qdbm.sourceforge.net/spex.html#odeumapi> for more details.

=head2 Example

This is a example of QDBM_File::InvertedIndex.

    use Fcntl;
    use QDBM_File;
    
    my $filename = "mydata";
    my $db = QDBM_File::InvertedIndex->new($filename, O_RDWR|O_CREAT) or die $!;
    
    my $uri = "http://www.perl.com/";
    my $doc = QDBM_File::InvertedIndex->create_document($uri);
    
    my @words = QDBM_File::InvertedIndex->analyze_text(
        "There is more than one way to do it."
    );
    
    for my $word (@words) {
        my $normal = QDBM_File::InvertedIndex->normalize_word($word);
        $doc->add_word($normal, $word);
    }
    
    $db->store_document($doc);
    
    my @id = $db->search_document("way");
    my $doc2 = $db->get_document_by_id($id[0]);
    
    print $doc2->get_uri(); # http://www.perl.com/

=head2 Methods

=over 4

=item QDBM_File::InvertedIndex-E<gt>new($filename, [$flags])

Constructor of QDBM_File::InvertedIndex.

=item QDBM_File::InvertedIndex-E<gt>create_document($uri)

Create QDBM_File::InvertedIndex::Document object. C<$uri> specifies the URI of a
document. The id number of a new document is not defined. It is defined when
the document is stored in a database.

=item $db-E<gt>store_document($doc, [$max_words, $is_overwrite])

Store document to the database. C<$max_words> specifies the max number of words
to be stored in the document database. Default is C<-1> (unlimited).
C<$is_overwrite> specifies whether the data of the duplicated document is
overwritten or not.

=item $db-E<gt>get_document_by_uri($uri)

Retrieve a document by a uri.

=item $db-E<gt>get_document_by_id($id)

Retrieve a document by an id.

=item $db-E<gt>get_document_id($uri)

Get id of uri.

=item $db-E<gt>delete_document_by_uri($uri)

Delete a document by a uri.

=item $db-E<gt>delete_document_by_id($id)

Delete a document by an id.

=item $db-E<gt>exists_document_by_uri($uri)

Check whether the document by a uri exists.

=item $db-E<gt>exists_document_by_id($id)

Check whether the document by an id exists.

=item $db-E<gt>get_next_document()

Get the next document.

=item $db-E<gt>search_document($word)

Search the inverted index for documents including a particular word. Return
values are array of id.

=item $db-E<gt>search_document_count($word)

Get number of documents including a word.

=item QDBM_File::InvertedIndex-E<gt>merge($filename, @filenames)

Merge plural database directories.

=item $db-E<gt>get_scores($doc, $max)

Get keywords of document in normalized form and their scores. C<$max> specifies
the max number of keywords to get.

=item $db-E<gt>set_tuning

    $db->set_tuning(
        $index_buckets,
        $inverted_index_division_num,
        $dirty_buffer_buckets,
        $dirty_buffer_size
    );

Set the global tuning parameters. C<$index_buckets> specifies the number of
buckets for inverted indexes. C<$inverted_index_division_num> specifies the
division number of inverted index. C<$dirty_buffer_buckets> specifies the number
of buckets for dirty buffers. C<$dirty_buffer_size> specifies the maximum bytes
to use memory for dirty buffers. The default setting is equivalent to
C<(32749, 7, 262139, 8388608)>. This method should be called before opening a
database.

=item $db-E<gt>set_char_class($space, $delimiter, $glue)

Set the classes of characters used by C<analyze_text()>. C<$space> spacifies a
string contains space characters. C<$delimiter> spacifies a string contains
delimiter characters. C<$glue> spacifies a string contains glue characters.

=item $db-E<gt>analyze_text($text)

Break a text into words and return appearance forms and normalized form into
lists.

=item QDBM_File::InvertedIndex-E<gt>analyze_text($text)

Break a text into words in appearance form. Words are separated with space
characters and such delimiters as period, comma and so on.

=item QDBM_File::InvertedIndex->normalize_word($word)

Get normalized form of a word.

=item $db-E<gt>query($query)

Query a database using a small boolean query language. Return values are list of
id.

    @doc_id = $db->query("There | more"); # "There" || "more"
    @doc_id = $db->query("There & foo");  # "There" && "foo"
    @doc_id = $db->query("There ! foo");  # "There" && !"foo"
    @doc_id = $db->query("There & (more | foo)");

=back

=head2 Document Methods

=over 4

=item QDBM_File::InvertedIndex::Document->new($uri)

Create QDBM_File::InvertedIndex::Document object. C<$uri> specifies the uri of a
document. The id number of a new document is not defined. It is defined when
the document is stored in a database.

=item $doc->set_attribute($name, $value)

Add an attribute to the document.

=item $doc->get_attribute($name)

Get an attribute of the document.

=item $doc->add_word($normalized_word, $appearance_word)

Add a word to the document. C<$normalized_word> specifies the string of the
normalized form of a word. Normalized forms are treated as keys of the inverted
index. C<$appearance_word> specifies the string of the appearance form of the
word.

=item $doc->get_uri()

Get uri of the document.

=item $doc->get_id()

Get id of the document.

=item $doc->get_normalized_words()

Return words of the document in normalized form.

=item $doc->get_appearance_words()

Get words of the document in appearance form.

=item $doc->get_scores($max, [$db])

Get keywords of document in normalized form and their scores. C<$max> specifies
the max number of keywords to get. C<$db> specifies QDBM_File::InvertedIndex
object with which the IDF for weighting is calculate.

=back

=head1 AUTHOR

Toshiyuki Yamato, C<< <toshiyuki.yamato@gmail.com> >>

=head1 BUGS AND WARNINGS

Currently umask flags is ignored implicitly, C<0644> is always used. It is used
for other dbm modules compatibility.

=head1 SEE ALSO

L<DB_File>, L<perldbmfilter>.

=head1 COPYRIGHT & LICENSE

Copyright 2007-2009 Toshiyuki Yamato, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
