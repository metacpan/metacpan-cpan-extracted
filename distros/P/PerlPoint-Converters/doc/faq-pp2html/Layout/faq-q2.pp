
// vim: set filetype=PerlPoint:


=Including Images

\QST

How can I \X<include images> in my document or in my presentation?

\ANS

Use the \C<\\IMAGE> tag to include images in your source file:

 \\INCLUDE{src=\B<image_file_name>}

\DSC

The \C<image_file_name> is either relative to the directory where the
PerlPoint source file is is located or it is an absolute pathname.
(The PerlPoint source file is the file containing the \C<\\IMAGE> tag.)

Other options which can be used in the \\IMAGE tag:

* border=n

* height=h

* width=w

* align=x

* alt=string

These options are translated to their corresponding
HTML equivalents.

The image file is copied to the image directory (only if the source is newer than the target ...)
The image directory can be specified by the \C<--image_dir> option. The default value for the
image directory is the target directory (or slice directory) which can be specified by the
\C<--target_dir> option.
