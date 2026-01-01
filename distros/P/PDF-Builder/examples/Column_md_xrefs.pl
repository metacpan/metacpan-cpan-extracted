#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
 use Data::Dumper; # for debugging
  $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

our $VERSION = '3.028'; # VERSION
our $LAST_UPDATE = '3.028'; # manually update whenever code is changed

my $fwd_ref = 0; # 1 to use HTML causing a forward reference and two passes

my $content;
my ($pdf, $page, $text, $grfx);

my $name = $0;
$name =~ s/\.pl/.pdf/; # write in examples directory
# TBD eventually there will be several documents of around 5 pages each

my $max_passes = 5;  # rec min 2, to ensure no visible changes in text
my $magenta = '#ff00ff';
my $fs = 15;
my $paras = [ 0, 7 ]; # paragraph indentation and top margin defaults: pts
my $debug = 0; # box around link text, red | at link target, blue | at
               # named destination point. 0/default = off, 1 = on
my ($rc, $next_y, $unused);

# initialize %state before first pass of column() call(s)
my %state = PDF::Builder->init_state(       # various settings
	# besides '_reft', tags used as reference targets (with id)
	# this list will vary by document
	{'_reft' => [ 'h1', 'h2', 'h3' ], } # _reft automatically added
	                    );
#print "initialized state tag_lists =\n";
#foreach (keys %{$state{'tag_lists'}}) {
# print "$_: [ @{$state{'tag_lists'}{$_}} ]\n";
#}

my ($ppn, $fpn);

for (my $pass_count=1; $pass_count<=$max_passes; $pass_count++) {
    # $pdf is global and only defined once, while everything else is
    # processed possibly multiple times until all content settles down
    print "**************************** pass $pass_count\n";

    # create $pdf object at every pass, to ensure old pages, etc. go away
    # TBD: add method to explicitly delete pages instead, permitting $pdf
    #      to be defined once before pass loop
   #$pdf = PDF::Builder->new();
    $pdf = PDF::Builder->new('compress'=>'none');

    $pdf->pass_start_state($pass_count, $max_passes, \%state);
    $ppn = 0;     # physical page number 1,2,... restart every pass

$ppn++;
print "======================================================= page $ppn\n";
$page = $pdf->page(); 
$fpn = "#".$ppn;  # formatted page = #physical page 1+
$text = $page->text();
$grfx = $page->gfx();

# output page number
$content = "<p><_move x=\"50%\"><span style=\"font-family: Helvetica; text-align: center;\">$fpn</span></p>";
$text->column($page, $text, $grfx, 'html', $content, 
	      'rect'=>[50,25, 500,25]);

$content = <<"END_OF_CONTENT";

# Chapter One, the End of the Beginning {#chap1}

Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod 
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo 
consequat. See [Explanation 1](xpage) for more. Duis aute 
irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat 
nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa 
qui officia deserunt mollit anim id est laborum.

## {#lesser} Something of lesser importance

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium 
doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore 
veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim 
ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia 
consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque 
porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, 
adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et 
dolore magnam aliquam quaerat voluptatem. <_reft id="back1" 
title="My Own Title" />. Ut enim ad minima veniam, quis nostrum exercitationem 
ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? 
Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam 
nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas 
nulla pariatur?
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras, 'start_y'=>$next_y,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 1A overflowed column!\n";
}

#print "=================== state after 1A\n"; print Dumper(%state);
$content = <<"END_OF_CONTENT";

At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis 
praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias 
excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui 
officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum 
quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta 
nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat 
facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Look
back at the very beginning of this document, 
[Chapter One (shortened)](chap1). 
Temporibus autem quibusdam et aut officiis debitis aut rerum 
necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non 
recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut 
reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus 
asperiores repellat.

