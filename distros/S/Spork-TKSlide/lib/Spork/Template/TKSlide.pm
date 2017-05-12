package Spork::Template::TKSlide;
use strict;
use warnings;
use Spork::Template::TT2 '-base';
our $VERSION = '0.01';

1;
__DATA__
__start.html__
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>[% slide_heading %]</title>
<meta name="generator" content="[% spork_version %]">
<link rel="stylesheet" type="text/css" href="[% style_file %]">
<link rel="alternate" type="text/css" href="slide-zen.css">
<link rel="alternate" type="text/css" href="slide-tkirby.css">
</head>
<body>

[% allpage_content %]

<script type="text/javascript" src="controls.js"></script>

</body>
</html>

__slide.html__
<!-- BEGIN slide.html -->
<div class="page" id="[% slide_name %]">
<div class="headline">[% slide_heading %]</div>
<div class="content">
[% image_html %]
[% slide_content %]
</div>
</div>
<!-- END slide.html -->
__controls.js__
/* TKSLIDE(javascript part), official site: http://www.csie.ntu.edu.tw/~b88039/slide/ */
 /* version: 2004.05.03 */
 var	pcount		= 0;		/* page count */
 var	pages		= null;		/* page list */
 var	cpage		= 0;		/* current page */
 var	opage		= 0;		/* previous page */
 var	pagedisplay	= null;		/* the panel show current page */
 var	cpanel		= null;
 var	gopage		= "";
 var	spagetimer	= null;
 var	hidetimer	= null;
 var	showtimer	= null;

 var	hcomp		= null;
 var	hcompp		= 0;
 var	scomp		= null;
 var	scompp		= 0;
 var	falldowner	= null;

 var	index		= null;
 var	indexshow	= 0;
 var	indexshower	= 0;
 var	escflag		= 0;
 var	cstyle		= -1;
 var	stylelinks	= null;

