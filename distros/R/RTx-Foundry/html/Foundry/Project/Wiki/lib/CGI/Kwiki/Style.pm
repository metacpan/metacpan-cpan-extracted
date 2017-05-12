package CGI::Kwiki::Style;
$VERSION = '0.18';
use strict;
use base 'CGI::Kwiki';

CGI::Kwiki->rebuild if @ARGV and $ARGV[0] eq '--rebuild';

sub directory { 'css' }
sub suffix { '.css' }

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Style - Default Stylesheets for CGI::Kwiki

=head1 DESCRIPTION

See installed kwiki pages for more information.

=head1 AUTHOR

Brian Ingerson <INGY@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2003. Brian Ingerson. All rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

__Display__

a         {text-decoration: none}
a:link    {color: #d64}
a:visited {color: #864}
a:hover   {text-decoration: underline}
a:active  {text-decoration: underline}
a.empty   {color: gray}
a.private {color: black}

.error    {color: #f00;}

pre {
	font-family: geneva, verdana, arial, sans-serif;
	font-size: 13px;
	color: #EEE;
	background-color: #333;
	border: 1px dashed #EEE;
	padding: 2px;
	padding-left: 10px;
	margin-left: 30px;
	margin-right: 75px;
}

del {
	text-decoration: none;
	background-color: yellow;
	color: blue;
}
ins {
	text-decoration: none;
	background-color: lightgreen;
	color: blue;
}

.title,
.side,
.sidetitle {
	font-size: large;
}

.description,
.blogbody,
.date,
.comments-body,
.comments-post,
.comments-head {
	font-size: medium;
}

.posted {
	font-size: small;
}

.syndicate,
.powered {
	font-size: x-small;
}

table.changes {
	width: 100%;
	table-layout: fixed;
} /* fix width of table from RecentChange page */

table.changes td.page-id {
} /* do nothing to "Page-ID" cell from RecentChange table */

table.changes td.edit-by {
	text-align: right;
} /* make "Edit-By" cell from RecentChange table align to right */

table.changes td.edit-time {
	font-size: x-small;
} /* decrease font size of "Edit-Time" cell from RecentChange table */

div.side a { display: list-item; list-style-type: none }
div.upper-nav { display: none; }
.blog h1 { display: none; }
textarea { width: 100% }
body div#content div.blog div.blogbody h1 { display: inline; }
__Hlb__
/* block */
body {
    color: #070707;
    background-color: #ccc;
    margin: 10px; padding: 0;
}

div#banner {
}

.description {
    padding-left: 30px;
}

div#content {
    margin: 0px;
    border-top: 2px solid #666;
    border-left: 1px solid #666; 
    border-right: 1px solid #666;
    background: #fffff7;
}

h2.title {
    padding: 10px;
}

div.upper-nav {
    border-top: 1px solid #ccc;
    border-bottom: 1px solid #ddd;
    margin: 0; 
    padding: 0 20px;
    background: #eee;
}

.edit {
    display: block;
    border-top: 1px solid #ccc;
    border-bottom: 1px solid #ddd;
    margin: 0; 
    padding: 5px 20px;
    background: #eee;
}

.sidetitle, .side {
    display: none;
}

.powered {
    border: 1px solid #666;
    padding: 5px;
    background: #eee;
}

h2.comments-head {
    width: 5em;
    border-right: 1px inset #666;
    border-top: 1px groove #fff;
    border-bottom: 1px inset #666;
    background: #eef;
}

.comments-post {
    padding: 0 20px 20px 20px;
}

/* basic text style */
body {
    font-family: "Palatino Linotype", Georgia, "Times New Roman", Times, serif;
}

div#content {
    line-height: 180%;
}

h2.title {
    font-size: xx-large;
    margin: 0;
    border: 0;
}

.powered {
    font-size: x-small;
    text-align: center;
}