Lorem <_reft id="Lorem" title="Lorem ipsum place" /> ipsum dolor sit amet, 
consectetur adipiscing elit. Proin id ante 
turpis. In aliquam id enim sed pharetra. Aenean cursus at nisi consectetur 
semper. Ut risus libero, finibus a aliquet ac, venenatis sit amet ligula. 
Praesent accumsan sapien vel cursus scelerisque. Integer nibh massa, porttitor 
eu fringilla sit amet, finibus vel purus. [A Link to the Second 
Heading](#lesser). Nunc laoreet metus eget malesuada pharetra. Sed nulla 
enim, consequat non blandit id, pretium sed erat. Just for the halibut, let's
[go back a little](back1) on this page. Donec in auctor 
elit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere 
cubilia curae; Duis placerat sollicitudin lacinia. Phasellus quis finibus diam, 
at fringilla ex.
END_OF_CONTENT

if ($fwd_ref) {
    $content .=
"
### Forward references causing a second pass

This is a forward reference using a *title* given at the target: [](xpage). 
And here is one using the target's natural text: [](someother).
";
#
#This is a forward reference with no title, target title, or natural text:
#[](Linking). It should say \"\[no title given\]\" as the link text.
#This is a forward reference to a non-existent target: [](glotz).
#There should be an error message for a dead link, as well as 
#\"\[no title given\]\".
#"
}

## test strike-out ~~ WORKS (with fix to Text)
#$content .= "\nThis line ~~should be struck~~ out.";
## test 3 forms of horizontal rule WORKS (=== with fix to Text)
#$content .= "\nhorizontal rule using hyphens\n\n---\n";
#$content .= "\nhorizontal rule using equals\n\n===\n";
#$content .= "\nhorizontal rule using underscores\n\n___\n";
## test underline WORKS
#$content .= "\nThis is <u>underlined</u> text, and this is <ins>inserted</ins> text.\n";
## test sub- and super-scripts does NOT work
#$content .= "\nH~2~O is water, x^2^ is x squared\n";
## test block quote WORKS, Text needs some work
#$content .= "\n> This is block quoted.\n";
## test nested block quote WORKS
#$content .= ">> This is double block quoted.\n";
## test paragraph within block WORKS
#$content .= "\n> A block quote\n\n> A new paragraph in BQ\n";
## test ordered list WORKS
#$content .= "\n1. item 1\n1. item 2\n";
#$content .= "    + item 1\n    + item 2\n";
#$content .= "1. item 3\n";
## test inline code and code blocks does NOT work
#$content .= "\nThis is `a code block` which s/b formatted fixed pitch.\n";
#$content .= "```\nThis is a fenced\n  code block.\n```\n";
## test <url> link WORKS 
#$content .= "\nThis is an <https://www.catskilltech.com> inline link right here.\n";
## test <email address> mailto link. note that @ must be escaped if within "
##   <a href="mailto:someone@somewhere.com">someone@somewhere.com</a>
##   WORKS, but is obfuscated
#$content .= "\nThis is an <someone\@somewhere.com> email address.\n";
## test url link does not WORK 
#$content .= "\nThis is an https://www.catskilltech.com inline link right here.\n";
## test <email address> mailto link. note that @ must be escaped if within "
##   does not WORK
#$content .= "\nThis is an someone\@somewhere.com email address.\n";

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras, 'start_y'=>$next_y,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 1B overflowed column!\n";
}

$ppn++;
#print "=================== state after 1B\n"; print Dumper(%state);
print "======================================================= page $ppn\n";
$page = $pdf->page();
$fpn = "#".$ppn;  # formatted page = #physical page
$text = $page->text();
$grfx = $page->gfx();

# output page number
$content = "<p><_move x=\"50%\"><span style=\"font-family: Helvetica; text-align: center;\">$fpn</span></p>";
$text->column($page, $text, $grfx, 'html', $content, 
	      'rect'=>[50,25, 500,25]);

$content = <<"END_OF_CONTENT";

## Here is a heading {#someother} for something or other

In odio elit, feugiat eget diam mattis, convallis lacinia sapien. Fusce 
convallis nunc enim, semper rhoncus eros porta vel. 
Nullam non velit sodales lectus vulputate condimentum. 
[Eat more of these delicious condiments.](lesser)
Fusce convallis neque nec velit pellentesque, quis suscipit nisi 
semper. Curabitur vitae ultrices dui. Nulla ut massa sit amet orci ultrices 
vestibulum non in urna. Curabitur ullamcorper metus id elementum lobortis. 
Suspendisse massa neque, tempor fermentum quam a, facilisis condimentum 
dolor.