/* ========== Default plugin functions ========== */
 function fade_in(position)
 {
  pages[cpage].style.filter	= "alpha(opacity="+position+")";
  position+=10;
  if(position<100) spagetimer	= setTimeout("fade_in("+position+");", 10);
  else pages[cpage].style.filter= "";
 }

 function slip_in(position)
 {
  pages[cpage].style.left	= position+"%";
  position+=10;
  if(position<10) spagetimer	= setTimeout("slip_in("+position+");", 10);
  else pages[cpage].style.left	= "";
 }

 function fall_down(v, a)
 {
  v				= v+a;
  a				= a+0.8;
  if(v<0) {
   hcompp.style.top		= v+"px";
   setTimeout("fall_down("+v+", "+a+");", 10);
  } else { 
   hcompp.style.top		= "";
   hcompp			= hcompp.nextHide;
   falldowner			= 0;
  }
 }

 function _showIndex(v)
 {
  v			= v+(!indexshow?25:-25);
  index.style.top	= v+"px";
  if((!indexshow?v<0:v>-404)) setTimeout("_showIndex("+v+");", 10);
  else { indexshower	= 0;
   index.style.top	= (indexshow?"-404px":"0px");
   index.childNodes[0].style.visibility = (indexshow?"hidden":"visible");
   indexshow		= 1 - indexshow;
  }
 }

 function showIndex()
 {
  if(indexshower) return;
  indexshower		= 1;
  if(!indexshow)
   index.childNodes[0].style.visibility = (indexshow?"hidden":"visible");
  setTimeout("_showIndex("+(indexshow?0:-404)+");", 10);
 }

 function func_parse(str)
 {
  var	i;
  var	k;
  var	s	= 0;
  var	e	= 0;
  var	sf	= 0;
  var	c;
  var	d;
  var	argc	= -1;
  var	argv	= null;
  for(i=0, c=0, d=0, e=0, k=0;i<str.length;i++) {
   if(str.charAt(i)!=' ' && sf==0) { sf=1; s=i; }
   if(str.charAt(i)=='\'') c		= 1-c;
   if(str.charAt(i)=='"') d		= 1-d;
   if(str.charAt(i)==')' && e==1 && c==0 && d==0) e = 0;
   if(str.charAt(i)!=' ' && e==1) { argc++; e=-1;}
   if(str.charAt(i)=='(' && e==0) e	= 1;
   if(str.charAt(i)==',' && c==0 && d==0) argc++;
   if(str.charAt(i)==';' && c==0 && d==0) { k=1, e=i; break; }
  } if(k==0) e= str.length;
  argv	= new Array(argc+3);
  argv[0]	= str.substring(s, str.indexOf("("));
  for(k=1, c=0, d=0, sf=0, i=str.indexOf("(")+1;i<e;i++) {
   if(str.charAt(i)!=' ' && sf==0) {sf=1, s=i;}
   if(str.charAt(i)=='\'') c	= 1-c;
   if(str.charAt(i)=='"') d	= 1-d;
   if((str.charAt(i)==',' || str.charAt(i)==' ' || str.charAt(i)==')') 
       && c==0 && d==0) {
    var	narg	= str.substring(s, i);
    if(s!=i) {
     sf		= 0;
     if(narg.charAt(0)=='"' || narg.charAt(0)=='\'') 
      narg=narg.substring(1, narg.length-1);
     argv[k++]	= narg;
    }
   } argv[k]	= e;
  } return argv;
 }

 function get_allhide(node, tpage)
 {
  var	i;
  var	argv;
  var str		= node.title;
  if(str) {
   while(str) {
    argv		= func_parse(str);
    str			= str.substring(argv[argv.length-1]+1);
    if(argv[0]=="hide") {
     node.showid	= (argv.length>=3?parseInt(argv[1]):0);
     node.hideid	= (argv.length>=4?parseInt(argv[2]):-1);
     node.display	= (argv.length>=5?parseInt(argv[3]):0);
     if(node.showid<-1) node.showid=-1;
     if(node.hideid<node.showid) node.hideid=-1;
     if(node.showid) {
      var ptr		= hcomp[tpage];
      var pptr		= null;
      while(ptr) {
       if(ptr.showid>node.showid) {
        if(!pptr) {
	 node.nextHide	= hcomp[tpage];
	 hcomp[tpage]	= node;
	 break;
	} else { 
	 node.nextHide	= pptr.nextHide;
	 pptr.nextHide	= node;
	 break;
	}
       } else if(ptr.showid==node.showid) {
        node.simuHide	= ptr.simuHide;
        ptr.simuHide	= node;
	break;
       } pptr		= ptr;
       ptr		= ptr.nextHide;
      }
      if(!ptr) { 
       if(pptr) {node.nextHide = pptr.nextHide; pptr.nextHide = node; }
       else { node.nextHide = hcomp[tpage]; hcomp[tpage] = node; }
      }
     } else {
      node.nextHide	= hcomp[tpage]; 
      hcomp[tpage]	= node;
     }
    }
    delete argv;
   } return;
  } else for(i=node.childNodes.length-1;i>=0;i--) { 
   get_allhide(node.childNodes[i], tpage);
  }
 }

 function showHider()
 {
  var	node;
  var	ptr			= hcompp;
  while(ptr) {
   //ptr.style.position		= "relative";
   //ptr.style.top		= "-300px";
   if(ptr.display) {
    if(ptr.nodeName=="img" || ptr.nodeName=="IMG") ptr.style.display = "inline";
    else ptr.style.display = "block";
   } else ptr.style.visibility	= "visible";
   ptr				= ptr.simuHide;
  } node			= hcomp[cpage];
  while(node) {
   ptr				= node;
   while(ptr) {
    if(ptr.hideid<=hcompp.showid && ptr.hideid>=0) {
     if(ptr.display) ptr.style.display = "none";
     else ptr.style.visibility	= "hidden";
    } else break;
    ptr				= ptr.simuHide;
   } node			= node.nextHide;
  } hcompp			= hcompp.nextHide;
  //falldowner			= 1;
  //setTimeout("fall_down(-300, 1);", 10);
 }

 function hideHider(tpage)
 {
  var	ptr			= null;
  var	node			= hcomp[tpage];
  var	sstr;
  while(node) {
   ptr				= node;
   while(ptr) { if(ptr.showid>=0) 
    sstr			= (ptr.display?"none":"hidden");
    else sstr			= (ptr.display?"block":"visible");
    if(ptr.showid<0 && (ptr.nodeName=="img" || ptr.nodeName=="IMG") && ptr.display)
     sstr = "inline";
    if(ptr.display) ptr.style.display = sstr; else ptr.style.visibility = sstr;
    ptr				= ptr.simuHide;
   }
   node				= node.nextHide;
  } hcompp			= hcomp[tpage];
  if(hcompp) while(hcompp.showid<0) {
   hcompp	= hcompp.nextHide;
   if(!hcompp) break;
  }
 }

 function keyparser(e)
 {
  var eve		= (e?e:event);
  var code		= (eve.charCode?eve.charCode:eve.keyCode);
  //alert(code);
  if(code>47 && code<58) { // number
   gopage		= gopage+(code-48);
   pagedisplay.childNodes[0].nodeValue	= "p. "+gopage+"_";
  }
  if(code==32) {
   if(gopage!="") {
    var	gpage			= parseInt(gopage);
    gopage			= "";
    if(isNaN(gpage)) gpage	= cpage;
    if(gpage<1) gpage		= 1;
    if(gpage>pcount) gpage	= pcount;
    change_page(gpage-1);
   } else if(hcompp) { if(!falldowner) showHider(); }
   else change_page(cpage+1);
  }
  if(code==27) {
   cpanel.style.display	= (escflag?"block":"none");
   if(index) index.style.display	= (escflag?"block":"none");
   escflag		= 1-escflag;
  }
  if(code==73) showIndex();
  if(code==40 || code==39) change_page(cpage+1);
  if(code==37 || code==38) change_page(cpage-1);
  if(code==192) change_page(opage);
  if(code==34) change_page(cpage+5);
  if(code==33) change_page(cpage-5);
  if(code==36) change_page(0);
  if(code==35) change_page(pcount-1);
 }

