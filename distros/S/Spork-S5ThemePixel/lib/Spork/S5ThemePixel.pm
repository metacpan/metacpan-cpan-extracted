package Spork::S5ThemePixel;
use Spork::S5Theme -Base;
use strict;

our $VERSION = '0.03';

__DATA__

=head1 NAME

  Spork::S5ThemePixel - Pixel Theme for Spork::S5

=head1 DESCRIPTION

Pixel Theme for Spork::S5 written by Martin Hense

=head1 COPYRIGHT

Copyright 2005 by Florian Merges <fmerges@cpan.org>

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__ui/framing.css__
/* The following styles size and place the slide components.
   Edit them if you want to change the overall slide layout.
   The commented lines can be uncommented (and modified, if necessary) 
    to help you with the rearrangement process. */

div#header, div#footer, div.slide {width: 100%; top: 0; left: 0;}
div#header {top: 0; height: 1em;}
div#footer {top: auto; bottom: 0; height: 2.5em;}
div.slide {top: 0; width: 92%; padding: 3.5em 4% 4%;}
/*div#controls {left: 50%; top: 0; width: 50%; height: 100%;}
#footer>*/
div#controls {bottom: 0; top: auto; height: auto;}

div#controls form {position: absolute; bottom: 0; right: 0; width: 100%;
  margin: 0;}
div#currentSlide {position: absolute; left: -500px; bottom: 1em; width: 130px; z-index: 10;}
/*html>body 
#currentSlide {position: fixed;}*/

/*
div#header {background: #FCC;}
div#footer {background: #CCF;}
div#controls {background: #BBD;}
div#currentSlide {background: #FFC;}
*/
__ui/opera.css__
/* DO NOT CHANGE THESE unless you really want to break Opera Show */
div.slide {
	visibility: visible !important;
	position: static !important;
	page-break-before: always;
}
#slide0 {page-break-before: avoid;}
__ui/pretty.css__
/* Pixel Theme 2004 by Martin Hense ::: www.lounge7.de */

/* Following are the presentation styles -- edit away!
   Note that the 'body' font size may have to be changed if the resolution is
    different than expected. */

body {background: transparent url(pixelbg.gif) repeat-y; color: #08093F; font-size: 1.8em;}
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
ul {margin-right: 7%; margin-left: 50px; list-style: square;}
li {margin-top: 0.75em; margin-right: 0;}
ul ul {line-height: 1;}
ul ul li {margin: .2em; font-size: 85%; list-style: square;}
img.leader {display: block; margin: 0 auto;}

div#header, div#footer {background: #005; color: #646587;
  font-family: Verdana, Helvetica, sans-serif;}
div#header {background: transparent url(pixelheader.jpg) 0 0 no-repeat; height: 75px;}
div#footer {font-size: 0.5em; font-weight: bold; padding: 1em 0; border-top: 1px solid #08093F; background: #fff;}
#footer h1, #footer h2 {display: block; padding: 0 1em;}
#footer h2 {font-style: italic;}

div.long {font-size: 0.75em;}
.slide {font-family: Verdana, Helvetica, Arial, sans-serif;}
.slide h1 {position: absolute; z-index: 1;
  margin: 0; padding: 0.3em 0 0 50px; white-space: nowrap;
  font: bold 150%/1em Helvetica, sans-serif; text-transform: capitalize;
  top: 1.4em; left: 2%;
  color: #08093F; background: transparent;}
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
  border: none;
  cursor: pointer;
  background: #fff; color: #646587;}
div#controls select {visibility: hidden; background: #DDD; color: #227;}
div#controls div:hover select {visibility: visible;}

#currentSlide {text-align: center; font-size: 0.5em; color: #646587;
   font-family: Verdana, Helvetica, sans-serif; font-weight: bold;}

#slide0 {padding-top: 3.5em; font-size: 90%;}
#slide0 h1 {position: static; white-space: normal;	
	margin: 0; padding: 60px 60px 0 150px; text-align: right;
   font: bold 2em Helvetica, sans-serif; white-space: normal; height: 281px;
   color: #fff; background: transparent url(pixelslide0bg.gif) no-repeat;}
#slide0 h3 {margin-top: 0.5em; font-size: 1.5em;}
#slide0 h4 {margin-top: 0; font-size: 1em;}

ul.urls {list-style: none; display: inline; margin: 0;}
.urls li {display: inline; margin: 0;}
.note {display: none;}
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

#footer h1 {margin: 0; border-bottom: 1px solid; color: gray; font-style: italic;}
#footer h2, #controls {display: none;}
__ui/s5-core.css__
/* Do not edit or override these styles! The system will likely break if you do. */

div#header, div#footer, div.slide {position: absolute;}
html>body div#header, html>body div#footer, html>body div.slide {position: fixed;}
div#header {z-index: 1;}
div.slide  {z-index: 2; visibility: hidden;}
#slide0 {visibility: visible;}
div#footer {z-index: 5;}
div#controls {position: absolute; z-index: 1;}
#footer>div#controls {position: fixed;}
.handout {display: none;}
__ui/slides.css__
@import url(s5-core.css); /* required to make the slide show run at all */
@import url(framing.css); /* sets basic placement and size of slide components */
@import url(pretty.css);  /* stuff that makes the slides look better than blah */
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
__ui/pixelbg.gif__
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
ewYlBAA7
__ui/pixelheader.jpg__
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
__ui/pixelslide0bg.gif__
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
