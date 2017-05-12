package Miril::Theme::Flashyweb::Stylesheet;

use strict;
use warnings;
use autodie;

sub get {

return <<EndOfHTML;

/*
Design by Free CSS Templates
http://www.freecsstemplates.org
Released for free under a Creative Commons Attribution 2.5 License
*/

body {
	margin-top: 20px;
	padding: 0;
	background: #FDF9EE;
	font-family: Arial, Helvetica, sans-serif;
	font-size: 12px;
	color: #6D6D6D;
}

h1, h2, h3 {
	margin: 0;
	font-family: Georgia, "Times New Roman", Times, serif;
	font-weight: normal;
	color: #006EA6;
}

h1, h2 {
	text-transform: lowercase;
}

h1 {
	letter-spacing: -1px;
	font-size: 35px;
}

h2 {
	font-size: 26px;
}

p, ul, ol {
	margin: 0 0 1.5em 0;
	text-align: justify;
	line-height: 26px;
}

a:link {
	color: #0094E0;
}

a:hover, a:active {
	text-decoration: none;
	color: #0094E0;
}

a:visited {
	color: #0094E0;
}

img {
	border: none;
}

img.left {
	float: left;
	margin: 7px 15px 0 0;
}

img.right {
	float: right;
	margin: 7px 0 0 15px;
}

/* Form */

form {
	margin: 0;
	padding: 0;
}

fieldset {
	margin: 0;
	padding: 0;
	border: none;
}

legend {
	display: none;
}

input, textarea, select, button {
	font-family: "Trebuchet MS", Arial, Helvetica, sans-serif;
	font-size: 13px;
	color: #333333;
}

#wrapper {
}

/* Header */

#header {
	width: 900px;
	min-height: 40px;
	margin: 0 auto 20px auto;
	padding-top: 10px;
}

#logo {
	float: left;
	height: 40px;
	margin-left: 10px;
}

#logo h1 {
	float: left;
	margin: 0;
	font-size: 38px;
	color: #0099E8;
}

#logo h1 sup {
	vertical-align: text-top;
	font-size: 24px;
}

#logo h1 a {
	color: #0099E8;
}

#logo h2 {
	float: left;
	margin: 0;
	padding: 20px 0 0 10px;
	text-transform: uppercase;
	font-family: Arial, Helvetica, sans-serif;
	font-size: 10px;
	color: #6D6D6D;
}

#logo a {
	text-decoration: none;
	color: #FFFFFF;
}

/* Menu */

#menu {
	float: right;
}

#menu ul {
	margin: 0;
	padding: 0;
	list-style: none;
}

#menu li {
	display: inline;
}

#menu a {
	display: block;
	float: left;
	margin-left: 5px;
	background: #0094E0;
	border: 1px dashed #FFFFFF;
	padding: 1px 10px;
	text-decoration: none;
	font-size: 12px;
	color: #FFFFFF;
}

#menu a:hover {
	text-decoration: underline;
}

#menu .active a {
}

/* Page */

#page {
	width: 900px;
	margin: 0 auto;
	background: #FFFFFF;
	border: 1px #F0E9D6 solid;
	padding: 20px 20px;
}

/* Content */

#content {
	float: left;
	width: 600px;
	padding-left: 10px;
}

/* Post */

.post {
}

.post .title {
	margin-bottom: 20px;
	padding-bottom: 5px;
	/* padding-left: 40px; */
	border-bottom: 1px dashed #D1D1D1;
	color: #8BCB2F;
}

.post .title b {
	font-weight: normal;
	color: #0094E0;
}

.post .entry {
}

.post .meta {
	margin: 0;
	padding: 15px 0 60px 0;
}

.post .meta p {
	margin: 0;
	line-height: normal;
}

.post .meta .byline {
	float: left;
	color: #0000FF;
}

.post .meta .links {
	float: left;
}

.post .meta .more {
	width: 185px;
	height: 35px;
	padding: 5px 10px;
	background: #8BCB2F;
	border: 1px dashed #FFFFFF;
	text-transform: uppercase;
	text-decoration: none;
	font-size: 9px;
}

.post .meta .comments {
	padding: 5px 10px;
	text-transform: uppercase;
	text-decoration: none;
	background: #0094E0;
	border: 1px dashed #FFFFFF;
	font-size: 9px;
}