Etiam sed vehicula ipsum. Nullam ac libero elit. Praesent vitae felis ut 
nulla rhoncus tristique. Remember the first heading [Big Shot](chap1)? There's 
a Named Destination right 
here -&gt;<_nameddest name="foo" />&lt;- here. 
Phasellus congue eros quis tellus mollis, ac vehicula quam luctus. 
Praesent nunc ipsum, fringilla nec odio ac, efficitur fermentum nisl. 
Pellentesque suscipit augue eu sodales euismod. Donec a ex mauris. Aenean in 
diam ut purus feugiat bibendum. Proin a orci convallis, gravida arcu ultricies, 
dapibus magna. Go [back to this page heading](someother).
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 2A overflowed column!\n";
}

#print "=================== state after 2A\n"; print Dumper(%state);
$content = <<"END_OF_CONTENT";

Integer vel dolor neque. Vestibulum scelerisque, sem eu bibendum tincidunt, 
libero odio rutrum ante, eu fringilla felis felis sit amet dolor. 
<_reft id="xpage" title="Another Cross Page link" />Cras et gravida arcu. 
Etiam ut quam pellentesque, tempor nisi in, aliquet purus. Aenean feugiat lorem 
sed eros suscipit, sit amet rhoncus urna dignissim. Nulla ac ipsum quis lorem 
dapibus scelerisque. Etiam condimentum turpis consectetur leo ultrices dapibus. 
Phasellus blandit mauris ac maximus facilisis. Vivamus convallis fringilla sem 
vel luctus. Pellentesque habitant morbi tristique senectus et netus et 
malesuada fames ac turpis egestas. Donec mattis ex id purus sagittis, a tempus 
urna fermentum. Aliquam euismod massa et lorem mollis varius.

Nam enim dui, efficitur eu tincidunt sed, fermentum a ipsum. Donec et velit ac 
dolor aliquam vehicula. Class aptent taciti sociosqu ad litora torquent per 
conubia nostra, per inceptos himenaeos. Fusce ut diam dolor. Curabitur et velit 
sit amet sapien volutpat faucibus sit amet vel libero. Nam in porttitor risus. 
Quisque sem nunc, viverra sed lectus cursus, lobortis egestas ipsum. Vivamus ut 
felis fringilla, rhoncus lectus ut, porta nisl. Aenean imperdiet sem eget magna 
bibendum dapibus. Vivamus luctus mauris eget vehicula maximus. Proin facilisis 
nulla vitae felis iaculis, et lobortis enim ultricies. Donec lacinia justo nec 
metus convallis suscipit. Nam varius a augue eu rhoncus. In hac habitasse 
platea dictumst. 

Link back to the heading, using its natural title: [](chap1).
Now link to one using its specified title: 
[{%xyz,%x,%y,2}](Lorem).

## Fully specified links

### Internal Links {#intlinks}  

<_reft id="Linking" />Linking within the same document to 
[same PDF](##foo) with a Named Destination target. Then 
link to it [first page](#1-50-600-undef)
at x,y = 50,600 with xyz fit. Finally, 
link to [that page {%fitv,200}](#1) on page 1 with a 
specified fit.

### {#extlinks} External Links

Note that the following examples use fixed target (path and filename) files.
If you do not have examples/resources/040_annotation.pdf in the right place (and
built with the Named Destination), these links will probably **not**
work!

Rather than linking within the same document, let's try 
[finding Nemo](resources/040_annotation.pdf##bar) 
with a Named Destination target. Then link to it
[on second page {%xyz,50,600,2.5}](resources/040_annotation.pdf#2)
at a specified x,y with xyz fit at a certain location.
Finally, link to
[{%fith,200} that page](resources/040_annotation.pdf#2)
with a specified fit.
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'md1', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras, 'start_y'=>$next_y,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 2B overflowed column!\n";
}

#print "=================== state after 2B\n"; print Dumper(%state);
# ---------------------------------------------------------------------------

    $rc = $text->pass_end_state($pass_count, $max_passes, $pdf, \%state
          ,'debug'=>$debug
    );
    # if rc is 0, we can quit the loop (everything has settled down)
    #  after outputting all the annotations (actual links) in the PDF
    if (!$rc) { last; }
    print "***** $rc link targets have not settled down yet.\n";

} # end of pass_count loop
if ($rc) {
    print "Content did not stabilize. The following target ids (tgtid)\n  were not settled down when maximum number of passes ($max_passes) was reached:\n";
    print $text->unstable_state(\%state);
    print "You may wish to adjust the input to resolve this.\n";
}

# end of program
$pdf->saveas($name);
# -----------------------

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
