#!/usr/bin/perl -w

# Formal testing for PPI::HTML::CodeFolder

# This test script verifies PPI/HTML/CodeFolder.pm can properly process itself
#	with various combinations of options

use strict;
BEGIN {
	$| = 1;
}

use Test::More tests => 13, no_diag => 1;
use PPI::HTML::CodeFolder;
use Data::Dumper;
#
#	find location of the codefolder we're using
#
my $file = $INC{'PPI/HTML/CodeFolder.pm'};
#
#	make directory to store output
#
foreach (qw(t/src t/src/PPI t/src/PPI/HTML)) {
	mkdir $_ unless -d $_;
}
#
#	flag to save output
#
my $saveAll = 0;
#
#	test basics first
#
my $expand = 1;
my $comments = 1;
my $pod = 1;
my $imports = 1;
my $heredocs = 1;
my $minlines = 4;

my $Document = PPI::Document->new( $file );
ok($Document, 'Load source');

my %tagcolors = (
    cast => '#339999',
    comment => '#008080',
    core => '#FF0000',
    double => '#999999',
    heredoc => '#FF0000',
    heredoc_content => '#FF0000',
    heredoc_terminator => '#FF0000',
    interpolate => '#999999',
    keyword => '#0000FF',
    line_number => '#666666',
    literal => '#999999',
    magic => '#0099FF',
    match => '#9900FF',
    number => '#990000',
    operator => '#DD7700',
    pod => '#008080',
    pragma => '#990000',
    regex => '#9900FF',
    single => '#999999',
    substitute => '#9900FF',
    transliterate => '#9900FF',
    word => '#999999',
);

# Create the PPI::HTML object
my $HTML = PPI::HTML::CodeFolder->new(
    line_numbers => 1,
    page         => 1,
    colors       => \%tagcolors,
    verbose      => undef,
    fold          => {
    	Abbreviate    => 1,
        POD           => $pod,
        Comments      => $comments,
        Expandable    => $expand,
        Heredocs      => $heredocs,
        Imports       => $imports,
        MinFoldLines  => $minlines,
        },
    );
ok($HTML, 'Constructor');

#
#	check JS
#
my $js = $HTML->foldJavascript();
saveIt('PPICF.js', $js);

my $expected = <<'EOJS';

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

EOJS

cmp_ok($js, 'eq', $expected, 'foldJavascript');

#
#	check CSS
#
my $css = $HTML->foldCSS();
saveIt('PPICF.css', $css);

$expected = <<'EOCSS';
<style type="text/css">
<!--


.dummy_class_for_firefox { color: white; }
.wo {
	color: #999999;
}
.tl {
	color: #9900FF;
}
.su {
	color: #9900FF;
}
.sg {
	color: #999999;
}
.re {
	color: #9900FF;
}
.pg {
	color: #990000;
}
.pd {
	color: #008080;
}
.op {
	color: #DD7700;
}
.nm {
	color: #990000;
}
.mt {
	color: #9900FF;
}
.mg {
	color: #0099FF;
}
.ll {
	color: #999999;
}
.ln {
	color: #666666;
}
.kw {
	color: #0000FF;
}
.ip {
	color: #999999;
}
.ht {
	color: #FF0000;
}
.hc {
	color: #FF0000;
}
.hd {
	color: #FF0000;
}
.db {
	color: #999999;
}
.co {
	color: #FF0000;
}
.ct {
	color: #008080;
}
.cs {
	color: #339999;
}

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
EOCSS

cmp_ok($css, 'eq', $expected, 'foldCSS');

# Process the file
my $content = $HTML->html( $Document, 'PPI/HTML/CodeFolder.pm.html' );

saveIt('PPICF.html', $content);

$expected = <<'EOHTML';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="robots" content="noarchive">
<style type="text/css">
<!--
 

.dummy_class_for_firefox { color: white; }
.wo {
	color: #999999;
}
.tl {
	color: #9900FF;
}
.su {
	color: #9900FF;
}
.sg {
	color: #999999;
}
.re {
	color: #9900FF;
}
.pg {
	color: #990000;
}
.pd {
	color: #008080;
}
.op {
	color: #DD7700;
}
.nm {
	color: #990000;
}
.mt {
	color: #9900FF;
}
.mg {
	color: #0099FF;
}
.ll {
	color: #999999;
}
.ln {
	color: #666666;
}
.kw {
	color: #0000FF;
}
.ip {
	color: #999999;
}
.ht {
	color: #FF0000;
}
.hc {
	color: #FF0000;
}
.hd {
	color: #FF0000;
}
.db {
	color: #999999;
}
.co {
	color: #FF0000;
}
.ct {
	color: #008080;
}
.cs {
	color: #339999;
}
 
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
 
<script type='text/javascript'>
 
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
 

</script>
 
</head>
<body bgcolor="#FFFFFF" text="#000000">
<div id='ft1' class='folddiv'><pre id='preft1'><span class="pd">=pod
 
=begin classdoc
 
 Subclasses &lt;cpan&gt;PPI::HTML&lt;/cpan&gt; to add code folding for POD,
 comments, and 'use'/'require' statements. Optionally permits abbreviation
 of standard PPI::HTML class/token names with user specified
 replacements. For line number output, moves the line numbers
 from individual &amp;lt;span&amp;gt;'s to a single table column,
 with the source body in the 2nd column.
 &lt;p&gt;
 Copyright&amp;copy; 2007, Presicient Corp., USA
 All rights reserved.
 &lt;p&gt;
 Permission is granted to use this software under the terms of the
 &lt;a href='http://perldoc.perl.org/perlartistic.html'&gt;Perl Artisitic License&lt;/a&gt;.
 
 @author D. Arnold
 @since 2007-01-22
 @self    $self
 

=end classdoc
 
=cut
 
 </span></pre></div>
<div id='ft29' class='folddiv'><pre id='preft29'><span class="kw">
use</span> <span class="wo">PPI::HTML</span>;
<span class="kw">use</span> <span class="pg">base</span> (<span class="sg">'PPI::HTML'</span>);
 
<span class="kw">use</span> <span class="pg">strict</span>;
<span class="kw">use</span> <span class="pg">warnings</span>;
</pre></div>
<div id='ft113' class='folddiv'><pre id='preft113'><span class="ct">
#</span>
<span class="ct">#    folddiv CSS
# </span></pre></div>
<div id='ft118' class='folddiv'><pre id='preft118'><span class="hc">
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
    overflow : hidden;  // to keep FF on OS X happy
}
 
