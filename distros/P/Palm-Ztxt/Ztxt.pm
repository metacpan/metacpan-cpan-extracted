package Palm::Ztxt;

use 5.006001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Palm::Ztxt ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = sprintf "%s.%s%s", q$Name: Rel-0_91 $ =~ /^Name: Rel-(\d+)_(\d+)(_\d+|)\s*$/, 999,"00",join "", (gmtime)[5] +1900, map {sprintf "%02d", $_} (gmtime)[4]+1;


require XSLoader;
XSLoader::load('Palm::Ztxt', $VERSION);


sub new {
    my ($class) = shift;

    my $self = {wbits=>16, line_length=>0, method=>2, @_};
    bless $self, $class;

    my $db_loc = $self->init();
    $self->check_db($db_loc);

    $self->{process_method} = 2;
    $self->{line_length} = 0;
    $self->{wbits} = 15;

# TODO: set default attributes
#    if ($params{file_name}) {
#        open(FH, "<", $params{file_name}) || die $!;
#	local $/ = undef;
#    	$self->disect(<>);
#    }
#    delete $params{file_name};
#    while (my($_, $v) = each %params) {
#        /title/	&& $self->set_title($v), last;
#        /text/		&& $self->text($v),  last;
#    }
#
    return $self;
}


1;
__END__

=head1 NAME

Palm::Ztxt - Perl extension for creating and manipulating zTXTs using libztxt.

=head1 DESCRIPTION

