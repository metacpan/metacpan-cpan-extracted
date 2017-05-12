package Spork::S5ThemeRedSimple;
use Spork::S5Theme -Base;
our $VERSION = '0.01';

__DATA__

=head1 NAME

  Spork::S5ThemeRedSimple - A Simplistic Red Color Theme

=head1 COPYRIGHT

Copyright 2004 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

=cut

__ui/button.gif__
R0lGODlhIwAjAPcAAEj+AMIxAMwzAPPz8wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAMALAAAAAAjACMA
QAh1AAcIHBCgoMGDCBMmHEhQocOHECNKnEixIsKGFitizMixo8ePID0OEECypMmTKFOeHKmypcuX
MGPKnEmzps2bOHPqvMlwp0mGAn2mHBgSIkuhKotGRNpSKUSmSZ06hJpS6lSqJ60qxJpVK0KuP70a
HMhVYEAAADs=
__ui/framing.css__
/* The following styles size and place the slide components.
   Edit them if you want to change the overall slide layout.
   The commented lines can be uncommented (and modified, if necessary) 
    to help you with the rearrangement process. */

div#header, div#footer, div.slide {width: 100%; top: 0; left: 0;}
div#header {top: 0; height: 3em;}
div#footer {top: auto; bottom: 0; height: 2.5em;}
div.slide {top: 0; width: 92%; padding: 3.5em 4% 4%;}
div#controls {left: 50%; top: 0; width: 50%; height: 100%;}
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

body {background: #fff; color: #000; font-size: 2em; font-family: Verdana, Arial, sans-serif;}

a {
	color: #c30;
	text-decoration: none;
}

a:hover {
	text-decoration: underline;
}

:link, :visited {text-decoration: none;}
#controls :active {color: #333 !important;}
#controls :focus {outline: none;}
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

code {padding: 2px 0.25em; font-weight: bold; color: #555;}
code.bad, code del {color: red;}
code.old {color: silver;}
pre {font-size: .7em;
	margin: 0 auto;
	background-color: #f3f3f3;
	border: 1px solid #d5d5d5;
	width: 80%;
	padding: 20px;}
pre code {display: block;}
pre code span {
	font-weight: normal;
	font-size: 0.98em;
}
ul {margin-left: 85px; margin-right: 3%; list-style: disc; padding: 0;}
li {margin-top: 5px; margin-right: 0;}
ul ul {line-height: 1;}
ul ul li {margin: .2em; font-size: 85%; list-style: square;}
p, li {
	line-height: 1.2;
}
img.leader {display: block; margin: 0 auto;}


div#header, div#footer {color: #AAB;
  font-family: Verdana, Helvetica, sans-serif;}
div#header {background: #cc3300;
  line-height: 1px;}
div#footer {font-size: 0.5em; font-weight: bold; padding: 1em 0; color: #666;}
#footer h1, #footer h2 {display: block; padding: 0 1em;}
#footer h2 {margin-top: 0.5em;}

div.long {font-size: 0.75em;}
.slide h1 {position: absolute; top: 0.8em; left: 0; z-index: 1;
  margin-left: 85px; padding: 0; white-space: nowrap;
  font-weight: bold; font-size: 150%; line-height: 1;
  color: #f3f3f3;}
.slide h3 {font-size: 130%;}
h1 abbr {font-variant: small-caps;}

div#controls {position: absolute; z-index: 1; left: 75%; top: 0;
  width: 25%; height: 100%;
  text-align: right;}
#footer>div#controls {position: fixed; bottom: 0; padding: 2em 0;
  top: auto; height: auto;}
div#controls form {position: absolute; bottom: 0; right: 0; width: 100%;
  margin: 0; padding: 0;}
div#controls a {font-size: 2em; padding: 0; margin: 0 0.5em; border: none; color: #f3f3f3; 
  cursor: pointer;}
div#controls a:hover {color: #f3f3f3;}
div#controls select {visibility: hidden; background: #f3f3f3; color: #333;}
div#controls div:hover select {visibility: visible;}

#toggle, #prev, #next {
	display: block;
	width: 35px; height: 35px;
	float: left;
	background: url(button.gif) no-repeat 0 0;
}
#toggle {
	background-image: url(toggle.gif);
}
#toggle span {
	display: none;
}
#next {
	text-align: left;
}

#currentSlide {text-align: center; font-size: 0.5em; color: #666; font-weight: bold;}
#currentSlide span {display: none;}

#slide0 {padding-top: 3.5em; font-size: 90%;}
#slide0 h1 {position: static; margin: 1em 0 1.33em; padding: 5px 0 5px 20px;
   font: bold 2.2em Arial, Verdana, sans-serif; white-space: normal;
   color: #000; background: transparent url(slide0h1.gif) no-repeat left bottom;
	text-transform: none; }
#slide0 h3 {margin-top: 0.3em; font-size: 1.2em;}
#slide0 h4 {margin:0; font-size: 0.9em;}

ul.urls {list-style: none; display: inline; margin: 0;}
.urls li {display: inline; margin: 0;}
.note {display: none;}

acronym {
	font-size: 90%;
}

