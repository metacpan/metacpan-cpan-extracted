#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
#use Data::Dumper; # for debugging
# $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

our $VERSION = '3.027'; # VERSION
our $LAST_UPDATE = '3.027'; # manually update whenever code is changed

# README.md is used below on page 5. Be sure to insert a fresh copy at build 
#  time, and check if goes more pages. \ -> \\, $PERL_version -> \$PERL_version
my $use_Table = 1; # if 1, use PDF::Table for table example
# TBD automatically check if PDF::Table available, and if so, use it

#my $pdf = PDF::Builder->new();
my $pdf = PDF::Builder->new('compress'=>'none');
my $content;
my ($page, $text, $grfx);
my $page_num = 0;

my $name = $0;
$name =~ s/\.pl/.pdf/; # write in examples directory

my $magenta = '#ff00ff';
my $fs = 15;
my ($rc, $next_y, $unused);
print "CAUTION: page 4 requires that your HTML::Tagset installation be patched\n  so that <ins> and <del> are handled properly!\n";
# for debugging use
if (0) { #############################################
} #############################################

print "======================================================= pg 1\n";
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);

print "---- single string entries\n";
$text->column($page, $text, $grfx, 'none', 
	      "This is a single string text.\n\nWith two paragraphs.", 
	      'rect'=>[50,750, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'md1', 
	      "This is a _single string_ **MD** text.\n\nIt should have two paragraphs.", 
	      'rect'=>[50,650, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'html', 
	      "<p>This is a <i>single <b>string</b></i> HTML text.</p><p>With two paragraphs.</p>", 
	      'rect'=>[50,550, 500,50], 'outline'=>$magenta);

print "---- array of string entries\n";
# should be two paragraphs, as a new array element starts a new paragraph
restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'none', 
	      ["This is an array.","Of single string texts. Two paragraphs."], 
	      'rect'=>[50,450, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'md1', 
	      ["This is an **array**\n \n","Of single _string_ MD texts, two paragraphs."], 
	      'rect'=>[50,350, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
$text->column($page, $text, $grfx, 'html', 
	      ['<p>This is an <b>array</b></p>','<p>of single <i>string</i> HTML texts. Two paragraphs.</p>'], 
	      'rect'=>[50,250, 500,50], 'outline'=>$magenta);

restore_props($text, $grfx);
print "---- pre array of hashes\n";
$text->column($page, $text, $grfx, 'pre', [
	{'text'=>'', 'tag'=>'style' }, # dummy style tag
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'This is an array', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'of single string hashes.', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'With ', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'some ', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'i'},
	{'text'=>'markup', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'!', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'/i'},
	{'text'=>'', 'tag'=>'/p'},
], 'rect'=>[50,150, 500,50], 'outline'=>$magenta);

# larger font size and narrower columns to force line wraps
print "======================================================= pg 2\n";
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);

print "---- single string entries\n";
 
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'none', 
	 "This is a single string text.\n\nWith two paragraphs.", 
	 [50,750, 50,50], $magenta, $fs);

restore_props($text, $grfx);
multicol($page, $text, $grfx, 'md1', 
	 "This is a _single string_ **MD** text.\n\nIt should have two paragraphs.", 
	 [50,650, 50,50], $magenta, $fs);

restore_props($text, $grfx);
multicol($page, $text, $grfx, 'html', 
	 "<p>This is a <i>single <b>string</b></i> HTML text.</p><p>Two paragraphs.</p>", 
	 [50,550, 50,50], $magenta, $fs);

print "---- array of string entries\n";
 
# should be two paragraphs, as a new array element starts a new paragraph
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'none', 
         ["This is an array","Of single string texts. Two paragraphs."], 
	 [50,450, 50,50], $magenta, $fs);

# would be glued together into one line, except there is a blank line in middle
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'md1', 
         ["This is an **array**\n\n","Of single _string_ MD texts. Two paragraphs.\n"], 
	 [50,350, 50,50], $magenta, $fs);

# explicitly have two paragraphs
 
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'html', 
	 ["<p>This is an <b>array</b></p>\n","<p>Of single <i>string</i> HTML texts. Two paragraphs.</p>\n"], 
	 [50,250, 50,50], $magenta, $fs);

print "---- pre array of hashes\n";
 
restore_props($text, $grfx);
multicol($page, $text, $grfx, 'pre', [
	{'text'=>'', 'tag'=>'style' }, # dummy style tag
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'This is an array', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'Of single string hashes.', 'tag'=>''},
	{'text'=>'', 'tag'=>'/p'},
	{'text'=>'', 'tag'=>'p'},
	{'text'=>'With ', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'some ', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'i'},
	{'text'=>'markup', 'tag'=>''},
	{'text'=>'', 'tag'=>'b'},
	{'text'=>'!', 'tag'=>''},
	{'text'=>'', 'tag'=>'/b'},
	{'text'=>'', 'tag'=>'/i'},
	{'text'=>'', 'tag'=>'/p'},
    ], [50,150, 50,50], $magenta, $fs);