div a:link {
    text-decoration: none;
    color: #993300; }

div a:visited {
    text-decoration: none;
    color: #660000;}
    
div a:hover {
    text-decoration: underline;
    color: #cc0000;}
    
div a:active {
    text-decoration: none;
    color: #cc0000;}

/* content style */
div p { 
    margin: 15px; 
}

h1, h2, h3, h4, h5, h6 {
    color: #333;
    margin: 0 10% 0 0;
    padding: 0 10px;
    border-bottom: 1px solid #666;
    text-decoration: none;
}

li { 
    color: black;
    margin-bottom: 0.2em;
    margin-right: 5%;
}
    
ul {
    color: black;
}

/* this reverses the 2nd and 3rd level list item bullets */
ul>li>ul {list-style-type: square;}
ul>li>ul>li>ul {list-style-type: circle;}

/* latex style list item */
ol li ol li { list-style-type: lower-alpha; }
ol li ol li ol li { list-style-type: lower-roman; }

blockquote pre {
    font-family: courier, "courier new", monaco, monospace;
    color: #000;
    background: #f0f0f0; 
    margin: 0.5em;
}

code, pre, tt {
    font-family: courier, "courier new", monaco, monospace;
    color:#333333;
}

div#content div.blog div.upper-nav {
    display: inline;
}

a.empty:before {
    vertical-align: top;
    font-size: xx-small;
    content: '?'
}

a.empty:after {
    vertical-align: top;
    font-size: xx-small;
    content: '?'
}
a.private {color: black}
__Jedi__
	body {
		margin:0px 0px 20px 0px;
		background:#000;
		}
	A			{ color: #FFCC99; text-decoration: underline; }
	A:link		{ color: #FFCC99; text-decoration: underline; }
	A:visited	{ color: #CC9966; text-decoration: underline; }
	A:active	{ color: #666666;  }
	A:hover		{ color: #666666;  }

	h1, h2,	h3 {
		margin:	0px;
		padding: 0px;
	}

	abbr, acronym, .help {
		cursor: help;
	}

	pre {
		font-family:geneva, verdana, arial, sans-serif;
		font-size:13px;
		color:#EEE;
		line-height:15px;
		background-color: #333;
		border: 1px dashed #EEE;
		padding: 2px;
		padding-left: 10px;
		margin-left: 30px;
		margin-right: 75px;
	}

	strong {
		color:yellow;
	}

	input:focus,
	textarea:focus {
		background:yellow;
	}

	input[type="button"]:focus {
		background:button-highlight;
	}

	code {
		color:#9999CC;
	}

	#banner	{
		position:relative;
		width:95%;
		font-family:palatino,  georgia,	verdana, arial,	sans-serif;
		color:#CCC;
		font-size:x-large;
		font-weight:normal;
		padding:15px;
		border-top:4px double #999;
		z-index:10;
		}

	#banner	a,
	#banner	a:link,
	#banner	a:visited,
	#banner	a:active,
	#banner	a:hover	{
		font-family: palatino,	georgia, verdana, arial, sans-serif;
		font-size: xx-large;
		color: #CCC;
		text-decoration: none;
		}

	.description {
		font-family:palatino,  georgia,	"times new roman", serif;
		color:#CCC;
		font-size:medium;
		text-transform:none;
		}

	.caticon {
		float:left;
		text-align:center;
		font-family:verdana, arial, sans-serif;
		color:#CCC;
		font-size:small;
		font-weight:normal;
		background:#000;
		line-height:140%;
		padding:2px;
		width:50px;
		}

	#content {
		position:absolute;
		background:#000;
		margin-right:20px;
		margin-bottom:20px;
		border:1px solid #000;
		top: 75px;
		left: 225px;
		width: 60%;
		}

	#container {
		background:#000;
		border:1px solid #000;
		}

	#links {
		padding:15px;
		border:1px solid #000;
		width:200px;
		margin-left:0;
		}

	.blog {
		padding:15px;
		background:#000;
		}

	.blogbody {
		font-family:palatino, georgia, verdana,	arial, sans-serif;
		color:#CCC;
		font-size:medium;
		font-weight:normal;
		background:#000;
		line-height:200%;
		}

	.blogbody a,
	.blogbody a:link,
	.blogbody a:visited,
	.blogbody a:active,
	.blogbody a:hover {
		font-weight: normal;
		text-decoration: underline;
	}

	.title	{
		font-family: palatino, georgia,	"times new roman", serif;
		font-size: x-large;
		color: #999;
		}

	.pre {
		font-family:geneva, verdana, arial, sans-serif;
		color:#EEE;
		background-color: #222;
		border: 1px solid #EEE;
		padding: 2px;
		padding-left: 10px;
		padding-right: 10px;
		margin-left: 30px;
		margin-right: 75px;
	}

	.codenote {
		color:#888;
		float:right;
	}

	#menu {
		color:#CCC;
		margin-bottom:15px;
		background:#000;
		text-align:center;
		}

	.date	{
		font-family:palatino, georgia, "times new roman", serif;
		font-size: large;
		color: #CCC;
		border-bottom:1px solid	#999;
		margin-bottom:10px;
		font-weight:bold;
		}

	.posted	{
		font-family:verdana, arial, sans-serif;
		font-size: small;
		color: #FFFFFF;
		margin-bottom:25px;
		clear:both;
		}


	.calendar {
		font-family:verdana, arial, sans-serif;
		color:#999;
		font-size:x-small;
		font-weight:normal;
		background:#000;
		line-height:140%;
		padding:2px;
		text-align:left;
		}

	.calendarhead {
		font-family:palatino, georgia, "times new roman", serif;
		color:#9999FF;
		font-size:small;
		font-weight:normal;
		padding:2px;
		letter-spacing:	.3em;
		background:#000;
		text-transform:uppercase;
		text-align:right;
		}

	.side {
		font-family:verdana, arial, sans-serif;
		color:#CCC;
		font-size:small;
		font-weight:normal;
		background:#000;
		line-height:140%;
		padding:2px;
		}

	.sidetitle {
		font-family:palatino, georgia, "times new roman", serif;
		color:#9999FF;
		font-size:medium;
		font-weight:normal;
		padding:2px;
		margin-top:30px;
		letter-spacing:	.3em;
		background:#000;
		text-transform:uppercase;
		}

	.syndicate {
		font-family:verdana, arial, sans-serif;
		font-size:xx-small;
		line-height:140%;
		padding:2px;
		margin-top:15px;
		background:#000;
		}

	.powered {
		font-family:palatino, georgia, "times new roman", serif;
		color:#999;
		font-size:x-small;
		line-height:140%;
		text-transform:uppercase;
		padding:2px;
		margin-top:50px;
		letter-spacing:	.2em;
		background:#000;
		}


	.comments-body {
		font-family:palatino, georgia, verdana,	arial, sans-serif;
		color:#999;
		font-size:medium;
		font-weight:normal;
		background:#000;
		line-height:140%;
		padding-bottom:10px;
		padding-top:10px;
		border-bottom:1px dotted #666;
		}

	.comments-post {
		font-family:verdana, arial, sans-serif;
		color:#999;
		font-size:medium;
		font-weight:normal;
		background:#000;
		}


	.trackback-url {
		font-family:palatino, georgia, verdana,	arial, sans-serif;
		color:#999;
		font-size:large;
		font-weight:normal;
		background:#000;
		line-height:140%;
		padding:5px;
		border:1px dotted #666;
		}


	.trackback-body	{
		font-family:palatino, georgia, verdana,	arial, sans-serif;
		color:#999;
		font-size:large;
		font-weight:normal;
		background:#000;
		line-height:140%;
		padding-bottom:10px;
		padding-top:10px;
		border-bottom:1px dotted #666;
		}

	.trackback-post	{
		font-family:verdana, arial, sans-serif;
		color:#999;
		font-size:medium;
		font-weight:normal;
		background:#000;
		}


	.comments-head	{
		font-family:palatino, georgia, verdana,	arial, sans-serif;
		font-size:medium;
		color: #999;
		border-bottom:1px solid	#666;
		margin-top:20px;
		font-weight:bold;
		background:#000;
		}

	#banner-commentspop {
		font-family:palatino, georgia, verdana,	arial, sans-serif;
		color:#000;
		font-size:large;
		font-weight:bold;
		border-left:1px	solid #000;
		border-right:1px solid #000;
		border-top:1px solid #000;
		background:#FFCC99;
		padding-left:15px;
		padding-right:15px;
		padding-top:5px;
		padding-bottom:5px;
		}

	div#content div.blog div.blogbody { 
		padding-top:1em;
		}
