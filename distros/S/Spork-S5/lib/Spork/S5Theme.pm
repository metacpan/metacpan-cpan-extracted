package Spork::S5Theme;
use Spork::Plugin -Base;
use mixin 'Spoon::Installer';

const class_id => 'theme';

__DATA__

=head1 NAME

Spork::S5ThemeDefault - Default Theme for Spork::S5

=head1 AUTHOR

Kang-min Liu <gugod@gugod.org>

=head1 COPYRIGHT

Copyright (c) 2005. Kang-min Liu. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__template/s5/s5.html__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" 
	"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=[% character_encoding %]">
<title>[% presentation_topic %]</title>
<meta name="generator" content="Spork-S5" />
<meta name="version" content="Spork-S5 0.04" />
<meta name="author" content="[% author_name %]" />
<link rel="stylesheet" href="ui/slides.css" type="text/css" media="projection" id="slideProj" />
<link rel="stylesheet" href="ui/opera.css" type="text/css" media="projection" id="operaFix" />
<link rel="stylesheet" href="ui/print.css" type="text/css" media="print" id="slidePrint" />
[% FOR css_file = hub.css.files -%]
  <link rel="stylesheet" type="text/css" href="[% css_file %]" />
[% END -%]
<script src="ui/slides.js" type="text/javascript"></script>
</head>
<body>

<div class="layout">
  <div id="currentSlide"></div>
  <div id="header"></div>
  <div id="footer">
    <h2>[% author_name %]</h2>
    <h2>[% author_email %]</h2>
    <div id="controls"></div>
  </div>
</div>

<div class="slide">
    <h1>[% presentation_title %]</h1>
    <h2>[% presentation_place %]</h2>
    <h3>[% presentation_date %]</h3>
</div>

[% FOREACH s = slides %]
[% s %]
[% END %]
</body>
</html>
__template/s5/slide.html__
<div class="slide">
[% image_html %]
[% slide_content %]
[%- UNLESS last -%]
<small>continued...</small>
[% END %]
</div>
__ui/opera.css__
/* DO NOT CHANGE THESE unless you really want to break Opera Show */
div.slide {
	visibility: visible !important;
	position: static !important;
	page-break-before: always;
}
#slide0 {page-break-before: avoid;}
__ui/pretty.css__
/* Following are the presentation styles -- edit away!
   Note that the 'body' font size may have to be changed if the resolution is
    different than expected. */

body {background: #fff url(bodybg.gif) -16px 0 no-repeat; color: #000; font-size: 2em;}
:link, :visited {text-decoration: none;}
#controls :active {color: #88A !important;}
#controls :focus {outline: 1px dotted #227;}
h1, h2, h3, h4 {font-size: 100%; margin: 0; padding: 0; font-weight: inherit;}
ul, pre {margin: 0; line-height: 1em;}
html, body {margin: 0; padding: 0;}

blockquote, q {font-style: italic;}
blockquote {padding: 0 2em 0.5em; margin: 0 1.5em 0.5em; text-align: center; font-size: 1em;}
blockquote p {margin: 0;}
blockquote i {font-style: normal;}
blockquote b {display: block; margin-top: 0.5em; font-weight: normal; font-size: smaller; font-style: normal;}
blockquote b i {font-style: italic;}

kbd {font-weight: bold; font-size: 1em;}
sup {font-size: smaller; line-height: 1px;}

code {padding: 2px 0.25em; font-weight: bold; color: #533;}
code.bad, code del {color: red;}
code.old {color: silver;}
pre {padding: 0; margin: 0.25em 0 0.5em 0.5em; color: #533; font-size: 90%;}
pre code {display: block;}
ul {margin-left: 5%; margin-right: 7%; list-style: disc;}
li {margin-top: 0.75em; margin-right: 0;}
ul ul {line-height: 1;}
ul ul li {margin: .2em; font-size: 85%; list-style: square;}
img.leader {display: block; margin: 0 auto;}

div#header, div#footer {background: #005; color: #AAB;
  font-family: Verdana, Helvetica, sans-serif;}
div#header {background: #005 url(bodybg.gif) -16px 0 no-repeat;
  line-height: 1px;}
div#footer {font-size: 0.5em; font-weight: bold; padding: 1em 0;}
#footer h1, #footer h2 {display: block; padding: 0 1em;}
#footer h2 {font-style: italic;}

div.long {font-size: 0.75em;}
.slide h1 {position: absolute; top: 0.7em; left: 87px; z-index: 1;
  margin: 0; padding: 0.3em 0 0 50px; white-space: nowrap;
  font: bold 150%/1em Helvetica, sans-serif; text-transform: capitalize;
  color: #DDE; background: #005;}
.slide h3 {font-size: 130%;}
h1 abbr {font-variant: small-caps;}

div#controls {position: absolute; z-index: 1; left: 50%; top: 0;
  width: 50%; height: 100%;
  text-align: right;}
#footer>div#controls {position: fixed; bottom: 0; padding: 1em 0;
  top: auto; height: auto;}