# let's try some large sample MD and HTML
print "======================================================= pg 3\n";
#
# Lorem Ipsum text ('none') in mix of single string and array
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);

# as an array of strings
my @ALoremIpsum = (
"Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo. Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur 
aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione 
dolor sit, voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem 
ipsum, quia amet, consectetur, adipisci velit, sed quia non numquam eius 
modi tempora incidunt, ut labore et dolore magnam aliquam quaerat 
voluptatem.
",
"Ut enim ad minima veniam, quis nostrum exercitationem ullam 
corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? 
Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam 
nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas 
nulla pariatur?

At vero eos et accusamus et iusto odio dignissimos ducimus, 
qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores 
et quas molestias excepturi sint, obcaecati cupiditate non provident, 
similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum 
et dolorum fuga.


",
"Et harum quidem rerum facilis est et expedita distinctio. 
Nam libero tempore, cum soluta nobis est eligendi optio, cumque nihil 
impedit, quo minus id, quod maxime placeat, facere possimus, omnis voluptas 
assumenda est, omnis dolor repellendus.

",  	 
"Temporibus autem quibusdam et aut 
officiis debitis aut rerum necessitatibus saepe eveniet, ut et voluptates 
repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur 
a sapiente delectus, ut aut reiciendis voluptatibus maiores alias 
consequatur aut perferendis doloribus asperiores repellat.
"
);
my $SLoremIpsum = join("\n",@ALoremIpsum);

print "---- Lorem Ipsum array of string entries, default paragraphs\n";
$text->column($page, $text, undef, 'html', 
  "<h2>Paragraphs with default characteristics</h2>", 'rect'=>[50,730, 500,25]);
# default paragraph indent and top margin
restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'none', \@ALoremIpsum, 
	          'rect'=>[50,700, 500,250], 'outline'=>$magenta );
if ($rc) { 
    print STDERR "Lorem Ipsum array overflowed the column!\n";
}
print "---- Lorem Ipsum string entry, block-style paragraphs\n";
$text->column($page, $text, undef, 'html', 
  "<h2>Paragraphs with block style (no indent, vertical space)</h2>", 'rect'=>[50,380, 500,25]);
# no indent, extra top margin
restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'none', $SLoremIpsum, 
	          'rect'=>[50,350, 500,300], 'outline'=>$magenta, 
		  'para'=>[ 0, 5 ] );
if ($rc) { 
    print STDERR "Lorem Ipsum string overflowed the column!\n";
}

# customer sample Markdown
print "======================================================= pg 4\n";
print "---- Customer sample Markdown and Table\n";
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);

$content = <<"END_OF_CONTENT";
Example of Markdown that needs to be supported in document text blocks. There is no need to support this within tables, although it would be a "nice" feature.

Firstly just some simple styling: *italics*, **bold** and ***both***.

There should also be support for _alternative italics_

Then a bulleted list:

* Unordered item
* Another unordered item

And a numbered list:

1. Item one
2. Item two

# We will need a heading

## And a subheading

Finally we&#x92;ll need some [external links](https://duckduckgo.com).

Show that [another link](https://www.catskilltech.com) on the same page works.

Show some <ins>inserted</ins> text and <u>underlined</u> text that display 
underlines. Show some <del>deleted</del> text, <strike>strike-out</strike> text,
and <s>s'd out</s> text that show line-throughs. 
More than <span style="text-decoration: 'underline line-through overline'">one
at a time</span> are possible via style attribute, also via
<u><s>nested tags</s></u>.

Then we need some styling features in tables as shown in the table below. There is no need to support this in text blocks, although it would be a nice feature (colored text is already available in text blocks using its options).
END_OF_CONTENT
# TBD in above text, <u><s>nested</s></u> <del><ins>tags</ins></del> lost the
# space between the words in Treebuilder? needs investigating

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', 
	          $content, 
		  'rect'=>[50,750, 500,708], 'outline'=>$magenta, 
		  'para'=>[ 0, 5 ] );
if ($rc) { 
    print STDERR "Sample Markdown overflowed the column!\n";
}

# customer sample HTML
$next_y -= 20; # gap to table

