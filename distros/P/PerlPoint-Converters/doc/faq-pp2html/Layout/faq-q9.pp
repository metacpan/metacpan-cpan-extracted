
// vim: set filetype=PerlPoint:


=Changing Box Colors

\QST

\X{mode="index_only"}<text boxes, colors of>
How can I change the colors for text boxes (sample code)?

\ANS

Use the \C<--box_color> and \C<--boxtext_color> options:

  pp2html --box_color #FFFF99 --boxtext_color blue input.pp

or use the \C<\\BOXCOLORS> tag to control the colors of individual
text boxes:

  \\BOXCOLORS{bg="#FFFF99" \B<fg>=blue}

\BOXCOLORS{bg="#FFFF99" fg=blue}

  \\BOXCOLORS{\B<set>=default}

\BOXCOLORS{set=default}

  This should be in default colors again ...

\DSC

The  \C<--box_color> and \C<--boxtext_color> options control the values
of the default colors for background and foreground of text boxes.

The \\BOXCOLORS tag changes the defaults, i. e. after this tag all
following text boxes have changed colors. \C<\\BOXCOLORS{set=default}>
returns to default values.