.folddiv {
    position: absolute;
    visibility: hidden;
    overflow : hidden;  // to keep FF on OS X happy
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
 
--&gt;
&lt;/style&gt; </span></pre></div>
<div id='ft185' class='folddiv'><pre id='preft185'><span class="hc">
function ppiHtmlCF(startlines, endlines) 
{
    this.startlines = startlines;
    this.endlines = endlines;
    this.foldstate = [];
    for (var i = 0; i &lt; startlines.length; i++)
        this.foldstate[startlines[i]] = &quot;closed&quot;;
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
    for (var n = 0; n &lt; this.startlines.length; n++) {
        line = this.startlines[n];
        if ((this.foldstate[line] != null) &amp;&amp; (this.foldstate[line] == &quot;open&quot;))
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
     *  no cookie, create one w/ all folds closed
     */
        this.setCookie('');
    }
    else {
        for (var n = 0; n &lt; this.startlines.length; n++) {
            line = this.startlines[n];
            if (this.foldstate[line] == null) 
                this.foldstate[line] = &quot;closed&quot;;
 
            if (opened.indexOf(':' + line + ':') &gt;= 0) {
                if (this.foldstate[line] == &quot;closed&quot;)
                    this.accordian(line, this.endlines[n]);
            }
            else {
                if (this.foldstate[line] == &quot;open&quot;)
                    this.accordian(line, this.endlines[n]);
            }
        }
    }
};
 
/*
 *  renders line number and fold button margins
 */
ppiHtmlCF.prototype.renderMargins = function(lastline)
{
    var start = 1;
    var lnmargin = '';
    var btnmargin = '';
    for (var i = 0; i &lt; this.startlines.length; i++) {
        if (start != this.startlines[i]) {
            for (var j = start; j &lt; this.startlines[i]; j++) {
                lnmargin += j + &quot;\n&quot;;
                btnmargin += &quot;\n&quot;;
            }
        }
        start = this.endlines[i] + 1;
        lnmargin += &quot;&lt;span id='lm&quot; + this.startlines[i] + &quot;' class='lnpre'&gt;&quot; + this.startlines[i] + &quot;&lt;/span&gt;\n&quot;;
        btnmargin += &quot;&lt;a id='ll&quot; + this.startlines[i] + &quot;' class='foldbtn' &quot; + 
            &quot;onclick=\&quot;ppihtml.accordian(&quot; + this.startlines[i] + &quot;,&quot; + this.endlines[i] + &quot;)\&quot;&gt;&amp;oplus;&lt;/a&gt;\n&quot;;
    }
    if (lastline &gt; this.endlines[this.endlines.length - 1]) {
        for (var j = start; j &lt;= lastline; j++) {
            lnmargin += j + &quot;\n&quot;;
            btnmargin += &quot;\n&quot;;
        }
    }
    lnmargin += &quot;\n&quot;;
    btnmargin += &quot;\n&quot;;
    buttons = document.getElementById(&quot;btnmargin&quot;);
    lnno = document.getElementById(&quot;lnnomargin&quot;);
    if (navigator.appVersion.indexOf(&quot;MSIE&quot;)!=-1) {
        lnno.outerHTML = &quot;&lt;pre id='lnnomargin' class='lnpre'&gt;&quot; + lnmargin + &quot;&lt;/pre&gt;&quot;;
        buttons.outerHTML = &quot;&lt;pre id='btnmargin' class='lnpre'&gt;&quot; + btnmargin + &quot;&lt;/pre&gt;&quot;;
    }
    else {
        lnno.innerHTML = lnmargin;
        buttons.innerHTML = btnmargin;
    }
}
 
/*
 *  Accordian function for folded code
 *
 *  if clicked fold is closed
 *      replace contents of specified lineno margin span
 *          with complete lineno list
 *      replace contents of specified link span with end - start + 1 oplus's + linebreaks
 *      replace contents of insert span with contents of src_div
 *      foldstate = open
 *  else
 *      replace contents of specified lineno margin span with start lineno
 *      replace contents of specified link span with single oplus
 *      replace contents of specified insert span with &quot;Folded lines start to end&quot;
 *      foldstate = closed
 *
 *  For fancier effect, use delay to add/remove a single line at a time, with
 *  delay millsecs between updates
 */
ppiHtmlCF.prototype.accordian = function(startline, endline)
{
    if (document.getElementById) {
        if (navigator.appVersion.indexOf(&quot;MSIE&quot;)!=-1) {
            this.ie_accordian(startline, endline);
        }
        else {
            this.ff_accordian(startline, endline);
        }
    }
}
/*
 *  MSIE is a pile of sh*t, so we have to bend over
 *  backwards and completely rebuild the document elements
 *  Bright bunch of folks up there in Redmond...BTW this bug
 *  exists in IE 4 thru 7, despite people screaming for a solution
 *  for a decade. So MSFT is deaf as well as dumb
 */
ppiHtmlCF.prototype.ie_accordian = function(startline, endline)
{
    src = document.getElementById(&quot;preft&quot; + startline);
    foldbtn = document.getElementById('btnmargin');
    lineno = document.getElementById('lnnomargin');
    insert = document.getElementById(&quot;src&quot; + startline);
    linenos = lineno.innerHTML;
    buttons = foldbtn.innerHTML;
    if ((this.foldstate[startline] == null) || (this.foldstate[startline] == &quot;closed&quot;)) {
        lnr = &quot;&lt;span[^&gt;]+&gt;&quot; + startline + &quot;[\r\n]*&lt;/span&gt;&quot;;
        lnre = new RegExp(lnr, &quot;i&quot;);
        bnr = &quot;id=ll&quot; + startline + &quot;[^&lt;]+&lt;/a&gt;&quot;;
        btnre = new RegExp(bnr, &quot;i&quot;);
 
        lnfill = startline + &quot;\n&quot;;
        btnfill = &quot;&amp;oplus;\n&quot;;
        for (i = startline + 1; i &lt;= endline; i++) {
            lnfill += i + &quot;\n&quot;;
            btnfill += &quot;&amp;oplus;\n&quot;;
        }
 
        linenos = linenos.replace(lnre, &quot;&lt;span id='lm&quot; + startline + &quot;' class='lnpre'&gt;&quot; + lnfill + &quot;&lt;/span&gt;&quot;);
        buttons = buttons.replace(btnre, &quot;id='ll&quot; + startline + &quot;' class='foldbtn' style='background-color: yellow' onclick=\&quot;ppihtml.accordian(&quot; + 
            startline + &quot;, &quot; + endline + &quot;)\&quot;&gt;&quot; + btnfill + &quot;&lt;/a&gt;&quot;);
 
        foldbtn.outerHTML = &quot;&lt;pre id='btnmargin' class='lnpre'&gt;&quot; + buttons + &quot;&lt;/pre&gt;&quot;;
        lineno.outerHTML = &quot;&lt;pre id='lnnomargin' class='lnpre'&gt;&quot; + linenos + &quot;&lt;/pre&gt;&quot;;
        insert.outerHTML = &quot;&lt;span id='src&quot; + startline + &quot;'&gt;&lt;pre class='bodypre'&gt;&quot; + src.innerHTML + &quot;&lt;/pre&gt;&lt;/span&gt;&quot;;
        this.foldstate[startline] = &quot;open&quot;;
    }
    else {
        lnr = &quot;&lt;span[^&gt;]+&gt;&quot; + startline + &quot;[\r\n][^&lt;]*&lt;/span&gt;&quot;;
        lnre = new RegExp(lnr, &quot;i&quot;);
        bnr = &quot;id=ll&quot; + startline + &quot;[^&lt;]+&lt;/a&gt;&quot;;
        btnre = new RegExp(bnr, &quot;i&quot;);
 
        if (! linenos.match(lnre))
            alert(&quot;linenos no match&quot;);
        if (! buttons.match(btnre))
            alert(&quot;buttons no match&quot;);
        linenos = linenos.replace(lnre, &quot;&lt;span id='lm&quot; + startline + &quot;' class='lnpre'&gt;&quot; + startline + &quot;\n&lt;/span&gt;&quot;);
        buttons = buttons.replace(btnre, &quot;id='ll&quot; + startline + &quot;' class='foldbtn' style='background-color: #E9E9E9' onclick=\&quot;ppihtml.accordian(&quot; +
            startline + &quot;, &quot; + endline + &quot;)\&quot;&gt;&amp;oplus;\n&lt;/a&gt;&quot;);
 
        foldbtn.outerHTML = &quot;&lt;pre id='btnmargin' class='lnpre'&gt;&quot; + buttons + &quot;&lt;/pre&gt;&quot;;
        lineno.outerHTML = &quot;&lt;pre id='lnnomargin' class='lnpre'&gt;&quot; + linenos + &quot;&lt;/pre&gt;&quot;;
        insert.outerHTML = &quot;&lt;span id='src&quot; + startline + &quot;'&gt;&lt;pre class='foldfill'&gt;Folded lines &quot; + startline + &quot; to &quot; + endline + &quot;&lt;/pre&gt;&lt;/span&gt;&quot;;
 
        this.foldstate[startline] = &quot;closed&quot;;
    }
    this.updateCookie();
}
 
ppiHtmlCF.prototype.ff_accordian = function(startline, endline)
{
    src = document.getElementById(&quot;preft&quot; + startline);
    foldbtn = document.getElementById(&quot;ll&quot; + startline);
    lineno = document.getElementById(&quot;lm&quot; + startline);
    insert = document.getElementById(&quot;src&quot; + startline);
    if ((this.foldstate[startline] == null) || (this.foldstate[startline] == &quot;closed&quot;)) {
        lnfill = startline + &quot;\n&quot;;
        btnfill = &quot;&amp;oplus;\n&quot;;
        for (i = startline + 1; i &lt;= endline; i++) {
            lnfill += (i &lt; endline) ? i + &quot;\n&quot; : i;
            btnfill += (i &lt; endline) ? &quot;&amp;oplus;\n&quot; : &quot;&amp;oplus;&quot;;
        }
        foldbtn.innerHTML = btnfill;
        lineno.innerHTML = lnfill;
        foldbtn.style.backgroundColor = &quot;yellow&quot;;
        insert.innerHTML = src.innerHTML;
        insert.className = &quot;bodypre&quot;;
        this.foldstate[startline] = &quot;open&quot;;
    }
    else {
        foldbtn.innerHTML = &quot;&amp;oplus;&quot;;
        foldbtn.style.backgroundColor = &quot;#E9E9E9&quot;;
        lineno.innerHTML = startline;
        insert.innerHTML = &quot;Folded lines &quot; + startline + &quot; to &quot; + endline;
        insert.className = &quot;foldfill&quot;;
        this.foldstate[startline] = &quot;closed&quot;;
    }
    this.updateCookie();
}
 
/*
 *  open/close all folds
 */
ppiHtmlCF.prototype.fold_all = function(foldstate)
{
    for (i = 0; i &lt; this.startlines.length; i++) {
        line = this.startlines[i];
        if (this.foldstate[line] == null) 
            this.foldstate[line] = &quot;closed&quot;;
 
        if (this.foldstate[line] != foldstate)
            this.accordian(line, this.endlines[i]);
    }
    this.updateCookie();
}
 
ppiHtmlCF.prototype.add_fold = function(startline, endline)
{
    this.startlines[this.startlines.length] = startline;
    this.endlines[this.endlines.length] = endline;
    this.foldstate[this.foldstate.length] = &quot;closed&quot;;
}
 </span></pre></div>
<div id='ft452' class='folddiv'><pre id='preft452'><span class="pd">
=pod
 
=begin classdoc
 
    Constructor. Uses PPI::HTML base constructor, then installs some
    additional members based on the &lt;code&gt;fold&lt;/code&gt; argument.
 
 @optional colors hashref of &lt;b&gt;original&lt;/b&gt; PPI::HTML classnames to color codes/names
 @optional css    a &lt;cpan&gt;CSS::Tiny&lt;/cpan&gt; object containg additional stylsheet properties
 @optional fold   hashref of code folding properties; if not specified, a default
                  set of properties is applied. Folding properties include:
 &lt;ul&gt;
 &lt;li&gt;Abbreviate - hashref mapping full classnames to smaller classnames; useful
        to provide further output compression; default uses predefined mapping
 &lt;li&gt;Comments - if true, fold comments; default true
 &lt;li&gt;Expandable - if true, provide links to unfold lines in place; default false
 &lt;li&gt;Imports  - if true, fold 'use' and 'require' statements; default false
 &lt;li&gt;Javascript  - name of file to reference for the fold expansion javascript in the output HTML;
    default none, resulting in Javascript embedded in output HTML.&lt;br&gt;
    Note that the Javascript may be retrieved separately via the &lt;code&gt;foldJavascript()&lt;/code&gt; method.
 &lt;li&gt;MinFoldLines - minimum number of consecutive foldable lines required before folding is applied;
            default is 4
 &lt;li&gt;POD - if true, fold POD line; default true
 &lt;li&gt;Stylesheet - name of file to reference for the CSS for abbreviated classnames and
            fold DIVs in the output HTML; default none,resulting in CSS embedded in output
            HTML.&lt;br&gt;
    Note that the CSS may be retrieved separately via the &lt;code&gt;foldCSS()&lt;/code&gt; method.
 &lt;li&gt;Tabs - size of tabs; default 4
 &lt;/ul&gt;
 
 @optional line_numbers if true, include line numbering in the output HTML
 @optional page   if true, wrap the output in a HTML &amp;lt;head&amp;gt; and &amp;lt;body&amp;gt;
       sections. &lt;b&gt;NOTE: CodeFolder forces this to true.
 @optional verbose   if true, spews various diagnostic info
 
 @return    a new PPI::HTML::CodeFolder object
 
=end classdoc
 
=cut
 
 </span></pre></div>
<div id='ft500' class='folddiv'><pre id='preft500'><span class="ct">#</span>
<span class="ct">#    remove line numbering option since it greatly simplifies the spanning
#    scan later; we'll apply it after we're done
# </span></pre></div>
<div id='ft545' class='folddiv'><pre id='preft545'><span class="pd">
=pod
 
=begin classdoc
 
    Returns the Javascript used for fold expansion.
 
 @return    Javascript for fold expansion, as a string
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft559' class='folddiv'><pre id='preft559'><span class="pd">
 
=pod
 
=begin classdoc
 
Write out the Javascript used for fold expansion.
 
@return    1 on success; undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft581' class='folddiv'><pre id='preft581'><span class="pd">
=pod
 
=begin classdoc
 
Write out the CSS used for the sources.
 
@return    1 on success; undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft602' class='folddiv'><pre id='preft602'><span class="pd">
=pod
 
=begin classdoc
 
    Returns the CSS used for the abbreviated classes and fold DIVs.
 
 @return    CSS as a string
 
=end classdoc
 
=cut
 
 </span></pre></div>
<div id='ft620' class='folddiv'><pre id='preft620'><span class="hc">&lt;style type=&quot;text/css&quot;&gt;
&lt;!--
body {
    font-family: fixed, Courier;
    font-size: 10pt;
} </span></pre></div>
<div id='ft636' class='folddiv'><pre id='preft636'><span class="ct">#</span>
<span class="ct">#   !!!fix for (yet another) Firefox bug: need a dummy class
#   at front of CSS or firefox ignores the first class...
# </span></pre></div>
<div id='ft651' class='folddiv'><pre id='preft651'><span class="pd">
=pod
 
=begin classdoc
 
    Generate folded HTML from source PPI document.
    Overrides base class &lt;code&gt;html()&lt;/code&gt; to apply codefolding support.
 
@param $src    a &lt;cpan&gt;PPI::Document&lt;/cpan&gt; object, OR the
                path to the source file, OR a scalarref of the
                actual source text.
@optional $outfile name of the output HTML file; If not specified for a filename $src, the
            default is &quot;$src.html&quot;; If not specified for either PPI::Document or text $src,
            defaults to an empty string.
@optional $script   a name used if source is a script file. Script files might not include
            any explicit packages or method declarations which would be mapped into the
            table of contents. By specifying this parameter, an entry is forced into the 
            table of contents for the script, with any &quot;main&quot; package methods within the
            script reassigned to this script name. If not specified, and &lt;code&gt;$src&lt;/code&gt;
            is not a filename, an error will be issued when the TOC is generated. 
 
 @return    on success, the folded HTML; undef on failure
 
 @returnlist    on success, the folded HTML and a hashref mapping packages to an arrayref of method names;
                undef on failure
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft692' class='folddiv'><pre id='preft692'><span class="ct">#</span>
<span class="ct">#   expand tabs as needed (we use 4 space tabs)
#   have to adjust some spans that confuse tab processing
# </span></pre></div>
<div id='ft703' class='folddiv'><pre id='preft703'><span class="ct">#</span>
<span class="ct">#   scan for and replace tabs; adjust positions
#   of extracted tags as needed
# </span></pre></div>
<div id='ft745' class='folddiv'><pre id='preft745'><span class="ct">#</span>
<span class="ct">#   split multiline comments into 2 spans: 1st line (in case its midline)
#   and the remainder; note that the prior substitution avoids
#   doing this to single line comments
# </span></pre></div>
<div id='ft751' class='folddiv'><pre id='preft751'><span class="ct">#</span>
<span class="ct"># keep folded fragments here for later insertion
# as fold DIVs; key is starting line number,
# value is [ number of lines, text ]
# </span></pre></div>
<div id='ft757' class='folddiv'><pre id='preft757'><span class="ct">#</span>
<span class="ct">#    count &lt;br&gt; tags, and looks for any of
#    comment, pod, or use/require keyword (depending on the options);
#    keeps track of start and end position of foldable segments
# </span></pre></div>
<div id='ft784' class='folddiv'><pre id='preft784'><span class="ct">#</span>
<span class="ct">#   trim small folds;
#   since its used frequently, create a sorted list of the fold DIV lines;
#   isolate positions of folds and extract folded content
# </span></pre></div>
<div id='ft802' class='folddiv'><pre id='preft802'><span class="ct">#</span>
<span class="ct">#    now remove the folded lines; we work from bottom to top since
#    we're changing the HTML as we go, which would invalidate the
#    positional elements we've kept. If fold expansion is enabled, we replace
#    w/ a hyperlink; otherwise we replace with a simple indication of the fold
# </span></pre></div>
<div id='ft829' class='folddiv'><pre id='preft829'><span class="ct">#</span>
<span class="ct">#    now create the line number table (if requested)
#    NOTE: this is where having the breakable lines would be really
#    useful!!!
# </span></pre></div>
<div id='ft847' class='folddiv'><pre id='preft847'><span class="ct">#</span>
<span class="ct">#   fix Firefox blank lines inside spans bug: add a single space to
#   all blank lines
# </span></pre></div>
<div id='ft855' class='folddiv'><pre id='preft855'><span class="pd">
=pod
 
=begin classdoc
 
Return current package/method cross reference.
 
@return    hashref of current package/method cross reference
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft869' class='folddiv'><pre id='preft869'><span class="pd">
=pod
 
=begin classdoc
 
Write out a table of contents document for the current collection of
sources as a nested HTML list. The output filename is 'toc.html'.
The caller may optionally specify the order of packages in the menu.
 
@param $path directory to write TOC file
@optional Order arrayref of packages in the order in which they should appear in TOC; if a partial list,
                    any remaining packages will be appended to the TOC in alphabetical order
 
@return this object on success, undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft899' class='folddiv'><pre id='preft899'><span class="pd">
=begin classdoc
 
Generate a table of contents document for the current collection of
sources as a nested HTML list. Caller may optionally specify
the order of packages in the menu.
 
@param $tocpath     path of output TOC file
@optional Order arrayref of packages in the order in which they should appear in TOC; if a partial list,
                    any remaining packages will be appended to the TOC in alphabetical order
 
@return the TOC document
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft961' class='folddiv'><pre id='preft961'><span class="pd">
=pod
 
=begin classdoc
 
Write out a frame container document to hold the rendered source and TOC.
The file is written to &quot;$path/index.html&quot;.
 
@param $path directory to write the document.
@param $title Title string for resulting document
@optional $home the &quot;home&quot; document initially loaded into the main frame; default none
 
@return this object on success, undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft989' class='folddiv'><pre id='preft989'><span class="pd">
=begin classdoc
 
Generate a frame container document to hold the rendered source and TOC.
 
@return the frame container document as a string
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft1026' class='folddiv'><pre id='preft1026'><span class="ct">#</span>
<span class="ct">#   assume package &quot;main&quot; to start; on exit,
#   if we have a script name, then replace all &quot;main&quot;
#   entries with $script
# </span></pre></div>
<div id='ft1094' class='folddiv'><pre id='preft1094'><span class="ct">#</span>
<span class="ct">#   accumulate foldable sections, including leading/trailing whitespace
#
#   my $fre = $foldres{$_}[0];
#   push @{$folded{$_}}, [ $-[1], $+[1] - 1 ]
#       if ($$html=~/$fre/gcs);</span>
 
<span class="ct">#       push @{$folded{Whitespace}}, [ $-[1], $+[1] - 1 ]</span>
<span class="ct">#       while ($$html=~/\G.*?&lt;br&gt;((?:\s*&lt;br&gt;)+)/gcs);
#   _mergeSection(_cvtToLines($folded{Whitespace}, $lnmap))
#       if scalar @{$folded{Whitespace}};
 </span></pre></div>
<table border=0 width='100%' cellpadding=0 cellspacing=0>
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
<pre class='bodypre'><span id='src1' class='foldfill'>Folded lines 1 to 27</span>
<a name='PPI::HTML::CodeFolder'></a><span class="kw">package</span> <span class="wo">PPI::HTML::CodeFolder</span>;
<span id='src29' class='foldfill'>Folded lines 29 to 35</span>
<span class="kw">our</span> $VERSION <span class="op">=</span> <span class="sg">'1.01'</span>;
 
<span class="kw">our</span> %classabvs <span class="op">=</span> qw(
 
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
<span class="ct">#</span>
<span class="ct">#   fold section regular expressions
#</span>
<span class="kw">my</span> %foldres <span class="op">=</span> (
    <span class="wo">Whitespace</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)((?:\s*&lt;br&gt;)+)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;((?:\s*&lt;br&gt;)+)/
    ]<span class="op">,</span>
    <span class="wo">Comments</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*(&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*(&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/
    ]<span class="op">,</span>
    <span class="wo">POD</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*(&lt;span\s+class=['&quot;]pod['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*(&lt;span\s+class=['&quot;]pod['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/
    ]<span class="op">,</span>
    <span class="wo">Heredocs</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*(&lt;span\s+class=['&quot;]heredoc_content['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*(&lt;span\s+class=['&quot;]heredoc_content['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/
    ]<span class="op">,</span>
    <span class="wo">Imports</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*
                (
                    (?:&lt;span\s+class=['&quot;]keyword['&quot;]&gt;(?:use|require)&lt;\/span&gt;.+?;\s*)+
                    (?:&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)?
                )
                (?=&lt;br&gt;)
                /x<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*
                (
                    (?:&lt;span\s+class=['&quot;]keyword['&quot;]&gt;(?:use|require)&lt;\/span&gt;.+?;\s*)+
                    (?:&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)?
                )
                (?=&lt;br&gt;)
                /x
    ]<span class="op">,</span>
);
<span id='src113' class='foldfill'>Folded lines 113 to 116</span>
<span class="kw">our</span> $ftcss <span class="op">=</span> <span class="hd">&lt;&lt;'EOFTCSS'</span>;
<span id='src118' class='foldfill'>Folded lines 118 to 179</span>
<span class="ht">EOFTCSS</span>
<span class="ct">#</span>
<span class="ct">#    fold expansion javascript
#</span>
<span class="kw">our</span> $ftjs <span class="op">=</span> <span class="hd">&lt;&lt;'EOFTJS'</span>;
<span id='src185' class='foldfill'>Folded lines 185 to 450</span>
<span class="ht">EOFTJS</span>
<span id='src452' class='foldfill'>Folded lines 452 to 494</span>
<a name='PPI::HTML::CodeFolder::new'></a><span class="kw">sub</span> <span class="wo">new</span> {
    <span class="kw">my</span> ($class<span class="op">,</span> %args) <span class="op">=</span> <span class="mg">@_</span>;
 
    <span class="kw">my</span> $fold <span class="op">=</span> <span class="wo">delete</span> $args{<span class="wo">fold</span>};
    <span class="kw">my</span> $verb <span class="op">=</span> <span class="wo">delete</span> $args{<span class="wo">verbose</span>};
<span id='src500' class='foldfill'>Folded lines 500 to 503</span>
    <span class="kw">my</span> $needs_ln <span class="op">=</span> <span class="wo">delete</span> $args{<span class="wo">line_numbers</span>};
<span class="ct">#</span>
<span class="ct">#   force page wrapping
#</span>
    $args{<span class="wo">page</span>} <span class="op">=</span> <span class="nm">1</span>;
    <span class="kw">my</span> $self <span class="op">=</span> $class<span class="op">-&gt;</span><span class="wo">SUPER::new</span>(%args);
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> $self;
 
    $self<span class="op">-&gt;</span>{<span class="wo">_needs_ln</span>} <span class="op">=</span> $needs_ln;
    $self<span class="op">-&gt;</span>{<span class="wo">_verbose</span>} <span class="op">=</span> $verb;
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>} <span class="op">=</span> $fold <span class="op">?</span>
        { <span class="cs">%</span>$fold } <span class="op">:</span>
        {
        <span class="wo">Abbreviate</span>    <span class="op">=&gt;</span> <span class="cs">\</span>%classabvs<span class="op">,</span>
        <span class="wo">Comments</span>      <span class="op">=&gt;</span> <span class="nm">1</span><span class="op">,</span>
        <span class="wo">Heredocs</span>      <span class="op">=&gt;</span> <span class="nm">0</span><span class="op">,</span>
        <span class="wo">Imports</span>       <span class="op">=&gt;</span> <span class="nm">0</span><span class="op">,</span>
        <span class="wo">Javascript</span>    <span class="op">=&gt;</span> <span class="co">undef</span><span class="op">,</span>
        <span class="wo">Expandable</span>      <span class="op">=&gt;</span> <span class="nm">0</span><span class="op">,</span>
        <span class="wo">MinFoldLines</span>  <span class="op">=&gt;</span> <span class="nm">4</span><span class="op">,</span>
        <span class="wo">POD</span>           <span class="op">=&gt;</span> <span class="nm">1</span><span class="op">,</span>
        <span class="wo">Stylesheet</span>    <span class="op">=&gt;</span> <span class="co">undef</span><span class="op">,</span>
        <span class="wo">Tabs</span>          <span class="op">=&gt;</span> <span class="nm">4</span><span class="op">,</span>
        };
 
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>} <span class="op">=</span> <span class="cs">\</span>%classabvs
        <span class="wo">if</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>} <span class="op">&amp;&amp;</span> (<span class="op">!</span> (<span class="wo">ref</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>}));
 
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">MinFoldLines</span>} <span class="op">=</span> <span class="nm">4</span>
        <span class="wo">unless</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">MinFoldLines</span>};
 
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Tabs</span>} <span class="op">=</span> <span class="nm">4</span>
        <span class="wo">unless</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Tabs</span>};
<span class="ct">#</span>
<span class="ct">#   keep a running package/method cross reference
#</span>
    $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>} <span class="op">=</span> {};
 
    <span class="kw">return</span> $self;
}
<span id='src545' class='foldfill'>Folded lines 545 to 557</span>
<a name='PPI::HTML::CodeFolder::foldJavascript'></a><span class="kw">sub</span> <span class="wo">foldJavascript</span> { <span class="kw">return</span> $ftjs; }
<span id='src559' class='foldfill'>Folded lines 559 to 572</span>
<a name='PPI::HTML::CodeFolder::writeJavascript'></a><span class="kw">sub</span> <span class="wo">writeJavascript</span> { 
    <span class="mg">$@</span> <span class="op">=</span> <span class="mg">$!</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">open</span> <span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$_[1]&quot;</span>;
    <span class="wo">print</span> <span class="wo">OUTF</span> $ftjs;
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> <span class="nm">1</span>;
}
<span id='src581' class='foldfill'>Folded lines 581 to 593</span>
<a name='PPI::HTML::CodeFolder::writeCSS'></a><span class="kw">sub</span> <span class="wo">writeCSS</span> { 
    <span class="mg">$@</span> <span class="op">=</span> <span class="mg">$!</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">open</span> <span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$_[1]&quot;</span>;
    <span class="wo">print</span> <span class="wo">OUTF</span> <span class="mg">$_</span>[<span class="nm">0</span>]<span class="op">-&gt;</span><span class="wo">foldCSS</span>();
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> <span class="nm">1</span>;
}
<span id='src602' class='foldfill'>Folded lines 602 to 615</span>
<a name='PPI::HTML::CodeFolder::foldCSS'></a><span class="kw">sub</span> <span class="wo">foldCSS</span> {
    <span class="kw">my</span> $self <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> $orig_colors <span class="op">=</span> <span class="wo">exists</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>};
    <span class="kw">my</span> $css <span class="op">=</span> $self<span class="op">-&gt;</span><span class="wo">_css_html</span>() <span class="op">||</span> <span class="hd">&lt;&lt; 'EOCSS'</span>;
<span id='src620' class='foldfill'>Folded lines 620 to 625</span>
<span class="ht">EOCSS</span>
 
    <span class="kw">my</span> $ftc <span class="op">=</span> $ftcss;
    <span class="wo">if</span> ($self<span class="op">-&gt;</span>{<span class="wo">colors</span>}{<span class="wo">line_number</span>}) {
        <span class="kw">my</span> $lnc <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>}{<span class="wo">line_number</span>};
        $ftc<span class="op">=~</span><span class="su">s/(.lnpre\s+.+?color: )#888888;/$1$lnc;/gs</span>;
    }
 
    <span class="wo">delete</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>} <span class="wo">unless</span> $orig_colors;
    $css<span class="op">=~</span><span class="su">s|--&gt;\s*&lt;/style&gt;||s</span>;
<span id='src636' class='foldfill'>Folded lines 636 to 639</span>
    $css<span class="op">=~</span><span class="su">s/(&lt;!--.*?\n)/$1\n\n.dummy_class_for_firefox { color: white; }\n/</span>;
<span class="ct">#</span>
<span class="ct">#    replace classes w/ abbreviations
#</span>
    <span class="wo">if</span> ($self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>}) {
        <span class="kw">my</span> ($long<span class="op">,</span> $abv);
        $css<span class="op">=~</span><span class="su">s/\.$long \{/.$abv {/s</span>
            <span class="wo">while</span> (($long<span class="op">,</span> $abv) <span class="op">=</span> <span class="wo">each</span> <span class="cs">%</span>{$self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>}});
    }
    <span class="kw">return</span> $css <span class="op">.</span> $ftc;
}
<span id='src651' class='foldfill'>Folded lines 651 to 680</span>
<a name='PPI::HTML::CodeFolder::html'></a><span class="kw">sub</span> <span class="wo">html</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $src<span class="op">,</span> $outfile<span class="op">,</span> $script) <span class="op">=</span> <span class="mg">@_</span>;
 
    <span class="kw">my</span> $orig_colors <span class="op">=</span> <span class="wo">exists</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>};
    <span class="kw">my</span> $html <span class="op">=</span> $self<span class="op">-&gt;</span><span class="wo">SUPER::html</span>($src)
        <span class="op">or</span> <span class="kw">return</span> <span class="co">undef</span>;
 
    $outfile <span class="op">=</span> (<span class="wo">ref</span> $src) <span class="op">?</span> <span class="sg">''</span> <span class="op">:</span> <span class="db">&quot;$src.html&quot;</span>
        <span class="wo">unless</span> $outfile;
    $script <span class="op">||=</span> $src 
        <span class="wo">unless</span> <span class="wo">ref</span> $src <span class="op">||</span> (<span class="wo">substr</span>($src<span class="op">,</span> <span class="nm">-3</span>) <span class="op">eq</span> <span class="sg">'.pm'</span>);
<span id='src692' class='foldfill'>Folded lines 692 to 695</span>
    <span class="kw">my</span> @lns <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\n/</span><span class="op">,</span> $html;
    <span class="kw">my</span> $tabsz <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Tabs</span>};
    <span class="wo">foreach</span> <span class="wo">my</span> $line (@lns) {
        <span class="wo">next</span> <span class="wo">if</span> $line<span class="op">=~</span><span class="su">s/^\s*$//</span>;
        <span class="wo">next</span> <span class="wo">unless</span> $line<span class="op">=~</span><span class="tl">tr/\t//</span>;
        <span class="kw">my</span> $offs <span class="op">=</span> <span class="nm">0</span>;
        <span class="kw">my</span> $pad;
<span id='src703' class='foldfill'>Folded lines 703 to 706</span>
        <span class="wo">pos</span>($line) <span class="op">=</span> <span class="nm">0</span>;
        <span class="wo">while</span> ($line<span class="op">=~</span><span class="mt">/\G.*?((&lt;[^&gt;]+&gt;)|\t)/gc</span>) {
            $offs <span class="op">+=</span> <span class="wo">length</span>(<span class="mg">$2</span>)<span class="op">,</span>
            <span class="wo">next</span>
                <span class="wo">unless</span> (<span class="mg">$1</span> <span class="op">eq</span> <span class="db">&quot;\t&quot;</span>);
 
            $pad <span class="op">=</span> $tabsz <span class="op">-</span> (<span class="mg">$-</span>[<span class="nm">1</span>] <span class="op">-</span> $offs) <span class="op">%</span> $tabsz;
            <span class="wo">substr</span>($line<span class="op">,</span> <span class="mg">$-</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="nm">1</span><span class="op">,</span> <span class="sg">' '</span> <span class="op">x</span> $pad);
            <span class="wo">pos</span>($line) <span class="op">=</span> <span class="mg">$-</span>[<span class="nm">1</span>] <span class="op">+</span> $pad <span class="op">-</span> <span class="nm">1</span>;
        }
    }
    $html <span class="op">=</span> <span class="wo">join</span>(<span class="db">&quot;\n&quot;</span><span class="op">,</span> @lns);
 
    <span class="wo">delete</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>} <span class="wo">unless</span> $orig_colors;
 
    <span class="kw">my</span> $opts <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>};