if ($use_Table) {
    # use PDF::Table to draw a table, inheriting font from above
    # you need to be careful to end a cell with font, etc. restored
    #   this only works if PDF::Table installed!

    use PDF::Table;
    my $table = PDF::Table->new();
    my $table_data = [
        # row 1, solid color lines
	[
	    [ 'html', '<font color="red">This is some red text</font>',
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ],
            [ 'html', "<span style=\"color:green\">This is some green text</span>",
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ],
	],

        # row 2, special symbols, colored
	[
	    [ 'html', 'This is a red cross: <font face="ZapfDingbats" color="red">8</font>.',
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ],
	    [ 'html', "This is a green tick: <span style=\"font-family:ZapfDingbats; color:green\">4</span>.",
	      { 'font_size' => 12, 'para' => [ 0, 0 ] } ], 
        ],

        # row 3, like row 2, but using macro substitutions
	[
	    [ 'html', "This is a red cross substitute: %cross%.",
	      { 'font_size'=>12, 'para'=>[ 0, 0 ],
		'substitute'=>[
		    ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
		    ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>'] ]
	      }
            ],
	    [ 'html', "This is a green tick substitute: %tick%.",
	      { 'font_size'=>12, 'para'=>[ 0, 0 ],
		'substitute'=>[
		    ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
		    ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>'] ]
	      }
            ],
  	],

        # row 4, non-markup text
	[ 'Plain old text',
	  'More plain text'
        ],
	             ];

    my $size = '* *'; # two equal columns
    $table->table(
        $pdf, $page, $table_data,
        'x'      => 50,
        'y'      => $next_y,
        'w'      => 500,
        'h'      => $next_y-42,
        'next_y' => 750,
        'next_h' => 708,
        'size'   => $size,
        # global markups (can be overridden for row, column, or cell)
        'padding' => 4.5,
    );

} else {
    # fake a table so that PDF::Table is not required within PDF::Builder 
    # examples! 
    # "table" 2 columns width 500, padding 5, font size 12, draw borders 
    # and rules
    # we will show a number of different techniques
    # do 6 cells as 6 small columns in 3x2 grid
    my $table_rows = 4;
    my $table_cols = 2;
    my $cell_height = 20;
    my $row_num = 0;
    # 
 
    # row 1, simple color text
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          '<font color="red">This is some red text</font>', 
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );

    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          '<span style="color:green">This is some green text</span>', 
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $row_num++;

    # row 2, show a tick and cross, changed color, font and span tags
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          'This is a red cross: <font face="ZapfDingbats" color="red">8</font>.', 
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
 
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          "This is a green tick: <span style=\"font-family:ZapfDingbats; color:green\">4</span>.", 
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ] );
    $row_num++;
 
    # row 3, like 2 but illustrate text/HTML substitution
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'md1', 
	          "This is a red cross substitute: %cross%.", 
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
		  'substitute'=>[
		      ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
		      ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>']
	          ]);
 
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'html', 
	          "This is a green tick substitute: %tick%.", 
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
		  'substitute'=>[
		      ['%cross%','<font face="ZapfDingbats" color="red">', '8', '</font>'],
		      ['%tick%','<span style="font-family: ZapfDingbats; color: green;">', '4', '</span>']
	          ]);
    $row_num++;

    # row 4, non-markup text
    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'none', 
	          "Plain old text",
		  'rect'=>[55,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
	         );

    restore_props($text, $grfx);
    $text->column($page, $text, $grfx, 'none', 
	          "More plain text",
		  'rect'=>[305,$next_y-(5+$row_num*$cell_height), 240,20], 
		  'font_size'=>12, 'para'=>[ 0, 0 ], 
	         );
    $row_num++;

    # draw border and rules
    $grfx->poly(50,$next_y, 550,$next_y, 550,$next_y-($table_rows*20), 50,$next_y-($table_rows*20), 50,$next_y);
    # horizontal dividers between rows
    for (my $r = 1; $r < $table_rows; $r++) {
        $grfx->move(50,$next_y-($r*20));
        $grfx->hline(550);
    }
    # vertical divider between columns
    $grfx->move(300,$next_y);
    $grfx->vline($next_y-60);
    # draw it all
    $grfx->strokecolor('black');
    $grfx->stroke();
}

# more pages with more extensive MD
print "======================================================= pg 5-10\n";
print "---- A README.md file for PDF::Builder\n";
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);
#  might need three or four pages
#  three <img> calls (GitHub buttons), several `code` 
#  escape $ and \ in several lines, unescape \* 
#  example block in Paper Sizes note needs manual reformat (revisit
#    when <pre> supported)
$content = <<"END_OF_CONTENT";
# PDF::Builder release 3.027

A Perl library to create and modify PDF (Portable Document Format) files

## What is it?

