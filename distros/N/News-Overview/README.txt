News::Overview
==============

News::Overview is an object class for storing combined information about a
specific newsgroup in a compressed and usable manner.  It is based on the
semi-codified XOVER extension to RFC1036.  This summary information is
used by news readers to organize and summarize information about the
newsgroup, and by news servers to improve network performance.  

Note that this class is not directly useful on its own; it is meant as a
helper class for other classes.

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


Existing Applications
=====================

So far, all of the applications aren't released yet, but here's where
they're going to be:

News::Web
  http://www.killfile.org/~tskirvin/software/news-web

News::Archive
  http://www.killfile.org/~tskirvin/software/news-archive