<span class="ct">#</span>
<span class="ct">#    extract stylesheet and replace with abbreviated version
#</span>
    <span class="kw">my</span> $style <span class="op">=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Stylesheet</span>} <span class="op">?</span>
        <span class="db">&quot;&lt;link type='text/css' rel='stylesheet' href='&quot;</span> <span class="op">.</span> 
            <span class="wo">_pathAdjust</span>($outfile<span class="op">,</span> $opts<span class="op">-&gt;</span>{<span class="wo">Stylesheet</span>}) <span class="op">.</span> <span class="db">&quot;' /&gt;&quot;</span> <span class="op">:</span>
        $self<span class="op">-&gt;</span><span class="wo">foldCSS</span>();
 
    $style <span class="op">.=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Javascript</span>} <span class="op">?</span>
        <span class="db">&quot;\n&lt;script type='text/javascript' src='&quot;</span> <span class="op">.</span>
            <span class="wo">_pathAdjust</span>($outfile<span class="op">,</span> $opts<span class="op">-&gt;</span>{<span class="wo">Javascript</span>}) <span class="op">.</span> <span class="db">&quot;'&gt;&lt;/script&gt;\n&quot;</span> <span class="op">:</span>
        <span class="db">&quot;\n&lt;script type='text/javascript'&gt;\n$ftjs\n&lt;/script&gt;\n&quot;</span>
        <span class="wo">if</span> $opts<span class="op">-&gt;</span>{<span class="wo">Expandable</span>};
<span class="ct">#</span>
<span class="ct">#   original html may have no style, so we've got to add OR replace
#</span>
    $html<span class="op">=~</span><span class="su">s|&lt;/head&gt;|$style&lt;/head&gt;|s</span>
        <span class="wo">unless</span> ($html<span class="op">=~</span><span class="su">s|&lt;style type=&quot;text/css&quot;&gt;.+&lt;/style&gt;|$style|s</span>);
<span class="ct">#</span>
<span class="ct">#   force spans to end before line endings
#</span>
    $html<span class="op">=~</span><span class="su">s!(&lt;br&gt;\s*)&lt;/span&gt;!&lt;/span&gt;$1!g</span>;
<span id='src745' class='foldfill'>Folded lines 745 to 749</span>
    $html<span class="op">=~</span><span class="su">s/(?!&lt;br&gt;\s+)(&lt;span class=['&quot;]comment['&quot;]&gt;[^&lt;]+)&lt;br&gt;\n/$1&lt;\/span&gt;&lt;br&gt;\n&lt;span class=&quot;comment&quot;&gt;/g</span>;
<span id='src751' class='foldfill'>Folded lines 751 to 755</span>
    <span class="kw">my</span> %folddivs <span class="op">=</span> ( <span class="nm">1</span> <span class="op">=&gt;</span> [ <span class="nm">0</span><span class="op">,</span> <span class="sg">''</span><span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="nm">0</span> ]);
<span id='src757' class='foldfill'>Folded lines 757 to 761</span>
    <span class="kw">my</span> $lineno <span class="op">=</span> <span class="nm">1</span>;
    <span class="kw">my</span> $lastfold <span class="op">=</span> <span class="nm">1</span>;
 
    $html<span class="op">=~</span><span class="su">s/&lt;br&gt;\n/&lt;br&gt;/g</span>;
<span class="ct">#</span>
<span class="ct">#   now process remainder
#</span>
    <span class="wo">study</span> $html;
    <span class="wo">pos</span>($html) <span class="op">=</span> <span class="nm">0</span>;
    $html<span class="op">=~</span><span class="mt">/^.*?(&lt;body[^&gt;]+&gt;&lt;pre&gt;)/s</span>;
    <span class="kw">my</span> $startpos <span class="op">=</span> <span class="mg">$+</span>[<span class="nm">1</span>];
<span class="ct">#</span>
<span class="ct">#   map linebreak positions to line numbers
#</span>
    <span class="kw">my</span> @lnmap <span class="op">=</span> (<span class="nm">0</span><span class="op">,</span> $startpos);
    <span class="wo">push</span> @lnmap<span class="op">,</span> <span class="mg">$+</span>[<span class="nm">1</span>]
        <span class="wo">while</span> ($html<span class="op">=~</span><span class="mt">/\G.*?(&lt;br&gt;)/gcs</span>);
<span class="ct">#</span>
<span class="ct">#   now scan for foldables
#</span>
    <span class="wo">pos</span>($html) <span class="op">=</span> $startpos;
    <span class="kw">my</span> @folds <span class="op">=</span> <span class="wo">_extractFolds</span>(<span class="cs">\</span>$html<span class="op">,</span> $startpos<span class="op">,</span> <span class="cs">\</span>@lnmap<span class="op">,</span> $opts);
<span id='src784' class='foldfill'>Folded lines 784 to 788</span>
    <span class="kw">my</span> $ln <span class="op">=</span> <span class="nm">0</span>;
    <span class="kw">my</span> @ftsorted <span class="op">=</span> ();
    <span class="wo">foreach</span> (@folds) {
        <span class="wo">if</span> (<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">-</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>] <span class="op">+</span> <span class="nm">1</span> <span class="op">&gt;=</span> $opts<span class="op">-&gt;</span>{<span class="wo">MinFoldLines</span>}) {
            $folddivs{<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]} <span class="op">=</span> [ <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="wo">substr</span>($html<span class="op">,</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]]<span class="op">,</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">+</span> <span class="nm">1</span>] <span class="op">-</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]])<span class="op">,</span> 
                $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]]<span class="op">,</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">+</span> <span class="nm">1</span>] ];
            <span class="wo">push</span> @ftsorted<span class="op">,</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>];
        }
        <span class="wo">elsif</span> ($self<span class="op">-&gt;</span>{<span class="wo">_verbose</span>}) {
<span class="ct">#           print &quot;*** skipping section at line $_-&gt;[0]to $_-&gt;[1]\n&quot;;</span>
<span class="ct">#           print substr($html, $lnmap[$_-&gt;[0]], $lnmap[$_-&gt;[1] + 1] - $lnmap[$_-&gt;[0]]), &quot;\n&quot;;</span>
        }
    }
<span id='src802' class='foldfill'>Folded lines 802 to 807</span>
    <span class="wo">substr</span>($html<span class="op">,</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">2</span>]<span class="op">,</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">3</span>] <span class="op">-</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">2</span>]<span class="op">,</span>
        <span class="db">&quot;&lt;span id='src$_' class='foldfill'&gt;Folded lines $_ to &quot;</span> <span class="op">.</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">0</span>] <span class="op">.</span> <span class="db">&quot;&lt;/span&gt;\n&quot;</span>)
        <span class="wo">foreach</span> (<span class="wo">reverse</span> @ftsorted);
<span class="ct">#</span>
<span class="ct">#    abbreviate the default span classes for both the html and fold divs
#</span>
    <span class="wo">pos</span>($html) <span class="op">=</span> <span class="nm">0</span>;
    <span class="kw">my</span> $abvs <span class="op">=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Abbreviate</span>};
    <span class="wo">if</span> ($abvs) {
        $html<span class="op">=~</span><span class="su">s/(&lt;span\s+class=['&quot;])([^'&quot;]+)(['&quot;])/$1 . ($$abvs{$2} || $2) . $3/egs</span>;
        <span class="wo">if</span> ($opts<span class="op">-&gt;</span>{<span class="wo">Expandable</span>}) {
            <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s/(&lt;span\s+class=['&quot;])([^'&quot;]+)(['&quot;])/$1 . ($$abvs{$2} || $2) . $3/egs</span>
                <span class="wo">foreach</span> (<span class="wo">values</span> %folddivs);
        }
    }
<span class="ct">#</span>
<span class="ct">#    create and insert fold DIVs if requested
#</span>
    <span class="kw">my</span> $expdivs <span class="op">=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Expandable</span>} <span class="op">?</span> <span class="wo">_addFoldDivs</span>(<span class="cs">\</span>%folddivs<span class="op">,</span> <span class="cs">\</span>@ftsorted) <span class="op">:</span> <span class="sg">''</span>;
 
    $html<span class="op">=~</span><span class="su">s/&lt;br&gt;/\n/gs</span>;
<span id='src829' class='foldfill'>Folded lines 829 to 833</span>
    <span class="wo">_addLineNumTable</span>(<span class="cs">\</span>$html<span class="op">,</span> <span class="cs">\</span>@ftsorted<span class="op">,</span> <span class="cs">\</span>%folddivs<span class="op">,</span> <span class="cs">\</span>$expdivs<span class="op">,</span> $#lnmap)
        <span class="wo">if</span> $self<span class="op">-&gt;</span>{<span class="wo">_needs_ln</span>};
<span class="ct">#</span>
<span class="ct">#   extract a package/method reference list, and add anchors for them
#</span>
    $self<span class="op">-&gt;</span><span class="wo">_extractXRef</span>(<span class="cs">\</span>$html<span class="op">,</span> $outfile<span class="op">,</span> $script);
<span class="ct">#</span>
<span class="ct">#   report number of spans, for firefox performance report
#</span>
    <span class="wo">if</span> ($self<span class="op">-&gt;</span>{<span class="wo">_verbose</span>}) {
        <span class="kw">my</span> $spancnt <span class="op">=</span> $html<span class="op">=~</span><span class="su">s/&lt;\/span&gt;/&lt;\/span&gt;/gs</span>;
        <span class="wo">print</span> <span class="db">&quot;\n***Total spans: $spancnt\n&quot;</span>;
    }
<span id='src847' class='foldfill'>Folded lines 847 to 850</span>
    $html<span class="op">=~</span><span class="su">s!\n\n!\n \n!gs</span>;
 
    <span class="kw">return</span> $html;
}
<span id='src855' class='foldfill'>Folded lines 855 to 867</span>
<a name='PPI::HTML::CodeFolder::getCrossReference'></a><span class="kw">sub</span> <span class="wo">getCrossReference</span> { <span class="kw">return</span> <span class="mg">$_</span>[<span class="nm">0</span>]<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>}; }
<span id='src869' class='foldfill'>Folded lines 869 to 887</span>
<a name='PPI::HTML::CodeFolder::writeTOC'></a><span class="kw">sub</span> <span class="wo">writeTOC</span> {
    <span class="kw">my</span> $self <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> $path <span class="op">=</span> <span class="co">shift</span>;
    <span class="mg">$@</span> <span class="op">=</span> <span class="db">&quot;Can't open $path/toc.html: $!&quot;</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">CORE::open</span>(<span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$path/toc.html&quot;</span>);
 
    <span class="wo">print</span> <span class="wo">OUTF</span> $self<span class="op">-&gt;</span><span class="wo">getTOC</span>(<span class="db">&quot;$path/toc.html&quot;</span><span class="op">,</span> <span class="mg">@_</span>);
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> $self;
}
<span id='src899' class='foldfill'>Folded lines 899 to 915</span>
<a name='PPI::HTML::CodeFolder::getTOC'></a><span class="kw">sub</span> <span class="wo">getTOC</span> {
    <span class="kw">my</span> $self <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> $tocpath <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> %args <span class="op">=</span> <span class="mg">@_</span>;
    <span class="kw">my</span> @order <span class="op">=</span> $args{<span class="wo">Order</span>} <span class="op">?</span> <span class="cs">@</span>{$args{<span class="wo">Order</span>}} <span class="op">:</span> ();
    <span class="kw">my</span> $sources <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>};
    <span class="kw">my</span> $base;
    <span class="kw">my</span> $doc <span class="op">=</span>
<span class="db">&quot;&lt;html&gt;
&lt;body&gt;
&lt;small&gt;
&lt;!-- INDEX BEGIN --&gt;
&lt;ul&gt;
&quot;</span>;
    <span class="kw">my</span> %ordered <span class="op">=</span> ();
    $ordered{<span class="mg">$_</span>} <span class="op">=</span> <span class="nm">1</span> <span class="wo">foreach</span> (@order);
    <span class="wo">foreach</span> (<span class="wo">sort</span> <span class="wo">keys</span> <span class="cs">%</span>$sources) {
        <span class="wo">push</span> @order<span class="op">,</span> <span class="mg">$_</span> <span class="wo">unless</span> <span class="wo">exists</span> $ordered{<span class="mg">$_</span>};
    }
 
    <span class="wo">foreach</span> <span class="wo">my</span> $class (@order) {
<span class="ct">#</span>
<span class="ct">#   due to input @order, we might get classes that don't exist
#</span>
        <span class="wo">next</span> <span class="wo">unless</span> <span class="wo">exists</span> $sources<span class="op">-&gt;</span>{$class};
 
        $base <span class="op">=</span> <span class="wo">_pathAdjust</span>($tocpath<span class="op">,</span> $sources<span class="op">-&gt;</span>{$class}{<span class="wo">URL</span>});
        $doc <span class="op">.=</span>  <span class="db">&quot;&lt;li&gt;&lt;a href='$base' target='mainframe'&gt;$class&lt;/a&gt;
        &lt;ul&gt;\n&quot;</span>;
        <span class="kw">my</span> $info <span class="op">=</span> $sources<span class="op">-&gt;</span>{$class}{<span class="wo">Methods</span>};
        $doc <span class="op">.=</span>  <span class="db">&quot;&lt;li&gt;&lt;a href='&quot;</span> <span class="op">.</span> <span class="wo">_pathAdjust</span>($tocpath<span class="op">,</span> $info<span class="op">-&gt;</span>{<span class="mg">$_</span>}) <span class="op">.</span> <span class="db">&quot;' target='mainframe'&gt;$_&lt;/a&gt;&lt;/li&gt;\n&quot;</span>
            <span class="wo">foreach</span> (<span class="wo">sort</span> <span class="wo">keys</span> <span class="cs">%</span>$info);
        $doc <span class="op">.=</span>  <span class="db">&quot;&lt;/ul&gt;\n&lt;/li&gt;\n&quot;</span>;
    }
 
    $doc <span class="op">.=</span>  <span class="db">&quot;
&lt;/ul&gt;
&lt;!-- INDEX END --&gt;
&lt;/small&gt;
&lt;/body&gt;
&lt;/html&gt;
&quot;</span>;
 
    <span class="kw">return</span> $doc;
}
<span id='src961' class='foldfill'>Folded lines 961 to 978</span>
<a name='PPI::HTML::CodeFolder::writeFrameContainer'></a><span class="kw">sub</span> <span class="wo">writeFrameContainer</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $path<span class="op">,</span> $title<span class="op">,</span> $home) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="mg">$@</span> <span class="op">=</span> <span class="db">&quot;Can't open $path/index.html: $!&quot;</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">open</span>(<span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$path/index.html&quot;</span>);
 
    <span class="wo">print</span> <span class="wo">OUTF</span> $self<span class="op">-&gt;</span><span class="wo">getFrameContainer</span>($title<span class="op">,</span> $home);
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> $self;
}
<span id='src989' class='foldfill'>Folded lines 989 to 999</span>
<a name='PPI::HTML::CodeFolder::getFrameContainer'></a><span class="kw">sub</span> <span class="wo">getFrameContainer</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $title<span class="op">,</span> $home) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="kw">return</span> $home <span class="op">?</span>
<span class="db">&quot;&lt;html&gt;&lt;head&gt;&lt;title&gt;$title&lt;/title&gt;&lt;/head&gt;
&lt;frameset cols='15%,85%'&gt;
&lt;frame name='navbar' src='toc.html' scrolling=auto frameborder=0&gt;
&lt;frame name='mainframe' src='$home'&gt;
&lt;/frameset&gt;
&lt;/html&gt;
&quot;</span> <span class="op">:</span>
<span class="db">&quot;&lt;html&gt;&lt;head&gt;&lt;title&gt;$title&lt;/title&gt;&lt;/head&gt;
&lt;frameset cols='15%,85%'&gt;
&lt;frame name='navbar' src='toc.html' scrolling=auto frameborder=0&gt;
&lt;frame name='mainframe'&gt;
&lt;/frameset&gt;
&lt;/html&gt;
&quot;</span>;
}
<span class="ct">#</span>
<span class="ct">#   extract a package/method reference list, and add anchors for them
#</span>
<a name='PPI::HTML::CodeFolder::_extractXRef'></a><span class="kw">sub</span> <span class="wo">_extractXRef</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $html<span class="op">,</span> $outfile<span class="op">,</span> $script) <span class="op">=</span> <span class="mg">@_</span>;
    $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>} <span class="op">=</span> {} <span class="wo">unless</span> <span class="wo">exists</span> $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>};
    <span class="kw">my</span> $pkgs <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>};
    <span class="kw">my</span> $pkglink;