PDF::Builder is a **fork** of the popular PDF::API2\* Perl library. It
provides a library of modules and functions so that a PDF file (document) may
be built and maintained from Perl programs (it can also read in, modify, and
write back out existing PDF files). It is not a WYSIWYG editor; nor is it a
canned utility or converter. It does _not_ have a GUI or command line interface
-- it is driven by _your_ Perl program. It is a set of **building blocks**
(methods) with which you can perform a wide variety of operations, ranging
from basic operations (such as selecting a font face), to defining an entire
page at a time in the document (using a large subset of either Markdown or HTML
markup languages). You can call it from arbitrary Perl programs, which may even
create content on-the-fly (or read it in from other sources). Quite a few code
examples are provided, to help you to get started with the process of creating
a PDF document. Many enhancements are in the pipeline to make PDF::Builder even
more powerful and versatile.

\\*Note that PDF::Builder is **not** built on PDF::API2, and does **not**
require that it be installed. The two libraries are completely independent of
each other and one will not interfere with the other if both are installed.

**Gadzooks!** For a delightful look at the (rather grisly) origin of this
typographical term, as well as many other terms, watch
https://www.youtube.com/watch?v=cd5iFbuNKv8 .

[Home Page](https://www.catskilltech.com/FreeSW/product/PDF%2DBuilder/title/PDF%3A%3ABuilder/freeSW_full), including Documentation and Examples.

[![Open Issues](https://img.shields.io/github/issues/PhilterPaper/Perl-PDF-Builder)](https://github.com/PhilterPaper/Perl-PDF-Builder/issues)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](https://makeapullrequest.com)
[![Maintenance](https://img.shields.io/badge/Maintained%3F-yes-green.svg)](https://GitHub.com/PhilterPaper/Perl-PDF-Builder/graphs/commit-activity)

This archive contains the distribution PDF::Builder.
See **Changes** file for the version and list of changes from the previous
release.

## Obtaining and Installing the Package

The installable Perl package may be obtained from
"https://metacpan.org/pod/PDF::Builder", or via a CPAN installer package. If
you install this product, only the run-time modules will be installed. Download
the full `.tar.gz` file and unpack it (uncompress, then extract directory --
hint: on Windows, **7-Zip File Manager** is an excellent tool) to get
utilities, test buckets, example usage, etc.

Alternatively, you can obtain the full source files from
"https://github.com/PhilterPaper/Perl-PDF-Builder", where the ticket list
(bugs, enhancement requests, etc.) is also kept. Unlike the installable CPAN
version, this will have to be manually installed (copy files; there are no XS
compiles at this time).

Other than an installer for standard CPAN packages (such as 'cpan' on
Strawberry Perl for Windows), no other tools or manually-installed prereqs are
needed (worst case, you can unpack the `.tar.gz` file and copy files into
place yourself!). Currently there are no compiles and links (Perl extensions)
done during the install process, only copying of .pm Perl module files. 

A package installer such as "cpan" (included with Strawberry Perl and some
other systems) can retrieve the package, unpack and copy files, and run 
installation tests without manual intervention. Not only PDF::Builder itself, 
but any needed prerequisites, may be quickly installed in this manner. Some 
Perl distributions (e.g., ActiveState) may repackage PDF::Builder and 
prerequisites into their own install format, as may Linux distributions such
as Red Hat or SUSE. Finally, it is possible to copy files directly from the 
GitHub repository to your system, and manually run the "t" (installation) 
tests, all without going through a `.tar.gz` CPAN package. There are many 
possibilities.

Note that there are several "optional" libraries (Perl modules) used to extend
and improve PDF::Builder. Read about the list of optional libraries in
PDF::Builder::Docs, and decide whether or not you want to install any of them.
By default, **none** are installed.

## Requirements

### Perl

**Perl 5.28** or higher. It will likely run on somewhat earlier versions, but
the CPAN installer may refuse to install it. The reason this version was
chosen was so that LTS (Long Term Support) versions of Perl going back about
6 years are officially supported (by PDF::Builder), and older versions are not
supported. The intent is to not waste time and effort trying to fix bugs which
are an artifact of old Perl releases.

Usually about once a year the minimum level is bumped up, but this depends on 
whether Strawberry releases the newest Perl level. As Strawberry Perl releases 
new Perl levels, usually on an annual basis, we intend to bump up our required 
minimum Perl level (even-numbered production releases), to keep support for the 
last 6 calendar years of Perl releases, dropping older ones.

#### Older Perls

If you MUST install on an older (pre 5.28) Perl, you can try the following for
Strawberry Perl (Windows). NO PROMISES! Something similar MAY work for other
OS's and Perl installations:

1. Unpack installation file (`.tar.gz`, via a utility such as 7-Zip) into a directory, and cd to that directory
1. Edit META.json and change 5.028000 to 5.016000 or whatever level desired
1. Edit META.yml and change 5.028000 to 5.016000 or whatever level desired
1. Edit Makefile.PL and change `use 5.028000;` to `use 5.016000;`, change `\$PERL_version` from `5.028000` to `5.016000`
1. `cpan .`

Note that some Perl installers MAY have a means to override or suppress the
Perl version check. That may be easier to use. Or, you may have to repack the
edited directory back into a `.tar.gz` installable. YMMV.

If all goes well, PDF::Builder will be installed on your system. Whether or
not it will RUN is another matter. Please do NOT open a bug report (ticket)
unless you're absolutely sure that the problem is not a result of using an old
Perl release, e.g., PDF::Builder is using a feature introduced in Perl 5.022
and you're trying to run Perl 5.012!

### Libraries used

These libraries are available from CPAN.

#### REQUIRED

These libraries should be automatically installed...

* Compress::Zlib
* Font::TTF
* Test::Exception (needed only for installation tests)
* Test::Memory::Cycle (needed only for installation tests)

#### OPTIONAL

These libraries are _recommended_ for improved functionality and performance.
The default behavior is **not** to attempt to install them during PDF::Builder
installation, in order to speed up the testing process and not clutter up
matters, especially if an optional package fails to install. You can always
manually install them later, if you desire to make use of their added
functionality.

* Perl::Critic (1.150 or higher, need if running tools/1\_pc.pl)
* Graphics::TIFF (19 or higher, recommended if using TIFF image functions)
* Image::PNG::Libpng (0.57 or higher, recommended for enhanced PNG image function processing)
* HarfBuzz::Shaper (0.024 or higher, needed for Latin script ligatures and kerning, as well as for any complex script such as Arabic, Indic scripts, or Khmer)
* Text::Markdown (1.000031 or higher, needed if using 'md1' markup)
* HTML::TreeBuilder (5.07 or higher, needed if using 'html' or 'md1' markup)
* Pod::Simple::XHTML (3.45 or higher, needed if using buildDoc.pl utility to create HTML documentation)
* SVGPDF (0.087 or higher, needed if using SVG image functions)

If an optional package is needed for certain extended functionality, but not
installed, sometimes PDF::Builder
will be able to fall back to built-in partial functionality (TIFF and PNG
images), but other times will fail. After installing the missing package, you
may wish to then run the t-test suite for that library to confirm that it is
properly running, as well as running the examples.

**Note** that some of these packages, in turn, make use of various open source
libraries (DLLs/shared libs) that you may need to hunt around for, and install
on your system before you can install a given package. That is, they may not
necessarily come with your Operating System or Perl installation. Some such
packages may try to use "Alien" to build such prereqs, if missing. Other
packages are "pure Perl" and should install without trouble.

#### Fixes needed to OPTIONAL packages

Sometimes fixes or patches are needed for optional prerequisites. See the file
**INFO/Prereq\_fixes.md** for a list of known issues.

### External utilities

t/tiff.t (install testing for TIFF support) makes use of GhostScript and 
ImageMagick (convert utility). You may need to install these in order to get
full testing (tests that need them will be skipped if they are not installed).
Note that it has been reported that some versions of Mac Perl systems have
a 'convert' utility that is missing the default Arial font, and thus will fail
(see ticket 223).

## Manually building

As is the usual practice with building such a package (from the command line),
the steps are:

1. perl Makefile.PL
1. make
1. make test
1. make install

If you have your system configured to run Perl for a .pl/.PL file, you may be
able to omit "perl" from the first command, which creates a Makefile. "make"
is the generic command to run (it feeds on the Makefile produced by
Makefile.PL), but your system may have it under a different name, such as
dmake, gmake (e.g., Strawberry Perl on Windows), or nmake.

PDF::Builder does not currently compile and link anything, so `gcc`, `g++`,
etc. will not be used. The build process merely copies .pm files into place,
and runs the "t" tests to confirm the proper installation.

## Copyright

This software is Copyright (c) 2017-2025 by Phil M. Perry.

Previous copyrights are held by others (Steve Simms, Alfred Reibenschuh, 
et al.). See The HISTORY section of the documentation for more information.

We would like to acknowledge the efforts and contributions of a number of
users of PDF::Builder (and its predecessor, PDF::API2), who have given their
time to report issues, ask for new features, and have even contributed code.
Generally, you will find their names listed in the Changes and/or issue tickets
related to some particular item. See the **INFO/ACKNOWLEDGE.md** and
**INFO/SPONSORS** files.

## License

This is free software, licensed under:

`The GNU Lesser General Public License, Version 2.1, February 1999`

EXCEPT for some files which are explicitly under other, compatible, licenses
(the Perl License and the MIT License). You are permitted (at your option) to
redistribute and/or modify this software (those portions under LGPL) at an
LGPL version greater than 2.1. See INFO/LICENSE for more information on the
licenses and warranty statement.

### Carrying On...

PDF::Builder is Open Source software, built upon the efforts not only of the
current maintainer, but also of many people before me. Therefore, it's perfectly
fair to make use of the algorithms and even code (within the terms of the
LICENSE). That's exactly how the State of the
Art progresses! Just please be considerate and acknowledge the work of others
that you are building on, as well as pointing back to this package. Drop us a
note with news of your project (if based on the code and algorithms in
PDF::Builder, or even just heavily inspired by it) and we'll be happy to make
a pointer to _your_ work. The more cross-pollination, the better!

## See Also

* INFO/SUPPORT file for information on reporting bugs, etc. via GitHub Issues
* INFO/DEPRECATED file for information on deprecated features
* INFO/KNOWN\_INCOMP file for known incompatibilities with PDF::API2
* INFO/Prereq\_fixes.md possible patches for prerequisites
* CONTRIBUTING file for how to contribute to the project
* LICENSE file for more on the license term
* INFO/RoadMap file for the PDF::Builder road map
* INFO/ACKNOWLEDGE.md for "thank yous" to those who contributed to this product
* INFO/CONVERSION file for how to convert from PDF::API2 to PDF::Builder
* INFO/Changes\* files for older change logs
* INFO/PATENTS file for information on patents

`INFO/old/` also has some build and test tool files that are not currently used.

## Documentation

To build the full HTML documentation (all the POD), get the full installation
and go to the `docs/` directory. Run `buildDoc.pl --all` to generate the full
tree of documentation. There's a lot of additional information in the
PDF::Builder::Docs module (it's all documentation).

You may find it more convenient to point your browser to our
[Home Page](https://www.catskilltech.com/FreeSW/product/PDF-Builder/title/PDF%3A%3ABuilder/freeSW_full)
to see the full documentation build (as well as most of the example outputs).

We admit that the documentation is a bit light on "how to" task orientation.
We hope to more fully address this in the future, but for now, get the full
installation and look at the `examples/` and `contrib/` directories for sample
code that may help you figure out how to do things. The installation tests in
the `t/` and `xt/` directories might also be useful to you.

### A Note on Paper Sizes

Per PDF specifications, the default paper (media) size set in PDF::Builder
is 'US Letter' (8.5in x 11in, 216mm x 279mm). If you're in the civilized world,
and don't measure things in "bananas",
you may wish to specify 'A4' instead, in the `\$pdf->mediabox('A4');` call.
Note that A4 is narrower and taller than Letter. If you want to ensure that
your output will be printable around the world, consider using the _universal_
paper size: `\$pdf->mediabox('universal');`.
This will result in some wasted
space at the top of a printed A4 page, or some wasted right margin on a printed
Letter page, but it's better than having content cut off! It may also be
satisfactory to leave sufficient _margins_ around document content on standard
US Letter _or_ A4 media, with the following **minimum** margins (allowing
3mm/.125" for paper handling, plus extra for media size differences):

`bottom: 3mm = .125" = 9pt`  (bottom same for all media)

`left:   3mm = .125" = 9pt`  (left same for all media)


`A4 top:     21mm = .83" = 60pt` (A4 taller than Letter)

`Letter top: 3mm = .125" = 9pt`

`Letter right:  9mm = .375" = 27pt` (Letter wider than A4)

`A4 right:      3mm = .125" = 9pt`

Please see the discussion on `mediabox()` and other "box" calls, about how
much of a page can actually be _printed_ on, allowing for pinch rollers and
other paper transport mechanisms. The above suggested margins assume, in
addition to Letter paper being .25" wider and .7" shorter than A4, that 1/8"
(9pt, 3mm) of paper is unprintable around the edges; your printer may vary.
END_OF_CONTENT

restore_props($text,$grfx);
# page 5
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>[ 0, 5 ] );
# pages 6-8
while ($rc) { 
    # new page. uses fixed column template, no headers/footers/page numbers
    $page = $pdf->page();
    $grfx = $page->gfx();
    $text = $page->text();
    footer(++$page_num, $pdf, $text);

#print Dumper($unused) if $page_num == 7;
    ($rc, $next_y, $unused) =
        $text->column($page, $text, $grfx, 'pre', $unused, 
		      'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		      'para'=>[ 0, 5 ] );
}

# for various lists, see Column_lists.pl

# block quotes and font extent changes
print "======================================================= pg 11\n";
print "---- Block quotes\n";
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);

$content = <<"END_OF_CONTENT";
<h2>Block Quote (left and right margins)</h2>
<p>Sed ut perspiciatis, &mdash; unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo. Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur 
aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione 
dolor sit, voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem 
ipsum, quia amet, consectetur, adipisci velit, sed quia non numquam eius 
modi tempora incidunt, ut labore et dolore magnam aliquam quaerat 
voluptatem.</p>
<blockquote>Ut enim ad minima veniam, quis nostrum exercitationem ullam 
corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? 
Quis autem vel eum iure reprehenderit, qui in ea voluptate velit esse, quam 
nihil molestiae consequatur, vel illum, qui dolorem eum fugiat, quo voluptas 
nulla pariatur?
At vero eos et accusamus et iusto odio dignissimos ducimus, 
qui blanditiis praesentium voluptatum deleniti atque corrupti, quos dolores 
et quas molestias excepturi sint, obcaecati cupiditate non provident, 
similique sunt in culpa, qui officia deserunt mollitia animi, id est laborum 
et dolorum fuga.</blockquote>
<p>Sed ut perspiciatis, unde omnis iste natus error sit 
voluptatem accusantium doloremque laudantium, totam rem aperiam eaque ipsa, 
quae ab illo inventore veritatis et quasi architecto beatae vitae dicta 
sunt, explicabo. Nemo enim ipsam voluptatem, quia voluptas sit, aspernatur 
aut odit aut fugit, sed quia consequuntur magni dolores eos, qui ratione 
dolor sit, voluptatem sequi nesciunt, neque porro quisquam est, qui dolorem 
ipsum, quia amet, consectetur, adipisci velit, sed quia non numquam eius 
modi tempora incidunt, ut labore et dolore magnam aliquam quaerat 
voluptatem.</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,300], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) { 
    print STDERR "Block quotes example overflowed column!\n";
}

print "---- Font size changes\n";
$content = <<"END_OF_CONTENT";
<p><span style="font-size: 15pt">Here is some text at 15 point size. We follow
it <i>somewhere</i> down the line with <span style="font-size: 45pt">much larger text, 
<span style="font-size:  60pt"><s>and</s> follow <span style="text-decoration: overline;">it</span> with some ginormous text.</span> <u>That</u> 
should have moved the entirety of the baseline </span><span style="text-decoration: overline;">down</span> by quite a bit, 
while maintaining an even baseline.</span></p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,425, 500,380], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ] );
if ($rc) { 
    print STDERR "Font size changes example overflowed column!\n";
}

# setting your own CSS for Markdown or none
print "======================================================= pg 12\n";
$page = $pdf->page();
$grfx = $page->gfx();
$text = $page->text();
footer(++$page_num, $pdf, $text);

print "---- horizontal rules Markdown\n";
$content = <<"END_OF_CONTENT";
Markdown horizontal rules: 3 or more ---, ***, or ___. full width

----------

Between two rules

****

Between two rules

___

Last commentary
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,125], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "Markdown horizontal rule example overflowed column!\n";
}