div#controls form {position: absolute; bottom: 0; right: 0; width: 100%;
  margin: 0; padding: 0;}
div#controls a {font-size: 2em; padding: 0; margin: 0 0.5em; 
  background: #005; border: none; color: #779; 
  cursor: pointer;}
div#controls select {visibility: hidden; background: #DDD; color: #227;}
div#controls div:hover select {visibility: visible;}

#currentSlide {text-align: center; font-size: 0.5em; color: #449;}

#slide0 {padding-top: 3.5em; font-size: 90%;}
#slide0 h1 {position: static; margin: 1em 0 1.33em; padding: 0;
   font: bold 2em Helvetica, sans-serif; white-space: normal;
   color: #000; background: transparent;}
#slide0 h3 {margin-top: 0.5em; font-size: 1.5em;}
#slide0 h4 {margin-top: 0; font-size: 1em;}

ul.urls {list-style: none; display: inline; margin: 0;}
.urls li {display: inline; margin: 0;}
.note {display: none;}

__ui/framing.css__
/* The following styles size, place, and layer the slide components.
   Edit these if you want to change the overall slide layout.
   The commented lines can be uncommented (and modified, if necessary) 
    to help you with the rearrangement process. */

div#header, div#footer, div.slide {width: 100%; top: 0; left: 0;}
div#header {top: 0; height: 3em; z-index: 1;}
div#footer {top: auto; bottom: 0; height: 2.5em; z-index: 5;}
div.slide {top: 0; width: 92%; padding: 3.5em 4% 4%; z-index: 2;}
div#controls {left: 50%; top: 0; width: 50%; height: 100%; z-index: 1;}
#footer>div#controls {bottom: 0; top: auto; height: auto;}

div#controls form {position: absolute; bottom: 0; right: 0; width: 100%;
  margin: 0;}
#currentSlide {position: absolute; width: 10%; left: 45%; bottom: 1em; z-index: 10;}
html>body #currentSlide {position: fixed;}

/*
div#header {background: #FCC;}
div#footer {background: #CCF;}
div#controls {background: #BBD;}
div#currentSlide {background: #FFC;}
*/

__ui/print.css__
/* The next rule is necessary to have all slides appear in print! DO NOT REMOVE IT! */
div.slide, ul {page-break-inside: avoid; visibility: visible !important;}
h1 {page-break-after: avoid;}

body {font-size: 12pt; background: white;}
* {color: black;}

#slide0 h1 {font-size: 200%; border: none; margin: 0.5em 0 0.25em;}
#slide0 h3 {margin: 0; padding: 0;}
#slide0 h4 {margin: 0 0 0.5em; padding: 0;}
#slide0 {margin-bottom: 3em;}

