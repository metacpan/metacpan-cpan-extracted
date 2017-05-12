package Parse::ExuberantCTags;

use 5.006001;
use strict;
use warnings;

our $VERSION = '1.02';

require XSLoader;
XSLoader::load('Parse::ExuberantCTags', $VERSION);


1;
__END__

=head1 NAME

Parse::ExuberantCTags - Efficiently parse exuberant ctags files

=head1 SYNOPSIS

  use Parse::ExuberantCTags;
  my $parser = Parse::ExuberantCTags->new( 'tags_filename' );
  
  # find a given tag that starts with 'foo' and do not ignore case
  my $tag = $parser->findTag("foo", ignore_case => 0, partial => 1);
  if (defined $tag) {
    print $tag->{name}, "\n";
  }
  $tag = $parser->findNextTag();
  # ...
  
  # iterator interface (use findTag instead, it does a binary search)
  $tag = $parser->firstTag;
  while (defined($tag = $parser->nextTag)) {
    # use the tag structure
  }

=head1 DESCRIPTION

This Perl module parses I<ctags> files and handles both traditional
ctags as well as extended ctags files such as produced with I<Exuberant
ctags>. To the best of my knowledge, it does not handle emacs-style "I<etags>"
files.

The module is implemented as a wrapper around the F<readtags> library that normally
ships with I<Exuberant ctags>. If you do not know what that is, you are
encouraged to have a look at L<http://ctags.sourceforge.net/>. In order to use
this module, you do not need I<Exuberant ctags> on your system. The module
ships a copy of F<readtags>. Quoting the F<readtags> documentation:

  The functions defined in this interface are intended to provide tag file
  support to a software tool. The tag lookups provided are sufficiently fast
  enough to permit opening a sorted tag file, searching for a matching tag,
  then closing the tag file each time a tag is looked up (search times are
  on the order of hundreths of a second, even for huge tag files). This is
  the recommended use of this library for most tool applications. Adhering
  to this approach permits a user to regenerate a tag file at will without
  the tool needing to detect and resynchronize with changes to the tag file.
  Even for an unsorted 24MB tag file, tag searches take about one second.

Take away from this that tag files should be sorted by the generating program.

=head1 TAG FORMAT

The methods that return a tag entry all return tags in the same format.
Examples count for a billion words:

  {
    name              => 'IO::File',
    file              => '/usr/lib/perl/5.10/IO/File.pm',
    fileScope         => 0,
    kind              => 'p',
    addressPattern    => '/package IO::File;/',
    addressLineNumber => 3,
    extension         => {
      class => 'IO::File',
    },
  }

The structure has the name of the tag (C<name>), the file it was found in
(C<file>), a flag indicating whether the tag is scoped to the file only,
the type of the tag entry (C<kind>), the C<ex> search pattern for locating
the definition (C<addressPattern>), the line number (C<addressLineNumber>),
and then key/value pairs from the extension section of the tag.

Not all of the fields are guaranteed to be available. Particularly the C<extension>
section will be empty if the tags file doesn't make use of the extended format.
Refer to the ctags reference for details.

=head1 METHODS

=head2 new

Given the name of a file to read the tags from, opens that file and returns
a C<Parse::ExuberantCTags> object on success, false otherwise.

=head2 findTag

Takes the name of the tag to be sought as first argument.

Following the tag name, two optional arguments (key/value pairs)
are supported:

Setting C<<partial => 1>> makes the tag name match if it's the
start of a tag. Setting C<<ignore_case => 1>> makes the search ignore
the case of the tag. Note that setting C<<ignore_case>> to true
results in a slower linear instead of a binary search!

Returns a tag structure or undef if none matched.

=head2 findNextTag

Returns the next tag that matches the previous search (see C<findTag>).

Returns undef if no more tags match.

=head2 firstTag

Returns the first tag in the file. Returns undef if the file is emtpy.

=head2 nextTag

Returns the next tag or undef if the end of the file is reached.

=head1 CAVEATS

The SetSortType call is currently not supported. Let me know if you
need it and I'll add a wrapper.

=head1 SEE ALSO

Exuberant ctags homepage: L<http://ctags.sourceforge.net/>

Wikipedia on ctags: L<http://en.wikipedia.org/wiki/Ctags>

Module that can produce ctags files from Perl code: L<Perl::Tags>

L<File::PackageIndexer>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This Perl module is a wrapper around the F<readtags> library
that is shipped as part of the exuberant ctags program.
A copy of F<readtags> is included with this module.
F<readtags> was put in the public domain by its author. The full
copyright/license information from the code is:

  Copyright (c) 1996-2003, Darren Hiebert
  This source code is released into the public domain.

The XS wrapper and this document are:

Copyright (C) 2009-2010 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