# note some tags capitalized, and some attributes capitalized
print "---- horizontal rules HTML\n";
$content = <<"END_OF_CONTENT";
<p>HTML horizontal rules, with CSS</p>
<hR>
<p>Between two rules, above is default settings</p>
<hr style="height: 5; color: blue">
<p>Between two rules, above is very thick and blue</p>
<hr style="width: 200" />
<P>Above rule is only 200pt long</p>
<HR size="17" Color="orange" WIDTH="300">
<p>Above rule is <em>very</em> thick orange and 300pt long</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,585, 500,185], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "HTML horizontal rule example overflowed column!\n";
}

print "---- PDF page link\n";
$content = <<"END_OF_CONTENT";
Let's try linking to [another page](#4) of this document.

Also try a link to a [specific place](#4-50-200) unzoomed.

While we're here, how about [linking](#4-50-200-1.5) with zoom-in?
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,375, 500,100], 'outline'=>$magenta, 
		  'para'=>[ 0, 10 ],
	         );
if ($rc) { 
    print STDERR "PDF links example overflowed column!\n";
}

# --------------
# some bogus tags and CSS properties
# expect one message about invalid 'glotz' tag. notice that HTML::TreeBuilder
#   does NOT insert an extra </glotz> tag into the stream, as one already found
# expect 'snork' CSS to be ignored
#
print "---- Bogus HTML tags and CSS property names\n";
$content = <<"END_OF_CONTENT";
<p>
<glotz>This is within a 'glotz' tag</glotz>. 
This is <glotz>within another.</glotz>
</p>