<span id='src1026' class='foldfill'>Folded lines 1026 to 1030</span>
    <span class="kw">my</span> $curpkg <span class="op">=</span> <span class="sg">'main'</span>;
    $pkgs<span class="op">-&gt;</span>{<span class="wo">main</span>} <span class="op">=</span> {
        <span class="wo">URL</span> <span class="op">=&gt;</span> $outfile<span class="op">,</span>
        <span class="wo">Methods</span> <span class="op">=&gt;</span> {}
    }
        <span class="wo">if</span> $script;
 
    <span class="wo">while</span> (<span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/\G.*?(&lt;span class=['&quot;]kw['&quot;]&gt;)\s*(package|sub)\s*&lt;\/span&gt;\s*(&lt;span class=['&quot;][^'&quot;]+['&quot;]&gt;\s*)?([\w:]+)/gcs</span>) {
<span class="ct"># &quot; to keep Textpad formatting happy</span>
        <span class="kw">my</span> $pkg <span class="op">=</span> <span class="mg">$4</span>;
        <span class="kw">my</span> $next <span class="op">=</span> <span class="wo">pos</span>(<span class="cs">$</span>$html);
        <span class="kw">my</span> $insert <span class="op">=</span> <span class="mg">$-</span>[<span class="nm">1</span>];
        <span class="wo">if</span> (<span class="mg">$2</span> <span class="op">eq</span> <span class="sg">'package'</span>) {
            $curpkg <span class="op">=</span> $pkg;
            <span class="wo">next</span> <span class="wo">if</span> <span class="wo">exists</span> $pkgs<span class="op">-&gt;</span>{$pkg} <span class="op">&amp;&amp;</span> $pkgs<span class="op">-&gt;</span>{$pkg}{<span class="wo">URL</span>};   <span class="ct"># only use 1st definition of package</span>
            $pkglink <span class="op">=</span> $pkg;
            $pkgs<span class="op">-&gt;</span>{$pkg} <span class="op">=</span> {
                <span class="wo">URL</span> <span class="op">=&gt;</span> <span class="db">&quot;$outfile#$pkg&quot;</span><span class="op">,</span>
                <span class="wo">Methods</span> <span class="op">=&gt;</span> {}
            };
        }
        <span class="wo">else</span> {
            <span class="wo">if</span> ($pkg<span class="op">=~</span><span class="mt">/^(.+)::(\w+)$/</span>) {
<span class="ct">#</span>
<span class="ct">#   fully qualified name, check if we have a pkg entry for it
#</span>
                $pkgs<span class="op">-&gt;</span>{<span class="mg">$1</span>} <span class="op">=</span> {
                    <span class="wo">URL</span> <span class="op">=&gt;</span> <span class="sg">''</span><span class="op">,</span>
                    <span class="wo">Methods</span> <span class="op">=&gt;</span> {}
                }
                    <span class="wo">unless</span> <span class="wo">exists</span> $pkgs<span class="op">-&gt;</span>{<span class="mg">$1</span>};
                $pkgs<span class="op">-&gt;</span>{<span class="mg">$1</span>}{<span class="wo">Methods</span>}{<span class="mg">$2</span>} <span class="op">=</span> <span class="db">&quot;$outfile#$pkg&quot;</span>;
                $pkglink <span class="op">=</span> $pkg;
            }
            <span class="wo">else</span> {
                $pkglink <span class="op">=</span> ($curpkg <span class="op">eq</span> <span class="sg">'main'</span>) <span class="op">?</span> $pkg <span class="op">:</span> <span class="db">&quot;$curpkg\:\:$pkg&quot;</span>;
                $pkgs<span class="op">-&gt;</span>{$curpkg}{<span class="wo">Methods</span>}{$pkg} <span class="op">=</span> <span class="db">&quot;$outfile#$pkglink&quot;</span>;
            }
        }
        $pkglink <span class="op">=</span> <span class="db">&quot;&lt;a name='$pkglink'&gt;&lt;/a&gt;&quot;</span>;
        <span class="wo">substr</span>(<span class="cs">$</span>$html<span class="op">,</span> $insert<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> $pkglink);
        $next <span class="op">+=</span> <span class="wo">length</span>($pkglink);
        <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $next;
    }
    $pkgs<span class="op">-&gt;</span>{$script} <span class="op">=</span> <span class="wo">delete</span> $pkgs<span class="op">-&gt;</span>{<span class="wo">main</span>}
        <span class="wo">if</span> $script;
    <span class="kw">return</span> $html;
}
 
<a name='PPI::HTML::CodeFolder::_extractFolds'></a><span class="kw">sub</span> <span class="wo">_extractFolds</span> {
    <span class="kw">my</span> ($html<span class="op">,</span> $startpos<span class="op">,</span> $lnmap<span class="op">,</span> $opts) <span class="op">=</span> <span class="mg">@_</span>;
<span class="ct">#</span>
<span class="ct">#   scan for foldables
#</span>
    <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $startpos;
    <span class="kw">my</span> %folded <span class="op">=</span> (
        <span class="wo">Whitespace</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">Comments</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">POD</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">Heredocs</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">Imports</span> <span class="op">=&gt;</span> []<span class="op">,</span>
    );
    <span class="kw">my</span> $whitespace <span class="op">=</span> [];
<span id='src1094' class='foldfill'>Folded lines 1094 to 1105</span>
    <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $startpos;
    <span class="wo">foreach</span> (qw(Whitespace Comments POD Heredocs Imports)) {
        <span class="wo">next</span> <span class="wo">unless</span> (<span class="mg">$_</span> <span class="op">eq</span> <span class="sg">'Whitespace'</span>) <span class="op">||</span> $opts<span class="op">-&gt;</span>{<span class="mg">$_</span>};
<span class="ct">#</span>
<span class="ct">#   capture anything at the very beginning
#</span>
        <span class="kw">my</span> $fre <span class="op">=</span> $foldres{<span class="mg">$_</span>}[<span class="nm">0</span>];
        <span class="wo">push</span> <span class="cs">@</span>{$folded{<span class="mg">$_</span>}}<span class="op">,</span> [ <span class="mg">$-</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="mg">$+</span>[<span class="nm">1</span>] <span class="op">-</span> <span class="nm">1</span> ]
            <span class="wo">if</span> (<span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/$fre/gcs</span>);
    
        $fre <span class="op">=</span> $foldres{<span class="mg">$_</span>}[<span class="nm">1</span>];
        <span class="wo">push</span> <span class="cs">@</span>{$folded{<span class="mg">$_</span>}}<span class="op">,</span> [ <span class="mg">$-</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="mg">$+</span>[<span class="nm">1</span>] <span class="op">-</span> <span class="nm">1</span> ]
            <span class="wo">while</span> (<span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/$fre/gcs</span>);
        <span class="wo">_mergeSection</span>(<span class="wo">_cvtToLines</span>($folded{<span class="mg">$_</span>}<span class="op">,</span> $lnmap))
            <span class="wo">if</span> <span class="wo">scalar</span> <span class="cs">@</span>{$folded{<span class="mg">$_</span>}};
        <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $startpos;
    }
<span class="ct">#</span>
<span class="ct">#   now merge different sections
#</span>
    <span class="kw">my</span> $last <span class="op">=</span> <span class="sg">'Whitespace'</span>;
    <span class="wo">foreach</span> (qw(Imports POD Heredocs Comments)) {
        <span class="wo">_mergeSections</span>($folded{<span class="mg">$_</span>}<span class="op">,</span> $folded{$last});
        $last <span class="op">=</span> <span class="mg">$_</span>;
    }
    <span class="kw">return</span> <span class="cs">@</span>{$folded{$last}};
}
 
<a name='PPI::HTML::CodeFolder::_cvtToLines'></a><span class="kw">sub</span> <span class="wo">_cvtToLines</span> {
    <span class="kw">my</span> ($pos<span class="op">,</span> $lnmap) <span class="op">=</span> <span class="mg">@_</span>;
    
    <span class="kw">my</span> $ln <span class="op">=</span> <span class="nm">1</span>;
    <span class="wo">foreach</span> (<span class="cs">@</span>$pos) {
        $ln<span class="op">++</span> <span class="wo">while</span> ($ln <span class="op">&lt;=</span> <span class="cs">$#</span>$lnmap) <span class="op">&amp;&amp;</span> ($lnmap<span class="op">-&gt;</span>[$ln] <span class="op">&lt;=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]);
        <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>] <span class="op">=</span> $ln <span class="op">-</span> <span class="nm">1</span>;
        $ln<span class="op">++</span> <span class="wo">while</span> ($ln <span class="op">&lt;=</span> <span class="cs">$#</span>$lnmap) <span class="op">&amp;&amp;</span> ($lnmap<span class="op">-&gt;</span>[$ln] <span class="op">&lt;=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]);
        <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">=</span> $ln <span class="op">-</span> <span class="nm">1</span>;
    }
    <span class="kw">return</span> $pos;
}
 
<a name='PPI::HTML::CodeFolder::_mergeSection'></a><span class="kw">sub</span> <span class="wo">_mergeSection</span> {
    <span class="kw">my</span> $sect <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> @temp <span class="op">=</span> <span class="co">shift</span> <span class="cs">@</span>$sect;
    <span class="wo">foreach</span> (<span class="cs">@</span>$sect) {
        <span class="wo">push</span>(@temp<span class="op">,</span> <span class="mg">$_</span>)<span class="op">,</span>
        <span class="wo">next</span>
            <span class="wo">unless</span> ($temp[<span class="nm">-1</span>][<span class="nm">1</span>] <span class="op">+</span> <span class="nm">1</span> <span class="op">&gt;=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]);
<span class="ct">#</span>
<span class="ct">#   if current surrounds new, the discard new
#</span>
        $temp[<span class="nm">-1</span>][<span class="nm">1</span>] <span class="op">=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]
            <span class="wo">if</span> ($temp[<span class="nm">-1</span>][<span class="nm">1</span>] <span class="op">&lt;</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]);
    }
    <span class="cs">@</span>$sect <span class="op">=</span> @temp;
    <span class="nm">1</span>;
}
 
<a name='PPI::HTML::CodeFolder::_mergeSections'></a><span class="kw">sub</span> <span class="wo">_mergeSections</span> {
    <span class="kw">my</span> ($first<span class="op">,</span> $second) <span class="op">=</span> <span class="mg">@_</span>;
    
    <span class="wo">if</span> (<span class="cs">$#</span>$first <span class="op">&lt;</span> <span class="nm">0</span>) {
        <span class="cs">@</span>$first <span class="op">=</span> <span class="cs">@</span>$second;
        <span class="kw">return</span> $first;
    }
 
    <span class="kw">my</span> @temp <span class="op">=</span> ();
    <span class="wo">push</span> @temp<span class="op">,</span> (($first<span class="op">-&gt;</span>[<span class="nm">0</span>][<span class="nm">0</span>] <span class="op">&lt;</span> $second<span class="op">-&gt;</span>[<span class="nm">0</span>][<span class="nm">0</span>]) <span class="op">?</span> <span class="co">shift</span> <span class="cs">@</span>$first <span class="op">:</span> <span class="co">shift</span> <span class="cs">@</span>$second)
        <span class="wo">while</span> (<span class="cs">@</span>$first <span class="op">&amp;&amp;</span> <span class="cs">@</span>$second);
 
    <span class="wo">push</span> @temp<span class="op">,</span> <span class="cs">@</span>$first <span class="wo">if</span> <span class="wo">scalar</span> <span class="cs">@</span>$first;
    <span class="wo">push</span> @temp<span class="op">,</span> <span class="cs">@</span>$second <span class="wo">if</span> <span class="wo">scalar</span> <span class="cs">@</span>$second;
    <span class="wo">_mergeSection</span>(<span class="cs">\</span>@temp);
    <span class="cs">@</span>$first <span class="op">=</span> @temp;
    <span class="nm">1</span>;
}
 
<a name='PPI::HTML::CodeFolder::_addLineNumTable'></a><span class="kw">sub</span> <span class="wo">_addLineNumTable</span> {
    <span class="kw">my</span> ($html<span class="op">,</span> $ftsorted<span class="op">,</span> $folddivs<span class="op">,</span> $expdivs<span class="op">,</span> $linecnt) <span class="op">=</span> <span class="mg">@_</span>;
 
    <span class="cs">$</span>$html<span class="op">=~</span><span class="su">s/&lt;pre&gt;/&lt;pre class='bodypre'&gt;/</span>;
    <span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/(&lt;body[^&gt;]+&gt;)/s</span>;
    <span class="kw">my</span> $insert <span class="op">=</span> <span class="mg">$+</span>[<span class="nm">0</span>];
<span class="ct">#</span>
<span class="ct">#   generate JS declaration of fold sections
#</span>
    <span class="kw">my</span> $startfolds <span class="op">=</span> <span class="wo">scalar</span> <span class="cs">@</span>$ftsorted <span class="op">?</span>
        <span class="sg">'['</span> <span class="op">.</span> <span class="wo">join</span>(<span class="sg">','</span><span class="op">,</span> <span class="cs">@</span>$ftsorted) <span class="op">.</span> <span class="db">&quot; ],\n[&quot;</span> <span class="op">.</span> <span class="wo">join</span>(<span class="sg">','</span><span class="op">,</span> <span class="wo">map</span> $folddivs<span class="op">-&gt;</span>{<span class="mg">$_</span>}[<span class="nm">0</span>]<span class="op">,</span> <span class="cs">@</span>$ftsorted) <span class="op">.</span> <span class="db">&quot; ]&quot;</span> <span class="op">:</span>
        <span class="db">&quot;[], []&quot;</span>;
 
    <span class="kw">my</span> $linenos <span class="op">=</span> <span class="cs">$</span>$expdivs <span class="op">.</span> <span class="db">&quot;
&lt;table border=0 width='100\%' cellpadding=0 cellspacing=0&gt;
&lt;tr&gt;
    &lt;td width=40 bgcolor='#E9E9E9' align=right valign=top&gt;
    &lt;pre id='lnnomargin' class='lnpre'&gt;
    &lt;/pre&gt;
&lt;/td&gt;
&lt;td width=8 bgcolor='#E9E9E9' align=right valign=top&gt;
&lt;pre id='btnmargin' class='lnpre'&gt;
&lt;/pre&gt;
&lt;/td&gt;
&lt;td bgcolor='white' align=left valign=top&gt;
&quot;</span>;
    <span class="wo">substr</span>(<span class="cs">$</span>$html<span class="op">,</span> $insert<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> $linenos);
    <span class="wo">substr</span>(<span class="cs">$</span>$html<span class="op">,</span> <span class="wo">index</span>(<span class="cs">$</span>$html<span class="op">,</span> <span class="sg">'&lt;/body&gt;'</span>)<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="db">&quot;
&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;
 
&lt;script type='text/javascript'&gt;
&lt;!--
 
var ppihtml = new ppiHtmlCF($startfolds);
ppihtml.renderMargins($linecnt);
/*
 *  all rendered, now selectively open from any existing cookie
 */
ppihtml.openFromCookie();
 
--&gt;
&lt;/script&gt;
&quot;</span>
    );
    <span class="kw">return</span> <span class="nm">1</span>;
}
 
<a name='PPI::HTML::CodeFolder::_addFoldDivs'></a><span class="kw">sub</span> <span class="wo">_addFoldDivs</span> {
    <span class="kw">my</span> ($folddivs<span class="op">,</span> $ftsorted) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="wo">foreach</span> <span class="wo">my</span> $ft (<span class="wo">values</span> <span class="cs">%</span>$folddivs) {
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s/&lt;br&gt;/\n/gs</span>;
<span class="ct">#</span>
<span class="ct">#   squeeze out leading whitespace, but keep aligned
#</span>
        <span class="kw">my</span> $shortws <span class="op">=</span> <span class="nm">1000000</span>;
        <span class="kw">my</span> @lns <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\n/</span><span class="op">,</span> $ft<span class="op">-&gt;</span>[<span class="nm">1</span>];
<span class="ct">#</span>
<span class="ct">#   expand tabs as needed (we use 4 space tabs)
#</span>
        <span class="wo">foreach</span> (@lns) {
            <span class="wo">next</span> <span class="wo">if</span> <span class="su">s/^\s*$//</span>;
            $shortws <span class="op">=</span> <span class="nm">0</span><span class="op">,</span> <span class="wo">last</span>
                <span class="wo">unless</span> <span class="mt">/^(\s+)/</span>;
            $shortws <span class="op">=</span> <span class="wo">length</span>(<span class="mg">$1</span>)
                <span class="wo">if</span> ($shortws <span class="op">&gt;</span> <span class="wo">length</span>(<span class="mg">$1</span>))
        }
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">=</span> <span class="wo">join</span>(<span class="db">&quot;\n&quot;</span><span class="op">,</span> <span class="wo">map</span> { <span class="mg">$_</span> <span class="op">?</span> <span class="wo">substr</span>(<span class="mg">$_</span><span class="op">,</span> $shortws) <span class="op">:</span> <span class="sg">''</span>; } @lns)
            <span class="wo">if</span> $shortws;
<span class="ct">#</span>
<span class="ct">#   move whitespace inside any leading/trailing spans
#</span>
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!(&lt;/span&gt;)(\s+)$!$2$1!s</span>;
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!^(\s+)(&lt;span [^&gt;]+&gt;)!$2$1!s</span>;
<span class="ct">#</span>
<span class="ct">#   if ends on span, make sure its not creating newline
#</span>
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!\n&lt;/span&gt;$! &lt;/span&gt;!s</span>;
<span class="ct">#</span>
<span class="ct">#   likewise if it doesn't end on a span
#</span>
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!\n$!!s</span>;
    }
    <span class="kw">return</span> <span class="wo">join</span>(<span class="sg">''</span><span class="op">,</span> <span class="wo">map</span> <span class="db">&quot;\n&lt;div id='ft$_' class='folddiv'&gt;&lt;pre id='preft$_'&gt;$folddivs-&gt;{$_}[1]&lt;/pre&gt;&lt;/div&gt;&quot;</span><span class="op">,</span> <span class="cs">@</span>$ftsorted);
}
 
<a name='PPI::HTML::CodeFolder::_pathAdjust'></a><span class="kw">sub</span> <span class="wo">_pathAdjust</span> {
    <span class="kw">my</span> ($path<span class="op">,</span> $jspath) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="kw">return</span> $jspath
        <span class="wo">unless</span> (<span class="wo">substr</span>($jspath<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="nm">2</span>) <span class="op">eq</span> <span class="sg">'./'</span>) <span class="op">&amp;&amp;</span> (<span class="wo">substr</span>($path<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="nm">2</span>) <span class="op">eq</span> <span class="sg">'./'</span>);
<span class="ct">#</span>
<span class="ct">#   relative path, adjust as needed from current base
#</span>
    <span class="kw">my</span> @parts <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\//</span><span class="op">,</span> $path;
    <span class="kw">my</span> @jsparts <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\//</span><span class="op">,</span> $jspath;
    <span class="kw">my</span> $jsfile <span class="op">=</span> <span class="wo">pop</span> @jsparts;  <span class="ct"># get rid of filename</span>
    <span class="wo">pop</span> @parts;     <span class="ct"># remove filename</span>
    <span class="co">shift</span> @parts;
    <span class="co">shift</span> @jsparts; <span class="ct"># and the relative lead</span>
    <span class="kw">my</span> $prefix <span class="op">=</span> <span class="sg">''</span>;
    <span class="co">shift</span> @parts<span class="op">,</span> 
    <span class="co">shift</span> @jsparts
        <span class="wo">while</span> @parts <span class="op">&amp;&amp;</span> @jsparts <span class="op">&amp;&amp;</span> ($parts[<span class="nm">0</span>] <span class="op">eq</span> $jsparts[<span class="nm">0</span>]);
    <span class="wo">push</span> @jsparts<span class="op">,</span> $jsfile;
    <span class="kw">return</span> (<span class="sg">'../'</span> <span class="op">x</span> <span class="wo">scalar</span> @parts) <span class="op">.</span> <span class="wo">join</span>(<span class="sg">'/'</span><span class="op">,</span> @jsparts)
}
 
<span class="nm">1</span>;
</pre>
</td></tr></table>
 
<script type='text/javascript'>
<!--
 
var ppihtml = new ppiHtmlCF([1,29,113,118,185,452,500,545,559,581,602,620,636,651,692,703,745,751,757,784,802,829,847,855,869,899,961,989,1026,1094 ],
[27,35,116,179,450,494,503,557,572,593,615,625,639,680,695,706,749,755,761,788,807,833,850,867,887,915,978,999,1030,1105 ]);
ppihtml.renderMargins(1290);
/*
 *	all rendered, now selectively open from any existing cookie
 */
ppihtml.openFromCookie();
 
-->
</script>
</body>
</html>
EOHTML

chomp $expected;

cmp_ok($content, 'eq', $expected, 'Valid output w/ embedded JS/CSS');
saveIt('t/src/PPI/HTML/CodeFolder.pm.html', $content);

#
#	verify output wo/ embedded JS/CSS
#
$HTML = PPI::HTML::CodeFolder->new(
    line_numbers => 1,
    page         => 1,
    colors       => \%tagcolors,
    verbose      => undef,
    fold          => {
    	Abbreviate    => 1,
        POD           => $pod,
        Comments      => $comments,
        Expandable    => $expand,
        Heredocs      => $heredocs,
        Imports       => $imports,
        MinFoldLines  => $minlines,
        Javascript    => 'myjsfile.js',
        Stylesheet    => 'mystype.css',
        },
    );
ok($HTML, 'Constructor wo/ embedded JS/CSS');

# Process the file
$content = $HTML->html( $Document, 'PPI/HTML/CodeFolder.pm.html' );
saveIt('PPICFmin.html', $content);

my $minhtml = <<'EOMINHTML';
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN">
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
  <meta name="robots" content="noarchive">
<link type='text/css' rel='stylesheet' href='mystype.css' />
<script type='text/javascript' src='myjsfile.js'></script>
 
</head>
<body bgcolor="#FFFFFF" text="#000000">
<div id='ft1' class='folddiv'><pre id='preft1'><span class="pd">=pod
 
=begin classdoc
 
 Subclasses &lt;cpan&gt;PPI::HTML&lt;/cpan&gt; to add code folding for POD,
 comments, and 'use'/'require' statements. Optionally permits abbreviation
 of standard PPI::HTML class/token names with user specified
 replacements. For line number output, moves the line numbers
 from individual &amp;lt;span&amp;gt;'s to a single table column,
 with the source body in the 2nd column.
 &lt;p&gt;
 Copyright&amp;copy; 2007, Presicient Corp., USA
 All rights reserved.
 &lt;p&gt;
 Permission is granted to use this software under the terms of the
 &lt;a href='http://perldoc.perl.org/perlartistic.html'&gt;Perl Artisitic License&lt;/a&gt;.
 
 @author D. Arnold
 @since 2007-01-22
 @self    $self
 

=end classdoc
 
=cut
 
 </span></pre></div>
