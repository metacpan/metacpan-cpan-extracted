# Acknowledgements and Thanks

_PDF::Builder_ did not spring fully formed from the forehead of the current 
maintainer, ready for use. It is the product of many dozens, if not
hundreds, of people working on many projects over many years.

_PDF::Builder_ makes use of many Perl libraries and packages, as well as (in
many cases) underlying open source libraries -- too many to list here (but you
can follow the trail of all the `use XXX` entries in the code, if you are so 
inclined).

- Starting with the origins of the package, **Alfred Reibenschuh** built the 
original _PDF::API2_ library, drawing on work by **Martin Hosken** 
(_Text::PDF_, via the _Text::PDF::API_ wrapper). Reibenschuh has also been
actively participating in discussions about where _PDF::Builder_ can
go in future developments.
- **Steve Simms** took over _PDF::API2_ and has continued to maintain it and
extend its functionality. Much of his work is incorporated into _PDF::Builder_
after the latter was forked from the former.
- **Cary Gravel** (_Graphics::TIFF_ package) and **Jeffrey Ratcliffe** 
contributed much work to TIFF image support.
- **Ben Bullock** added features to the PNG library to support the needs of
this package.
- **Johan Vromans** wrote the SVG-to-PDF library package (_SVGPDF_) for SVG 
image support, and _HarfBuzz::Shaper_, which can be used by _PDF::Builder_ 
applications to support many text shaping features. He also wrote a number of 
other packages, which, while not used by (or directly contributing code to) 
_PDF::Builder_, did inspire the Font Manager and some aspects of markup 
language support. He also has discussed with us many aspects of text processing 
that may prove useful in future code and may show up later.
- **Vadim Repin** contributed a number of fixes and minor enhancements.
- **Davide Cervone** contributed support for allowing _PDF::Builder_ to 
interface with _MathJax_ (NodeJS) for equation support `(upcoming feature)`.

And of course, many thanks to those who reported bugs and requested needed
enhancements, sometimes even contributing some code and test cases. These
people are usually listed in the `Changes` file, or in the GitHub bug report
ticket. 

A special shout-out goes to **Gregor Herrmann** and **Petr Pisar** for working 
with us to report and fix problems discovered during packaging of their 
_Linux_ distributions (which redistribute _PDF::Builder_).

## Sponsorships

Thanks also go out to **Andy Beverley** of _Amtivo Group_ for financial 
sponsorship of the Markdown and HTML formatted input.

See also _INFO/SPONSORS_.

## Carrying On...

_PDF::Builder_ is Open Source software, built upon the efforts not only of the
current maintainer, but also of many people before me. Therefore, it's perfectly
fair to make use of the algorithms and even code (within the terms of the
LICENSE) for other projects, and even to port them to other languages and 
platforms (Java, Rust, Python, Typescript, etc.), as well as package 
_PDF::Builder_ into Linux and other OS distributions. That's how the State of 
the Art progresses! Just please be considerate and acknowledge the work of 
others that you are building on, as well as pointing back to this package. 
Drop us a note with news of your project (if based on the code and algorithms 
in _PDF::Builder_, or even just heavily inspired by it) and we'll be happy to 
make a pointer to your work. The more cross-pollination, the better!