<p style="snork: 1em;">This paragraph has CSS 'snork' property.</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,260, 500,60], 'outline'=>$magenta, 
		  'para'=>[ 0, 10 ],
	         );
if ($rc) { 
    print STDERR "Invalid tags and CSS example overflowed column!\n";
}
 
# ------ some <_move> and text-align usage
#
print "---- <_move> and text-align usage\n";
$content = <<"END_OF_CONTENT";
<p>
<span style="text-align: left;">text-align: left</span>
</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[100,187, 400,13], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "1. <_move> and text-align example overflowed column!\n";
}
 
$content = <<"END_OF_CONTENT";
<p>
<_move x="50%"><span style="text-align: center;">text-align: center</span>
</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[100,174, 400,13], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "2. <_move> and text-align example overflowed column!\n";
}
 
$content = <<"END_OF_CONTENT";
<p>
<_move x="100%"><span style="text-align: right;">text-align: right</span>
</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[100,161, 400,13], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "3. <_move> and text-align example overflowed column!\n";
print "rc=$rc, leftover text =\n";
print Dumper(@$unused);
}
 
$content = <<"END_OF_CONTENT";
<p>
<_move x="50%"><span style="text-align: center;">1.text at center</span>
<_move x="0%"><span style="text-align: left;">2.explicit LJ at 0%</span>
<_move x="100%"><span style="text-align: right;">3.RJ text at 100%</span>
</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[100,144, 400,13], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "4. <_move> and text-align example overflowed column!\n";
}
 