/* ========== Style Manipulating functions ========== */
 function setNextStyle() { change_style(cstyle+1); }

 function change_style(style_number)
 {
  if(stylelinks.length<=0) return;
  if(style_number>stylelinks || style_number<0) return;
  if(cstyle<stylelinks.length) {
   stylelinks[cstyle].disabled		= true; 
   stylelinks[cstyle].rel		= "alternate";
  }
  cstyle				= style_number;
  if(cstyle>=stylelinks.length) cstyle	= 0; 
  if(cstyle<stylelinks.length) {
   stylelinks[cstyle].disabled		= false;
   stylelinks[cstyle].rel		= "stylesheet";
  } 
  setCookie("capge", cpage);
  setCookie("cstyle", cstyle);
 }

/* ========== Page manipulating functions ========== */
 function show_page(tpage, visible)
 {
  if(cpage==tpage && visible==0) return;
  if(visible) {
   //pages[cpage].style.filter	= "filter(opacity=0)";
   //if(spagetimer) clearTimeout(spagetimer);
   //spagetimer		= setTimeout("slip_in(-100)", 10);
   //spagetimer		= setTimeout("fade_in(0)", 10);
   //pages[cpage].style.left	= "-100%";
  }
  pages[tpage].style.display	= (visible?"block":"none");
  pages[tpage].style.zIndex	= (visible?visible:0);
  if(visible) {
   pagedisplay.childNodes[0].nodeValue	= "p. "+(tpage+1)+(tpage==pcount-1?"e":"");
   hideHider(tpage);
  } else hidetimer		= null; 
 }

 function change_page(page_number)
 {
  if(page_number<0 || page_number>=pcount || cpage==page_number) {
   pagedisplay.childNodes[0].nodeValue	= "p. "+(cpage+1)+(cpage==pcount-1?"e":"");
   return;
  }
  show_page(page_number, 1);
  opage			= cpage;
  cpage			= page_number;
  gopage		= "";
  hidetimer = setTimeout("show_page("+opage+", 0);", 10);  // prevet page blink //
  setCookie("cpage", cpage);
  setCookie("cstyle", cstyle);
 }

