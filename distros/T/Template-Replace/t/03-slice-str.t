#!perl -T

#
# TODO: Custom delimiters!
#

use strict;
use warnings;
use Test::More 'no_plan';

use Template::Replace;
use FindBin;

use Data::Dumper;

#
# Prepare data directory ...
#
my $data_dir = "$FindBin::Bin/data";                       # construct path
$data_dir = $1 if $data_dir =~ m#^((?:/(?!\.\./)[^/]+)+)#; # un-taint
mkdir $data_dir unless -e $data_dir;                       # create if missing

#
# Cleanup beforehand ... no need for it so far!
#


#
# Let's have some prerequisites ...
#
my $tmpl;
my $str;


#
# Testing tmpl->_slice_str() ...
#
$tmpl = Template::Replace->new(); # standard delimiters

eval { $tmpl->_slice_str(); };
like( $@, qr/Missing string argument!/, '_slice_str without string' );

eval { $tmpl->_slice_str({}); };
like( $@, qr/Not a string argument!/, '_slice_str with no-scalar' );

is_deeply( $tmpl->_slice_str(''), [], '_slice_str with empty string' );

is_deeply(
	$tmpl->_slice_str('Single line'),
	[ 'Single line' ],
	'_slice_str with single line'
);

is_deeply(
	$tmpl->_slice_str(<<EOS
Multiline string
  without any slices
inside
EOS
	),
	[ <<EOS
Multiline string
  without any slices
inside
EOS
	],
	'_slice_str with multiline string'
);

is_deeply(
    $tmpl->_slice_str('($variable$)'),
    ['($variable$)'],
    '_slice_str with variable'
);

is_deeply(
	$tmpl->_slice_str('<!--(section)-->'),
	[ '<!--(section)-->' ],
	'_slice_str with section (no closing part)'
);
is_deeply(
	$tmpl->_slice_str('<!--(section)--><!--(/section)-->'),
	[ '<!--(section)-->', '<!--(/section)-->' ],
	'_slice_str with section (nothing inside)'
);
is_deeply(
	$tmpl->_slice_str('<!--( section )--><!--( / section )-->'),
	[ '<!--( section )-->', '<!--( / section )-->' ],
	'_slice_str with spaces inside section delimiters'
);
is_deeply(
	$tmpl->_slice_str('<!--(($section$))--><!--(/($section$))-->'),
	[ '<!--(($section$))-->', '<!--(/($section$))-->' ],
	'_slice_str with variable delimiters inside section delimiters'
);
is_deeply(
	$tmpl->_slice_str('<!--( ($ section $) )--><!--( / ($ section $) )-->'),
	[ '<!--( ($ section $) )-->', '<!--( / ($ section $) )-->' ],
	'_slice_str with spaces and var delimiters inside section delimiters'
);

eval {
    $tmpl->_slice_str('($variable 1$)($ variable 2 $)($($variable 3$)$)');
};
like(
    $@, qr/Repeated start delimiter in slice/,
    '_slice_str with repeated start delimiter'
);

eval {
    $tmpl->_slice_str('($variable 1$)($ variable 2 $)($ ($variable 3$) $)');
};
like(
    $@, qr/Repeated start delimiter in slice/,
    '_slice_str with repeated start delimiter'
);

is_deeply(
    $tmpl->_slice_str(
        'A string <!--( Section )--> with section <!--( /Section )--> inside'
    ),
    [
        "A string ",
        "<!--( Section )-->",
        " with section ",
        "<!--( /Section )-->",
        " inside"
    ],
    '_slice_str with inline section'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
A string<!--( Section )-->
followed by a section<!--( /Section )-->
with markers on the same line.
EOS
    ),
    [
        "A string",
        "<!--( Section )-->\n",
        "followed by a section",
        "<!--( /Section )-->\n",
        "with markers on the same line.\n"
    ],
    '_slice_str with string and section markers on same line.'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
A string <!--( Section )--> 
followed by a section <!--( /Section )--> 
with markers on the same line.
EOS
    ),
    [
        'A string ',
        "<!--( Section )--> \n",
        "followed by a section ",
        "<!--( /Section )--> \n",
        "with markers on the same line.\n"
    ],
    '_slice_str with string and section markers on same line.'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
A string
<!--( Section )--> followed by a section <!--( /Section )-->
with markers on the same line.
EOS
    ),
    [
        "A string\n",
        "<!--( Section )-->",
        ' followed by a section ',
        "<!--( /Section )-->\n",
        "with markers on the same line.\n"
    ],
    '_slice_str with string and section markers on same line.'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
A string
    <!--( Section )--> followed by a section <!--( /Section )-->
with markers on the same line.
EOS
    ),
    [
        "A string\n",
        "    <!--( Section )-->",
        ' followed by a section ',
        "<!--( /Section )-->\n",
        "with markers on the same line.\n"
    ],
    '_slice_str with string and section markers on same line.'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
A string
  <!--( Section )-->
  followed by a section
  <!--( /Section )-->
with markers on the same line.
EOS
    ),
    [
        "A string\n",
        "  <!--( Section )-->\n",
        "  followed by a section\n",
        "  <!--( /Section )-->\n",
        "with markers on the same line.\n"
    ],
    '_slice_str with string and section markers their own lines.'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
  <!--( Section )-->
  followed by a section
  <!--( /Section )-->
with markers on the same line.
EOS
    ),
    [
        "  <!--( Section )-->\n",
        "  followed by a section\n",
        "  <!--( /Section )-->\n",
        "with markers on the same line.\n"
    ],
    '_slice_str with string and section markers their own lines.'
);

is_deeply(
    $tmpl->_slice_str(<<EOS
<!--( Sec1 )-->
Sec1 is a normal section with (\$var1\$) inside.
<!--( /Sec1 )-->

There should be an end-of-line before this. <!--( Sec2 )-->
But not before this one! <!--(/Sec2)-->
Again not before this <!--(Sec3)-->inline section<!--(/Sec3)-->.
<!--#
    A multiline comment
    <!--(Sec4)-->
    A section inside a comment.
    <!--(/Sec4)-->
#-->
And more text.
EOS
    ),
    [
        "<!--( Sec1 )-->\n",
        "Sec1 is a normal section with ",
        "(\$var1\$)",
        " inside.\n",
        "<!--( /Sec1 )-->\n",
        "\nThere should be an end-of-line before this. ",
        "<!--( Sec2 )-->\n",
        "But not before this one! ",
        "<!--(/Sec2)-->\n",
        "Again not before this ",
        "<!--(Sec3)-->",
        "inline section",
        "<!--(/Sec3)-->",
        ".\n",
        "<!--#\
    A multiline comment\
    <!--(Sec4)-->\
    A section inside a comment.\
    <!--(/Sec4)-->\
#-->\
",
        "And more text.\n"
    ],
    '_slice_str with complex example'
);

#
# Cleanup ... no need for it so far!
#