$content = <<"END_OF_CONTENT";
<p>
<_move x="50%" dx="72">1.Center+72pt LJ text.
<_move x="50%" dx="-72"><span style="text-align: center;">2.Center-72pt CJ text.</span>
</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[100,131, 400,13], 'outline'=>$magenta, 
		  'para'=>[ 0, 0 ],
	         );
if ($rc) { 
    print STDERR "5. <_move> and text-align example overflowed column!\n";
}
 
# Column_layouts.pl TBD
# TBD figure out a good way to fall back for unavailable fonts
# demonstrate balanced columns two long columns and one short, first pass
#   fill blindly, overflowing to column 2 then 3, then by trial-and-error
#   shorten long two columns until short one just fills (show initial and
#   final runs). graphic X-out block for ad.
#   headline in English Towne Medium (.otf) "New Yawk Times" ("All the news
#   that fits, we print!"). Headline under it (across 3 columns): "Congress
#   Does Something Stoopid". Lorem Ipsum for body text.
#   continuation to page __ method? text to output for very last line in col.
# demonstrate column shapes that split line in two (only first part used)
# demonstrate irregularly shaped columns, including a bowtie scaled 3 times
# demonstrate two column layout with insets and marginpar (inset routine to
#   place text w/ hr's, return cutout outline for columns outline creation,
#   intersect with rectangles for columns)
# demonstrate a circular column, etc.
# demonstrate a spline column cutout, with image in background with edges
#   that fade away so text can overlap outer fringes of image
# ---------------------------------------------------------------------------
# end of program
$pdf->saveas($name);
# -----------------------
 
