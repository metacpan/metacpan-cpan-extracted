package Spork::S5ThemeBlue;
use Spork::S5Theme -Base;
use strict;

our $VERSION = '0.03';

__DATA__

=head1 NAME

  Spork::S5ThemeBlue - Blue Theme for Spork::S5

=head1 DESCRIPTION

Blue Theme for Spork::S5 written by Martin Hense

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
/* Blue Theme 2004 by Martin Hense ::: www.lounge7.de */

/* Following are the presentation styles -- edit away!
   Note that the 'body' font size may have to be changed if the resolution is
    different than expected. */

body {background: #000294 url(bluebottom.gif) right bottom no-repeat; color: #fff; font-size: 1.8em;}
:link, :visited {text-decoration: none; color: #F8B73E;}
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

code {padding: 2px 0.25em; font-weight: bold; color: #AAABF8;}
code.bad, code del {color: red;}
code.old {color: silver;}
pre {padding: 0; margin: 0.25em 0 0.5em 0.5em; color: #533; font-size: 90%;}
pre code {display: block;}
ul {margin-left: 5%; margin-right: 7%; list-style: disc;}
li {margin-top: 0.75em; margin-right: 0;}
ul ul {line-height: 1;}
ul ul li {margin: .2em; font-size: 85%; list-style: square;}
img.leader {display: block; margin: 0 auto;}

div#header, div#footer {background: #005; color: #9183BF;
  font-family: Verdana, Helvetica, sans-serif;}
div#header {background: #005 url(bodybg.gif) -16px 0 no-repeat;
  line-height: 1px;}
div#footer {font-size: 0.5em; font-weight: bold; padding: 1em 0; height: 36px; border-top: 1px solid #08093F; background: #000136 url(bluefooter.gif) top right no-repeat; }
#footer h1, #footer h2 {display: block; padding: 0 1em;}
#footer h2 {font-style: italic;}

div.long {font-size: 0.75em;}
.slide {
	font-family: georgia, Times, 'Times New Roman', serif;
  background: transparent url(bluebg.gif) repeat-x;
}
.slide h1 {position: absolute; left: 87px; z-index: 1;
 white-space: nowrap;
 text-transform: capitalize;
 top: 1em; width: 80%;
 margin: 0 auto; text-align: center; padding: 0;
 font: 150%/1em georgia, Times, 'Times New Roman', serif;
 color: #fff; background: transparent;  
 }
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
  background: transparent; color: #9183BF;
  }
div#controls select {visibility: hidden; background: #DDD; color: #227;}
div#controls div:hover select {visibility: visible;}

#currentSlide {text-align: center; font-size: 0.5em; color: #9183BF; font-family: Verdana, Helvetica, sans-serif;}

#slide0 {padding-top: 3.5em; font-size: 90%;}
#slide0 h1 {position: static; margin: 1em 0 1.33em; padding: 0;
   white-space: normal;
   background: transparent;
margin: 0 auto; width: 75%; text-align: center;
   font: 2.5em Georgia, Times, 'Times New Roman', serif; height: 281px;
   color: #fff;}
#slide0 h3 {font-size: 1.5em;}
#slide0 h4 {font-size: 1em;}
#slide0 h3, #slide0 h4, #slide0 p {margin: 0; text-align: center; color: #fff;}
#slide0 p {margin-top: 0.7em;}

ul.urls {list-style: none; display: inline; margin: 0;}
.urls li {display: inline; margin: 0;}
.note {display: none;}
__ui/print.css__
/* Blue Theme 2004 by Martin Hense ::: www.lounge7.de */

/* Following are the presentation styles -- edit away!
   Note that the 'body' font size may have to be changed if the resolution is
    different than expected. */

body {background: #000294 url(bluebottom.gif) right bottom no-repeat; color: #fff; font-size: 1.8em;}
:link, :visited {text-decoration: none; color: #F8B73E;}
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

code {padding: 2px 0.25em; font-weight: bold; color: #AAABF8;}
code.bad, code del {color: red;}
code.old {color: silver;}
pre {padding: 0; margin: 0.25em 0 0.5em 0.5em; color: #533; font-size: 90%;}
pre code {display: block;}
ul {margin-left: 5%; margin-right: 7%; list-style: disc;}
li {margin-top: 0.75em; margin-right: 0;}
ul ul {line-height: 1;}
ul ul li {margin: .2em; font-size: 85%; list-style: square;}
img.leader {display: block; margin: 0 auto;}

div#header, div#footer {background: #005; color: #9183BF;
  font-family: Verdana, Helvetica, sans-serif;}
div#header {background: #005 url(bodybg.gif) -16px 0 no-repeat;
  line-height: 1px;}
div#footer {font-size: 0.5em; font-weight: bold; padding: 1em 0; height: 36px; border-top: 1px solid #08093F; background: #000136 url(bluefooter.gif) top right no-repeat; }
#footer h1, #footer h2 {display: block; padding: 0 1em;}
#footer h2 {font-style: italic;}

div.long {font-size: 0.75em;}
.slide {
	font-family: georgia, Times, 'Times New Roman', serif;
  background: transparent url(bluebg.gif) repeat-x;
}
.slide h1 {position: absolute; left: 87px; z-index: 1;
 white-space: nowrap;
 text-transform: capitalize;
 top: 1em; width: 80%;
 margin: 0 auto; text-align: center; padding: 0;
 font: 150%/1em georgia, Times, 'Times New Roman', serif;
 color: #fff; background: transparent;  
 }
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
  background: transparent; color: #9183BF;
  }
div#controls select {visibility: hidden; background: #DDD; color: #227;}
div#controls div:hover select {visibility: visible;}

#currentSlide {text-align: center; font-size: 0.5em; color: #9183BF; font-family: Verdana, Helvetica, sans-serif;}

#slide0 {padding-top: 3.5em; font-size: 90%;}
#slide0 h1 {position: static; margin: 1em 0 1.33em; padding: 0;
   white-space: normal;
   background: transparent;
margin: 0 auto; width: 75%; text-align: center;
   font: 2.5em Georgia, Times, 'Times New Roman', serif; height: 281px;
   color: #fff;}
#slide0 h3 {font-size: 1.5em;}
#slide0 h4 {font-size: 1em;}
#slide0 h3, #slide0 h4, #slide0 p {margin: 0; text-align: center; color: #fff;}
#slide0 p {margin-top: 0.7em;}

ul.urls {list-style: none; display: inline; margin: 0;}
.urls li {display: inline; margin: 0;}
.note {display: none;}
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
__ui/bluebg.gif__
R0lGODlhtQCZANUlAAAAAQABTQABKQACdQAAFQABYQABPQACiQAADQABWQABNgACggAAIgABbgAB
RgACkgAACgABVgABMgACfgAAHgABagAABgABUgABLgACegAAGgABZgABQgACjgAAEgABXgABOgAC
hgAAJQACcgABSgAClAACbwABJgAAAwABTwABKwACdwAAFwABYwABPwACiwAADwABWwAAAAAAAAAA
AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACwAAAAAtQCZAAAG/0CAcEgsGo/IpHLJ
bDqf0Kh0Sq1ar9isdsvter/gJ2pMLpvP6LR6zW673/C4fE6v2+/4vH7Ptvj/gIGCg4SFhoeIiYqL
jI2Oj5CRkpOUlZaXmJmam5yLEJ+goaKjpKWmp6ipqqusra6vsLGys7S1tre4ubq7vL2+v8DBwrII
xcbHyMnKy8zNzs/Q0dLT1NXW19jZ2tvc3d7f4OHi49Iw5ufo6err7O3u7/Dx8vP09fb3+Pn6+/z9
/u8eAgocSLCgwYMIEypcyLChw4cQI0qcSLGixYsYM2rcyLGjx48OCYgcSbKkyZMoU6pcybKly5cw
Y8qcSbOmzZs4c+rcybOnz/+fQF+yGEq0qNGjSJMqXcq0qdOnUKNKnUq1qtWrWLNq3cpUg9evYMOK
HUu2rNmzaNOqXcu2rdu3cOPKnUu3rt27ePPq3ct3LYW/gAMLHky4sOHDiBMrXsy4sePHkCNLnky5
suXLmDNr3sy5s+fPoEOLlsygtOnTqFOrXs26tevXsGPLnk27tu3buHPr3s27t+/fwIMLH068uPHj
yHGLWM68ufPn0KNLn069uvXr2LNr3869u/fv4MOLH0++vPnz6NNjP8G+vfv38OPLn0+/vv37+PPr
38+/v///AAYo4IAE1ifAgQgmqOCCDDbo4IMQRijhhBRWaOGFGGao4YYcduj/4YcghijiiCSWSKEK
KKao4oostujiizDGKOOMNNZo44045qjjjjz26OOPQMaIwZBEFmnkkUgmqeSSTDbp5JNQRinllFRW
aeWVWGap5ZZcdunll2CGCaUEZJZp5plopqnmmmy26eabcMYp55x01mnnnXjmqeeefPbp55+ABiro
oIQWauihdyqg6KKMNuroo5BGKumklFZq6aWYZqrpppx26umnoIYq6qiklmrqqaimquqqrLbq6quw
xiqroiDUauutuOaq66689urrr8AGK+ywxBZr7LHIJqvsssw26+yz0EYr7bTCGmDttdhmq+223Hbr
7bfghivuuOSWa+656Kar/+667Lbr7rvwxivvvPSO68K9+Oar77789uvvvwAHLPDABBds8MEIJ6zw
wgw37PDDAHMg8cQUV2zxxRhnrPHGHHfs8ccghyzyyCSXbPLJKKes8sost+zyyzB/7MDMNNds8804
56zzzjz37PPPQAct9NBEF2300UgnrfTSTDft9NNQRy311FRXbfXVWGet9dYzk+D112CHLfbYZJdt
9tlop6322my37fbbcMct99x012333XjnrffefK8dwN+ABy744IQXbvjhiCeu+OKMN+7445BHLvnk
lFdu+eWYZ6755px3zngKoIcu+uikl2766ainrvrqrLfu+uuwxy777LTXbv/77binfsHuvPfu++/A
By/88MQXb/zxyCev/PLMN+/889BHL/301Fdv/fXYZ498BNx37/334Icv/vjkl2/++einr/767Lfv
/vvwxy///PTXb//9+Oev//789+///+9LgAAHSMACGvCACEygAhfIwAY68IEQjKAEJ0jBClrwghjM
oAY3yMEOevCDIHxgDEZIwhKa8IQoTKEKV8jCFrrwhTCMoQxnSMMa2vCGOMyhDnfIwg/48IdADKIQ
h0jEIhrxiEhMohKXyMQmOvGJUIyiFKdIxSpa8YpYzKIWt8jFJRbgi2AMoxjHSMYymvGMaEyjGtfI
xja68Y1wjKMc50jHOtr/8Y54zKMe98jHPrKxBYAMpCAHSchCGvKQiEykIhfJyEY68pGQjKQkJ0nJ
SlrykphM5AY2yclOevKToAylKEdJylKa8pSoTKUqV8nKVrrylbCMpSxnScta2vKWuMwlKivAy176
8pfADKYwh0nMYhrzmMhMpjKXycxmOvOZ0IymNKdJzWpa85rYzKY2t8nNbnrzm89sgDjHSc5ymvOc
6EynOtfJzna6853wjKc850nPetrznvjMpz73yc9++vOfAA2oQAdK0ILW0wQITahCF8rQhjr0oRCN
qEQnStGKWvSiGM2oRjfK0Y569KMgjegIRkrSkpr0pChNqUpXytKWuvSl/zCNqUxnStOa2vSmOM2p
TnfK05769KdADSpMB0DUohr1qEhNqlKXytSmOvWpUI2qVKdK1apa9apYzapWt8rVrnr1q2ANq1ij
uoKymvWsaE2rWtfK1ra69a1wjatc50rXutr1rnjNq173yte+ujUDgA2sYAdL2MIa9rCITaxiF8vY
xjr2sZCNrGQnS9nKWvaymM2sZjfL2c56trETCK1oR0va0pr2tKhNrWpXy9rWuva1sI2tbGdL29ra
9ra4za1ud8vb3vr2t8ANrnCHS1zaLuC4yE2ucpfL3OY697nQja50p0vd6lr3utjNrna3y93ueve7
4A2veMdL3vKa97zoTf+vetfL3va6973HDYF850vf+tr3vvjNr373y9/++ve/AA6wgAdM4AIb+MAI
TrCCF8zgBjv4wRD+7wEmTOEKW/jCGM6whjfM4Q57+MMgDrGIR0ziEpv4xChOsYpXzOIWu/jFMI4x
iF9A4xrb+MY4zrGOd8zjHvv4x0AOspCHTOQiG/nISE6ykpfM5B534MlQjrKUp0zlKlv5yljOspa3
zOUue/nLYA6zmMdM5jKb+cxoTrOa18zmNnP5AXCOs5znTOc62/nOeM6znvfM5z77+c+ADrSgB03o
Qhv60IhOtKIXzehGO/rRkI60pCc96BJY+tKYzrSmN83pTnv606AOtagcR03qUpv61KhOtapXzepW
u/rVsI61rGdN61EHAQA7
__ui/bluebottom.gif__
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
oRZaoAkAADs=
__ui/bluefooter.gif__
R0lGODlhWQJBAKIEAAAAKwAAMQAALQAANQABNgAAAAAAAAAAACwAAAAAWQJBAAAD/0i63K4ByEmr
veDpzbv/YCiOZGmeaKqubOu+cCzPcYTdODDQfO//wKBwSCwaj8iFLcekBJLQqHRKrVqvWOOy2Xxm
v+CweEwumztbLnN3brvf8Lh8zhio1V66fs/v+/8od2qAhIWGh4hjAoJdiY6PkJGSLGmMGGyTmZqb
nIeVlhZ5naOkpaZgdqA5oqetrq+wNIuqOJixt7i5uhuftBS2u8HCw6OpvjfAxMrLzISzx5fN0tPU
cL3QEqzV29zdUdg42t7j5OUy1+AByebs7e4h4Kvv8/T1DOjx6vb7/OTP8RjE9RtIMJgxgBgECCzI
sOEpfAgVOpxIsRTEiAsratwIaP/AP4Th1nEcSVLOQZA5JJZcydLNSZSrMracSRPKS5irRNbcyTOI
R5yCAujrSbQoj59ABSnUabSp0xEXk14QyvSp1av3pNJSOBSrV69Itari2vWr2aJRxTIhW/WsW40D
0qrlQrbs27sU486FWXdAW7yA2endK1VAXXV/AytuNpiwY8NCI0f2m3ix5VYBPjrejMOwZ8hCL4su
FVcz59MVuFYezdpRadSoVbeeDStuZthJ2a6mzXuTbdO4lbLtTZyZ7dvBE/Ytztzb8czAcYKevLu5
9Wp+JUv+zL27du1+r4sfT768+fPo06tfz769+/fw48ufT7++/fv48+vfz7+///8cAAYo4IAEFmjg
gQgmqOCCDDbo4IMQRijhhMQkAAA7
