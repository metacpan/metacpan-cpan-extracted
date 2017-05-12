
// vim: set filetype=PerlPoint:


=My Own Bullets With Styles

\QST

How can I use my own \X<bullet images> with a predefined style?

\ANS

Assume that the style you want to use has its own bullet
images but you would prefer to use other bullet images instead.

In this case you may place your own bullet images in the
desired target directory and then call pp2html with the
following options:

  pp2html --target_dir ./slides \\
          --bullet mydot1.gif --bullet mydot2.gif \\
          input.pp

\DSC

The \C<--target_dir> option places all slides in the
specified directory. This directory should contain the two
bullet images \C<mydot1.gif> and \C<mydot2.gif> for top level
and second level lists.

The \C<--bullet> options tell pp2html to use the new gif files
for unordered lists.

