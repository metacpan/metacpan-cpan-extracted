
// vim: set filetype=PerlPoint:


=Creating a New Style

\QST

How can I create a new \X<style>?

\ANS

The easiest method is to copy all files from
an exsiting \X<style directory> to a new style directory and then
modify the files. 

Assume that all your \I<pp2html> styles are located in your style collection
\C<~/my_styles/>:

  % cd    # cd to your home directory
  % ls -F ./my_styles
  big_blue/
  orange_slides/

Create a new directory for the new style:

  % mkdir fancy_colors

Choose a style which is best suited to be a base for the new style and
copy all files from the old style to the new style, e. g.:

  % cp orange_slides/* fancy_colors

Rename the files:

  % cd fancy_colors
  % rename -s/orange_slides/fancy_colors/ *orange_slides*

  (Yes, this is my own \B<rename> script which is quite comfortable :-))

Edit the \C<fancy_colors.cfg> file and the template files according to
your needs.

\DSC

A \I<pp2html> style is a set of template and options files contained 
in a separate directory:
  
* The name of the style directory is also the name of
  the style.

* There must be an options file with the following naming
  convention: \I<<style-name\>>\B<.cfg>

* The style directory should be a subdirectory of the
  directory where you start \I<pp2html> or it should be a
  subdirectory of a style collection directory so that you
  can use the \C<--style_dir=>\I<<style_collection_dir\>> option.


The name of the options file is fixed: Must be the style name followed
by \B<.cfg>. The names of the other files can be chosen at will but it
is recommended to use a strict naming convention. This makes it easy to
rename the files if you want to create a new style based on an
existing style.


The template files should make use of keywords like \C<TOP_RGIHT_TXT>
or \C<LABEL_NEXT>. Default values for these keywords can be set in the
options file with the corresponding options, e.g.: --label_next="Next"

When you use this style, you can always overwrite these settings by
using a local options file in your document directory:

  pp2html @local.cfg --style_dir ~/my_styles \\
          --style fancy_colors  input.pp

In \C<local.cfg> you may write:

  --label_next="Weiter"

