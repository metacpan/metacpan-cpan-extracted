=pod

=begin classdoc

 Subclasses <cpan>PPI::HTML</cpan> to add code folding for POD,
 comments, and 'use'/'require' statements. Optionally permits abbreviation
 of standard PPI::HTML class/token names with user specified
 replacements. For line number output, moves the line numbers
 from individual &lt;span&gt;'s to a single table column,
 with the source body in the 2nd column.
 <p>
 Copyright&copy; 2007, Presicient Corp., USA
 All rights reserved.
 <p>
 Permission is granted to use this software under the terms of the
 <a href='http://perldoc.perl.org/perlartistic.html'>Perl Artisitic License</a>.

 @author D. Arnold
 @since 2007-01-22
 @self    $self


=end classdoc

=cut


package PPI::HTML::CodeFolder;

use PPI::HTML;
use base ('PPI::HTML');

use strict;
use warnings;

our $VERSION = '1.01';

our %classabvs = qw(

arrayindex ai
backtick bt
cast cs
comment ct
core co
data dt
double db
end en
heredoc hd
heredoc_content hc
heredoc_terminator ht
interpolate ip
keyword kw
label lb
line_number ln
literal ll
magic mg
match mt
number nm
operator op
pod pd
pragma pg
prototype pt
readline rl
regex re
regexp re
separator sp
single sg
structure st
substitute su
symbol sy
transliterate tl
word wo
words wd

);
#
#	fold section regular expressions
#
my %foldres = (
	Whitespace => [
		qr/\G(?<=<pre>)((?:\s*<br>)+)/,
	    qr/\G.*?<br>((?:\s*<br>)+)/
	],
	Comments => [
		qr/\G(?<=<pre>)\s*(<span\s+class=['"]comment['"]>.+?<\/span>)(?=<br>)/,
		qr/\G.*?<br>\s*(<span\s+class=['"]comment['"]>.+?<\/span>)(?=<br>)/
	],
	POD => [
		qr/\G(?<=<pre>)\s*(<span\s+class=['"]pod['"]>.+?<\/span>)(?=<br>)/,
		qr/\G.*?<br>\s*(<span\s+class=['"]pod['"]>.+?<\/span>)(?=<br>)/
	],
	Heredocs => [
		qr/\G(?<=<pre>)\s*(<span\s+class=['"]heredoc_content['"]>.+?<\/span>)(?=<br>)/,
		qr/\G.*?<br>\s*(<span\s+class=['"]heredoc_content['"]>.+?<\/span>)(?=<br>)/
	],
	Imports => [
		qr/\G(?<=<pre>)\s*
		    	(
		    		(?:<span\s+class=['"]keyword['"]>(?:use|require)<\/span>.+?;\s*)+
		    		(?:<span\s+class=['"]comment['"]>.+?<\/span>)?
		    	)
	    		(?=<br>)
		    	/x,
		qr/\G.*?<br>\s*
		    	(
		    		(?:<span\s+class=['"]keyword['"]>(?:use|require)<\/span>.+?;\s*)+
		    		(?:<span\s+class=['"]comment['"]>.+?<\/span>)?
		    	)
		    	(?=<br>)
				/x
	],
);

#
#    folddiv CSS
#
our $ftcss = <<'EOFTCSS';

.popupdiv {
    font-family: fixed, Courier;
    font-size: 8pt;
    font-style: normal;
    /* lineheight: 10pt; */
    border:solid 1px #666666;
    padding:4px;
    position:absolute;
    z-index:100;
    visibility: hidden;
    color: black;
    top:10px;
    left:20px;
    width:auto;
    height:auto;
    background-color:#ffffcc;
    layer-background-color:#ffffcc;
/*    opacity: .9;
    filter: alpha(opacity=90); */
    overflow : hidden;	// to keep FF on OS X happy
}

.folddiv {
    position: absolute;
    visibility: hidden;
    overflow : hidden;	// to keep FF on OS X happy
}

.bodypre {
    font-family: fixed, Courier;
    font-size: 9pt;
    line-height: 13pt;
    text-align: left;
    color:  black;
}

.lnpre {
    font-family: fixed, Courier;
    font-size: 9pt;
    line-height: 13pt;
    text-align: right;
    color: #666666;
}

.foldfill {
    font-family: fixed, Courier;
    font-size: 8pt;
    font-style: italic;
    line-height: 13pt;
    color: blue;
}

.foldbtn {
    font-family: fixed, Courier;
    font-size: 9pt;
    line-height: 13pt;
    color: blue;
}

-->
</style>
EOFTCSS
#
#    fold expansion javascript
#
our $ftjs = <<'EOFTJS';

function ppiHtmlCF(startlines, endlines) 
{
	this.startlines = startlines;
	this.endlines = endlines;
	this.foldstate = [];
	for (var i = 0; i < startlines.length; i++)
		this.foldstate[startlines[i]] = "closed";
}

// Clears the cookie
ppiHtmlCF.prototype.clearCookie = function()
{
	var now = new Date();
	var yesterday = new Date(now.getTime() - 1000 * 60 * 60 * 24);
	this.setCookie('', yesterday);
};

// Sets value in the cookie
ppiHtmlCF.prototype.setCookie = function(cookieValue, expires)
{
	document.cookie =
		'ppihtmlcf=' + escape(cookieValue) + ' ' + 
		+ (expires ? '; expires=' + expires.toGMTString() : '')
		+ ' path=' + location.pathname;
};

// Gets the cookie
ppiHtmlCF.prototype.getCookie = function() {
	var cookieValue = '';
	var posName = document.cookie.indexOf('ppihtmlcf=');
	if (posName != -1) {
		var posValue = posName + 'ppihtmlcf='.length;
		var endPos = document.cookie.indexOf(';', posValue);
		if (endPos != -1) cookieValue = unescape(document.cookie.substring(posValue, endPos));
		else cookieValue = unescape(document.cookie.substring(posValue));
	}
	return (cookieValue);
};

// updates cookie with current set of unfolded section startlines as a string
ppiHtmlCF.prototype.updateCookie = function()
{
	var str = ':';
	for (var n = 0; n < this.startlines.length; n++) {
		line = this.startlines[n];
	   	if ((this.foldstate[line] != null) && (this.foldstate[line] == "open"))
			str += line + ':';
	}
	if (str == ':')
		this.setCookie('');
	else
		this.setCookie(str);
};

// forces all folds to current cookie state
ppiHtmlCF.prototype.openFromCookie = function()
{
	var opened = this.getCookie();
	if (opened == '') {
	/*
	 *	no cookie, create one w/ all folds closed
	 */
		this.setCookie('');
	}
	else {
		for (var n = 0; n < this.startlines.length; n++) {
			line = this.startlines[n];
		   	if (this.foldstate[line] == null) 
		   		this.foldstate[line] = "closed";

			if (opened.indexOf(':' + line + ':') >= 0) {
				if (this.foldstate[line] == "closed")
					this.accordian(line, this.endlines[n]);
			}
			else {
				if (this.foldstate[line] == "open")
					this.accordian(line, this.endlines[n]);
			}
		}
	}
};

/*
 *	renders line number and fold button margins
 */
ppiHtmlCF.prototype.renderMargins = function(lastline)
{
	var start = 1;
	var lnmargin = '';
	var btnmargin = '';
    for (var i = 0; i < this.startlines.length; i++) {
		if (start != this.startlines[i]) {
	        for (var j = start; j < this.startlines[i]; j++) {
	    		lnmargin += j + "\n";
	    		btnmargin += "\n";
	    	}
	    }
	    start = this.endlines[i] + 1;
		lnmargin += "<span id='lm" + this.startlines[i] + "' class='lnpre'>" + this.startlines[i] + "</span>\n";
		btnmargin += "<a id='ll" + this.startlines[i] + "' class='foldbtn' " + 
			"onclick=\"ppihtml.accordian(" + this.startlines[i] + "," + this.endlines[i] + ")\">&oplus;</a>\n";
	}
	if (lastline > this.endlines[this.endlines.length - 1]) {
		for (var j = start; j <= lastline; j++) {
			lnmargin += j + "\n";
			btnmargin += "\n";
		}
	}
	lnmargin += "\n";
	btnmargin += "\n";
	buttons = document.getElementById("btnmargin");
	lnno = document.getElementById("lnnomargin");
	if (navigator.appVersion.indexOf("MSIE")!=-1) {
		lnno.outerHTML = "<pre id='lnnomargin' class='lnpre'>" + lnmargin + "</pre>";
		buttons.outerHTML = "<pre id='btnmargin' class='lnpre'>" + btnmargin + "</pre>";
	}
	else {
		lnno.innerHTML = lnmargin;
		buttons.innerHTML = btnmargin;
	}
}

/*
 *	Accordian function for folded code
 *
 *	if clicked fold is closed
 *		replace contents of specified lineno margin span
 *			with complete lineno list
 *		replace contents of specified link span with end - start + 1 oplus's + linebreaks
 *		replace contents of insert span with contents of src_div
 *		foldstate = open
 *	else
 *		replace contents of specified lineno margin span with start lineno
 *		replace contents of specified link span with single oplus
 *		replace contents of specified insert span with "Folded lines start to end"
 *		foldstate = closed
 *
 *	For fancier effect, use delay to add/remove a single line at a time, with
 *	delay millsecs between updates
 */
ppiHtmlCF.prototype.accordian = function(startline, endline)
{
    if (document.getElementById) {
		if (navigator.appVersion.indexOf("MSIE")!=-1) {
    		this.ie_accordian(startline, endline);
    	}
    	else {
    		this.ff_accordian(startline, endline);
    	}
    }
}
/*
 *	MSIE is a pile of sh*t, so we have to bend over
 *	backwards and completely rebuild the document elements
 *	Bright bunch of folks up there in Redmond...BTW this bug
 *	exists in IE 4 thru 7, despite people screaming for a solution
 *	for a decade. So MSFT is deaf as well as dumb
 */
ppiHtmlCF.prototype.ie_accordian = function(startline, endline)
{
   	src = document.getElementById("preft" + startline);
   	foldbtn = document.getElementById('btnmargin');
   	lineno = document.getElementById('lnnomargin');
   	insert = document.getElementById("src" + startline);
	linenos = lineno.innerHTML;
	buttons = foldbtn.innerHTML;
   	if ((this.foldstate[startline] == null) || (this.foldstate[startline] == "closed")) {
	   	lnr = "<span[^>]+>" + startline + "[\r\n]*</span>";
	   	lnre = new RegExp(lnr, "i");
	   	bnr = "id=ll" + startline + "[^<]+</a>";
	   	btnre = new RegExp(bnr, "i");

   		lnfill = startline + "\n";
   		btnfill = "&oplus;\n";
   		for (i = startline + 1; i <= endline; i++) {
   			lnfill += i + "\n";
   			btnfill += "&oplus;\n";
   		}

		linenos = linenos.replace(lnre, "<span id='lm" + startline + "' class='lnpre'>" + lnfill + "</span>");
		buttons = buttons.replace(btnre, "id='ll" + startline + "' class='foldbtn' style='background-color: yellow' onclick=\"ppihtml.accordian(" + 
			startline + ", " + endline + ")\">" + btnfill + "</a>");

   		foldbtn.outerHTML = "<pre id='btnmargin' class='lnpre'>" + buttons + "</pre>";
   		lineno.outerHTML = "<pre id='lnnomargin' class='lnpre'>" + linenos + "</pre>";
   		insert.outerHTML = "<span id='src" + startline + "'><pre class='bodypre'>" + src.innerHTML + "</pre></span>";
      	this.foldstate[startline] = "open";
	}
	else {
	   	lnr = "<span[^>]+>" + startline + "[\r\n][^<]*</span>";
	   	lnre = new RegExp(lnr, "i");
	   	bnr = "id=ll" + startline + "[^<]+</a>";
	   	btnre = new RegExp(bnr, "i");

		if (! linenos.match(lnre))
			alert("linenos no match");
		if (! buttons.match(btnre))
			alert("buttons no match");
		linenos = linenos.replace(lnre, "<span id='lm" + startline + "' class='lnpre'>" + startline + "\n</span>");
		buttons = buttons.replace(btnre, "id='ll" + startline + "' class='foldbtn' style='background-color: #E9E9E9' onclick=\"ppihtml.accordian(" +
			startline + ", " + endline + ")\">&oplus;\n</a>");

   		foldbtn.outerHTML = "<pre id='btnmargin' class='lnpre'>" + buttons + "</pre>";
   		lineno.outerHTML = "<pre id='lnnomargin' class='lnpre'>" + linenos + "</pre>";
   		insert.outerHTML = "<span id='src" + startline + "'><pre class='foldfill'>Folded lines " + startline + " to " + endline + "</pre></span>";

       	this.foldstate[startline] = "closed";
	}
	this.updateCookie();
}

ppiHtmlCF.prototype.ff_accordian = function(startline, endline)
{
  	src = document.getElementById("preft" + startline);
   	foldbtn = document.getElementById("ll" + startline);
   	lineno = document.getElementById("lm" + startline);
   	insert = document.getElementById("src" + startline);
   	if ((this.foldstate[startline] == null) || (this.foldstate[startline] == "closed")) {
   		lnfill = startline + "\n";
   		btnfill = "&oplus;\n";
   		for (i = startline + 1; i <= endline; i++) {
   			lnfill += (i < endline) ? i + "\n" : i;
   			btnfill += (i < endline) ? "&oplus;\n" : "&oplus;";
   		}
   		foldbtn.innerHTML = btnfill;
   		lineno.innerHTML = lnfill;
   		foldbtn.style.backgroundColor = "yellow";
   		insert.innerHTML = src.innerHTML;
   		insert.className = "bodypre";
       	this.foldstate[startline] = "open";
	}
	else {
		foldbtn.innerHTML = "&oplus;";
   		foldbtn.style.backgroundColor = "#E9E9E9";
   		lineno.innerHTML = startline;
   		insert.innerHTML = "Folded lines " + startline + " to " + endline;
   		insert.className = "foldfill";
       	this.foldstate[startline] = "closed";
	}
	this.updateCookie();
}

/*
 *	open/close all folds
 */
ppiHtmlCF.prototype.fold_all = function(foldstate)
{
	for (i = 0; i < this.startlines.length; i++) {
		line = this.startlines[i];
	   	if (this.foldstate[line] == null) 
	   		this.foldstate[line] = "closed";

		if (this.foldstate[line] != foldstate)
	   		this.accordian(line, this.endlines[i]);
	}
	this.updateCookie();
}

ppiHtmlCF.prototype.add_fold = function(startline, endline)
{
	this.startlines[this.startlines.length] = startline;
	this.endlines[this.endlines.length] = endline;
	this.foldstate[this.foldstate.length] = "closed";
}

EOFTJS

=pod

=begin classdoc

    Constructor. Uses PPI::HTML base constructor, then installs some
    additional members based on the <code>fold</code> argument.

 @optional colors hashref of <b>original</b> PPI::HTML classnames to color codes/names
 @optional css    a <cpan>CSS::Tiny</cpan> object containg additional stylsheet properties
 @optional fold   hashref of code folding properties; if not specified, a default
                  set of properties is applied. Folding properties include:
 <ul>
 <li>Abbreviate - hashref mapping full classnames to smaller classnames; useful
        to provide further output compression; default uses predefined mapping
 <li>Comments - if true, fold comments; default true
 <li>Expandable - if true, provide links to unfold lines in place; default false
 <li>Imports  - if true, fold 'use' and 'require' statements; default false
 <li>Javascript  - name of file to reference for the fold expansion javascript in the output HTML;
    default none, resulting in Javascript embedded in output HTML.<br>
    Note that the Javascript may be retrieved separately via the <code>foldJavascript()</code> method.
 <li>MinFoldLines - minimum number of consecutive foldable lines required before folding is applied;
            default is 4
 <li>POD - if true, fold POD line; default true
 <li>Stylesheet - name of file to reference for the CSS for abbreviated classnames and
            fold DIVs in the output HTML; default none,resulting in CSS embedded in output
            HTML.<br>
    Note that the CSS may be retrieved separately via the <code>foldCSS()</code> method.
 <li>Tabs - size of tabs; default 4
 </ul>

 @optional line_numbers if true, include line numbering in the output HTML
 @optional page   if true, wrap the output in a HTML &lt;head&gt; and &lt;body&gt;
       sections. <b>NOTE: CodeFolder forces this to true.
 @optional verbose   if true, spews various diagnostic info

 @return    a new PPI::HTML::CodeFolder object

=end classdoc

=cut


sub new {
    my ($class, %args) = @_;

    my $fold = delete $args{fold};
    my $verb = delete $args{verbose};
#
#    remove line numbering option since it greatly simplifies the spanning
#    scan later; we'll apply it after we're done
#
    my $needs_ln = delete $args{line_numbers};
#
#   force page wrapping
#
    $args{page} = 1;
    my $self = $class->SUPER::new(%args);
    return undef
        unless $self;

    $self->{_needs_ln} = $needs_ln;
    $self->{_verbose} = $verb;
    $self->{fold} = $fold ?
        { %$fold } :
        {
        Abbreviate    => \%classabvs,
        Comments      => 1,
        Heredocs      => 0,
        Imports       => 0,
        Javascript    => undef,
        Expandable      => 0,
        MinFoldLines  => 4,
        POD           => 1,
        Stylesheet    => undef,
        Tabs          => 4,
        };

    $self->{fold}{Abbreviate} = \%classabvs
        if $self->{fold}{Abbreviate} && (! (ref $self->{fold}{Abbreviate}));

    $self->{fold}{MinFoldLines} = 4
        unless $self->{fold}{MinFoldLines};

    $self->{fold}{Tabs} = 4
        unless $self->{fold}{Tabs};
#
#	keep a running package/method cross reference
#
	$self->{_pkgs} = {};

    return $self;
}

=pod

=begin classdoc

    Returns the Javascript used for fold expansion.

 @return    Javascript for fold expansion, as a string

=end classdoc

=cut

sub foldJavascript { return $ftjs; }


=pod

=begin classdoc

Write out the Javascript used for fold expansion.

@return    1 on success; undef on failure, with error message in $@

=end classdoc

=cut

sub writeJavascript { 
	$@ = $!,
	return undef
		unless open OUTF, ">$_[1]";
	print OUTF $ftjs;
	close OUTF;
	return 1;
}

=pod

=begin classdoc

Write out the CSS used for the sources.

@return    1 on success; undef on failure, with error message in $@

=end classdoc

=cut

sub writeCSS { 
	$@ = $!,
	return undef
		unless open OUTF, ">$_[1]";
	print OUTF $_[0]->foldCSS();
	close OUTF;
	return 1;
}

=pod

=begin classdoc

    Returns the CSS used for the abbreviated classes and fold DIVs.

 @return    CSS as a string

=end classdoc

=cut


sub foldCSS {
    my $self = shift;
    my $orig_colors = exists $self->{colors};
    my $css = $self->_css_html() || << 'EOCSS';
<style type="text/css">
<!--
body {
    font-family: fixed, Courier;
    font-size: 10pt;
}
EOCSS

	my $ftc = $ftcss;
	if ($self->{colors}{line_number}) {
		my $lnc = $self->{colors}{line_number};
		$ftc=~s/(.lnpre\s+.+?color: )#888888;/$1$lnc;/gs;
	}

    delete $self->{colors} unless $orig_colors;
    $css=~s|-->\s*</style>||s;
#
#	!!!fix for (yet another) Firefox bug: need a dummy class
#	at front of CSS or firefox ignores the first class...
#
	$css=~s/(<!--.*?\n)/$1\n\n.dummy_class_for_firefox { color: white; }\n/;
#
#    replace classes w/ abbreviations
#
    if ($self->{fold}{Abbreviate}) {
        my ($long, $abv);
        $css=~s/\.$long \{/.$abv {/s
            while (($long, $abv) = each %{$self->{fold}{Abbreviate}});
    }
    return $css . $ftc;
}

=pod

=begin classdoc

    Generate folded HTML from source PPI document.
    Overrides base class <code>html()</code> to apply codefolding support.

@param $src    a <cpan>PPI::Document</cpan> object, OR the
                path to the source file, OR a scalarref of the
                actual source text.
@optional $outfile name of the output HTML file; If not specified for a filename $src, the
			default is "$src.html"; If not specified for either PPI::Document or text $src,
			defaults to an empty string.
@optional $script	a name used if source is a script file. Script files might not include
			any explicit packages or method declarations which would be mapped into the
			table of contents. By specifying this parameter, an entry is forced into the 
			table of contents for the script, with any "main" package methods within the
			script reassigned to this script name. If not specified, and <code>$src</code>
			is not a filename, an error will be issued when the TOC is generated. 

 @return    on success, the folded HTML; undef on failure
 
 @returnlist	on success, the folded HTML and a hashref mapping packages to an arrayref of method names;
 				undef on failure

=end classdoc

=cut

sub html {
    my ($self, $src, $outfile, $script) = @_;

    my $orig_colors = exists $self->{colors};
    my $html = $self->SUPER::html($src)
        or return undef;

	$outfile = (ref $src) ? '' : "$src.html"
		unless $outfile;
	$script ||= $src 
		unless ref $src || (substr($src, -3) eq '.pm');
#
#	expand tabs as needed (we use 4 space tabs)
#	have to adjust some spans that confuse tab processing
#
	my @lns = split /\n/, $html;
	my $tabsz = $self->{fold}{Tabs};
	foreach my $line (@lns) {
		next if $line=~s/^\s*$//;
		next unless $line=~tr/\t//;
		my $offs = 0;
		my $pad;
#
#	scan for and replace tabs; adjust positions
#	of extracted tags as needed
#
		pos($line) = 0;
		while ($line=~/\G.*?((<[^>]+>)|\t)/gc) {
			$offs += length($2),
			next
				unless ($1 eq "\t");

			$pad = $tabsz - ($-[1] - $offs) % $tabsz;
			substr($line, $-[1], 1, ' ' x $pad);
			pos($line) = $-[1] + $pad - 1;
		}
	}
	$html = join("\n", @lns);

    delete $self->{colors} unless $orig_colors;

    my $opts = $self->{fold};
#
#    extract stylesheet and replace with abbreviated version
#
	my $style = $opts->{Stylesheet} ?
        "<link type='text/css' rel='stylesheet' href='" . 
        	_pathAdjust($outfile, $opts->{Stylesheet}) . "' />" :
        $self->foldCSS();

    $style .= $opts->{Javascript} ?
        "\n<script type='text/javascript' src='" .
        	_pathAdjust($outfile, $opts->{Javascript}) . "'></script>\n" :
        "\n<script type='text/javascript'>\n$ftjs\n</script>\n"
        if $opts->{Expandable};
#
#   original html may have no style, so we've got to add OR replace
#
    $html=~s|</head>|$style</head>|s
        unless ($html=~s|<style type="text/css">.+</style>|$style|s);
#
#	force spans to end before line endings
#
	$html=~s!(<br>\s*)</span>!</span>$1!g;
#
#	split multiline comments into 2 spans: 1st line (in case its midline)
#	and the remainder; note that the prior substitution avoids
#	doing this to single line comments
#
	$html=~s/(?!<br>\s+)(<span class=['"]comment['"]>[^<]+)<br>\n/$1<\/span><br>\n<span class="comment">/g;
#
# keep folded fragments here for later insertion
# as fold DIVs; key is starting line number,
# value is [ number of lines, text ]
#
    my %folddivs = ( 1 => [ 0, '', 0, 0 ]);
#
#    count <br> tags, and looks for any of
#    comment, pod, or use/require keyword (depending on the options);
#    keeps track of start and end position of foldable segments
#
    my $lineno = 1;
    my $lastfold = 1;

	$html=~s/<br>\n/<br>/g;
#
#   now process remainder
#
	study $html;
    pos($html) = 0;
    $html=~/^.*?(<body[^>]+><pre>)/s;
	my $startpos = $+[1];
#
#	map linebreak positions to line numbers
#
	my @lnmap = (0, $startpos);
	push @lnmap, $+[1]
	    while ($html=~/\G.*?(<br>)/gcs);
#
#	now scan for foldables
#
	pos($html) = $startpos;
	my @folds = _extractFolds(\$html, $startpos, \@lnmap, $opts);
#
#	trim small folds;
#   since its used frequently, create a sorted list of the fold DIV lines;
#	isolate positions of folds and extract folded content
#
	my $ln = 0;
	my @ftsorted = ();
	foreach (@folds) {
		if ($_->[1] - $_->[0] + 1 >= $opts->{MinFoldLines}) {
			$folddivs{$_->[0]} = [ $_->[1], substr($html, $lnmap[$_->[0]], $lnmap[$_->[1] + 1] - $lnmap[$_->[0]]), 
				$lnmap[$_->[0]], $lnmap[$_->[1] + 1] ];
			push @ftsorted, $_->[0];
		}
		elsif ($self->{_verbose}) {
#			print "*** skipping section at line $_->[0]to $_->[1]\n";
#			print substr($html, $lnmap[$_->[0]], $lnmap[$_->[1] + 1] - $lnmap[$_->[0]]), "\n";
		}
	}
#
#    now remove the folded lines; we work from bottom to top since
#    we're changing the HTML as we go, which would invalidate the
#    positional elements we've kept. If fold expansion is enabled, we replace
#    w/ a hyperlink; otherwise we replace with a simple indication of the fold
#
	substr($html, $folddivs{$_}[2], $folddivs{$_}[3] - $folddivs{$_}[2],
		"<span id='src$_' class='foldfill'>Folded lines $_ to " . $folddivs{$_}[0] . "</span>\n")
    	foreach (reverse @ftsorted);
#
#    abbreviate the default span classes for both the html and fold divs
#
    pos($html) = 0;
    my $abvs = $opts->{Abbreviate};
    if ($abvs) {
        $html=~s/(<span\s+class=['"])([^'"]+)(['"])/$1 . ($$abvs{$2} || $2) . $3/egs;
        if ($opts->{Expandable}) {
            $_->[1]=~s/(<span\s+class=['"])([^'"]+)(['"])/$1 . ($$abvs{$2} || $2) . $3/egs
                foreach (values %folddivs);
        }
    }
#
#    create and insert fold DIVs if requested
#
    my $expdivs = $opts->{Expandable} ? _addFoldDivs(\%folddivs, \@ftsorted) : '';

    $html=~s/<br>/\n/gs;
#
#    now create the line number table (if requested)
#    NOTE: this is where having the breakable lines would be really
#    useful!!!
#
	_addLineNumTable(\$html, \@ftsorted, \%folddivs, \$expdivs, $#lnmap)
	    if $self->{_needs_ln};
#
#	extract a package/method reference list, and add anchors for them
#
	$self->_extractXRef(\$html, $outfile, $script);
#
#	report number of spans, for firefox performance report
#
	if ($self->{_verbose}) {
		my $spancnt = $html=~s/<\/span>/<\/span>/gs;
		print "\n***Total spans: $spancnt\n";
	}
#
#	fix Firefox blank lines inside spans bug: add a single space to
#	all blank lines
#
	$html=~s!\n\n!\n \n!gs;

    return $html;
}

=pod

=begin classdoc

Return current package/method cross reference.

@return    hashref of current package/method cross reference

=end classdoc

=cut

sub getCrossReference { return $_[0]->{_pkgs}; }

=pod

=begin classdoc

Write out a table of contents document for the current collection of
sources as a nested HTML list. The output filename is 'toc.html'.
The caller may optionally specify the order of packages in the menu.

@param $path directory to write TOC file
@optional Order	arrayref of packages in the order in which they should appear in TOC; if a partial list,
					any remaining packages will be appended to the TOC in alphabetical order

@return	this object on success, undef on failure, with error message in $@

=end classdoc

=cut

sub writeTOC {
	my $self = shift;
	my $path = shift;
	$@ = "Can't open $path/toc.html: $!",
	return undef
		unless CORE::open(OUTF, ">$path/toc.html");

	print OUTF $self->getTOC("$path/toc.html", @_);
	close OUTF;
	return $self;
}

=begin classdoc

Generate a table of contents document for the current collection of
sources as a nested HTML list. Caller may optionally specify
the order of packages in the menu.

@param $tocpath		path of output TOC file
@optional Order	arrayref of packages in the order in which they should appear in TOC; if a partial list,
					any remaining packages will be appended to the TOC in alphabetical order

@return	the TOC document

=end classdoc

=cut

sub getTOC {
	my $self = shift;
	my $tocpath = shift;
	my %args = @_;
	my @order = $args{Order} ? @{$args{Order}} : ();
	my $sources = $self->{_pkgs};
	my $base;
	my $doc =
"<html>
<body>
<small>
<!-- INDEX BEGIN -->
<ul>
";
	my %ordered = ();
	$ordered{$_} = 1 foreach (@order);
	foreach (sort keys %$sources) {
		push @order, $_ unless exists $ordered{$_};
	}

	foreach my $class (@order) {
#
#	due to input @order, we might get classes that don't exist
#
		next unless exists $sources->{$class};

		$base = _pathAdjust($tocpath, $sources->{$class}{URL});
		$doc .=  "<li><a href='$base' target='mainframe'>$class</a>
		<ul>\n";
		my $info = $sources->{$class}{Methods};
		$doc .=  "<li><a href='" . _pathAdjust($tocpath, $info->{$_}) . "' target='mainframe'>$_</a></li>\n"
			foreach (sort keys %$info);
		$doc .=  "</ul>\n</li>\n";
	}

	$doc .=  "
</ul>
<!-- INDEX END -->
</small>
</body>
</html>
";

	return $doc;
}

=pod

=begin classdoc

Write out a frame container document to hold the rendered source and TOC.
The file is written to "$path/index.html".

@param $path directory to write the document.
@param $title Title string for resulting document
@optional $home the "home" document initially loaded into the main frame; default none

@return	this object on success, undef on failure, with error message in $@

=end classdoc

=cut

sub writeFrameContainer {
	my ($self, $path, $title, $home) = @_;
	$@ = "Can't open $path/index.html: $!",
	return undef
		unless open(OUTF, ">$path/index.html");

	print OUTF $self->getFrameContainer($title, $home);
	close OUTF;
	return $self;
}

=begin classdoc

Generate a frame container document to hold the rendered source and TOC.

@return	the frame container document as a string

=end classdoc

=cut

sub getFrameContainer {
	my ($self, $title, $home) = @_;
	return $home ?
"<html><head><title>$title</title></head>
<frameset cols='15%,85%'>
<frame name='navbar' src='toc.html' scrolling=auto frameborder=0>
<frame name='mainframe' src='$home'>
</frameset>
</html>
" :
"<html><head><title>$title</title></head>
<frameset cols='15%,85%'>
<frame name='navbar' src='toc.html' scrolling=auto frameborder=0>
<frame name='mainframe'>
</frameset>
</html>
";
}
#
#	extract a package/method reference list, and add anchors for them
#
sub _extractXRef {
	my ($self, $html, $outfile, $script) = @_;
	$self->{_pkgs} = {} unless exists $self->{_pkgs};
	my $pkgs = $self->{_pkgs};
	my $pkglink;
#
#	assume package "main" to start; on exit,
#	if we have a script name, then replace all "main"
#	entries with $script
#
	my $curpkg = 'main';
	$pkgs->{main} = {
		URL => $outfile,
		Methods => {}
	}
		if $script;

	while ($$html=~/\G.*?(<span class=['"]kw['"]>)\s*(package|sub)\s*<\/span>\s*(<span class=['"][^'"]+['"]>\s*)?([\w:]+)/gcs) {
# " to keep Textpad formatting happy
		my $pkg = $4;
		my $next = pos($$html);
		my $insert = $-[1];
		if ($2 eq 'package') {
			$curpkg = $pkg;
			next if exists $pkgs->{$pkg} && $pkgs->{$pkg}{URL};	# only use 1st definition of package
			$pkglink = $pkg;
			$pkgs->{$pkg} = {
				URL => "$outfile#$pkg",
				Methods => {}
			};
		}
		else {
			if ($pkg=~/^(.+)::(\w+)$/) {
#
#	fully qualified name, check if we have a pkg entry for it
#
				$pkgs->{$1} = {
					URL => '',
					Methods => {}
				}
					unless exists $pkgs->{$1};
				$pkgs->{$1}{Methods}{$2} = "$outfile#$pkg";
				$pkglink = $pkg;
			}
			else {
				$pkglink = ($curpkg eq 'main') ? $pkg : "$curpkg\:\:$pkg";
				$pkgs->{$curpkg}{Methods}{$pkg} = "$outfile#$pkglink";
			}
		}
		$pkglink = "<a name='$pkglink'></a>";
		substr($$html, $insert, 0, $pkglink);
		$next += length($pkglink);
		pos($$html) = $next;
	}
	$pkgs->{$script} = delete $pkgs->{main}
		if $script;
	return $html;
}

sub _extractFolds {
	my ($html, $startpos, $lnmap, $opts) = @_;
#
#	scan for foldables
#
	pos($$html) = $startpos;
	my %folded = (
		Whitespace => [],
		Comments => [],
		POD => [],
		Heredocs => [],
		Imports => [],
	);
	my $whitespace = [];
#
#	accumulate foldable sections, including leading/trailing whitespace
#
#	my $fre = $foldres{$_}[0];
#	push @{$folded{$_}}, [ $-[1], $+[1] - 1 ]
#    	if ($$html=~/$fre/gcs);

#   	push @{$folded{Whitespace}}, [ $-[1], $+[1] - 1 ]
#	    while ($$html=~/\G.*?<br>((?:\s*<br>)+)/gcs);
#	_mergeSection(_cvtToLines($folded{Whitespace}, $lnmap))
#		if scalar @{$folded{Whitespace}};

	pos($$html) = $startpos;
	foreach (qw(Whitespace Comments POD Heredocs Imports)) {
		next unless ($_ eq 'Whitespace') || $opts->{$_};
#
#	capture anything at the very beginning
#
		my $fre = $foldres{$_}[0];
   		push @{$folded{$_}}, [ $-[1], $+[1] - 1 ]
	    	if ($$html=~/$fre/gcs);
	
		$fre = $foldres{$_}[1];
   		push @{$folded{$_}}, [ $-[1], $+[1] - 1 ]
	    	while ($$html=~/$fre/gcs);
		_mergeSection(_cvtToLines($folded{$_}, $lnmap))
			if scalar @{$folded{$_}};
		pos($$html) = $startpos;
	}
#
#	now merge different sections
#
	my $last = 'Whitespace';
	foreach (qw(Imports POD Heredocs Comments)) {
		_mergeSections($folded{$_}, $folded{$last});
		$last = $_;
	}
	return @{$folded{$last}};
}

sub _cvtToLines {
	my ($pos, $lnmap) = @_;
	
	my $ln = 1;
	foreach (@$pos) {
		$ln++ while ($ln <= $#$lnmap) && ($lnmap->[$ln] <= $_->[0]);
		$_->[0] = $ln - 1;
		$ln++ while ($ln <= $#$lnmap) && ($lnmap->[$ln] <= $_->[1]);
		$_->[1] = $ln - 1;
	}
	return $pos;
}

sub _mergeSection {
	my $sect = shift;
	my @temp = shift @$sect;
	foreach (@$sect) {
		push(@temp, $_),
		next
			unless ($temp[-1][1] + 1 >= $_->[0]);
#
#	if current surrounds new, the discard new
#
		$temp[-1][1] = $_->[1]
			if ($temp[-1][1] < $_->[1]);
	}
	@$sect = @temp;
	1;
}

sub _mergeSections {
	my ($first, $second) = @_;
	
	if ($#$first < 0) {
		@$first = @$second;
		return $first;
	}

	my @temp = ();
	push @temp, (($first->[0][0] < $second->[0][0]) ? shift @$first : shift @$second)
		while (@$first && @$second);

	push @temp, @$first if scalar @$first;
	push @temp, @$second if scalar @$second;
	_mergeSection(\@temp);
	@$first = @temp;
	1;
}

sub _addLineNumTable {
	my ($html, $ftsorted, $folddivs, $expdivs, $linecnt) = @_;

	$$html=~s/<pre>/<pre class='bodypre'>/;
	$$html=~/(<body[^>]+>)/s;
	my $insert = $+[0];
#
#	generate JS declaration of fold sections
#
	my $startfolds = scalar @$ftsorted ?
		'[' . join(',', @$ftsorted) . " ],\n[" . join(',', map $folddivs->{$_}[0], @$ftsorted) . " ]" :
		"[], []";

	my $linenos = $$expdivs . "
<table border=0 width='100\%' cellpadding=0 cellspacing=0>
<tr>
    <td width=40 bgcolor='#E9E9E9' align=right valign=top>
    <pre id='lnnomargin' class='lnpre'>
	</pre>
</td>
<td width=8 bgcolor='#E9E9E9' align=right valign=top>
<pre id='btnmargin' class='lnpre'>
</pre>
</td>
<td bgcolor='white' align=left valign=top>
";
	substr($$html, $insert, 0, $linenos);
	substr($$html, index($$html, '</body>'), 0, "
</td></tr></table>

<script type='text/javascript'>
<!--

var ppihtml = new ppiHtmlCF($startfolds);
ppihtml.renderMargins($linecnt);
/*
 *	all rendered, now selectively open from any existing cookie
 */
ppihtml.openFromCookie();

-->
</script>
"
	);
	return 1;
}

sub _addFoldDivs {
	my ($folddivs, $ftsorted) = @_;
	foreach my $ft (values %$folddivs) {
		$ft->[1]=~s/<br>/\n/gs;
#
#	squeeze out leading whitespace, but keep aligned
#
		my $shortws = 1000000;
		my @lns = split /\n/, $ft->[1];
#
#	expand tabs as needed (we use 4 space tabs)
#
		foreach (@lns) {
			next if s/^\s*$//;
			$shortws = 0, last
				unless /^(\s+)/;
			$shortws = length($1)
				if ($shortws > length($1))
		}
		$ft->[1] = join("\n", map { $_ ? substr($_, $shortws) : ''; } @lns)
			if $shortws;
#
#	move whitespace inside any leading/trailing spans
#
		$ft->[1]=~s!(</span>)(\s+)$!$2$1!s;
		$ft->[1]=~s!^(\s+)(<span [^>]+>)!$2$1!s;
#
#	if ends on span, make sure its not creating newline
#
		$ft->[1]=~s!\n</span>$! </span>!s;
#
#	likewise if it doesn't end on a span
#
		$ft->[1]=~s!\n$!!s;
	}
	return join('', map "\n<div id='ft$_' class='folddiv'><pre id='preft$_'>$folddivs->{$_}[1]</pre></div>", @$ftsorted);
}

sub _pathAdjust {
	my ($path, $jspath) = @_;
	return $jspath
		unless (substr($jspath, 0, 2) eq './') && (substr($path, 0, 2) eq './');
#
#	relative path, adjust as needed from current base
#
	my @parts = split /\//, $path;
	my @jsparts = split /\//, $jspath;
	my $jsfile = pop @jsparts;	# get rid of filename
	pop @parts;		# remove filename
	shift @parts;
	shift @jsparts;	# and the relative lead
	my $prefix = '';
	shift @parts, 
	shift @jsparts
		while @parts && @jsparts && ($parts[0] eq $jsparts[0]);
	push @jsparts, $jsfile;
	return ('../' x scalar @parts) . join('/', @jsparts)
}

1;
