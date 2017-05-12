
// vim: set filetype=pp2html:

=L

\X{mode=index_only}<Tag \\L>
The \B<\\L> tag is used to specify hyperlinks to other pages.


\B<Syntax>

\\L{url="\I<target-page>" target=\I<window>}<link text>


\B<Options>

:\B<url>: Mandatory option to specify the target page.

:\B<target>:  Specify the target window in a framset, the top level window or a new browser window.
          Useful values are:

* _top : present page in the toplevel window

* _blank : present page in a new browser window

\B<Body>

The body is the text used for this hyperlink.


\B<Example>

  Please visit the \\L{url="http://www.ypac.org/Europe"}<YAPC::Europe> homepage.

produces

  Please visit the \L{url="http://www.ypac.org/Europe"}<YAPC::Europe> homepage.


\B<See also>

\B<\\XREF>, \B<\\PAGEREF>, \B<\\SECTIONREF>

