We're going to have a couple standard widgets here.

* search.pl     = Search Box
* content.pl    = Generic Static Content (like an About Me blurb)
* categories.pl = Category List
* archives.pl   = Blog Post Archive List


Rhetoric::Widgets

* directory structure
  $base/widgets/$position/[0-9][0-9]_*.pl

* The .pl files should return subroutines that return strings.

* The subroutines will be run in Rhetoric->service().

* The parameters are the current controller object and its args.

* Returning undef makes the widget invisible.

* Returning a string will make the widget visible
  if the theme supports that $position.

* Almost every theme will support a position called "sidebar".

* Some themes will support positions like "bottom" or "sidebar2".

