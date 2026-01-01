#!/usr/bin/perl
#
use warnings;
use strict;
use PDF::Builder;
#use Data::Dumper; # for debugging
# $Data::Dumper::Sortkeys = 1; # hash keys in sorted order

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

for (my $pass_count=1; $pass_count <= $max_passes; $pass_count++) {
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
<h1 id="chap1">Chapter One, the End of the Beginning</h1>

<p>Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod 
tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, 
quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo 
consequat. See <a href="xpage">Explanation 1</a> for more. Duis aute 
irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat 
nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa 
qui officia deserunt mollit anim id est laborum.</p>

<h2 id="lesser">Something of lesser importance</h2>

<p>Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium 
doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore 
veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim 
ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia 
consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque 
porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, 
adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et 
dolore magnam aliquam quaerat voluptatem. <_reft id="back1" 
title="My Own Title">. Ut enim ad minima veniam, quis nostrum exercitationem 
ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? 
Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam 
nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas 
nulla pariatur?</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras, 'start_y'=>$next_y,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 1A overflowed column!\n";
}

$content = <<"END_OF_CONTENT";
<p>At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis 
praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias 
excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui 
officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum 
quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta 
nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat 
facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Look
back at the very beginning of this document, 
<a href="chap1">Chapter One (shortened)</a>. 
Temporibus autem quibusdam et aut officiis debitis aut rerum 
necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non 
recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut 
reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus 
asperiores repellat.</p>
<!-- TBI <_reft> first item in <p> causes no top margin! -->
<p>Lorem <_reft id="Lorem" title="Lorem ipsum place"> ipsum dolor sit amet, 
consectetur adipiscing elit. Proin id ante 
turpis. In aliquam id enim sed pharetra. Aenean cursus at nisi consectetur 
semper. Ut risus libero, finibus a aliquet ac, venenatis sit amet ligula. 
Praesent accumsan sapien vel cursus scelerisque. Integer nibh massa, porttitor 
eu fringilla sit amet, finibus vel purus. <a href="lesser">A Link to 
the Second Heading</a>. Nunc laoreet metus eget malesuada pharetra. Sed nulla 
enim, consequat non blandit id, pretium sed erat. Just for the halibut, let's
<a href="back1">go back a little</a> on this page. Donec in auctor 
elit. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere 
cubilia curae; Duis placerat sollicitudin lacinia. Phasellus quis finibus diam, 
at fringilla ex.</p>
END_OF_CONTENT

if ($fwd_ref) {
    $content .=
"
<h3>Forward references causing a second pass</h3>

<p>This is a forward reference using a <i>title=</i> given at the target:
<a href=\"xpage\"></a>. 
And here is one using the target's natural text: <a href=\"someother\"></a>.
</p>";
#
#<p>This is a forward reference with no title, target title, or natural text:
#<a href=\"Linking\"></a>. It should say \"[no title given]\" as the link text.
#This is a forward reference to a non-existent target: <a href="glotz"></a>.
#There should be an error message for a dead link, as well as 
#\"[no title given]\".</p>
#"
}

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras, 'start_y'=>$next_y,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 1B overflowed column!\n";
}

$ppn++;
print "======================================================= page $ppn\n";
$page = $pdf->page();
$fpn = "#".$ppn;  # formatted page = #physical page
$text = $page->text();
$grfx = $page->gfx();

# output page number
$content = "<p><_move x=\"50%\"><span style=\"font-family: Helvetica; text-align: center;\">$fpn</span></p>";
$text->column($page, $text, $grfx, 'html', $content, 
	      'rect'=>[50,25, 500,25],
	      'font_info'=>'-fm-');

$content = <<"END_OF_CONTENT";
<h2 id="someother">Here is a heading for something or other</h2>