div.image {
	margin: 0 auto;
	text-align: center;
	background-color: #f3f3f3;
	border: 1px solid #000;
	font-size: 0.66%;
	width: 400px;
	padding: 20px;
}

p { 
	margin-left: 85px;
}

div.image p, #slide0 p {
	margin-left: 0;
}
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
__ui/slide0h1.gif__
R0lGODlhWAJYAvcAAMIxAMwzAPPz8/Pz8wAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAMALAAAAABYAlgC
QAj+AAEIHEhwgMGDCBMqXMiwocOHECNKnEixosWLGDNq3Mixo8ePIEOKHEmyZEiCKAGYXMmypcuX
MGPKnEmzps2bG1MWxMmzp8+fQIMKHUq0qEKdA40qXcq0qdOnUKPmRKpSqtWrWLNq3cq1ItWqXcOK
HUu2rNmVX8+qXcu2rduwad/KnUu3rl2Yce/q3cu3r9+Def8KHky4cNbAhhMrXszYJuLGkCNLnozx
MeXLmDNLtqy5s+fPezmDHk26NFnRplOrXt0UNevXsGM7piq7tu3beGnj3s2791SkvoMLH87QNfHj
yFkbT868ueflzqNLhwx9uvXrgqtj386drvbu4MP+m/0uvrz5w7rPq18vljz79/CBuo9Pv/7M+fbz
6y+Jf7///7/pBOCABKKVXoEIJhhgSgo26KBXBz4o4YQI9UfhhfFZiOGG6mnI4YfheQjiiNiJSOKJ
0ZmI4orIqcjii8G5COOMuMlI442x2YjjjqrpyOOPo/kI5JCaCUnkkZMZieSSjCnJ5JOFOQnllH5J
SeWVd1mJ5ZZyacnll2t5CeaYp0VI5pnUmYnmmomJyeabUbkJ55xMyUnnnUTZieeeP+nJ5583+Qno
oDIJSuihLRmK6KIkKcroox85CumkGklK6aUQAofppk5ZyumnxakJ6qg9eUoqqaaeCmqqqnLKaqv+
mL4KK6WyzgpprbYyimuuiO7KK6G+/gposMLySWyxeB6LLJ3KLgtns86yCW20aE5LLZnWXgtmttpy
yW23WH4LLpXijgtlueYyiW66SK7LLpHuvgtkvPLySG+9ON6LL4367gtjv/6yCHDAKA5MMIkGHwxi
wgpzyHDDGD4MMYUSTyxhxRY7iHHGCm7MMYIef0xgyCIDSHLJ/p2Msn4qr2xfyy7TB3PM8M1MM3s2
39yhqDq7ynPPsf4MNK1CD31r0UbrinTSvS7NNLBOPz1s1FIbS3XVyV6NNbNab/1s115LC3bY1Y5N
NrZmn71t2mp7y3bb4b4NN7lyz31u3Xari3f+3u3uzTe8fv89b+CC20t44fkejji/ii8OYwCQRy65
43RKbnkAlM95+eSZv7l55J17/jnmoa85Oumln3l66miuzjqZrr8OZuyyu/157bOPjvuXtO9O9+2+
Y9l78E8OT/ySxh9/ZPLKD8l88z8+D/2O0k9/Y/XWz4h99i9uz/2K3n9/Yvjij0h++R+ej/6G6q9/
YfvuTwh//A/OT3+D9t+fYP76F8h//wP6HwD/I8AB7qeABswPAhNYnwUyMD4OfOB7IijB9VCwgue5
IAbLo8ENhqeDHuwOCEO4nRGS8DomPOF0UqjC6LCwhc15IQyTI8MZHqeGNhwODnMYnB3ysDf+Pvzh
boIoxNsQsYi1OSISY6PEJb6miU5cjUCAF0X9QLGKprkiFkmjxS2Cpote9AwYw6iZMZIRM2Y8I2XS
qEbJsLGNkHkjHBkjxzkqpo52NAwe80iYPfJRMH78o18CKUi+ELKQejkkIu2iyEXSpZGOlAskI+mW
SVKSLZa8pFoyqUmzcLKTZPkkKMUiylF2pZSm3AoqU5mVVbLyKq58pVRiKUuo0LKWTrklLpmiy10q
pZe+LAowgzmUYRIzKMY85k+SqcyeMLOZOHkmNG0izWnSpJrWlAk2swmTbXLTJd78JkvCKU6TTHFz
5Xyi7tK5GnKyUyTufCdI4ilPj9Cznhz+uSc+NaLPfWKkn/60CEADSpGBElQiBj0oRBKqUIcwtKEM
eShEFSLRiSKkohY1CEYzulGLdnSiH4VoSBs6UoWW9KAnJWhKA7pSf7Z0ny/FZ0zrOVN51vSdN2Vn
TtO503L2VJw//WZQuXm6ohr1qEhNqlKXytSmOvWpUI2qVKdK1apa9apYzapWt8rVriY1Zxld6DrD
GhmwkrUhQ82mWc+6kLRac61sTYhbpwnXuB5krtCsq10HgNdm6tWufVXmX+Ma2GMOlq2FJeZhz5rY
YC6WrOe83F4X89iwNtaXleXoWCcbpcZxFiuRtdxnDZNZj252tH8pLUhPi9q+qFakrG3+bWg8K9un
XHaXryVpbGtrl9yadLe89Q5tg7uU2+LStygFLnHfglyVKne5bWkuS58L3TANt7rFpC52x3Pd7QLF
uLWUrku1692xiBem5C0vXLqrXp6AV5bnlWl627uV+NJ0vvRFj6byu5b3vtK+NsUvf60CYJwKeMBx
Yi+CtXngBXdKwQ5+iX9ZWWCdNjjCS6kwTy+MYaNo2Kcc7nCeICxik0w4lR8GaohLHJQUC3XFLO4T
iWMMTxjTmCcuJqqNbxyoGfPYnjv+MU1ynM0Tm5LI1jTyKJE8TSWDksnQdHInodxMKWuSysq08iWx
fEwtU5LLxPRyJMEcTDE7ksy+NPP+ItG8SzUjks24dHMh4VxLOQuSzrK08x/x/Eo985HPrPRzHgGd
SkHbkdBHBgAVhZzg/TLalkF+dG4cLemmGHqOiB7lpeGYaVBuuo2d7uSn1RhqTY76jKW+5KnJmGpK
rjqMrY7kq70Ya0fOeou1XuStsZhrRO66ir0u5K+jGGxBDtuJxf7jsZeYbD4uG4nNzuOzixhtO05b
iNWe47V/mG04bpuH3W7jt3MYbjWO24blPuO5Z5huMq4bhu0O47tbGG8vzluF9d7ivU+Ybyzum4T9
ruK/QxjwKA7cgwV34sE3mPAlLhyDDUfiwysY8SJOXIIVF+LFH5jxH26cgR3n4cf+ExjyHI7cgCW3
4ckHmPIZrhyALYfhy/sX8xbOXH81V+HN75fzE+6cfj0n4c/jF/QQDt19Rffg0deX9A0uHX1Nh7ii
0Vnpp0S9gk8v39UlmHXxbf2BXf/e1xkYdu6NPYFlz97ZDZh26619gG2f3tsBGHfozb1/dW/e3fWX
d+Xt/X59P97f6Rd44g0+foUP3uHdl3jfLX59jd/d49EXedxNvnyVr93lxZd52W3+e51/3ee5F3rW
jT57pU/d6a2X+tKtfnqtD93roRf7zs2+ebXP3O2Vl3vK7f54vXfc74kX/MUNP3jFR9zxfZf8wi1/
d80X3PNxF/2/Tb921efb9WUtl/28bf913bfb91kX/rmNP3Xlh9v5S+fV9rv//fCPv/znT//62//+
+M+/5QICADs=
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
	'<a accesskey="t" id="toggle" href="javascript:toggle();"><span>&#216;<\/span><\/a>' +
	'<a accesskey="z" id="prev" href="javascript:go(-1);"><span>&laquo;<\/span><\/a>' +
	'<a accesskey="x" id="next" href="javascript:go(1);"><span>&raquo;<\/span><\/a>' +
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
__ui/toggle.gif__
R0lGODlhIwAjAPcAAEj+AMIxAMMzA8M2B8Q5CswzAMw1A804B84+Ds9BEtBEFslPJcpSKc1cNdJQ
JdRcNM5hPM9kQNdoQ9FtS9huS9JwT9hwTdNzU9R5W9V8Xtl1U9t7W9t+XtZ/YtyEZt2HatiIbt+Q
dd2bhN2cht6hjOGchOGqmOGrmOKvnuSrmOWum+axn+a0o+a1pOa/subAs+nBtOrHu+rHvOnKwOzP
xevSyevVzezY0e3b1e/e2O7h3O/h3O/i3e/i3vDk4PDm4/Ho5fDo5vHr6fHt6/Lt6/Lu7PLx8PPy
8vPz80j+AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAEkALAAAAAAjACMA
QAj+AJMITBKgoMGDCBMmHEhQocODSCJKRJLhocEaESNYTAghYo2NAS5EDLIA5IIgESsobAiy5UKX
MEFikAjiocQZEjuAtBGRQUwGEW3ErKBjolEkOlRaTFKgqdOnUKNKhcp0qtWrWJ0mkPDgqlEgCrIW
oBBRSFirLFoYKIAASEQNWCWKhSr3KlkkNOY2pRGRgtgDMspumMqhSMQYa/Uqxspw8VWGAh2LHRiz
clXJcysbPIrEiNKDmI+GmKrQhZEhE2wafSFAIVQDOSKu8IpEbYmIPA5ERWgiIomNAloXFBHRREKo
RCImUIwgIpHdB4dEFO5yQMQhx5+miOhB8YeIKaBGGxSAI+IFlyKR3KBuUKqKiDscXHXgI6IK0goH
oJCoY0QDAgQ0MEIPEp3AHkJYGWABDD8cEdERP8BgQWKPaQbTQJgxlkRAAAA7