First off, this module is NOT related to Palm::ZTxt module found on the weasel
reader website (http://gutenpalm.sourceforge.net/files/Palm-ZText-0.1.tar.gz).
The module, Palm-ZText-0.1, is a pure perl module that allows for the
manipulation of zTXTs; this module however, is an XS interface to the ztxt 
library used by the Weasel Reader (http://gutenpalm.sourceforge.net/), with
the addition that This module extends on libztext somewhat to give access to 
some fields that libztxt does not provide api functions for.

=head1 STATUS

This module seems to be stable; however, the API is not 100% finalized, it has
not had much use in a production envionment, and more tests need to be written.


=head1 SYNOPSIS

  use Palm::Ztxt;
  my $ztxt = new Palm::Ztxt;
  $ztxt->set_title($title);
  $ztxt->set_data($data);
  $ztxt->add_bookmark($bkmark_title, $offset);
  $ztxt->add_annotation($anno_title, $offset);
  my $zbook = $ztxt->get_output();

  my $ztxt = new Palm::Ztxt;
  $ztxt->disect($zbook);
  my $title = $ztxt->get_title();
  my $book = $ztxt->get_data();
  my $bookmarks = $ztxt->get_bookmarks();
  my $get_annotations = $ztxt->get_annotations();
  $ztxt->delete_bookmark($title, $offset);
  $ztxt->delete_annotation($title, $offset, $annotation);

  # Stuff that will probably never need to be changed
  $ztxt->set_type($type);
  $type = $ztxt->get_type();
  $ztxt->attribs($attribs);
  $attribs = $ztxt->attribs();
  $ztxt->creator($creator);
  $creator = $ztxt->creator();

  # Attributes that affect the way ztext processes()/generates() the ztext
  # These can be set at any time before $ztxt->get_output() is called.

  $ztxt->{process_length};
  $ztxt->{Wbits};
  $ztxt->{CompressType};
  $ztxt->{ProcessMethod};
  $ztxt->{attribs};


=head1 API DOCUMENTATION

=over

=item * new()

  my $ztxt = Palm::Ztxt->new();

Instantiate a new Palm::Ztxt object.


=item * disect()

Takes a compressed zbook or a reference thereto and disects it so that it can be 
manipulated by this module.

  my $zbook = read_zbook();
  my $ztxt = new Palm::Ztxt();
  $ztxt->disect($zbook);
  $ztxt->disect(\$zbook);



=item * set_title()

Set the title of a book:

  my $ztxt->title("Title of Book");

=item * get_title()

Get the title of the book:

  my $title = $ztxt->title();


=item * set_data();

This is the method whereby the book part of the zbook is setèd.  set_data() 
takes a single parameter viz., a string (or a reference thereto) that is
to become the body of the zTXT.  If the length of the text is less than 2
characters, set_data will throw an exception because the zTXT library does 
not seem to have a concept of a NULL /really, relay short book.

  $ztxt->set_data($book);
  $ztxt->set_data(\$book);

=item * get_data();

return the data portion of the zTXT.  The book, as it were.

  my $book = $ztxt->get_data();


=item * get_output()

Returns the compressed & compiled zTXT that can be sent to the palm or written
to a file or sent to /dev/null. The output of this function can even be used
as the input to $ztxt->disect.

my $ztxt = $ztxt->get_output();

if get_output notices that any of the $ztxt attributes are set incorrectly it
will raise an exception, so if you try to set $ztxt->{compression_type} =9_999
hoping for really great compression the only thing you will get for your
troubles is to have your script die (assuming no eval) when you call
$ztxt->get_output()


=item * add_bookmark()

Takes a title and an offset, and adds it to the zTXT. Call this as many times
as you like, once for each bookmark that you wish to add.

$ztxt->add_bookmark($title, $offset);

The length of the title of the bookmark can be at most 20 characters. If the 
length of the title exceeds this limit, add_bookmark will throw an exception.

[TODO: either the title of the bookmark will
be truncated to 20 characters or Palm::Ztxt will throw an exception depending
on the value of C<$ztxt->{FatalErrors}> ]


=item * get_bookmarks()

Returns an reference to an array of references to hashes each containing 2 keys:
'title' and 'offset'. 

  my $bookmark_hashref = $ztxt->get_bookmarks();

  $bookmark_hashref = [
      {title=> "Bookmark 1's title", offset=> "Bookmark 1's offset"},
      {title=> "Bookmark 2's title", offset=> "Bookmark 2's offset"},
      {title=> "Bookmark 3's title", offset=> "Bookmark 3's offset"},
  ];


=item * delete_bookmark()

Removes a bookmark from an ebook.

  $ztxt->delete_bookmark($title, $offset);

The offset must be specified because it is possible that there is more than one
bookmark with the supplied title.


=item * add_annotation()

Takes a title and an offset, and adds it to the zTXT. Call this as many times
as you like, once for each bookmark that you wish to add.

$ztxt->add_bookmark($title, $offset, $annotation);

The length of the title of the annotation can be at most 20 characters. If the 
length of the title exceeds this limit, add_annotation will throw an exception.



=item * get_annotation()

Returns an reference to an array of references to hashes each containing 3 keys:
'title' and 'offset' and 'annotation'. 

  my $annotations_hashref = $ztxt->get_annotation();

  $annotations_hashref = [
      {
          title => "Annotation 1's title",
	  offset=> "Annotation 1's offset",
          annotation => "Annotation 1 Annotation",
      },
      {
          title => "Annotation 2's title",
	  offset=> "Annotation 2's offset",
          annotation => "Annotation 2 Annotation",
      },
  ];


=item * delete_annotation()

Removes an annotation from an ebook.

  $ztxt->delete_annotation($title, $offset, $annotation);

The offset & the annotation must be specified because it is possible that 
there is more than one annotation with the supplied title & offset?. (actually I
just don't feel like testing this, and I don't plan on using delete_annotation() 
any time in the near future).


=item * set_creator()

Change the creator of the database. The default creator, 'GPLm' should not be
changed; however, the option is given to help help confuse programmers, 
and cause new users of this module endless amounts of pain while they track 
down bugs caused by assuming this functions does something other than what it
does do, viz.,  Change the creator.


=item * type();

Get or change the type of the database. The default of 'zTXT' probably should 
not be changed. You know what?  Just pretend that this function does not exist. 
Skip over and look at the next one -- nothing to see here.


=item * get_attribs()

Get the attributes associated with the zTXT. Refer to ztxt/palm docs for more
information.

=item * set_attribs()

Set the attributes associated with the zTXT.

=back

=head1 ATTRIBUTES

=over

=item * compression_type

Get or set the compression type that zlib will use. The compression type can
be either "1" for "on demand" or 2 for "max compression". On demand will all 
for random access within the zTXT and max compression will give you slightly 
better compression the default is the "on demand"

=item * process_method

Get or set the method used to process the zTXT for output.
The method used to process the zTXT can be one of the following:

=over

=item * method 0

Scan the input buffer and calculate the average line length. Any line that
exceeds this length will have its trailing \n removed.  Also, extra 5
characters will be subtracted off of the autodetcted length to a minimum of 20

When using a process type of 0 a length parameter can also be specified, and 
if it exists, it will be used instead of the calculated average line length.


=item * method 1

Expurgate line feeds from any non-blank line.

=item * method 2

Do not molest the text.

=back

Note: if the method is set to anything other than 2, then the offsets used for
bookmarks and annotations will probably be wrong, so it would probably be best
to leave the process method as the default of 2. The ability to change the
processing method is provided for compatibility with the C library; use
at your own risk.


=item * wbits

Get or set the number of window bits used by zlib. The number of window bits
can be anywhere between 8 and 15 inclusive. The larger the number the more
memory that is used for compression and decompression. The default is 15 and
there is probably no need to change this.


=back

=head1 NOT IMPLEMENTED

The following functions are part of the makeztxt library; however, they are
not implemented by this module because, well, 1. I did not feel like it, and 2.
they are not really needed.

=over

=over 

=item * add_regex()

=item * crc32()

=item * list_bookmarks()

=item * get_num_annotations()

=item * get_num_bookmarks()

=item * strip_spaces()

=item * whitepsace()

=item * sanitize_string()

=back

=back

=head1 EXPORT

None.


=head1 KNOWN BUGS

=over

=item * passing an invalid zTXT to disect will cause a segfault :(.

so don't do something like $ztxt->disect(\"Garbage"), like I do when testing

=item * Tests. 

There needs to be more tests, and the test files need to be reorged & cleaned up

=back

=head1 SEE ALSO

For more information refer to the libztxt libraries that come with the 
Weasel Reader.

For help/questions/problems There is a mailing list set up for this module. 
To subscribe to the mailing lits, send an empty email to  ""

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Rudolf Lippan E<lt>rlippan@remotelinux.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003-2008 by Rudolf Lippan E<lt>rlippan@remotelinux.comE<gt>

The inlcuded makeztxt library is copyright by its author. See makeztxt-1.62/COPYING and makeztxt-1.62/libztxt/* for more information.




=cut
