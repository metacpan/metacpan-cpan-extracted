News::Archive
=============

News::Archive is a package for storing news articles in an accessible
form.  Articles are stored one-per-file, and are accessible by either
message-ID or overview information.  The files are then accessible with a
Net::NNTP compatible interface, for easy access by other packages.

This package was generated in response to the shortcomings of kiboze.pl,
an old script I wrote.  A new version of this script is included, and is
probably the number one use of this package.  If you just want to archive
your news for later use, this package is for you.

Dependencies
============

To use News::Archive, you will need the following packages (available in
CPAN or in the URLs below):

NewsLib 	      http://www.killfile.org/~tskirvin/software/newslib/
News::Overview 	      http://www.killfile.org/~tskirvin/software/news-overview/
News::Web 	      http://www.killfile.org/~tskirvin/software/news-web/

News::Newsrc	      (available through CPAN)
FileHandle::Unget     (available through CPAN)
WeakRef		      (available through CPAN)
Date::Parse	      (available through CPAN)

Installation Instructions
=========================

If you've got perl installed, it's easy:

  perl Makefile.PL
  make
  make test
  sudo make install

(If you don't have sudo installed, run the final command as root.)

If you don't have perl installed, then go install it and start over.
It'll do you good.

There is a web directory here; the files are not installed by default, but
are useful tips in using News::Web and News::Archive together to offer a
nice user interface.
