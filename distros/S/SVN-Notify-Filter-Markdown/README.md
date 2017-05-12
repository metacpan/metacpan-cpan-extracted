SVN/Notify/Filter/Markdown version 0.05
=======================================

This module filters [SVN::Notify](http://search.cpan.org/dist/SVN-Notify) log
message output from [Markdown](http://daringfireball.net/projects/markdown/)
format into HTML. Essentially, this means that if you write your commit log
messages using Markdown and like to use
[SVN::Notify::HTML](http://search.cpan.org/perldoc?SVN::Notify::HTML)
[SVN::Notify::HTML::ColorDiff](http://search.cpan.org/perldoc?SVN::Notify::HTML::ColorDiff)
to format your commit notifications, you can use this filter to convert the
Markdown in the log message to HTML.

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Or, if you don't have Module::Build installed, type the following:

    perl Makefile.PL
    make
    make test
    make install

Dependencies

SVN::Notify:Filter::Markdown has the following dependencies:

* SVN::Notify
  Sends Subversion activity notification messages.

* Text::Markdown
  Converts from Markdown to HTML.

Copyright and License
---------------------

Copyright (c) 2008-2011 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
