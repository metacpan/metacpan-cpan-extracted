
// vim: set filetype=PerlPoint:

+BL:\B<\F{color=blue size="+1"}<__body__>>

+RE:\B<\F{color=red size="+1"}<__body__>>

=Size of a Logo Image

\QST

\X{mode="index_only"}<logo image, size of>
How can I influence the size of my own logo image? The problem is
the following:

I use the predefined \I<pp_book> style which comes with its own logo image.
Now I have replaced this, using the following option:

  --logo_image_file_name "My_logo.gif"

The problem is, that my logo image is too big.

\ANS

Use the following trick:

  --logo_image_file_name 'My_logo.gif\RE<"> width=\BL<">70'

\DSC

In the template file there is the following HTML construct:

 <IMG SRC=\RE<">LOGO_IMAGE_FILENAME\BL<">>

Guess what happens: The \C<LOGO_IMAGE_FILENAME> is replaced with
all what's between the single quotes in the \C<--logo_image_file_name>
option. The result is:

 <IMG SRC=\RE<">My_logo.gif\RE<"> width=\BL<">70\BL<">>