<div id='ft29' class='folddiv'><pre id='preft29'><span class="kw">
use</span> <span class="wo">PPI::HTML</span>;
<span class="kw">use</span> <span class="pg">base</span> (<span class="sg">'PPI::HTML'</span>);
 
<span class="kw">use</span> <span class="pg">strict</span>;
<span class="kw">use</span> <span class="pg">warnings</span>;
</pre></div>
<div id='ft113' class='folddiv'><pre id='preft113'><span class="ct">
#</span>
<span class="ct">#    folddiv CSS
# </span></pre></div>
<div id='ft118' class='folddiv'><pre id='preft118'><span class="hc">
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
    overflow : hidden;  // to keep FF on OS X happy
}
 
.folddiv {
    position: absolute;
    visibility: hidden;
    overflow : hidden;  // to keep FF on OS X happy
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
 
--&gt;
&lt;/style&gt; </span></pre></div>
<div id='ft185' class='folddiv'><pre id='preft185'><span class="hc">
function ppiHtmlCF(startlines, endlines) 
{
    this.startlines = startlines;
    this.endlines = endlines;
    this.foldstate = [];
    for (var i = 0; i &lt; startlines.length; i++)
        this.foldstate[startlines[i]] = &quot;closed&quot;;
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
    for (var n = 0; n &lt; this.startlines.length; n++) {
        line = this.startlines[n];
        if ((this.foldstate[line] != null) &amp;&amp; (this.foldstate[line] == &quot;open&quot;))
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
     *  no cookie, create one w/ all folds closed
     */
        this.setCookie('');
    }
    else {
        for (var n = 0; n &lt; this.startlines.length; n++) {
            line = this.startlines[n];
            if (this.foldstate[line] == null) 
                this.foldstate[line] = &quot;closed&quot;;
 
            if (opened.indexOf(':' + line + ':') &gt;= 0) {
                if (this.foldstate[line] == &quot;closed&quot;)
                    this.accordian(line, this.endlines[n]);
            }
            else {
                if (this.foldstate[line] == &quot;open&quot;)
                    this.accordian(line, this.endlines[n]);
            }
        }
    }
};
 
/*
 *  renders line number and fold button margins
 */
ppiHtmlCF.prototype.renderMargins = function(lastline)
{
    var start = 1;
    var lnmargin = '';
    var btnmargin = '';
    for (var i = 0; i &lt; this.startlines.length; i++) {
        if (start != this.startlines[i]) {
            for (var j = start; j &lt; this.startlines[i]; j++) {
                lnmargin += j + &quot;\n&quot;;
                btnmargin += &quot;\n&quot;;
            }
        }
        start = this.endlines[i] + 1;
        lnmargin += &quot;&lt;span id='lm&quot; + this.startlines[i] + &quot;' class='lnpre'&gt;&quot; + this.startlines[i] + &quot;&lt;/span&gt;\n&quot;;
        btnmargin += &quot;&lt;a id='ll&quot; + this.startlines[i] + &quot;' class='foldbtn' &quot; + 
            &quot;onclick=\&quot;ppihtml.accordian(&quot; + this.startlines[i] + &quot;,&quot; + this.endlines[i] + &quot;)\&quot;&gt;&amp;oplus;&lt;/a&gt;\n&quot;;
    }
    if (lastline &gt; this.endlines[this.endlines.length - 1]) {
        for (var j = start; j &lt;= lastline; j++) {
            lnmargin += j + &quot;\n&quot;;
            btnmargin += &quot;\n&quot;;
        }
    }
    lnmargin += &quot;\n&quot;;
    btnmargin += &quot;\n&quot;;
    buttons = document.getElementById(&quot;btnmargin&quot;);
    lnno = document.getElementById(&quot;lnnomargin&quot;);
    if (navigator.appVersion.indexOf(&quot;MSIE&quot;)!=-1) {
        lnno.outerHTML = &quot;&lt;pre id='lnnomargin' class='lnpre'&gt;&quot; + lnmargin + &quot;&lt;/pre&gt;&quot;;
        buttons.outerHTML = &quot;&lt;pre id='btnmargin' class='lnpre'&gt;&quot; + btnmargin + &quot;&lt;/pre&gt;&quot;;
    }
    else {
        lnno.innerHTML = lnmargin;
        buttons.innerHTML = btnmargin;
    }
}
 
/*
 *  Accordian function for folded code
 *
 *  if clicked fold is closed
 *      replace contents of specified lineno margin span
 *          with complete lineno list
 *      replace contents of specified link span with end - start + 1 oplus's + linebreaks
 *      replace contents of insert span with contents of src_div
 *      foldstate = open
 *  else
 *      replace contents of specified lineno margin span with start lineno
 *      replace contents of specified link span with single oplus
 *      replace contents of specified insert span with &quot;Folded lines start to end&quot;
 *      foldstate = closed
 *
 *  For fancier effect, use delay to add/remove a single line at a time, with
 *  delay millsecs between updates
 */
ppiHtmlCF.prototype.accordian = function(startline, endline)
{
    if (document.getElementById) {
        if (navigator.appVersion.indexOf(&quot;MSIE&quot;)!=-1) {
            this.ie_accordian(startline, endline);
        }
        else {
            this.ff_accordian(startline, endline);
        }
    }
}
/*
 *  MSIE is a pile of sh*t, so we have to bend over
 *  backwards and completely rebuild the document elements
 *  Bright bunch of folks up there in Redmond...BTW this bug
 *  exists in IE 4 thru 7, despite people screaming for a solution
 *  for a decade. So MSFT is deaf as well as dumb
 */
ppiHtmlCF.prototype.ie_accordian = function(startline, endline)
{
    src = document.getElementById(&quot;preft&quot; + startline);
    foldbtn = document.getElementById('btnmargin');
    lineno = document.getElementById('lnnomargin');
    insert = document.getElementById(&quot;src&quot; + startline);
    linenos = lineno.innerHTML;
    buttons = foldbtn.innerHTML;
    if ((this.foldstate[startline] == null) || (this.foldstate[startline] == &quot;closed&quot;)) {
        lnr = &quot;&lt;span[^&gt;]+&gt;&quot; + startline + &quot;[\r\n]*&lt;/span&gt;&quot;;
        lnre = new RegExp(lnr, &quot;i&quot;);
        bnr = &quot;id=ll&quot; + startline + &quot;[^&lt;]+&lt;/a&gt;&quot;;
        btnre = new RegExp(bnr, &quot;i&quot;);
 
        lnfill = startline + &quot;\n&quot;;
        btnfill = &quot;&amp;oplus;\n&quot;;
        for (i = startline + 1; i &lt;= endline; i++) {
            lnfill += i + &quot;\n&quot;;
            btnfill += &quot;&amp;oplus;\n&quot;;
        }
 
        linenos = linenos.replace(lnre, &quot;&lt;span id='lm&quot; + startline + &quot;' class='lnpre'&gt;&quot; + lnfill + &quot;&lt;/span&gt;&quot;);
        buttons = buttons.replace(btnre, &quot;id='ll&quot; + startline + &quot;' class='foldbtn' style='background-color: yellow' onclick=\&quot;ppihtml.accordian(&quot; + 
            startline + &quot;, &quot; + endline + &quot;)\&quot;&gt;&quot; + btnfill + &quot;&lt;/a&gt;&quot;);
 
        foldbtn.outerHTML = &quot;&lt;pre id='btnmargin' class='lnpre'&gt;&quot; + buttons + &quot;&lt;/pre&gt;&quot;;
        lineno.outerHTML = &quot;&lt;pre id='lnnomargin' class='lnpre'&gt;&quot; + linenos + &quot;&lt;/pre&gt;&quot;;
        insert.outerHTML = &quot;&lt;span id='src&quot; + startline + &quot;'&gt;&lt;pre class='bodypre'&gt;&quot; + src.innerHTML + &quot;&lt;/pre&gt;&lt;/span&gt;&quot;;
        this.foldstate[startline] = &quot;open&quot;;
    }
    else {
        lnr = &quot;&lt;span[^&gt;]+&gt;&quot; + startline + &quot;[\r\n][^&lt;]*&lt;/span&gt;&quot;;
        lnre = new RegExp(lnr, &quot;i&quot;);
        bnr = &quot;id=ll&quot; + startline + &quot;[^&lt;]+&lt;/a&gt;&quot;;
        btnre = new RegExp(bnr, &quot;i&quot;);
 
        if (! linenos.match(lnre))
            alert(&quot;linenos no match&quot;);
        if (! buttons.match(btnre))
            alert(&quot;buttons no match&quot;);
        linenos = linenos.replace(lnre, &quot;&lt;span id='lm&quot; + startline + &quot;' class='lnpre'&gt;&quot; + startline + &quot;\n&lt;/span&gt;&quot;);
        buttons = buttons.replace(btnre, &quot;id='ll&quot; + startline + &quot;' class='foldbtn' style='background-color: #E9E9E9' onclick=\&quot;ppihtml.accordian(&quot; +
            startline + &quot;, &quot; + endline + &quot;)\&quot;&gt;&amp;oplus;\n&lt;/a&gt;&quot;);
 
        foldbtn.outerHTML = &quot;&lt;pre id='btnmargin' class='lnpre'&gt;&quot; + buttons + &quot;&lt;/pre&gt;&quot;;
        lineno.outerHTML = &quot;&lt;pre id='lnnomargin' class='lnpre'&gt;&quot; + linenos + &quot;&lt;/pre&gt;&quot;;
        insert.outerHTML = &quot;&lt;span id='src&quot; + startline + &quot;'&gt;&lt;pre class='foldfill'&gt;Folded lines &quot; + startline + &quot; to &quot; + endline + &quot;&lt;/pre&gt;&lt;/span&gt;&quot;;
 
        this.foldstate[startline] = &quot;closed&quot;;
    }
    this.updateCookie();
}
 
ppiHtmlCF.prototype.ff_accordian = function(startline, endline)
{
    src = document.getElementById(&quot;preft&quot; + startline);
    foldbtn = document.getElementById(&quot;ll&quot; + startline);
    lineno = document.getElementById(&quot;lm&quot; + startline);
    insert = document.getElementById(&quot;src&quot; + startline);
    if ((this.foldstate[startline] == null) || (this.foldstate[startline] == &quot;closed&quot;)) {
        lnfill = startline + &quot;\n&quot;;
        btnfill = &quot;&amp;oplus;\n&quot;;
        for (i = startline + 1; i &lt;= endline; i++) {
            lnfill += (i &lt; endline) ? i + &quot;\n&quot; : i;
            btnfill += (i &lt; endline) ? &quot;&amp;oplus;\n&quot; : &quot;&amp;oplus;&quot;;
        }
        foldbtn.innerHTML = btnfill;
        lineno.innerHTML = lnfill;
        foldbtn.style.backgroundColor = &quot;yellow&quot;;
        insert.innerHTML = src.innerHTML;
        insert.className = &quot;bodypre&quot;;
        this.foldstate[startline] = &quot;open&quot;;
    }
    else {
        foldbtn.innerHTML = &quot;&amp;oplus;&quot;;
        foldbtn.style.backgroundColor = &quot;#E9E9E9&quot;;
        lineno.innerHTML = startline;
        insert.innerHTML = &quot;Folded lines &quot; + startline + &quot; to &quot; + endline;
        insert.className = &quot;foldfill&quot;;
        this.foldstate[startline] = &quot;closed&quot;;
    }
    this.updateCookie();
}
 
/*
 *  open/close all folds
 */
ppiHtmlCF.prototype.fold_all = function(foldstate)
{
    for (i = 0; i &lt; this.startlines.length; i++) {
        line = this.startlines[i];
        if (this.foldstate[line] == null) 
            this.foldstate[line] = &quot;closed&quot;;
 
        if (this.foldstate[line] != foldstate)
            this.accordian(line, this.endlines[i]);
    }
    this.updateCookie();
}
 
ppiHtmlCF.prototype.add_fold = function(startline, endline)
{
    this.startlines[this.startlines.length] = startline;
    this.endlines[this.endlines.length] = endline;
    this.foldstate[this.foldstate.length] = &quot;closed&quot;;
}
 </span></pre></div>
<div id='ft452' class='folddiv'><pre id='preft452'><span class="pd">
=pod
 
=begin classdoc
 
    Constructor. Uses PPI::HTML base constructor, then installs some
    additional members based on the &lt;code&gt;fold&lt;/code&gt; argument.
 
 @optional colors hashref of &lt;b&gt;original&lt;/b&gt; PPI::HTML classnames to color codes/names
 @optional css    a &lt;cpan&gt;CSS::Tiny&lt;/cpan&gt; object containg additional stylsheet properties
 @optional fold   hashref of code folding properties; if not specified, a default
                  set of properties is applied. Folding properties include:
 &lt;ul&gt;
 &lt;li&gt;Abbreviate - hashref mapping full classnames to smaller classnames; useful
        to provide further output compression; default uses predefined mapping
 &lt;li&gt;Comments - if true, fold comments; default true
 &lt;li&gt;Expandable - if true, provide links to unfold lines in place; default false
 &lt;li&gt;Imports  - if true, fold 'use' and 'require' statements; default false
 &lt;li&gt;Javascript  - name of file to reference for the fold expansion javascript in the output HTML;
    default none, resulting in Javascript embedded in output HTML.&lt;br&gt;
    Note that the Javascript may be retrieved separately via the &lt;code&gt;foldJavascript()&lt;/code&gt; method.
 &lt;li&gt;MinFoldLines - minimum number of consecutive foldable lines required before folding is applied;
            default is 4
 &lt;li&gt;POD - if true, fold POD line; default true
 &lt;li&gt;Stylesheet - name of file to reference for the CSS for abbreviated classnames and
            fold DIVs in the output HTML; default none,resulting in CSS embedded in output
            HTML.&lt;br&gt;
    Note that the CSS may be retrieved separately via the &lt;code&gt;foldCSS()&lt;/code&gt; method.
 &lt;li&gt;Tabs - size of tabs; default 4
 &lt;/ul&gt;
 
 @optional line_numbers if true, include line numbering in the output HTML
 @optional page   if true, wrap the output in a HTML &amp;lt;head&amp;gt; and &amp;lt;body&amp;gt;
       sections. &lt;b&gt;NOTE: CodeFolder forces this to true.
 @optional verbose   if true, spews various diagnostic info
 
 @return    a new PPI::HTML::CodeFolder object
 
=end classdoc
 
=cut
 
 </span></pre></div>
<div id='ft500' class='folddiv'><pre id='preft500'><span class="ct">#</span>
<span class="ct">#    remove line numbering option since it greatly simplifies the spanning
#    scan later; we'll apply it after we're done
# </span></pre></div>
<div id='ft545' class='folddiv'><pre id='preft545'><span class="pd">
=pod
 
=begin classdoc
 
    Returns the Javascript used for fold expansion.
 
 @return    Javascript for fold expansion, as a string
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft559' class='folddiv'><pre id='preft559'><span class="pd">
 
=pod
 
=begin classdoc
 
Write out the Javascript used for fold expansion.
 
@return    1 on success; undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft581' class='folddiv'><pre id='preft581'><span class="pd">
=pod
 
=begin classdoc
 
Write out the CSS used for the sources.
 
@return    1 on success; undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft602' class='folddiv'><pre id='preft602'><span class="pd">
=pod
 
=begin classdoc
 
    Returns the CSS used for the abbreviated classes and fold DIVs.
 
 @return    CSS as a string
 
=end classdoc
 
=cut
 
 </span></pre></div>
<div id='ft620' class='folddiv'><pre id='preft620'><span class="hc">&lt;style type=&quot;text/css&quot;&gt;
&lt;!--
body {
    font-family: fixed, Courier;
    font-size: 10pt;
} </span></pre></div>
<div id='ft636' class='folddiv'><pre id='preft636'><span class="ct">#</span>
<span class="ct">#   !!!fix for (yet another) Firefox bug: need a dummy class
#   at front of CSS or firefox ignores the first class...
# </span></pre></div>
<div id='ft651' class='folddiv'><pre id='preft651'><span class="pd">
=pod
 
=begin classdoc
 
    Generate folded HTML from source PPI document.
    Overrides base class &lt;code&gt;html()&lt;/code&gt; to apply codefolding support.
 
@param $src    a &lt;cpan&gt;PPI::Document&lt;/cpan&gt; object, OR the
                path to the source file, OR a scalarref of the
                actual source text.
@optional $outfile name of the output HTML file; If not specified for a filename $src, the
            default is &quot;$src.html&quot;; If not specified for either PPI::Document or text $src,
            defaults to an empty string.
@optional $script   a name used if source is a script file. Script files might not include
            any explicit packages or method declarations which would be mapped into the
            table of contents. By specifying this parameter, an entry is forced into the 
            table of contents for the script, with any &quot;main&quot; package methods within the
            script reassigned to this script name. If not specified, and &lt;code&gt;$src&lt;/code&gt;
            is not a filename, an error will be issued when the TOC is generated. 
 
 @return    on success, the folded HTML; undef on failure
 
 @returnlist    on success, the folded HTML and a hashref mapping packages to an arrayref of method names;
                undef on failure
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft692' class='folddiv'><pre id='preft692'><span class="ct">#</span>
<span class="ct">#   expand tabs as needed (we use 4 space tabs)
#   have to adjust some spans that confuse tab processing
# </span></pre></div>
<div id='ft703' class='folddiv'><pre id='preft703'><span class="ct">#</span>
<span class="ct">#   scan for and replace tabs; adjust positions
#   of extracted tags as needed
# </span></pre></div>
<div id='ft745' class='folddiv'><pre id='preft745'><span class="ct">#</span>
<span class="ct">#   split multiline comments into 2 spans: 1st line (in case its midline)
#   and the remainder; note that the prior substitution avoids
#   doing this to single line comments
# </span></pre></div>
<div id='ft751' class='folddiv'><pre id='preft751'><span class="ct">#</span>
<span class="ct"># keep folded fragments here for later insertion
# as fold DIVs; key is starting line number,
# value is [ number of lines, text ]
# </span></pre></div>
<div id='ft757' class='folddiv'><pre id='preft757'><span class="ct">#</span>
<span class="ct">#    count &lt;br&gt; tags, and looks for any of
#    comment, pod, or use/require keyword (depending on the options);
#    keeps track of start and end position of foldable segments
# </span></pre></div>
<div id='ft784' class='folddiv'><pre id='preft784'><span class="ct">#</span>
<span class="ct">#   trim small folds;
#   since its used frequently, create a sorted list of the fold DIV lines;
#   isolate positions of folds and extract folded content
# </span></pre></div>
<div id='ft802' class='folddiv'><pre id='preft802'><span class="ct">#</span>
<span class="ct">#    now remove the folded lines; we work from bottom to top since
#    we're changing the HTML as we go, which would invalidate the
#    positional elements we've kept. If fold expansion is enabled, we replace
#    w/ a hyperlink; otherwise we replace with a simple indication of the fold
# </span></pre></div>
<div id='ft829' class='folddiv'><pre id='preft829'><span class="ct">#</span>
<span class="ct">#    now create the line number table (if requested)
#    NOTE: this is where having the breakable lines would be really
#    useful!!!
# </span></pre></div>
<div id='ft847' class='folddiv'><pre id='preft847'><span class="ct">#</span>
<span class="ct">#   fix Firefox blank lines inside spans bug: add a single space to
#   all blank lines
# </span></pre></div>
<div id='ft855' class='folddiv'><pre id='preft855'><span class="pd">
=pod
 
=begin classdoc
 
Return current package/method cross reference.
 
@return    hashref of current package/method cross reference
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft869' class='folddiv'><pre id='preft869'><span class="pd">
=pod
 
=begin classdoc
 
Write out a table of contents document for the current collection of
sources as a nested HTML list. The output filename is 'toc.html'.
The caller may optionally specify the order of packages in the menu.
 
@param $path directory to write TOC file
@optional Order arrayref of packages in the order in which they should appear in TOC; if a partial list,
                    any remaining packages will be appended to the TOC in alphabetical order
 
@return this object on success, undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft899' class='folddiv'><pre id='preft899'><span class="pd">
=begin classdoc
 
Generate a table of contents document for the current collection of
sources as a nested HTML list. Caller may optionally specify
the order of packages in the menu.
 
@param $tocpath     path of output TOC file
@optional Order arrayref of packages in the order in which they should appear in TOC; if a partial list,
                    any remaining packages will be appended to the TOC in alphabetical order
 
@return the TOC document
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft961' class='folddiv'><pre id='preft961'><span class="pd">
=pod
 
=begin classdoc
 
Write out a frame container document to hold the rendered source and TOC.
The file is written to &quot;$path/index.html&quot;.
 
@param $path directory to write the document.
@param $title Title string for resulting document
@optional $home the &quot;home&quot; document initially loaded into the main frame; default none
 
@return this object on success, undef on failure, with error message in $@
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft989' class='folddiv'><pre id='preft989'><span class="pd">
=begin classdoc
 
Generate a frame container document to hold the rendered source and TOC.
 
@return the frame container document as a string
 
=end classdoc
 
=cut
 </span></pre></div>
<div id='ft1026' class='folddiv'><pre id='preft1026'><span class="ct">#</span>
<span class="ct">#   assume package &quot;main&quot; to start; on exit,
#   if we have a script name, then replace all &quot;main&quot;
#   entries with $script
# </span></pre></div>
<div id='ft1094' class='folddiv'><pre id='preft1094'><span class="ct">#</span>
<span class="ct">#   accumulate foldable sections, including leading/trailing whitespace
#
#   my $fre = $foldres{$_}[0];
#   push @{$folded{$_}}, [ $-[1], $+[1] - 1 ]
#       if ($$html=~/$fre/gcs);</span>
 
<span class="ct">#       push @{$folded{Whitespace}}, [ $-[1], $+[1] - 1 ]</span>
<span class="ct">#       while ($$html=~/\G.*?&lt;br&gt;((?:\s*&lt;br&gt;)+)/gcs);
#   _mergeSection(_cvtToLines($folded{Whitespace}, $lnmap))
#       if scalar @{$folded{Whitespace}};
 </span></pre></div>
<table border=0 width='100%' cellpadding=0 cellspacing=0>
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
<pre class='bodypre'><span id='src1' class='foldfill'>Folded lines 1 to 27</span>
<a name='PPI::HTML::CodeFolder'></a><span class="kw">package</span> <span class="wo">PPI::HTML::CodeFolder</span>;
<span id='src29' class='foldfill'>Folded lines 29 to 35</span>
<span class="kw">our</span> $VERSION <span class="op">=</span> <span class="sg">'1.01'</span>;
 
<span class="kw">our</span> %classabvs <span class="op">=</span> qw(
 
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
<span class="ct">#</span>
<span class="ct">#   fold section regular expressions
#</span>
<span class="kw">my</span> %foldres <span class="op">=</span> (
    <span class="wo">Whitespace</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)((?:\s*&lt;br&gt;)+)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;((?:\s*&lt;br&gt;)+)/
    ]<span class="op">,</span>
    <span class="wo">Comments</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*(&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*(&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/
    ]<span class="op">,</span>
    <span class="wo">POD</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*(&lt;span\s+class=['&quot;]pod['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*(&lt;span\s+class=['&quot;]pod['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/
    ]<span class="op">,</span>
    <span class="wo">Heredocs</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*(&lt;span\s+class=['&quot;]heredoc_content['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*(&lt;span\s+class=['&quot;]heredoc_content['&quot;]&gt;.+?&lt;\/span&gt;)(?=&lt;br&gt;)/
    ]<span class="op">,</span>
    <span class="wo">Imports</span> <span class="op">=&gt;</span> [
        qr/\G(?&lt;=&lt;pre&gt;)\s*
                (
                    (?:&lt;span\s+class=['&quot;]keyword['&quot;]&gt;(?:use|require)&lt;\/span&gt;.+?;\s*)+
                    (?:&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)?
                )
                (?=&lt;br&gt;)
                /x<span class="op">,</span>
        qr/\G.*?&lt;br&gt;\s*
                (
                    (?:&lt;span\s+class=['&quot;]keyword['&quot;]&gt;(?:use|require)&lt;\/span&gt;.+?;\s*)+
                    (?:&lt;span\s+class=['&quot;]comment['&quot;]&gt;.+?&lt;\/span&gt;)?
                )
                (?=&lt;br&gt;)
                /x
    ]<span class="op">,</span>
);
<span id='src113' class='foldfill'>Folded lines 113 to 116</span>
<span class="kw">our</span> $ftcss <span class="op">=</span> <span class="hd">&lt;&lt;'EOFTCSS'</span>;
<span id='src118' class='foldfill'>Folded lines 118 to 179</span>
<span class="ht">EOFTCSS</span>
<span class="ct">#</span>
<span class="ct">#    fold expansion javascript
#</span>
<span class="kw">our</span> $ftjs <span class="op">=</span> <span class="hd">&lt;&lt;'EOFTJS'</span>;
<span id='src185' class='foldfill'>Folded lines 185 to 450</span>
<span class="ht">EOFTJS</span>
<span id='src452' class='foldfill'>Folded lines 452 to 494</span>
<a name='PPI::HTML::CodeFolder::new'></a><span class="kw">sub</span> <span class="wo">new</span> {
    <span class="kw">my</span> ($class<span class="op">,</span> %args) <span class="op">=</span> <span class="mg">@_</span>;
 
    <span class="kw">my</span> $fold <span class="op">=</span> <span class="wo">delete</span> $args{<span class="wo">fold</span>};
    <span class="kw">my</span> $verb <span class="op">=</span> <span class="wo">delete</span> $args{<span class="wo">verbose</span>};
<span id='src500' class='foldfill'>Folded lines 500 to 503</span>
    <span class="kw">my</span> $needs_ln <span class="op">=</span> <span class="wo">delete</span> $args{<span class="wo">line_numbers</span>};
<span class="ct">#</span>
<span class="ct">#   force page wrapping
#</span>
    $args{<span class="wo">page</span>} <span class="op">=</span> <span class="nm">1</span>;
    <span class="kw">my</span> $self <span class="op">=</span> $class<span class="op">-&gt;</span><span class="wo">SUPER::new</span>(%args);
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> $self;
 
    $self<span class="op">-&gt;</span>{<span class="wo">_needs_ln</span>} <span class="op">=</span> $needs_ln;
    $self<span class="op">-&gt;</span>{<span class="wo">_verbose</span>} <span class="op">=</span> $verb;
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>} <span class="op">=</span> $fold <span class="op">?</span>
        { <span class="cs">%</span>$fold } <span class="op">:</span>
        {
        <span class="wo">Abbreviate</span>    <span class="op">=&gt;</span> <span class="cs">\</span>%classabvs<span class="op">,</span>
        <span class="wo">Comments</span>      <span class="op">=&gt;</span> <span class="nm">1</span><span class="op">,</span>
        <span class="wo">Heredocs</span>      <span class="op">=&gt;</span> <span class="nm">0</span><span class="op">,</span>
        <span class="wo">Imports</span>       <span class="op">=&gt;</span> <span class="nm">0</span><span class="op">,</span>
        <span class="wo">Javascript</span>    <span class="op">=&gt;</span> <span class="co">undef</span><span class="op">,</span>
        <span class="wo">Expandable</span>      <span class="op">=&gt;</span> <span class="nm">0</span><span class="op">,</span>
        <span class="wo">MinFoldLines</span>  <span class="op">=&gt;</span> <span class="nm">4</span><span class="op">,</span>
        <span class="wo">POD</span>           <span class="op">=&gt;</span> <span class="nm">1</span><span class="op">,</span>
        <span class="wo">Stylesheet</span>    <span class="op">=&gt;</span> <span class="co">undef</span><span class="op">,</span>
        <span class="wo">Tabs</span>          <span class="op">=&gt;</span> <span class="nm">4</span><span class="op">,</span>
        };
 
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>} <span class="op">=</span> <span class="cs">\</span>%classabvs
        <span class="wo">if</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>} <span class="op">&amp;&amp;</span> (<span class="op">!</span> (<span class="wo">ref</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>}));
 
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">MinFoldLines</span>} <span class="op">=</span> <span class="nm">4</span>
        <span class="wo">unless</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">MinFoldLines</span>};
 
    $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Tabs</span>} <span class="op">=</span> <span class="nm">4</span>
        <span class="wo">unless</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Tabs</span>};
