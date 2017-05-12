
// vim: set filetype=pp2html:

=BOXCOLORS

\X{mode=index_only}<Tag \\BOXCOLORS>
The \B<\\BOXCOLORS> tag is used to change the background and foreground colors of
text boxes used for example code.


\B<Syntax>

\\BOXCOLORS{fg=\I<fgcolor> bg=\I<bgcolor>}

\\BOXCOLORS{set=default}


\B<Options>

:\B<fg>:This option specifies the foreground color

:\B<bg>:This option specifies the background color

:\B<set=default>:This option resets the colors to their original values.

\B<Body>

No body is allowed.


\B<Examples>

  \\BOXCOLORS{fg=white bg=blue}

  \\BOXCOLORS{bg="#AFBDCA"}

\BOXCOLORS{bg="#AFBDCA"}
the latter produces

  This is a colored box ...

\BOXCOLORS{set=default}

\B<See also>

\B<\\F>
