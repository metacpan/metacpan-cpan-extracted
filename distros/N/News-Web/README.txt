News::Web
=========

News::Web is a News<->Web gateway.  It's still in beta, but it seems to
work, so I'm pretty content with it.  For more information, read the
related manual pages.  

Dependencies
============

To use News::Web, you will need:

NewsLib
  http://www.killfile.org/~tskirvin/software/newslib

News::Overview
  http://www.killfile.org/~tskirvin/software/news-overview

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

Once you've done that, copy 'news.cgi' into a web directory as
'index.cgi', along with 'setcookie.cgi', 'defaults', and 'stylesheet.css'.
Modify them to your liking.  I'll work on a better installation method
later.
