
// Test of xref, index, etc.

=First page

* \X<see> also \XREF{name=p3}<page three>.

=Second page

And \X<see> also \SECTIONREF{name="First page"}.

Enter \X{mode=index_only}<Test, Index> index test into index.

=Third page

Text with \A{name=p3} an anchor on page three.
Please refer to page \PAGEREF{name="Second page"}.

=Links to the web

Some URLS:

* \L{url="http://www.pixel.de"}<Pixel GmbH>

* \L{url="http://www.mixed-mode.de" target="_blank"}<Mixed-Mode Asic Design GmbH>