<span class="ct">#</span>
<span class="ct">#   keep a running package/method cross reference
#</span>
    $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>} <span class="op">=</span> {};
 
    <span class="kw">return</span> $self;
}
<span id='src545' class='foldfill'>Folded lines 545 to 557</span>
<a name='PPI::HTML::CodeFolder::foldJavascript'></a><span class="kw">sub</span> <span class="wo">foldJavascript</span> { <span class="kw">return</span> $ftjs; }
<span id='src559' class='foldfill'>Folded lines 559 to 572</span>
<a name='PPI::HTML::CodeFolder::writeJavascript'></a><span class="kw">sub</span> <span class="wo">writeJavascript</span> { 
    <span class="mg">$@</span> <span class="op">=</span> <span class="mg">$!</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">open</span> <span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$_[1]&quot;</span>;
    <span class="wo">print</span> <span class="wo">OUTF</span> $ftjs;
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> <span class="nm">1</span>;
}
<span id='src581' class='foldfill'>Folded lines 581 to 593</span>
<a name='PPI::HTML::CodeFolder::writeCSS'></a><span class="kw">sub</span> <span class="wo">writeCSS</span> { 
    <span class="mg">$@</span> <span class="op">=</span> <span class="mg">$!</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">open</span> <span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$_[1]&quot;</span>;
    <span class="wo">print</span> <span class="wo">OUTF</span> <span class="mg">$_</span>[<span class="nm">0</span>]<span class="op">-&gt;</span><span class="wo">foldCSS</span>();
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> <span class="nm">1</span>;
}
<span id='src602' class='foldfill'>Folded lines 602 to 615</span>
<a name='PPI::HTML::CodeFolder::foldCSS'></a><span class="kw">sub</span> <span class="wo">foldCSS</span> {
    <span class="kw">my</span> $self <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> $orig_colors <span class="op">=</span> <span class="wo">exists</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>};
    <span class="kw">my</span> $css <span class="op">=</span> $self<span class="op">-&gt;</span><span class="wo">_css_html</span>() <span class="op">||</span> <span class="hd">&lt;&lt; 'EOCSS'</span>;
<span id='src620' class='foldfill'>Folded lines 620 to 625</span>
<span class="ht">EOCSS</span>
 
    <span class="kw">my</span> $ftc <span class="op">=</span> $ftcss;
    <span class="wo">if</span> ($self<span class="op">-&gt;</span>{<span class="wo">colors</span>}{<span class="wo">line_number</span>}) {
        <span class="kw">my</span> $lnc <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>}{<span class="wo">line_number</span>};
        $ftc<span class="op">=~</span><span class="su">s/(.lnpre\s+.+?color: )#888888;/$1$lnc;/gs</span>;
    }
 
    <span class="wo">delete</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>} <span class="wo">unless</span> $orig_colors;
    $css<span class="op">=~</span><span class="su">s|--&gt;\s*&lt;/style&gt;||s</span>;
<span id='src636' class='foldfill'>Folded lines 636 to 639</span>
    $css<span class="op">=~</span><span class="su">s/(&lt;!--.*?\n)/$1\n\n.dummy_class_for_firefox { color: white; }\n/</span>;
<span class="ct">#</span>
<span class="ct">#    replace classes w/ abbreviations
#</span>
    <span class="wo">if</span> ($self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>}) {
        <span class="kw">my</span> ($long<span class="op">,</span> $abv);
        $css<span class="op">=~</span><span class="su">s/\.$long \{/.$abv {/s</span>
            <span class="wo">while</span> (($long<span class="op">,</span> $abv) <span class="op">=</span> <span class="wo">each</span> <span class="cs">%</span>{$self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Abbreviate</span>}});
    }
    <span class="kw">return</span> $css <span class="op">.</span> $ftc;
}
<span id='src651' class='foldfill'>Folded lines 651 to 680</span>
<a name='PPI::HTML::CodeFolder::html'></a><span class="kw">sub</span> <span class="wo">html</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $src<span class="op">,</span> $outfile<span class="op">,</span> $script) <span class="op">=</span> <span class="mg">@_</span>;
 
    <span class="kw">my</span> $orig_colors <span class="op">=</span> <span class="wo">exists</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>};
    <span class="kw">my</span> $html <span class="op">=</span> $self<span class="op">-&gt;</span><span class="wo">SUPER::html</span>($src)
        <span class="op">or</span> <span class="kw">return</span> <span class="co">undef</span>;
 
    $outfile <span class="op">=</span> (<span class="wo">ref</span> $src) <span class="op">?</span> <span class="sg">''</span> <span class="op">:</span> <span class="db">&quot;$src.html&quot;</span>
        <span class="wo">unless</span> $outfile;
    $script <span class="op">||=</span> $src 
        <span class="wo">unless</span> <span class="wo">ref</span> $src <span class="op">||</span> (<span class="wo">substr</span>($src<span class="op">,</span> <span class="nm">-3</span>) <span class="op">eq</span> <span class="sg">'.pm'</span>);
<span id='src692' class='foldfill'>Folded lines 692 to 695</span>
    <span class="kw">my</span> @lns <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\n/</span><span class="op">,</span> $html;
    <span class="kw">my</span> $tabsz <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>}{<span class="wo">Tabs</span>};
    <span class="wo">foreach</span> <span class="wo">my</span> $line (@lns) {
        <span class="wo">next</span> <span class="wo">if</span> $line<span class="op">=~</span><span class="su">s/^\s*$//</span>;
        <span class="wo">next</span> <span class="wo">unless</span> $line<span class="op">=~</span><span class="tl">tr/\t//</span>;
        <span class="kw">my</span> $offs <span class="op">=</span> <span class="nm">0</span>;
        <span class="kw">my</span> $pad;
<span id='src703' class='foldfill'>Folded lines 703 to 706</span>
        <span class="wo">pos</span>($line) <span class="op">=</span> <span class="nm">0</span>;
        <span class="wo">while</span> ($line<span class="op">=~</span><span class="mt">/\G.*?((&lt;[^&gt;]+&gt;)|\t)/gc</span>) {
            $offs <span class="op">+=</span> <span class="wo">length</span>(<span class="mg">$2</span>)<span class="op">,</span>
            <span class="wo">next</span>
                <span class="wo">unless</span> (<span class="mg">$1</span> <span class="op">eq</span> <span class="db">&quot;\t&quot;</span>);
 
            $pad <span class="op">=</span> $tabsz <span class="op">-</span> (<span class="mg">$-</span>[<span class="nm">1</span>] <span class="op">-</span> $offs) <span class="op">%</span> $tabsz;
            <span class="wo">substr</span>($line<span class="op">,</span> <span class="mg">$-</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="nm">1</span><span class="op">,</span> <span class="sg">' '</span> <span class="op">x</span> $pad);
            <span class="wo">pos</span>($line) <span class="op">=</span> <span class="mg">$-</span>[<span class="nm">1</span>] <span class="op">+</span> $pad <span class="op">-</span> <span class="nm">1</span>;
        }
    }
    $html <span class="op">=</span> <span class="wo">join</span>(<span class="db">&quot;\n&quot;</span><span class="op">,</span> @lns);
 
    <span class="wo">delete</span> $self<span class="op">-&gt;</span>{<span class="wo">colors</span>} <span class="wo">unless</span> $orig_colors;
 
    <span class="kw">my</span> $opts <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">fold</span>};
<span class="ct">#</span>
<span class="ct">#    extract stylesheet and replace with abbreviated version
#</span>
    <span class="kw">my</span> $style <span class="op">=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Stylesheet</span>} <span class="op">?</span>
        <span class="db">&quot;&lt;link type='text/css' rel='stylesheet' href='&quot;</span> <span class="op">.</span> 
            <span class="wo">_pathAdjust</span>($outfile<span class="op">,</span> $opts<span class="op">-&gt;</span>{<span class="wo">Stylesheet</span>}) <span class="op">.</span> <span class="db">&quot;' /&gt;&quot;</span> <span class="op">:</span>
        $self<span class="op">-&gt;</span><span class="wo">foldCSS</span>();
 
    $style <span class="op">.=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Javascript</span>} <span class="op">?</span>
        <span class="db">&quot;\n&lt;script type='text/javascript' src='&quot;</span> <span class="op">.</span>
            <span class="wo">_pathAdjust</span>($outfile<span class="op">,</span> $opts<span class="op">-&gt;</span>{<span class="wo">Javascript</span>}) <span class="op">.</span> <span class="db">&quot;'&gt;&lt;/script&gt;\n&quot;</span> <span class="op">:</span>
        <span class="db">&quot;\n&lt;script type='text/javascript'&gt;\n$ftjs\n&lt;/script&gt;\n&quot;</span>
        <span class="wo">if</span> $opts<span class="op">-&gt;</span>{<span class="wo">Expandable</span>};
<span class="ct">#</span>
<span class="ct">#   original html may have no style, so we've got to add OR replace
#</span>
    $html<span class="op">=~</span><span class="su">s|&lt;/head&gt;|$style&lt;/head&gt;|s</span>
        <span class="wo">unless</span> ($html<span class="op">=~</span><span class="su">s|&lt;style type=&quot;text/css&quot;&gt;.+&lt;/style&gt;|$style|s</span>);
<span class="ct">#</span>
<span class="ct">#   force spans to end before line endings
#</span>
    $html<span class="op">=~</span><span class="su">s!(&lt;br&gt;\s*)&lt;/span&gt;!&lt;/span&gt;$1!g</span>;
<span id='src745' class='foldfill'>Folded lines 745 to 749</span>
    $html<span class="op">=~</span><span class="su">s/(?!&lt;br&gt;\s+)(&lt;span class=['&quot;]comment['&quot;]&gt;[^&lt;]+)&lt;br&gt;\n/$1&lt;\/span&gt;&lt;br&gt;\n&lt;span class=&quot;comment&quot;&gt;/g</span>;
<span id='src751' class='foldfill'>Folded lines 751 to 755</span>
    <span class="kw">my</span> %folddivs <span class="op">=</span> ( <span class="nm">1</span> <span class="op">=&gt;</span> [ <span class="nm">0</span><span class="op">,</span> <span class="sg">''</span><span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="nm">0</span> ]);
<span id='src757' class='foldfill'>Folded lines 757 to 761</span>
    <span class="kw">my</span> $lineno <span class="op">=</span> <span class="nm">1</span>;
    <span class="kw">my</span> $lastfold <span class="op">=</span> <span class="nm">1</span>;
 
    $html<span class="op">=~</span><span class="su">s/&lt;br&gt;\n/&lt;br&gt;/g</span>;
<span class="ct">#</span>
<span class="ct">#   now process remainder
#</span>
    <span class="wo">study</span> $html;
    <span class="wo">pos</span>($html) <span class="op">=</span> <span class="nm">0</span>;
    $html<span class="op">=~</span><span class="mt">/^.*?(&lt;body[^&gt;]+&gt;&lt;pre&gt;)/s</span>;
    <span class="kw">my</span> $startpos <span class="op">=</span> <span class="mg">$+</span>[<span class="nm">1</span>];
<span class="ct">#</span>
<span class="ct">#   map linebreak positions to line numbers
#</span>
    <span class="kw">my</span> @lnmap <span class="op">=</span> (<span class="nm">0</span><span class="op">,</span> $startpos);
    <span class="wo">push</span> @lnmap<span class="op">,</span> <span class="mg">$+</span>[<span class="nm">1</span>]
        <span class="wo">while</span> ($html<span class="op">=~</span><span class="mt">/\G.*?(&lt;br&gt;)/gcs</span>);
<span class="ct">#</span>
<span class="ct">#   now scan for foldables
#</span>
    <span class="wo">pos</span>($html) <span class="op">=</span> $startpos;
    <span class="kw">my</span> @folds <span class="op">=</span> <span class="wo">_extractFolds</span>(<span class="cs">\</span>$html<span class="op">,</span> $startpos<span class="op">,</span> <span class="cs">\</span>@lnmap<span class="op">,</span> $opts);
