StaticVolt
==========

**StaticVolt** is a static website generator supporting [Template Toolkit 2](http://template-toolkit.org)
(TT2) layouts and both [Markdown](http://daringfireball.net/projects/markdown/) and Textile content.

Getting Started
==========

  * Install using *cpan*, [*cpanm*](http://search.cpan.org/~miyagawa/App-cpanminus-1.5019/bin/cpanm) or from source.
  * Create a source and a layout directory:

      `mkdir -p docs/{_source,_layouts}`

  * Create a simple layout in *_layouts/main.html*:

        <!DOCTYPE html>
        <html>
            <head>
                <title></title>
            </head>
            <body>
                [% content %]
            </body>
        </html>



  * Create some content in *_source/index.markdown* with a YAML style header:


           ---
           layout: main.html
           drink : water
           ---
           Drink **plenty** of [% drink %].


  * Run the *staticvolt* tool to generate a *_site* directory
    containing the processed web-site.

  * Run `perldoc StaticVolt` for more (or read the docs [here](http://search.cpan.org/~haggai/StaticVolt-0.03/lib/StaticVolt.pm)).

Copyright and License 
==========

This software is Copyright (c) 2011 by Alan Haggai Alavi.

This is free software, licensed under:

        The Artistic License 2.0 (GPL Compatible)