/* ========= Cookie functions =========== */
 function setCookie(CookieName, value)
 {
  document.cookie	= CookieName+"="+value;
 }
 
 function getCookie(CookieName, defval)
 {
  var	retval		= defval;
  if(document.cookie) {
   var	i		= 0;
   var	cookie		= document.cookie;
   var	acookie		= cookie.split(";");
   var	bcookie		= null;
   var	limitloop	= 0;
   for(i=0;i<acookie.length;i++) {
    bcookie		= acookie[i].split("=");
    if(bcookie[0].indexOf(CookieName)>=0) retval = parseInt(bcookie[1]);
  }} eval(CookieName+"=(isNaN(retval)?defval:retval);");
  return (isNaN(retval)?defval:retval);
 }

/* ========== Initializer functions ========== */
 function initialIndex()
 {
  var	i;
  var	j;
  var	length;
  var	anchor;
  var	div
  var	title;
  var	clone;
  var	text;
  if(!(index=document.getElementById("index"))) return;
  anchor		= document.createElement("a");
  anchor.href		= "#";
  length		= index.childNodes.length;
  for(i=0, j=0;i<length;i++) 
  if(index.childNodes[i].nodeName=="div" || index.childNodes[i].nodeName=="DIV") {
   clone		= anchor.cloneNode(0);
   text			= index.childNodes[i].childNodes[0];
   index.childNodes[i].removeChild(text);
   clone.appendChild(text);
   clone.onclick	= new Function("change_page("+j+");");
   index.childNodes[i].appendChild(clone);
   j++;
  }
  anchor		= document.createElement("a");
  anchor.href		= "#";
  anchor.onclick	= showIndex;
  anchor.appendChild(document.createTextNode("- Index -"));
  title			= document.createElement("div");
  title.appendChild(anchor);
  title.className	= "indexTitle";
  div			= document.createElement("div");
  div.className		= "indexPanel";
  div.style.top		= "-404px";
  index.parentNode.removeChild(index);
  div.appendChild(index);
  div.appendChild(title);
  document.body.appendChild(div);
  index			= div;
 }

 function initialControlPanel()
 {
  var	i, j;
  var	links		= document.getElementsByTagName("link");
  cpanel		= document.getElementById("ctrl_panel");
  for(i=0, j=0;i<links.length;i++) if(links[i].rel=="alternate") j++;
  stylelinks		= new Array(j);
  for(i=0, j=0;i<links.length;i++) if(links[i].rel=="alternate") 
   stylelinks[j++] = links[i];
  if(cstyle<0) cstyle	= stylelinks.length;
  if(!cpanel) {
   var anchor;
   cpanel		= document.createElement("div");
   cpanel.id		= "ctrl_panel";
   cpanel.className	= "cpanel";
   cpanel.style.zIndex	= 2;
   anchor		= document.createElement("a");
   anchor.href		= "#";
   anchor.onclick	= setNextStyle;
   anchor.appendChild(document.createTextNode("S"));
   cpanel.appendChild(anchor);
   cpanel.appendChild(document.createTextNode(" / "));
   anchor		= document.createElement("a");
   anchor.href		= "#";
   anchor.onclick	= new Function("change_page(0);");
   anchor.appendChild(document.createTextNode("<<"));
   cpanel.appendChild(anchor);
   cpanel.appendChild(document.createTextNode(" / "));
   anchor		= document.createElement("a");
   anchor.href		= "#";
   anchor.onclick	= new Function("change_page(cpage-1);");
   anchor.appendChild(document.createTextNode("<"));
   cpanel.appendChild(anchor);
   cpanel.appendChild(document.createTextNode(" / "));
   anchor		= document.createElement("a");
   anchor.href		= "#";
   anchor.onclick	= new Function("change_page(cpage+1);");
   anchor.appendChild(document.createTextNode(">"));
   cpanel.appendChild(anchor);
   cpanel.appendChild(document.createTextNode(" / "));
   anchor		= document.createElement("a");
   anchor.href		= "#";
   anchor.onclick	= new Function("change_page(pcount-1);");
   anchor.appendChild(document.createTextNode(">>"));
   cpanel.appendChild(anchor);
   cpanel.appendChild(document.createTextNode(" | "));
   anchor		= document.createElement("span");
   anchor.className	= "pagedisplay";
   anchor.id		= "pagedisplay";
   pagedisplay		= anchor;
   anchor.appendChild(document.createTextNode("p. "+(cpage+1)+(cpage==pcount-1?"e":"")));
   cpanel.appendChild(anchor);
   anchor		= document.createElement("span");
   anchor.className	= "hider";
   anchor.id		= "hider";
   anchor.appendChild(document.createTextNode("<"));
   cpanel.appendChild(anchor);
   document.body.appendChild(cpanel);
  }
 }

 function initialHider()
 {
  var	i;
  for(i=0;i<pcount;i++) hcomp[i] = null, scomp[i] = null;
  for(i=0;i<pcount;i++) get_allhide(pages[i], i);
 }

 function initial()
 {
  var	i		= 0;
  var	j		= 0;
  var	body		= document.body;
  /* Allocate and initial variables */
  document.onkeydown	= keyparser;
  pcount		= body.childNodes.length;
  pages			= new Array(pcount);
  hcomp			= new Array(pcount);
  scomp			= new Array(pcount);

  /* Setup Pages */
  for(i=0, j=0;i<pcount;i++) {
   if((body.childNodes[i].nodeName=="DIV" ||
       body.childNodes[i].nodeName=="div") && 
      body.childNodes[i].className=="page") {
    pages[j++]		= body.childNodes[i];
  }} pcount		= j;

  /* Retrive cookie */
  getCookie("cpage", 0);
  getCookie("cstyle", -1);

  /* Setup slide controller */
  initialControlPanel();
  initialHider();
  setTimeout("initialIndex();", 10);
  change_style(cstyle);
  show_page(cpage, 1);
 }

 initial();