<span id='src784' class='foldfill'>Folded lines 784 to 788</span>
    <span class="kw">my</span> $ln <span class="op">=</span> <span class="nm">0</span>;
    <span class="kw">my</span> @ftsorted <span class="op">=</span> ();
    <span class="wo">foreach</span> (@folds) {
        <span class="wo">if</span> (<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">-</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>] <span class="op">+</span> <span class="nm">1</span> <span class="op">&gt;=</span> $opts<span class="op">-&gt;</span>{<span class="wo">MinFoldLines</span>}) {
            $folddivs{<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]} <span class="op">=</span> [ <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="wo">substr</span>($html<span class="op">,</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]]<span class="op">,</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">+</span> <span class="nm">1</span>] <span class="op">-</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]])<span class="op">,</span> 
                $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]]<span class="op">,</span> $lnmap[<span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">+</span> <span class="nm">1</span>] ];
            <span class="wo">push</span> @ftsorted<span class="op">,</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>];
        }
        <span class="wo">elsif</span> ($self<span class="op">-&gt;</span>{<span class="wo">_verbose</span>}) {
<span class="ct">#           print &quot;*** skipping section at line $_-&gt;[0]to $_-&gt;[1]\n&quot;;</span>
<span class="ct">#           print substr($html, $lnmap[$_-&gt;[0]], $lnmap[$_-&gt;[1] + 1] - $lnmap[$_-&gt;[0]]), &quot;\n&quot;;</span>
        }
    }
<span id='src802' class='foldfill'>Folded lines 802 to 807</span>
    <span class="wo">substr</span>($html<span class="op">,</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">2</span>]<span class="op">,</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">3</span>] <span class="op">-</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">2</span>]<span class="op">,</span>
        <span class="db">&quot;&lt;span id='src$_' class='foldfill'&gt;Folded lines $_ to &quot;</span> <span class="op">.</span> $folddivs{<span class="mg">$_</span>}[<span class="nm">0</span>] <span class="op">.</span> <span class="db">&quot;&lt;/span&gt;\n&quot;</span>)
        <span class="wo">foreach</span> (<span class="wo">reverse</span> @ftsorted);
<span class="ct">#</span>
<span class="ct">#    abbreviate the default span classes for both the html and fold divs
#</span>
    <span class="wo">pos</span>($html) <span class="op">=</span> <span class="nm">0</span>;
    <span class="kw">my</span> $abvs <span class="op">=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Abbreviate</span>};
    <span class="wo">if</span> ($abvs) {
        $html<span class="op">=~</span><span class="su">s/(&lt;span\s+class=['&quot;])([^'&quot;]+)(['&quot;])/$1 . ($$abvs{$2} || $2) . $3/egs</span>;
        <span class="wo">if</span> ($opts<span class="op">-&gt;</span>{<span class="wo">Expandable</span>}) {
            <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s/(&lt;span\s+class=['&quot;])([^'&quot;]+)(['&quot;])/$1 . ($$abvs{$2} || $2) . $3/egs</span>
                <span class="wo">foreach</span> (<span class="wo">values</span> %folddivs);
        }
    }
<span class="ct">#</span>
<span class="ct">#    create and insert fold DIVs if requested
#</span>
    <span class="kw">my</span> $expdivs <span class="op">=</span> $opts<span class="op">-&gt;</span>{<span class="wo">Expandable</span>} <span class="op">?</span> <span class="wo">_addFoldDivs</span>(<span class="cs">\</span>%folddivs<span class="op">,</span> <span class="cs">\</span>@ftsorted) <span class="op">:</span> <span class="sg">''</span>;
 
    $html<span class="op">=~</span><span class="su">s/&lt;br&gt;/\n/gs</span>;
<span id='src829' class='foldfill'>Folded lines 829 to 833</span>
    <span class="wo">_addLineNumTable</span>(<span class="cs">\</span>$html<span class="op">,</span> <span class="cs">\</span>@ftsorted<span class="op">,</span> <span class="cs">\</span>%folddivs<span class="op">,</span> <span class="cs">\</span>$expdivs<span class="op">,</span> $#lnmap)
        <span class="wo">if</span> $self<span class="op">-&gt;</span>{<span class="wo">_needs_ln</span>};
<span class="ct">#</span>
<span class="ct">#   extract a package/method reference list, and add anchors for them
#</span>
    $self<span class="op">-&gt;</span><span class="wo">_extractXRef</span>(<span class="cs">\</span>$html<span class="op">,</span> $outfile<span class="op">,</span> $script);
<span class="ct">#</span>
<span class="ct">#   report number of spans, for firefox performance report
#</span>
    <span class="wo">if</span> ($self<span class="op">-&gt;</span>{<span class="wo">_verbose</span>}) {
        <span class="kw">my</span> $spancnt <span class="op">=</span> $html<span class="op">=~</span><span class="su">s/&lt;\/span&gt;/&lt;\/span&gt;/gs</span>;
        <span class="wo">print</span> <span class="db">&quot;\n***Total spans: $spancnt\n&quot;</span>;
    }
<span id='src847' class='foldfill'>Folded lines 847 to 850</span>
    $html<span class="op">=~</span><span class="su">s!\n\n!\n \n!gs</span>;
 
    <span class="kw">return</span> $html;
}
<span id='src855' class='foldfill'>Folded lines 855 to 867</span>
<a name='PPI::HTML::CodeFolder::getCrossReference'></a><span class="kw">sub</span> <span class="wo">getCrossReference</span> { <span class="kw">return</span> <span class="mg">$_</span>[<span class="nm">0</span>]<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>}; }
<span id='src869' class='foldfill'>Folded lines 869 to 887</span>
<a name='PPI::HTML::CodeFolder::writeTOC'></a><span class="kw">sub</span> <span class="wo">writeTOC</span> {
    <span class="kw">my</span> $self <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> $path <span class="op">=</span> <span class="co">shift</span>;
    <span class="mg">$@</span> <span class="op">=</span> <span class="db">&quot;Can't open $path/toc.html: $!&quot;</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">CORE::open</span>(<span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$path/toc.html&quot;</span>);
 
    <span class="wo">print</span> <span class="wo">OUTF</span> $self<span class="op">-&gt;</span><span class="wo">getTOC</span>(<span class="db">&quot;$path/toc.html&quot;</span><span class="op">,</span> <span class="mg">@_</span>);
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> $self;
}
<span id='src899' class='foldfill'>Folded lines 899 to 915</span>
<a name='PPI::HTML::CodeFolder::getTOC'></a><span class="kw">sub</span> <span class="wo">getTOC</span> {
    <span class="kw">my</span> $self <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> $tocpath <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> %args <span class="op">=</span> <span class="mg">@_</span>;
    <span class="kw">my</span> @order <span class="op">=</span> $args{<span class="wo">Order</span>} <span class="op">?</span> <span class="cs">@</span>{$args{<span class="wo">Order</span>}} <span class="op">:</span> ();
    <span class="kw">my</span> $sources <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>};
    <span class="kw">my</span> $base;
    <span class="kw">my</span> $doc <span class="op">=</span>
<span class="db">&quot;&lt;html&gt;
&lt;body&gt;
&lt;small&gt;
&lt;!-- INDEX BEGIN --&gt;
&lt;ul&gt;
&quot;</span>;
    <span class="kw">my</span> %ordered <span class="op">=</span> ();
    $ordered{<span class="mg">$_</span>} <span class="op">=</span> <span class="nm">1</span> <span class="wo">foreach</span> (@order);
    <span class="wo">foreach</span> (<span class="wo">sort</span> <span class="wo">keys</span> <span class="cs">%</span>$sources) {
        <span class="wo">push</span> @order<span class="op">,</span> <span class="mg">$_</span> <span class="wo">unless</span> <span class="wo">exists</span> $ordered{<span class="mg">$_</span>};
    }
 
    <span class="wo">foreach</span> <span class="wo">my</span> $class (@order) {
<span class="ct">#</span>
<span class="ct">#   due to input @order, we might get classes that don't exist
#</span>
        <span class="wo">next</span> <span class="wo">unless</span> <span class="wo">exists</span> $sources<span class="op">-&gt;</span>{$class};
 
        $base <span class="op">=</span> <span class="wo">_pathAdjust</span>($tocpath<span class="op">,</span> $sources<span class="op">-&gt;</span>{$class}{<span class="wo">URL</span>});
        $doc <span class="op">.=</span>  <span class="db">&quot;&lt;li&gt;&lt;a href='$base' target='mainframe'&gt;$class&lt;/a&gt;
        &lt;ul&gt;\n&quot;</span>;
        <span class="kw">my</span> $info <span class="op">=</span> $sources<span class="op">-&gt;</span>{$class}{<span class="wo">Methods</span>};
        $doc <span class="op">.=</span>  <span class="db">&quot;&lt;li&gt;&lt;a href='&quot;</span> <span class="op">.</span> <span class="wo">_pathAdjust</span>($tocpath<span class="op">,</span> $info<span class="op">-&gt;</span>{<span class="mg">$_</span>}) <span class="op">.</span> <span class="db">&quot;' target='mainframe'&gt;$_&lt;/a&gt;&lt;/li&gt;\n&quot;</span>
            <span class="wo">foreach</span> (<span class="wo">sort</span> <span class="wo">keys</span> <span class="cs">%</span>$info);
        $doc <span class="op">.=</span>  <span class="db">&quot;&lt;/ul&gt;\n&lt;/li&gt;\n&quot;</span>;
    }
 
    $doc <span class="op">.=</span>  <span class="db">&quot;
&lt;/ul&gt;
&lt;!-- INDEX END --&gt;
&lt;/small&gt;
&lt;/body&gt;
&lt;/html&gt;
&quot;</span>;
 
    <span class="kw">return</span> $doc;
}
<span id='src961' class='foldfill'>Folded lines 961 to 978</span>
<a name='PPI::HTML::CodeFolder::writeFrameContainer'></a><span class="kw">sub</span> <span class="wo">writeFrameContainer</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $path<span class="op">,</span> $title<span class="op">,</span> $home) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="mg">$@</span> <span class="op">=</span> <span class="db">&quot;Can't open $path/index.html: $!&quot;</span><span class="op">,</span>
    <span class="kw">return</span> <span class="co">undef</span>
        <span class="wo">unless</span> <span class="wo">open</span>(<span class="wo">OUTF</span><span class="op">,</span> <span class="db">&quot;&gt;$path/index.html&quot;</span>);
 
    <span class="wo">print</span> <span class="wo">OUTF</span> $self<span class="op">-&gt;</span><span class="wo">getFrameContainer</span>($title<span class="op">,</span> $home);
    <span class="wo">close</span> <span class="wo">OUTF</span>;
    <span class="kw">return</span> $self;
}
<span id='src989' class='foldfill'>Folded lines 989 to 999</span>
<a name='PPI::HTML::CodeFolder::getFrameContainer'></a><span class="kw">sub</span> <span class="wo">getFrameContainer</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $title<span class="op">,</span> $home) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="kw">return</span> $home <span class="op">?</span>
<span class="db">&quot;&lt;html&gt;&lt;head&gt;&lt;title&gt;$title&lt;/title&gt;&lt;/head&gt;
&lt;frameset cols='15%,85%'&gt;
&lt;frame name='navbar' src='toc.html' scrolling=auto frameborder=0&gt;
&lt;frame name='mainframe' src='$home'&gt;
&lt;/frameset&gt;
&lt;/html&gt;
&quot;</span> <span class="op">:</span>
<span class="db">&quot;&lt;html&gt;&lt;head&gt;&lt;title&gt;$title&lt;/title&gt;&lt;/head&gt;
&lt;frameset cols='15%,85%'&gt;
&lt;frame name='navbar' src='toc.html' scrolling=auto frameborder=0&gt;
&lt;frame name='mainframe'&gt;
&lt;/frameset&gt;
&lt;/html&gt;
&quot;</span>;
}
<span class="ct">#</span>
<span class="ct">#   extract a package/method reference list, and add anchors for them
#</span>
<a name='PPI::HTML::CodeFolder::_extractXRef'></a><span class="kw">sub</span> <span class="wo">_extractXRef</span> {
    <span class="kw">my</span> ($self<span class="op">,</span> $html<span class="op">,</span> $outfile<span class="op">,</span> $script) <span class="op">=</span> <span class="mg">@_</span>;
    $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>} <span class="op">=</span> {} <span class="wo">unless</span> <span class="wo">exists</span> $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>};
    <span class="kw">my</span> $pkgs <span class="op">=</span> $self<span class="op">-&gt;</span>{<span class="wo">_pkgs</span>};
    <span class="kw">my</span> $pkglink;