__Kwiki__
body {
	background:#FFF;		
}

a         {text-decoration: none}
a:link    {color: #d64}
a:visited {color: #864}
a:hover   {text-decoration: underline}
a:active  {text-decoration: underline}
a.empty   {color: gray}
a.private {color: black}

h1, h2, h3 {
	margin: 0px;
	padding: 0px;
}

#banner {
	width: 10%;
	float: left;
	font-size:x-large;
	font-weight:bold;
	background:#FFF;
}
	
#banner h1 { display: none; }
			
#content {
	float:left;
	width:510px;
	background:#FFF;
	margin-bottom:20px;
}

#links {
	background:#FFF;
	color:#CCC;
	margin-right:25%;
}
	
.blog {
	padding-left:15px;					
	padding-right:15px;					
}	

.blogbody {
	font-size:small;
	font-weight:normal;
	background:#FFF;
}

.blogbody a,
.blogbody a:link,
.blogbody a:visited,
.blogbody a:active,
.blogbody a:hover {
	font-weight: normal;
}

.title	{ 
	font-size: small;
	color: #CCC;
}

div#content div.blog div.blogbody h2.title {
	font-size: xx-large;
	padding-bottom: 10px;
}

	
.date	{ 
	display: none;
}			
	
.side {
	color:#CCC;
	font-size:x-small;
	font-weight:normal;
	background:#FFF;
}	