<p>In odio elit, feugiat eget diam mattis, convallis lacinia sapien. Fusce 
convallis nunc enim, semper rhoncus eros porta vel. 
Nullam non velit sodales lectus vulputate condimentum. 
<a href="lesser">Eat more of these delicious condiments.</a>
Fusce convallis neque nec velit pellentesque, quis suscipit nisi 
semper. Curabitur vitae ultrices dui. Nulla ut massa sit amet orci ultrices 
vestibulum non in urna. Curabitur ullamcorper metus id elementum lobortis. 
Suspendisse massa neque, tempor fermentum quam a, facilisis condimentum 
dolor.</p>

<p>Etiam sed vehicula ipsum. Nullam ac libero elit. Praesent vitae felis ut 
nulla rhoncus tristique. Remember the first heading <a href="chap1">Big Shot</a>? There's a Named Destination right 
here -&gt;<_nameddest name="foo">&lt;- here. 
Phasellus congue eros quis tellus mollis, ac vehicula quam luctus. 
Praesent nunc ipsum, fringilla nec odio ac, efficitur fermentum nisl. 
Pellentesque suscipit augue eu sodales euismod. Donec a ex mauris. Aenean in 
diam ut purus feugiat bibendum. Proin a orci convallis, gravida arcu ultricies, 
dapibus magna. Go <a href="someother">back to this page heading</a>.</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 2A overflowed column!\n";
}

$content = <<"END_OF_CONTENT";
<p>Integer vel dolor neque. Vestibulum scelerisque, sem eu bibendum tincidunt, 
libero odio rutrum ante, eu fringilla felis felis sit amet dolor. 
<_reft id="xpage" title="Another Cross Page link">Cras et gravida arcu. 
Etiam ut quam pellentesque, tempor nisi in, aliquet purus. Aenean feugiat lorem 
sed eros suscipit, sit amet rhoncus urna dignissim. Nulla ac ipsum quis lorem 
dapibus scelerisque. Etiam condimentum turpis consectetur leo ultrices dapibus. 
Phasellus blandit mauris ac maximus facilisis. Vivamus convallis fringilla sem 
vel luctus. Pellentesque habitant morbi tristique senectus et netus et 
malesuada fames ac turpis egestas. Donec mattis ex id purus sagittis, a tempus 
urna fermentum. Aliquam euismod massa et lorem mollis varius.</p>

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

<p>Link back to the heading, using its natural title: <a href="chap1"></a>.
Now link to one using its specified title: 
<a href="Lorem" fit="xyz,%x,%y,2"></a>.</p>

<h2>Fully specified links</h2>

<h3 id="intlinks">Internal Links</h3>

<p><_reft id="Linking">Linking within the same document to 
<a href="##foo">same PDF</a> with a Named Destination target. Then 
link to it <a href="#1-50-600-undef">first page</a>
at x,y = 50,600 with xyz fit. Finally, 
link to <a href="#1" fit="fitv,200">that page</a> on page 1 with a 
specified fit.</p>

<h3 id="extlinks">External Links</h3>

<p>Note that the following examples use fixed target (path and filename) files.
If you do not have examples/resources/040_annotation.pdf in the right place (and
built with the Named Destination), these links will probably <b>not</b> 
work!</p>

<p>Rather than linking within the same document, let's try 
<a href="resources/040_annotation.pdf##bar">finding Nemo</a>
with a Named Destination target. Then link to it
<a href="resources/040_annotation.pdf#2">on second page {%xyz,50,600,2.5}</a>
at a specified x,y with xyz fit at a certain location.
Finally, link to
<a href="resources/040_annotation.pdf#2" fit="fith,200">that page</a>
with a specified fit.</p>
END_OF_CONTENT

restore_props($text, $grfx);
($rc, $next_y, $unused) =
    $text->column($page, $text, $grfx, 'html', $content, 
	          'rect'=>[50,750, 500,700], 'outline'=>$magenta, 
		  'para'=>$paras, 'start_y'=>$next_y,
	          'state'=>\%state, 'debug'=>$debug,
		  'page'=> [ $pass_count, $max_passes, $ppn, 'zz', $fpn, 'R', 0 ] );
if ($rc) {
    print STDERR "xref example 2B overflowed column!\n";
}

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
