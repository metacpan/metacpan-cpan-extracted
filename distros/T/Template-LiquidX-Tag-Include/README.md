[![Build Status](https://travis-ci.org/sanko/Template-LiquidX-Tag-Include.svg?branch=master)](https://travis-ci.org/sanko/Template-LiquidX-Tag-Include)
# NAME

Template::LiquidX::Tag::Include - Include another file (Functioning Custom Tag Example)

# Synopsis

    {% include 'comments.inc' %}

# Description

This is a demonstration of
[extending Template::Liquid](https://metacpan.org/pod/Template::Liquid#Extending-Template::Liquid).

If you find yourself using the same snippet of code or text in several
templates, you may consider making the snippet an include.

You include static filenames...

    use Template::Liquid;
    use Template::LiquidX::Tag::Include;
    Template::Liquid->parse("{%include 'my.inc'%}")->render();

...or 'dynamic' filenames (for example, based on a variable)...

    use Template::Liquid;
    use Template::LiquidX::Tag::Include;
    Template::Liquid->parse('{%include inc%}')->render(inc => 'my.inc');

# Notes

The default directory searched for includes is `./_includes/` but this can be
changed in the include statement...

    use Template::LiquidX::Tag::Include '~/my_site/templates/includes';

This mimics Jekyll's include statement and was a 15m hack so it's subject to
change ...and may be completly broken.

# See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

[Template::Liquid](https://metacpan.org/pod/Template::Liquid#Extending-Template::Liquid)'s section on
custom tags.

# Author

Sanko Robinson &lt;sanko@cpan.org> - http://sankorobinson.com/

# License and Legal

Copyright (C) 2009-2016 by Sanko Robinson &lt;sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the `LICENSE` file included with
this distribution or http://www.perlfoundation.org/artistic\_license\_2\_0.  For
clarification, see http://www.perlfoundation.org/artistic\_2\_0\_notes.

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.
