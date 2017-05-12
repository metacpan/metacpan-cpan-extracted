
use lib "./blib/lib";

#   create new object with operator overloading activated
use String::Divert;
my $html = new String::Divert;
$html->overload(1);

#   generate outer HTML framework
$html .=
    "<html>\n" .
    "  <head>\n" .
    "    " . $html->folder("head") .
    "  </head>\n" .
    "  <body>\n" .
    "    " . $html->folder("body") .
    "  </body>\n" .
    "</html>\n";
$html >> "body";

#   generate body
$html .= "<table>\n" .
         "  <tr>\n" .
         "   <td>\n" .
         "     " . $html->folder("left") .
         "   </td>\n" .
         "   <td>\n" .
         "     " . $html->folder("right") .
         "   </td>\n" .
         "  </tr>\n" .
         "</table>\n";

#   generate header
$html >> "head";
$html .= "<title>foo</title>\n";
$html << 1;

#   generate left contents
$html >> "left";
$html .= "bar1\n" .
         "bar2\n";
$html << 1;

#   generate right contents
$html >> "right";
$html .= "quux1\n" .
         "quux2\n";
$html << 1;

#   undivert all diversions and output unfolded HTML
$html << 0;
print $html;

#   destroy object
$html->destroy;