__slide-zen.css__
/* TKSLIDE(css part), official site: http://www.csie.ntu.edu.tw/~b88039/slide/ */
 /* this stylesheet is adapted from css zen, provided by gugod (gugod@gugod.org) */
 /* version: 2004.05.11 */
body
{overflow:hidden;
 margin:0px;
 padding:0px;
 font-size:16px;
 font-family:Tahoma, Arial;
 background:#fff url(http://meerkat.elixus.org//images/zen/blossoms.jpg) no-repeat bottom right;
}

a {text-decoration:none;}

a:visited {color:#669;}

img {border:none;}

.headline
{
  color: #7D775C;
  text-decoration:underline;
}

h1 {color: #707349;}
h2 {color: #707349;}
h3 {color: #707349;}
h4 {color: #707349;}
h5 {color: #707349;}
h6 {color: #707349;}

.page
{ position:absolute;z-index:0;overflow:hidden;
  bottom:0px;right:0px;top:0px;left:0px;
  border:none;
  padding-left:11%;
  margin:0px;
  width:74%;
  height:98%;
  display:none;
  background:#fff url(http://meerkat.elixus.org/images/zen/zen-bg.jpg) no-repeat top left;
  } 

.pagedisplay
 {border:1px inset #999;padding:1px;padding-left:10px;padding-right:10px;
  color:#eff;background:#afafaf;font-size:12px;
 }

.hider
 {border:1px outset #999;display:none;
 }

.headline
 {font-family:Arial;font-size:32px;text-align:center;padding:3px;padding-top:20px;}

.subtitle
 {font-family:Arial;font-size:12px;text-align:center;padding:3px;}

.author
 {position:absolute;right:10%;bottom:2%;}

.section
 {}

.content
 {margin:10px;}

.comment
 {position:absolute;left:0px;width:80%;bottom:12px;font-size:12px;border-top:1px solid #000;
  padding:7px;}

.list 
 {}

.list .caption
 {font-size:18px;font-weight:600;}

.list .content
 {margin:0px;padding:0px;}

.list div ul
 {margin-left:15px;margin-top:5px;list-item:list-style:disc inside;}

.cpanel 
 {
   position:absolute;z-index:1;color:#9c9c9c;
   background:#eee;
   padding: 5px;
   border:1px outset #bbb;
   right: 0%;
   top: 0%;
   font-size: 12px;
   font-family: courier;
   line-height:12px;
   height:12px;
 }

.indexPanel
 {
  position:absolute;z-index:10;left:0px;top:-400px;font-size:12px;font-family:courier;
  border:1px outset #eee;background:#fff;border-top:0px solid #eee;width:200px;
  padding-bottom:2px;
 }

.indexTitle
 {
  background:#eee;text-align:center;padding:0px;width:200px;
 }

.index
 {
  overflow:scroll;width:200px;height:400px;visibility:hidden;
  color:#274;background:#fff;white-space:nowrap;font-size:12px;
  padding-top:2px;padding-bottom:2px;padding-left:0px;padding-right:0px;
  border:2px inset #eee;border-top:0px solid #eee;
 }

.indexitem
 {
  overflow:hidden;white-space:nowrap;width:1000px;
  border-bottom:1px solid #eee;
  margin-bottom:2px;
 }

__slide.css__
/* TKSLIDE(css part), official site: http://www.csie.ntu.edu.tw/~b88039/slide/ */
 /* version: 2004.05.03 */
 body
  {font-size:16px;font-family:Lucida console;
   background:#000;}

 a
  {text-decoration:none;}

 a:visited 
  {color:#669;}

.indexPanel
 {
  border:2px outset #eee;background:#fff;border-top:0px solid #eee;
 }

.indexTitle
 {
  background:#ddd;text-align:center;padding:2px;
 }

.index
 {
  color:#274;background:#fff;
  padding-top:2px;padding-bottom:2px;padding-left:5px;padding-right:5px;
  border:2px inset #eee;border-top:0px solid #eee;
 }

.indexitem
 {
  overflow:hidden;
  border-bottom:1px solid #eee;
  margin-bottom:2px;
 }

.page
 {
  border:2px outset #aaa;
  background:#eee url(hill.jpg) no-repeat left bottom;padding:0px;margin:0px;
 } 

.pagedisplay
 {border:1px inset #999;padding:1px;padding-left:10px;padding-right:10px;
  color:#000;background:#bfbfbf;
 }

.hider
 {border:1px outset #999;
 }

.headline
 {font-family:Arial;padding:3px;padding-top:20px;}

.subtitle
 {font-family:Arial;padding:3px;}

.author
 {}

.section
 {}

.content
 {}

.comment
 {position:absolute;left:0px;width:80%;bottom:12px;font-size:12px;border-top:1px solid #000;
  padding:7px;}

.list 
 {}

.list .caption
 {}

.list .content
 {}

.list div ul
 {}

.cpanel 
 {
  position:absolute;z-index:1;color:#9c9c9c;
  background:#bbb;padding-top:2px;padding-bottom:2px;padding-left:5px;padding-right:5px;
  border:2px outset #bbb;
 }

__slide-tkirby.css__
/* TKSLIDE(css part), official site: http://www.csie.ntu.edu.tw/~b88039/slide/ */
 /* version: 2004.05.03 */
 body
  {font-size:16px;font-family:Lucida console;
   background:#000;}

 a
  {text-decoration:none;}

 a:visited 
  {color:#669;}

.indexPanel
 {
  border:2px outset #eee;background:#fff;border-top:0px solid #eee;
 }

.indexTitle
 {
  background:#ddd;text-align:center;padding:2px;
 }

.index
 {
  color:#274;background:#fff;
  padding-top:2px;padding-bottom:2px;padding-left:5px;padding-right:5px;
  border:2px inset #eee;border-top:0px solid #eee;
 }

.indexitem
 {
  overflow:hidden;
  border-bottom:1px solid #eee;
  margin-bottom:2px;
 }

.page
 {
  border:2px outset #aaa;
  background:#eee url(bgrnd.gif);padding:0px;margin:0px;
 } 

.pagedisplay
 {border:1px inset #999;padding:1px;padding-left:10px;padding-right:10px;
  color:#000;background:#bfbfbf;
 }

.hider
 {border:1px outset #999;
 }

.headline
 {font-family:Arial;padding:3px;padding-top:20px;}

.subtitle
 {font-family:Arial;padding:3px;}

.author
 {}

.section
 {}

.content
 {}

.comment
 {position:absolute;left:0px;width:80%;bottom:12px;font-size:12px;border-top:1px solid #000;
  padding:7px;}

.list 
 {}

.list .caption
 {}

.list .content
 {}

.list div ul
 {}

.cpanel 
 {
  position:absolute;z-index:1;color:#9c9c9c;
  background:#bbb;padding-top:2px;padding-bottom:2px;padding-left:5px;padding-right:5px;
  border:2px outset #bbb;
 }