sub footer {
    my ($page_num, $pdf, $text) = @_;
    # columns are generally 50 - 500 so center page number there
    # save current font and size
    my ($cur_font, $cur_fs) = $text->font();

    $text->font($pdf->get_font('face'=>'sans-serif', 'italic'=>0, 'bold'=>0), 10);
    $text->translate((500-50)*0.5+50, 10);
    $text->text("- $page_num -", 'align'=>'center');

    # restore font conditions on entry (if they were ever set)
    $text->font($cur_font, $cur_fs) if $cur_fs > 0;
    return;
}
# -----------------------

sub multicol {
    my ($page, $text, $grfx, $markup, $content, $rect, $outline, $fs) = @_;

    my ($rc, $start_y);

    ($rc, $start_y, $content) = 
        $text->column($page, $text, $grfx, $markup, $content, 
		      'rect'=>$rect, 'outline'=>$outline, 'font_size'=>$fs);
    while ($rc == 1) { # ran out of column, do another
	$rect->[0] += 50+$rect->[2];
        ($rc, $start_y, $content) = 
            $text->column($page, $text, $grfx, 'pre', $content, 
		          'rect'=>$rect, 'outline'=>$outline, 'font_size'=>$fs);
    }
    return;
}

# pause during debug
sub pause {
    print STDERR "=====> Press Enter key to continue...";
    my $input = <>;
    return;
}

#   restore font and color in case previous column left it in an odd state.
#   the default behavior is to use whatever font and color was left from any
#     previous operation (not necessarily a column() call) unless it was 
#     overridden by various settings.
sub restore_props {
    my ($text, $grfx) = @_;

#   $text->fillcolor('black');
#   $grfx->strokecolor('black');
    # italic and bold get reset to 'normal' anyway on column() entry,
    # but need to fix font face in case it was left something odd
#   $text->font($pdf->get_font('face'=>'default', 'italic'=>0, 'bold'=>0), 12);

    return;
}