h1 {border-top: 2pt solid gray; border-bottom: 1px dotted silver;}
.extra {background: transparent !important;}
div.extra, pre.extra, .example {font-size: 10pt; color: #333;}
ul.extra a {font-weight: bold;}
p.example {display: none;}

#header {display: none;}
#footer h1 {margin: 0; border-bottom: 1px solid; color: gray; font-style: italic;}
#footer h2, #controls {display: none;}

#currentSlide {display: none;}
__ui/s5-core.css__
/* Do not edit or override these styles! The system will likely break if you do. */

div#header, div#footer, div.slide {position: absolute;}
html>body div#header, html>body div#footer, html>body div.slide {position: fixed;}
div.slide  { visibility: hidden;}
#slide0 {visibility: visible;}
div#controls {position: absolute;}
#footer>div#controls {position: fixed;}
.handout {display: none;}

__ui/slides.css__
@import url(s5-core.css); /* required to make the slide show run at all */
@import url(framing.css); /* sets basic placement and size of slide components */
@import url(pretty.css);  /* stuff that makes the slides look better than blah */
tt {
font-family: courier;
font-size: smaller;
whitespace: pre;
}
__ui/slides.js__
// S5 slides.js -- released under CC by-sa 2.0 license
//
// Please see http://www.meyerweb.com/eric/tools/s5/credits.html for information 
// about all the wonderful and talented contributors to this code!

var snum = 0;
var smax = 1;
var undef;
var slcss = 1;
var isIE = navigator.appName == 'Microsoft Internet Explorer' ? 1 : 0;
var isOp = navigator.userAgent.indexOf('Opera') > -1 ? 1 : 0;
var isGe = navigator.userAgent.indexOf('Gecko') > -1 && navigator.userAgent.indexOf('Safari') < 1 ? 1 : 0;
var slideCSS = document.getElementById('slideProj').href;

function isClass(object, className) {
	return (object.className.search('(^|\\s)' + className + '(\\s|$)') != -1);
}

function GetElementsWithClassName(elementName,className) {
	var allElements = document.getElementsByTagName(elementName);
	var elemColl = new Array();
	for (i = 0; i< allElements.length; i++) {
		if (isClass(allElements[i], className)) {
			elemColl[elemColl.length] = allElements[i];
		}
	}
	return elemColl;
}

function isParentOrSelf(element, id) {
	if (element == null || element.nodeName=='BODY') return false;
	else if (element.id == id) return true;
	else return isParentOrSelf(element.parentNode, id);
}

function nodeValue(node) {
	var result = "";
	if (node.nodeType == 1) {
		var children = node.childNodes;
		for ( i = 0; i < children.length; ++i ) {
			result += nodeValue(children[i]);
		}		
	}
	else if (node.nodeType == 3) {
		result = node.nodeValue;
	}
	return(result);
}

function slideLabel() {
	var slideColl = GetElementsWithClassName('div','slide');
	var list = document.getElementById('jumplist');
	smax = slideColl.length;
	for (n = 0; n < smax; n++) {
		var obj = slideColl[n];

		var did = 'slide' + n.toString();
		obj.setAttribute('id',did);
		if(isOp) continue;

		var otext = '';
 		var menu = obj.firstChild;
		if (!menu) continue; // to cope with empty slides
		while (menu && menu.nodeType == 3) {
			menu = menu.nextSibling;
		}
	 	if (!menu) continue; // to cope with slides with only text nodes

		var menunodes = menu.childNodes;
		for (o = 0; o < menunodes.length; o++) {
			otext += nodeValue(menunodes[o]);
		}
		list.options[list.length] = new Option(n+' : ' +otext,n);
	}
}

function currentSlide() {
	var cs;
	if (document.getElementById) {
		cs = document.getElementById('currentSlide');
	} else {
		cs = document.currentSlide;
	}
	cs.innerHTML = '<span id="csHere">' + snum + '<\/span> ' + 
		'<span id="csSep">\/<\/span> ' + 
		'<span id="csTotal">' + (smax-1) + '<\/span>';
	if (snum == 0) {
		cs.style.visibility = 'hidden';
	} else {
		cs.style.visibility = 'visible';
	}
}

function go(inc) {
	if (document.getElementById("slideProj").disabled) return;
	var cid = 'slide' + snum;
	if (inc != 'j') {
		snum += inc;
		lmax = smax - 1;
		if (snum > lmax) snum = 0;
		if (snum < 0) snum = lmax;
	} else {
		snum = parseInt(document.getElementById('jumplist').value);
	}
	var nid = 'slide' + snum;
	var ne = document.getElementById(nid);
	if (!ne) {
		ne = document.getElementById('slide0');
		snum = 0;
	}
	document.getElementById(cid).style.visibility = 'hidden';
	ne.style.visibility = 'visible';
	document.getElementById('jumplist').selectedIndex = snum;
	currentSlide();
}

function toggle() {
    var slideColl = GetElementsWithClassName('div','slide');
    var obj = document.getElementById('slideProj');
    if (!obj.disabled) {
        obj.disabled = true;
        for (n = 0; n < smax; n++) {
            var slide = slideColl[n];
            slide.style.visibility = 'visible';
        }
    } else {
        obj.disabled = false;
        for (n = 0; n < smax; n++) {
            var slide = slideColl[n];
            slide.style.visibility = 'hidden';
        }
        slideColl[snum].style.visibility = 'visible';
    }
}

function showHide(action) {
	var obj = document.getElementById('jumplist');
	switch (action) {
	case 's': obj.style.visibility = 'visible'; break;
	case 'h': obj.style.visibility = 'hidden'; break;
	case 'k':
		if (obj.style.visibility != 'visible') {
			obj.style.visibility = 'visible';
		} else {
			obj.style.visibility = 'hidden';
		}
	break;
	}
}

// 'keys' code adapted from MozPoint (http://mozpoint.mozdev.org/)
function keys(key) {
	if (!key) {
		key = event;
		key.which = key.keyCode;
	}
 	switch (key.which) {
		case 10: // return
		case 13: // enter
			if (window.event && isParentOrSelf(window.event.srcElement, "controls")) return;
			if (key.target && isParentOrSelf(key.target, "controls")) return;
		case 32: // spacebar
		case 34: // page down
		case 39: // rightkey
		case 40: // downkey
			go(1);
			break;
		case 33: // page up
		case 37: // leftkey
		case 38: // upkey
			go(-1);
			break;
		case 84: // t
			toggle();
			break;
		case 67: // c
			showHide('k');
			break;
	}
}

function clicker(e) {
	var target;
	if (window.event) {
		target = window.event.srcElement;
		e = window.event;
	} else target = e.target;
 	if (target.href != null || isParentOrSelf(target, 'controls')) return true;
	if (!e.which || e.which == 1) go(1);
}

function slideJump() {
	if (window.location.hash == null) return;
	var sregex = /^#slide(\d+)$/;
	var matches = sregex.exec(window.location.hash);
	var dest = null;
	if (matches != null) {
		dest = parseInt(matches[1]);
	} else {
		var target = window.location.hash.slice(1);
		var targetElement = null;
		var aelements = document.getElementsByTagName("a");
		for (i = 0; i < aelements.length; i++) {
			var aelement = aelements[i];
			if ( (aelement.name && aelement.name == target)
			 || (aelement.id && aelement.id == target) ) {
				targetElement = aelement;
				break;
			}
		}
		while(targetElement != null && targetElement.nodeName != "body") {
			if (targetElement.className == "slide") break;
			targetElement = targetElement.parentNode;
		}
		if (targetElement != null && targetElement.className == "slide") {
			dest = parseInt(targetElement.id.slice(1));
		}
	}
	if (dest != null)
		go(dest - snum);
 }
 
function createControls() {
	controlsDiv = document.getElementById("controls");
	if (!controlsDiv) return;
	controlsDiv.innerHTML = '<form action="#" id="controlForm">' +
	'<div>' +
	'<a accesskey="t" id="toggle" href="javascript:toggle();">&#216;<\/a>' +
	'<a accesskey="z" id="prev" href="javascript:go(-1);">&laquo;<\/a>' +
	'<a accesskey="x" id="next" href="javascript:go(1);">&raquo;<\/a>' +
	'<\/div>' +
	'<div onmouseover="showHide(\'s\');" onmouseout="showHide(\'h\');"><select id="jumplist" onchange="go(\'j\');"><\/select><\/div>' +
	'<\/form>';
}

function notOperaFix() {
	var obj = document.getElementById('slideProj');
	obj.setAttribute('media','screen');
	if (isGe) {
		obj.setAttribute('href','null');   // Gecko fix
		obj.setAttribute('href',slideCSS); // Gecko fix
	}
}

function startup() {
	if (!isOp) createControls();
	slideLabel();
	if (!isOp) {		
		notOperaFix();
		slideJump();
		document.onkeyup = keys;
		document.onclick = clicker;
	}
}

window.onload = startup;




__ui/bodybg.gif__
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