<span id='src1026' class='foldfill'>Folded lines 1026 to 1030</span>
    <span class="kw">my</span> $curpkg <span class="op">=</span> <span class="sg">'main'</span>;
    $pkgs<span class="op">-&gt;</span>{<span class="wo">main</span>} <span class="op">=</span> {
        <span class="wo">URL</span> <span class="op">=&gt;</span> $outfile<span class="op">,</span>
        <span class="wo">Methods</span> <span class="op">=&gt;</span> {}
    }
        <span class="wo">if</span> $script;
 
    <span class="wo">while</span> (<span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/\G.*?(&lt;span class=['&quot;]kw['&quot;]&gt;)\s*(package|sub)\s*&lt;\/span&gt;\s*(&lt;span class=['&quot;][^'&quot;]+['&quot;]&gt;\s*)?([\w:]+)/gcs</span>) {
<span class="ct"># &quot; to keep Textpad formatting happy</span>
        <span class="kw">my</span> $pkg <span class="op">=</span> <span class="mg">$4</span>;
        <span class="kw">my</span> $next <span class="op">=</span> <span class="wo">pos</span>(<span class="cs">$</span>$html);
        <span class="kw">my</span> $insert <span class="op">=</span> <span class="mg">$-</span>[<span class="nm">1</span>];
        <span class="wo">if</span> (<span class="mg">$2</span> <span class="op">eq</span> <span class="sg">'package'</span>) {
            $curpkg <span class="op">=</span> $pkg;
            <span class="wo">next</span> <span class="wo">if</span> <span class="wo">exists</span> $pkgs<span class="op">-&gt;</span>{$pkg} <span class="op">&amp;&amp;</span> $pkgs<span class="op">-&gt;</span>{$pkg}{<span class="wo">URL</span>};   <span class="ct"># only use 1st definition of package</span>
            $pkglink <span class="op">=</span> $pkg;
            $pkgs<span class="op">-&gt;</span>{$pkg} <span class="op">=</span> {
                <span class="wo">URL</span> <span class="op">=&gt;</span> <span class="db">&quot;$outfile#$pkg&quot;</span><span class="op">,</span>
                <span class="wo">Methods</span> <span class="op">=&gt;</span> {}
            };
        }
        <span class="wo">else</span> {
            <span class="wo">if</span> ($pkg<span class="op">=~</span><span class="mt">/^(.+)::(\w+)$/</span>) {
<span class="ct">#</span>
<span class="ct">#   fully qualified name, check if we have a pkg entry for it
#</span>
                $pkgs<span class="op">-&gt;</span>{<span class="mg">$1</span>} <span class="op">=</span> {
                    <span class="wo">URL</span> <span class="op">=&gt;</span> <span class="sg">''</span><span class="op">,</span>
                    <span class="wo">Methods</span> <span class="op">=&gt;</span> {}
                }
                    <span class="wo">unless</span> <span class="wo">exists</span> $pkgs<span class="op">-&gt;</span>{<span class="mg">$1</span>};
                $pkgs<span class="op">-&gt;</span>{<span class="mg">$1</span>}{<span class="wo">Methods</span>}{<span class="mg">$2</span>} <span class="op">=</span> <span class="db">&quot;$outfile#$pkg&quot;</span>;
                $pkglink <span class="op">=</span> $pkg;
            }
            <span class="wo">else</span> {
                $pkglink <span class="op">=</span> ($curpkg <span class="op">eq</span> <span class="sg">'main'</span>) <span class="op">?</span> $pkg <span class="op">:</span> <span class="db">&quot;$curpkg\:\:$pkg&quot;</span>;
                $pkgs<span class="op">-&gt;</span>{$curpkg}{<span class="wo">Methods</span>}{$pkg} <span class="op">=</span> <span class="db">&quot;$outfile#$pkglink&quot;</span>;
            }
        }
        $pkglink <span class="op">=</span> <span class="db">&quot;&lt;a name='$pkglink'&gt;&lt;/a&gt;&quot;</span>;
        <span class="wo">substr</span>(<span class="cs">$</span>$html<span class="op">,</span> $insert<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> $pkglink);
        $next <span class="op">+=</span> <span class="wo">length</span>($pkglink);
        <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $next;
    }
    $pkgs<span class="op">-&gt;</span>{$script} <span class="op">=</span> <span class="wo">delete</span> $pkgs<span class="op">-&gt;</span>{<span class="wo">main</span>}
        <span class="wo">if</span> $script;
    <span class="kw">return</span> $html;
}
 
<a name='PPI::HTML::CodeFolder::_extractFolds'></a><span class="kw">sub</span> <span class="wo">_extractFolds</span> {
    <span class="kw">my</span> ($html<span class="op">,</span> $startpos<span class="op">,</span> $lnmap<span class="op">,</span> $opts) <span class="op">=</span> <span class="mg">@_</span>;
<span class="ct">#</span>
<span class="ct">#   scan for foldables
#</span>
    <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $startpos;
    <span class="kw">my</span> %folded <span class="op">=</span> (
        <span class="wo">Whitespace</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">Comments</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">POD</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">Heredocs</span> <span class="op">=&gt;</span> []<span class="op">,</span>
        <span class="wo">Imports</span> <span class="op">=&gt;</span> []<span class="op">,</span>
    );
    <span class="kw">my</span> $whitespace <span class="op">=</span> [];
<span id='src1094' class='foldfill'>Folded lines 1094 to 1105</span>
    <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $startpos;
    <span class="wo">foreach</span> (qw(Whitespace Comments POD Heredocs Imports)) {
        <span class="wo">next</span> <span class="wo">unless</span> (<span class="mg">$_</span> <span class="op">eq</span> <span class="sg">'Whitespace'</span>) <span class="op">||</span> $opts<span class="op">-&gt;</span>{<span class="mg">$_</span>};
<span class="ct">#</span>
<span class="ct">#   capture anything at the very beginning
#</span>
        <span class="kw">my</span> $fre <span class="op">=</span> $foldres{<span class="mg">$_</span>}[<span class="nm">0</span>];
        <span class="wo">push</span> <span class="cs">@</span>{$folded{<span class="mg">$_</span>}}<span class="op">,</span> [ <span class="mg">$-</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="mg">$+</span>[<span class="nm">1</span>] <span class="op">-</span> <span class="nm">1</span> ]
            <span class="wo">if</span> (<span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/$fre/gcs</span>);
    
        $fre <span class="op">=</span> $foldres{<span class="mg">$_</span>}[<span class="nm">1</span>];
        <span class="wo">push</span> <span class="cs">@</span>{$folded{<span class="mg">$_</span>}}<span class="op">,</span> [ <span class="mg">$-</span>[<span class="nm">1</span>]<span class="op">,</span> <span class="mg">$+</span>[<span class="nm">1</span>] <span class="op">-</span> <span class="nm">1</span> ]
            <span class="wo">while</span> (<span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/$fre/gcs</span>);
        <span class="wo">_mergeSection</span>(<span class="wo">_cvtToLines</span>($folded{<span class="mg">$_</span>}<span class="op">,</span> $lnmap))
            <span class="wo">if</span> <span class="wo">scalar</span> <span class="cs">@</span>{$folded{<span class="mg">$_</span>}};
        <span class="wo">pos</span>(<span class="cs">$</span>$html) <span class="op">=</span> $startpos;
    }
<span class="ct">#</span>
<span class="ct">#   now merge different sections
#</span>
    <span class="kw">my</span> $last <span class="op">=</span> <span class="sg">'Whitespace'</span>;
    <span class="wo">foreach</span> (qw(Imports POD Heredocs Comments)) {
        <span class="wo">_mergeSections</span>($folded{<span class="mg">$_</span>}<span class="op">,</span> $folded{$last});
        $last <span class="op">=</span> <span class="mg">$_</span>;
    }
    <span class="kw">return</span> <span class="cs">@</span>{$folded{$last}};
}
 
<a name='PPI::HTML::CodeFolder::_cvtToLines'></a><span class="kw">sub</span> <span class="wo">_cvtToLines</span> {
    <span class="kw">my</span> ($pos<span class="op">,</span> $lnmap) <span class="op">=</span> <span class="mg">@_</span>;
    
    <span class="kw">my</span> $ln <span class="op">=</span> <span class="nm">1</span>;
    <span class="wo">foreach</span> (<span class="cs">@</span>$pos) {
        $ln<span class="op">++</span> <span class="wo">while</span> ($ln <span class="op">&lt;=</span> <span class="cs">$#</span>$lnmap) <span class="op">&amp;&amp;</span> ($lnmap<span class="op">-&gt;</span>[$ln] <span class="op">&lt;=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]);
        <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>] <span class="op">=</span> $ln <span class="op">-</span> <span class="nm">1</span>;
        $ln<span class="op">++</span> <span class="wo">while</span> ($ln <span class="op">&lt;=</span> <span class="cs">$#</span>$lnmap) <span class="op">&amp;&amp;</span> ($lnmap<span class="op">-&gt;</span>[$ln] <span class="op">&lt;=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]);
        <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">=</span> $ln <span class="op">-</span> <span class="nm">1</span>;
    }
    <span class="kw">return</span> $pos;
}
 
<a name='PPI::HTML::CodeFolder::_mergeSection'></a><span class="kw">sub</span> <span class="wo">_mergeSection</span> {
    <span class="kw">my</span> $sect <span class="op">=</span> <span class="co">shift</span>;
    <span class="kw">my</span> @temp <span class="op">=</span> <span class="co">shift</span> <span class="cs">@</span>$sect;
    <span class="wo">foreach</span> (<span class="cs">@</span>$sect) {
        <span class="wo">push</span>(@temp<span class="op">,</span> <span class="mg">$_</span>)<span class="op">,</span>
        <span class="wo">next</span>
            <span class="wo">unless</span> ($temp[<span class="nm">-1</span>][<span class="nm">1</span>] <span class="op">+</span> <span class="nm">1</span> <span class="op">&gt;=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">0</span>]);
<span class="ct">#</span>
<span class="ct">#   if current surrounds new, the discard new
#</span>
        $temp[<span class="nm">-1</span>][<span class="nm">1</span>] <span class="op">=</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]
            <span class="wo">if</span> ($temp[<span class="nm">-1</span>][<span class="nm">1</span>] <span class="op">&lt;</span> <span class="mg">$_</span><span class="op">-&gt;</span>[<span class="nm">1</span>]);
    }
    <span class="cs">@</span>$sect <span class="op">=</span> @temp;
    <span class="nm">1</span>;
}
 
<a name='PPI::HTML::CodeFolder::_mergeSections'></a><span class="kw">sub</span> <span class="wo">_mergeSections</span> {
    <span class="kw">my</span> ($first<span class="op">,</span> $second) <span class="op">=</span> <span class="mg">@_</span>;
    
    <span class="wo">if</span> (<span class="cs">$#</span>$first <span class="op">&lt;</span> <span class="nm">0</span>) {
        <span class="cs">@</span>$first <span class="op">=</span> <span class="cs">@</span>$second;
        <span class="kw">return</span> $first;
    }
 
    <span class="kw">my</span> @temp <span class="op">=</span> ();
    <span class="wo">push</span> @temp<span class="op">,</span> (($first<span class="op">-&gt;</span>[<span class="nm">0</span>][<span class="nm">0</span>] <span class="op">&lt;</span> $second<span class="op">-&gt;</span>[<span class="nm">0</span>][<span class="nm">0</span>]) <span class="op">?</span> <span class="co">shift</span> <span class="cs">@</span>$first <span class="op">:</span> <span class="co">shift</span> <span class="cs">@</span>$second)
        <span class="wo">while</span> (<span class="cs">@</span>$first <span class="op">&amp;&amp;</span> <span class="cs">@</span>$second);
 
    <span class="wo">push</span> @temp<span class="op">,</span> <span class="cs">@</span>$first <span class="wo">if</span> <span class="wo">scalar</span> <span class="cs">@</span>$first;
    <span class="wo">push</span> @temp<span class="op">,</span> <span class="cs">@</span>$second <span class="wo">if</span> <span class="wo">scalar</span> <span class="cs">@</span>$second;
    <span class="wo">_mergeSection</span>(<span class="cs">\</span>@temp);
    <span class="cs">@</span>$first <span class="op">=</span> @temp;
    <span class="nm">1</span>;
}
 
<a name='PPI::HTML::CodeFolder::_addLineNumTable'></a><span class="kw">sub</span> <span class="wo">_addLineNumTable</span> {
    <span class="kw">my</span> ($html<span class="op">,</span> $ftsorted<span class="op">,</span> $folddivs<span class="op">,</span> $expdivs<span class="op">,</span> $linecnt) <span class="op">=</span> <span class="mg">@_</span>;
 
    <span class="cs">$</span>$html<span class="op">=~</span><span class="su">s/&lt;pre&gt;/&lt;pre class='bodypre'&gt;/</span>;
    <span class="cs">$</span>$html<span class="op">=~</span><span class="mt">/(&lt;body[^&gt;]+&gt;)/s</span>;
    <span class="kw">my</span> $insert <span class="op">=</span> <span class="mg">$+</span>[<span class="nm">0</span>];
<span class="ct">#</span>
<span class="ct">#   generate JS declaration of fold sections
#</span>
    <span class="kw">my</span> $startfolds <span class="op">=</span> <span class="wo">scalar</span> <span class="cs">@</span>$ftsorted <span class="op">?</span>
        <span class="sg">'['</span> <span class="op">.</span> <span class="wo">join</span>(<span class="sg">','</span><span class="op">,</span> <span class="cs">@</span>$ftsorted) <span class="op">.</span> <span class="db">&quot; ],\n[&quot;</span> <span class="op">.</span> <span class="wo">join</span>(<span class="sg">','</span><span class="op">,</span> <span class="wo">map</span> $folddivs<span class="op">-&gt;</span>{<span class="mg">$_</span>}[<span class="nm">0</span>]<span class="op">,</span> <span class="cs">@</span>$ftsorted) <span class="op">.</span> <span class="db">&quot; ]&quot;</span> <span class="op">:</span>
        <span class="db">&quot;[], []&quot;</span>;
 
    <span class="kw">my</span> $linenos <span class="op">=</span> <span class="cs">$</span>$expdivs <span class="op">.</span> <span class="db">&quot;
&lt;table border=0 width='100\%' cellpadding=0 cellspacing=0&gt;
&lt;tr&gt;
    &lt;td width=40 bgcolor='#E9E9E9' align=right valign=top&gt;
    &lt;pre id='lnnomargin' class='lnpre'&gt;
    &lt;/pre&gt;
&lt;/td&gt;
&lt;td width=8 bgcolor='#E9E9E9' align=right valign=top&gt;
&lt;pre id='btnmargin' class='lnpre'&gt;
&lt;/pre&gt;
&lt;/td&gt;
&lt;td bgcolor='white' align=left valign=top&gt;
&quot;</span>;
    <span class="wo">substr</span>(<span class="cs">$</span>$html<span class="op">,</span> $insert<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> $linenos);
    <span class="wo">substr</span>(<span class="cs">$</span>$html<span class="op">,</span> <span class="wo">index</span>(<span class="cs">$</span>$html<span class="op">,</span> <span class="sg">'&lt;/body&gt;'</span>)<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="db">&quot;
&lt;/td&gt;&lt;/tr&gt;&lt;/table&gt;
 
&lt;script type='text/javascript'&gt;
&lt;!--
 
var ppihtml = new ppiHtmlCF($startfolds);
ppihtml.renderMargins($linecnt);
/*
 *  all rendered, now selectively open from any existing cookie
 */
ppihtml.openFromCookie();
 
--&gt;
&lt;/script&gt;
&quot;</span>
    );
    <span class="kw">return</span> <span class="nm">1</span>;
}
 
<a name='PPI::HTML::CodeFolder::_addFoldDivs'></a><span class="kw">sub</span> <span class="wo">_addFoldDivs</span> {
    <span class="kw">my</span> ($folddivs<span class="op">,</span> $ftsorted) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="wo">foreach</span> <span class="wo">my</span> $ft (<span class="wo">values</span> <span class="cs">%</span>$folddivs) {
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s/&lt;br&gt;/\n/gs</span>;
<span class="ct">#</span>
<span class="ct">#   squeeze out leading whitespace, but keep aligned
#</span>
        <span class="kw">my</span> $shortws <span class="op">=</span> <span class="nm">1000000</span>;
        <span class="kw">my</span> @lns <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\n/</span><span class="op">,</span> $ft<span class="op">-&gt;</span>[<span class="nm">1</span>];
<span class="ct">#</span>
<span class="ct">#   expand tabs as needed (we use 4 space tabs)
#</span>
        <span class="wo">foreach</span> (@lns) {
            <span class="wo">next</span> <span class="wo">if</span> <span class="su">s/^\s*$//</span>;
            $shortws <span class="op">=</span> <span class="nm">0</span><span class="op">,</span> <span class="wo">last</span>
                <span class="wo">unless</span> <span class="mt">/^(\s+)/</span>;
            $shortws <span class="op">=</span> <span class="wo">length</span>(<span class="mg">$1</span>)
                <span class="wo">if</span> ($shortws <span class="op">&gt;</span> <span class="wo">length</span>(<span class="mg">$1</span>))
        }
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>] <span class="op">=</span> <span class="wo">join</span>(<span class="db">&quot;\n&quot;</span><span class="op">,</span> <span class="wo">map</span> { <span class="mg">$_</span> <span class="op">?</span> <span class="wo">substr</span>(<span class="mg">$_</span><span class="op">,</span> $shortws) <span class="op">:</span> <span class="sg">''</span>; } @lns)
            <span class="wo">if</span> $shortws;
<span class="ct">#</span>
<span class="ct">#   move whitespace inside any leading/trailing spans
#</span>
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!(&lt;/span&gt;)(\s+)$!$2$1!s</span>;
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!^(\s+)(&lt;span [^&gt;]+&gt;)!$2$1!s</span>;
<span class="ct">#</span>
<span class="ct">#   if ends on span, make sure its not creating newline
#</span>
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!\n&lt;/span&gt;$! &lt;/span&gt;!s</span>;
<span class="ct">#</span>
<span class="ct">#   likewise if it doesn't end on a span
#</span>
        $ft<span class="op">-&gt;</span>[<span class="nm">1</span>]<span class="op">=~</span><span class="su">s!\n$!!s</span>;
    }
    <span class="kw">return</span> <span class="wo">join</span>(<span class="sg">''</span><span class="op">,</span> <span class="wo">map</span> <span class="db">&quot;\n&lt;div id='ft$_' class='folddiv'&gt;&lt;pre id='preft$_'&gt;$folddivs-&gt;{$_}[1]&lt;/pre&gt;&lt;/div&gt;&quot;</span><span class="op">,</span> <span class="cs">@</span>$ftsorted);
}
 
<a name='PPI::HTML::CodeFolder::_pathAdjust'></a><span class="kw">sub</span> <span class="wo">_pathAdjust</span> {
    <span class="kw">my</span> ($path<span class="op">,</span> $jspath) <span class="op">=</span> <span class="mg">@_</span>;
    <span class="kw">return</span> $jspath
        <span class="wo">unless</span> (<span class="wo">substr</span>($jspath<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="nm">2</span>) <span class="op">eq</span> <span class="sg">'./'</span>) <span class="op">&amp;&amp;</span> (<span class="wo">substr</span>($path<span class="op">,</span> <span class="nm">0</span><span class="op">,</span> <span class="nm">2</span>) <span class="op">eq</span> <span class="sg">'./'</span>);
<span class="ct">#</span>
<span class="ct">#   relative path, adjust as needed from current base
#</span>
    <span class="kw">my</span> @parts <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\//</span><span class="op">,</span> $path;
    <span class="kw">my</span> @jsparts <span class="op">=</span> <span class="wo">split</span> <span class="mt">/\//</span><span class="op">,</span> $jspath;
    <span class="kw">my</span> $jsfile <span class="op">=</span> <span class="wo">pop</span> @jsparts;  <span class="ct"># get rid of filename</span>
    <span class="wo">pop</span> @parts;     <span class="ct"># remove filename</span>
    <span class="co">shift</span> @parts;
    <span class="co">shift</span> @jsparts; <span class="ct"># and the relative lead</span>
    <span class="kw">my</span> $prefix <span class="op">=</span> <span class="sg">''</span>;
    <span class="co">shift</span> @parts<span class="op">,</span> 
    <span class="co">shift</span> @jsparts
        <span class="wo">while</span> @parts <span class="op">&amp;&amp;</span> @jsparts <span class="op">&amp;&amp;</span> ($parts[<span class="nm">0</span>] <span class="op">eq</span> $jsparts[<span class="nm">0</span>]);
    <span class="wo">push</span> @jsparts<span class="op">,</span> $jsfile;
    <span class="kw">return</span> (<span class="sg">'../'</span> <span class="op">x</span> <span class="wo">scalar</span> @parts) <span class="op">.</span> <span class="wo">join</span>(<span class="sg">'/'</span><span class="op">,</span> @jsparts)
}
 
<span class="nm">1</span>;
</pre>
</td></tr></table>
 
<script type='text/javascript'>
<!--
 
var ppihtml = new ppiHtmlCF([1,29,113,118,185,452,500,545,559,581,602,620,636,651,692,703,745,751,757,784,802,829,847,855,869,899,961,989,1026,1094 ],
[27,35,116,179,450,494,503,557,572,593,615,625,639,680,695,706,749,755,761,788,807,833,850,867,887,915,978,999,1030,1105 ]);
ppihtml.renderMargins(1290);
/*
 *	all rendered, now selectively open from any existing cookie
 */
ppihtml.openFromCookie();
 
-->
</script>
</body>
</html>
EOMINHTML

chomp $minhtml;

cmp_ok($content, 'eq', $minhtml, 'Valid output wo/ embedded JS/CSS');

#
#	test cross reference
#
my $xref = $HTML->getCrossReference();

$expected = {
'PPI::HTML::CodeFolder' => {
'URL' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder',
'Methods' => {
'_extractXRef' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_extractXRef',
'getTOC' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getTOC',
'foldCSS' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::foldCSS',
'_addFoldDivs' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_addFoldDivs',
'html' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::html',
'_mergeSection' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_mergeSection',
'_cvtToLines' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_cvtToLines',
'new' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::new',
'foldJavascript' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::foldJavascript',
'_pathAdjust' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_pathAdjust',
'getCrossReference' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getCrossReference',
'_extractFolds' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_extractFolds',
'writeCSS' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeCSS',
'writeTOC' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeTOC',
'getFrameContainer' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getFrameContainer',
'writeFrameContainer' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeFrameContainer',
'_addLineNumTable' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_addLineNumTable',
'writeJavascript' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeJavascript',
'_mergeSections' => 'PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_mergeSections'
}
}
};

saveIt('PPICFxref.out', Dumper($xref));

is_deeply($xref, $expected, 'getCrossReference');
#
#	get TOC
#
my $toc = $HTML->getTOC();
saveIt('PPICFtoc.html', $toc);

$expected = <<'EOTOC';
<html>
<body>
<small>
<!-- INDEX BEGIN -->
<ul>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder' target='mainframe'>PPI::HTML::CodeFolder</a>
		<ul>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_addFoldDivs' target='mainframe'>_addFoldDivs</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_addLineNumTable' target='mainframe'>_addLineNumTable</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_cvtToLines' target='mainframe'>_cvtToLines</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_extractFolds' target='mainframe'>_extractFolds</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_extractXRef' target='mainframe'>_extractXRef</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_mergeSection' target='mainframe'>_mergeSection</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_mergeSections' target='mainframe'>_mergeSections</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_pathAdjust' target='mainframe'>_pathAdjust</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::foldCSS' target='mainframe'>foldCSS</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::foldJavascript' target='mainframe'>foldJavascript</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getCrossReference' target='mainframe'>getCrossReference</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getFrameContainer' target='mainframe'>getFrameContainer</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getTOC' target='mainframe'>getTOC</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::html' target='mainframe'>html</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::new' target='mainframe'>new</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeCSS' target='mainframe'>writeCSS</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeFrameContainer' target='mainframe'>writeFrameContainer</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeJavascript' target='mainframe'>writeJavascript</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeTOC' target='mainframe'>writeTOC</a></li>
</ul>
</li>

</ul>
<!-- INDEX END -->
</small>
</body>
</html>
EOTOC

is($toc, $expected, 'getTOC');

$toc = $HTML->getTOC('', Order => [ 'PPI::HTML::CodeFolder::Fragment', 'PPI::HTML::CodeFolder' ]);
saveIt('PPICFtoc_order.html', $toc);

$expected = <<'EOORDER';
<html>
<body>
<small>
<!-- INDEX BEGIN -->
<ul>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder' target='mainframe'>PPI::HTML::CodeFolder</a>
		<ul>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_addFoldDivs' target='mainframe'>_addFoldDivs</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_addLineNumTable' target='mainframe'>_addLineNumTable</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_cvtToLines' target='mainframe'>_cvtToLines</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_extractFolds' target='mainframe'>_extractFolds</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_extractXRef' target='mainframe'>_extractXRef</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_mergeSection' target='mainframe'>_mergeSection</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_mergeSections' target='mainframe'>_mergeSections</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::_pathAdjust' target='mainframe'>_pathAdjust</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::foldCSS' target='mainframe'>foldCSS</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::foldJavascript' target='mainframe'>foldJavascript</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getCrossReference' target='mainframe'>getCrossReference</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getFrameContainer' target='mainframe'>getFrameContainer</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::getTOC' target='mainframe'>getTOC</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::html' target='mainframe'>html</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::new' target='mainframe'>new</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeCSS' target='mainframe'>writeCSS</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeFrameContainer' target='mainframe'>writeFrameContainer</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeJavascript' target='mainframe'>writeJavascript</a></li>
<li><a href='PPI/HTML/CodeFolder.pm.html#PPI::HTML::CodeFolder::writeTOC' target='mainframe'>writeTOC</a></li>
</ul>
</li>

</ul>
<!-- INDEX END -->
</small>
</body>
</html>
EOORDER

is($toc, $expected, 'getTOC(ordered)');

my $rc = $HTML->writeTOC('t/src', Order => [ 'PPI::HTML::CodeFolder::Fragment', 'PPI::HTML::CodeFolder' ]);
ok($rc && (-e 't/src/toc.html'), 'writeTOC');

my $container = $HTML->getFrameContainer('PPI::HTML::CodeFolder Title', 'PPI/HTML/CodeFolder.pm.html');
saveIt('PPICF_frames.html', $container);
$expected = <<'EOFRAMES';
<html><head><title>PPI::HTML::CodeFolder Title</title></head>
<frameset cols='15%,85%'>
<frame name='navbar' src='toc.html' scrolling=auto frameborder=0>
<frame name='mainframe' src='PPI/HTML/CodeFolder.pm.html'>
</frameset>
</html>
EOFRAMES
is($container, $expected, 'getFrameContainer');

$rc = $HTML->writeFrameContainer('t/src', 'PPI::HTML::CodeFolder Title', 'PPI/HTML/CodeFolder.pm.html');
ok($rc && (-e 't/src/index.html'), 'writeFrameContainer');
#
#	cleanup our mess
#
unlink 't/src/PPI/HTML/CodeFolder.pm.html';
unlink 't/src/toc.html';
unlink 't/src/index.html';
rmdir $_ foreach (reverse qw(t/src t/src/PPI t/src/PPI/HTML));

sub saveIt {
	return unless $saveAll;
	open OUTF, ">$_[0]" or die $!;
	print OUTF $_[1];
	close OUTF;
}