.post .meta b {
	display: none;
}

.post .meta a {
	color: #FFFFFF;
}
/* Sidebar */

#sidebar {
	float: right;
	width: 230px;
	padding-right: 10px;
}

#sidebar ul {
	margin: 0;
	padding: 10px 0 0 0;
	list-style: none;
}

#sidebar li {
	margin-bottom: 40px;
}

#sidebar li ul {
}

#sidebar li li {
	margin: 0;
	padding: 6px 0;
	border-bottom: 1px dashed #D1D1D1;
	display: block;
}

#sidebar li li a {
	margin: 0;
	padding-left: 1.5em;
	display: block;
	line-height: 20px;
}

#sidebar h2 {
	padding-bottom: 5px;
	font-size: 18px;
	font-weight: normal;
	color: #0094E0;
}

#sidebar strong, #sidebar b {
	color: #8BCB2F;
}

#sidebar a {
	text-decoration: none;
	color: #6D6D6D;
}

/* Search */

#search {
}

#search h2 {
}

#s {
	width: 80%;
	margin-right: 5px;
	padding: 3px;
	border: 1px solid #F0F0F0;
}

#x {
	padding: 3px;
	background: #ECECEC repeat-x left bottom;
	border: none;
	text-transform: lowercase;
	font-size: 11px;
	color: #4F4F4F;
}

/* Boxes */

.box1 {
	padding: 20px;
}

.box2 {
	color: #BABABA;
}

.box2 h2 {
	margin-bottom: 15px;
	font-size: 16px;
	color: #FFFFFF;
}

.box2 ul {
	margin: 0;
	padding: 0;
	list-style: none;
}

.box2 a:link, .box2 a:hover, .box2 a:active, .box2 a:visited  {
	color: #EDEDED;
}

/* Footer */

#footer {
	width: 880px;
	margin: 0 auto;
	padding: 10px 0 0 0;
	color: #353535;
}

html>body #footer {
	height: auto;
}

#footer-menu {
}

#legal {
	clear: both;
	font-size: 11px;
	color: #6D6D6D;
}

#legal a {
	color: #0094E0;
}

#footer-menu {
	float: left;
	color: #353535;
	text-transform: capitalize;
}

#footer-menu ul {
	margin: 0;
	padding: 0;
	list-style: none;
}

#footer-menu li {
	display: inline;
}

#footer-menu a {
	display: block;
	float: left;
	padding: 1px 15px 1px 15px;
	text-decoration: none;
	font-size: 11px;
	color: #6D6D6D;
}

#footer-menu a:hover {
	text-decoration: underline;
}

#footer-menu .active a {
	padding-left: 0;
}

/* Petar's additions! */

.edit input.textbox {
	width: 50%;
}

.edit textarea {
	width: 100%;
	height: 250px;
}

.edit p.edit {
	margin-top: 5px;
	margin-bottom: 5px;
}

.post h2 {
	text-transform: none;
}

.dingbat {
	color: #006EA6;
}

#sidebar h2.bold {
	font-weight: bold;
}

div.entry * {
	color: #6D6D6D;
}

span.required {
	color: red;
}

p.item-desc {
	font-family: Georgia,"Times New Roman",Times,serif;
}

h3 .dingbat {
	margin-right: 10px;
}

div#error {
	border: 1px solid #F0E9D6;
	margin-bottom: 10px;
}

#error ul {
	margin: 1em 0 1em;
}

#error ul li pre {
	margin: 0;
	color: #6D6D6D;
}

#error h2 {
	margin-top: 0.5em;
	margin-left: 1em;
	color: red;
	font-size: 18px;
	font-weight: bold;
}

.more {
	margin-right: 5px;
}

div.entry p {
	line-height: 1.8em;
	font-family: Georgia,"Times New Roman",Times,serif;
	text-align: left;
}

div.entry li {
	line-height: 1.8em;
	font-family: Georgia,"Times New Roman",Times,serif;
	text-align: left;
}

div.entry h1, h2, h3 {
	margin-top: 0.7em;
	margin-bottom: 0.3em;
}

div.pager {
	text-align: center;
}

div.dingbat {
	float: left;
	width: 1.5em;
}

.invalid {
	outline: red solid medium;
}

li.warning {
	color: #8BCB2F;
}

li.fatal {
	color: #FF0000;
}


EndOfHTML

}

1;