.sidetitle {
	display: none;
}		
#links .side { display: none; float: right; }
div#links div.side span a { display: inline }
div#links div.side span:after { content: " | " }
	
.powered {
	display: none;
}	
	
.posted	{ 
	padding:3px;
	width:100%
}
	
.comments-head	{ 
	background: lightgrey;
	padding:3px;
	width:100%
}		

div#content div.blogbody div.posted { font-size: medium; }
div#content div.comments-head { font-size: medium; }

div#content div.blog div.blogbody table tr th h2 { text-align:left; }
div#content div.blog div.blogbody table tr td.edit-by { text-align: center; }
div#content div.blog div.blogbody table tr td.edit-time { font-size: medium; }
span.blog-date h2.date {display: inline; }

div.blog-meta {
	background-color: #e0e0e0;
	width: 100%;
	padding: 0.5em;
	height: 1.5em;
}

span.blog-date { float:left; }
span.blog-title { float:right; }
span.description { display: none; }
div#content div.blog div.upper-nav { display: inline; }
div.blog h1 { display: block; padding-bottom:0.5em; }

div.slide-body div.blogbody div#banner {
	width: 96%;
	float: none;
	text-align: center;
	background-color: #C0FFC0;
	font-size: medium;
	padding: 0.5em;
	margin-left: 2%;
	margin-right: 2%;
	line-height: 100%;
}
div.slide-body div.blogbody { padding: 0; margin: 0; left:0; right:0 }
form.edit input { position: absolute; left: 3% }
form.admin input { position: absolute; left: 3% }
h2.comments-head { display: none }
div textarea { width: auto }
body.diff div.posted { display: none }
body.diff div.comments-head { display: none }
body.diff div.comments-body { display: none }
blockquote pre {
	background-color: #FFF;
	color: black;
	border: none;
}
__Plasma__
body { background: #303030; color: #E0E0E0; }
#banner { position: relative; background:black; text-align: right; }
#banner h1 { text-align: left; }
#banner span.description:before { content: '--  '; }
#banner span.description { width: 60%; }

a.empty:after {
font-size: xx-small;
font-style: italic;
content: '?';
}

div#content {
position: absolute;;
left: 25ex;
width: 70%;
}

div#links {
margin-left: 0;
padding-top: 0.5em;
width: 25ex;
}

div#links div.sidetitle {
padding-top: 0.5em;
padding-bottom: 0.40em;
}

div#links div.side {
}

div.powered {
margin-top: 5em;
}

blockquote pre {
line-height: 1.1em;
padding-top: 0.5em;
padding-bottom: 0.5em;
background-color: black;
margin-left: 0px;
margin-right: 0px;
}
__Plasma__
body { background: #303030; color: #E0E0E0; }
#banner { position: relative; background:black; text-align: right; }
#banner h1 { text-align: left; }
#banner span.description:before { content: '--  '; }
#banner span.description { width: 60%; }

a.empty:after {
font-size: xx-small;
font-style: italic;
content: '?';
}

div#content {
position: absolute;;
left: 25ex;
width: 70%;
}

div#links {
margin-left: 0;
padding-top: 0.5em;
width: 25ex;
}

}

div#links div.sidetitle {
padding-top: 0.5em;
padding-bottom: 0.40em;
}

div#links div.side {
}

div.powered {
margin-top: 5em;
}

blockquote pre {
line-height: 1.1em;
padding-top: 0.5em;
padding-bottom: 0.5em;
background-color: black;
margin-left: 0px;
margin-right: 0px;
}

h1 {
color:#99F;
border-bottom: 5px solid #000;
padding: 2px;
margin: 0px;
margin-bottom: 8px;
}

h2 {
 color:#d94;
 font-size: 24px;
 padding: 2px;
 margin-top: 5px;
 border-bottom: 2px solid #606060;
}

h3 { 
 color:#a94;
 font-size: 20px;
 padding: 2px;
 margin-top: 5px;
 border-bottom: 1px dashed #808080;
}

h4 {
 color:#666;
 font-size: 18px;
 padding: 2px;
 margin-top: 5px;
}

__SlideShow__
pre { font-family: courier, monospace; font-weight: bolder }
li  { font-size: 20pt; padding-top: 10 }
.slide-body li { line-height: 140%; }
.slide-body h4 { height: 0em; line-height: 0em; }
