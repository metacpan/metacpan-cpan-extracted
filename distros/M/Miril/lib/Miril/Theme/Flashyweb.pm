package Miril::Theme::Flashyweb;

use strict;
use warnings;
use autodie;

use Miril::Theme::Flashyweb::Stylesheet;

### TEMPLATES ###

my $account = <<EndOfHTML;

<TMPL_VAR NAME="header">

	<!-- start content -->
	<div id="content">
		<div class="post">
			<h2 class="title"><span class="dingbat">&#x273b;</span> <TMPL_VAR NAME="user.username"></h2>
			<div class="edit">
				<form method="POST">

					<p class="edit">Name:<br>
					<input type="text" name="name" class="textbox" value='<TMPL_VAR NAME="user.name">' /></p>

					<p class="edit">New password:<br>
					<input type="password" name="new_password" class="textbox" />
					</p>

					<p class="edit">Retype new password:<br>
					<input type="password" name="retype_password" class="textbox" />
					</p>

					<p class="edit">Existing password: <span class="required">(Required)</span><br>
					<input type="password" name="password" class="textbox" />
					</p>

					<input type="hidden" name="username" value='<TMPL_VAR NAME="user.username">' />

					<button type="submit" id="x" name="action" value="account">Save</button>&nbsp;&nbsp;&nbsp;&nbsp;
					<button type="submit" id="x" name="action" value="list">Cancel</button>

				</form>
			</div>
		</div>
	</div>
	<!-- end content -->

<TMPL_VAR NAME="footer">

EndOfHTML

my $edit = <<EndOfHTML;

<TMPL_VAR NAME="header">

	<!-- start content -->
	<div id="content">
		<div class="post">
			<h2 class="title"><TMPL_IF NAME="post.title"><TMPL_VAR NAME="post.title"><TMPL_ELSE>New Article</TMPL_IF></h2>
			<div class="edit">
				<form method="POST">
					<p class="edit">Title:<br>
					<input type="text" name="title" class="textbox <TMPL_IF NAME="invalid.title"> invalid</TMPL_IF>" value='<TMPL_VAR NAME="post.title">' /></p>

					<p class="edit">ID:<br>
					<input type="text" name="id" class="textbox<TMPL_IF NAME="invalid.id"> invalid</TMPL_IF>" value='<TMPL_VAR NAME="post.id">' /></p>
					
					<p class="edit">Type:<br>
					<select name="type"<TMPL_IF NAME="invalid.type"> class="invalid"</TMPL_IF>>
					<TMPL_LOOP NAME="post.types">
						<option value='<TMPL_VAR NAME="this.id">'<TMPL_IF NAME="this.selected"> selected="selected"</TMPL_IF>><TMPL_VAR NAME="this.name"></option>
					</TMPL_LOOP>
					</select>
					</p>

					<TMPL_IF NAME="post.authors">
					<p class="edit">Author:<br>
					<select name="author"<TMPL_IF NAME="invalid.author"> class="invalid"</TMPL_IF>>
					<TMPL_LOOP NAME="post.authors">
						<option value='<TMPL_VAR NAME="this.id">'<TMPL_IF NAME="this.selected"> selected="selected"</TMPL_IF>><TMPL_VAR NAME="this.name"></option>
					</TMPL_LOOP>
					</select>
					</p>
					</TMPL_IF>

					<p class="edit">Status:<br>
					<select name="status" <TMPL_IF NAME="invalid.status"> class="invalid"</TMPL_IF>>
					<TMPL_LOOP NAME="post.statuses">
						<option value='<TMPL_VAR NAME="this.id">'<TMPL_IF NAME="this.selected"> selected="selected"</TMPL_IF>><TMPL_VAR NAME="this.name"></option>
					</TMPL_LOOP>
					</select>
					</p>

					<TMPL_IF NAME="post.topics">
					<p class="edit">Topic:<br>
					<select name="topic" size=3 multiple="multiple"<TMPL_IF NAME="invalid.topic"> class="invalid"</TMPL_IF>>
					<TMPL_LOOP NAME="post.topics">
						<option value='<TMPL_VAR NAME="this.id">'<TMPL_IF NAME="this.selected"> selected</TMPL_IF>><TMPL_VAR NAME="this.name"></option>
					</TMPL_LOOP>
					</select>
					</p>
					</TMPL_IF>

					<p class="edit" name="source">Body:<br>
					<textarea name="source"<TMPL_IF NAME="invalid.source"> class="invalid"</TMPL_IF>><TMPL_VAR NAME="post.source"></textarea></p>

					<input type="hidden" name="old_id" value='<TMPL_VAR NAME="post.id">' />

					<button type="submit" id="x" name="action" value="update">Save</button>&nbsp;&nbsp;&nbsp;&nbsp;
					<button type="submit" id="x" name="action" value="delete">Delete</button>&nbsp;&nbsp;&nbsp;&nbsp;
					<button type="submit" id="x" name="action" value="view">Cancel</button>
				</form>
			</div>
		</div>
	</div>
	<!-- end content -->


<TMPL_VAR NAME="footer">

EndOfHTML

my $files = <<EndOfHTML;

<TMPL_VAR NAME="header">

<div id="content">
	<div class="post">
		<h2 class="title"><span class="dingbat">&#x273b;</span> Files</h2>
		<div class="meta">
			<p class="links"><a href="?action=upload" class="more">Upload files</a></p>
		</div>
		<div class="entry">
		
		<form method="POST">
		<TMPL_LOOP NAME="files">
			<h3><input type="checkbox" name="file" value='<TMPL_VAR NAME="name">'> <a href='<TMPL_VAR NAME="href">' target="_blank"><TMPL_VAR NAME="name"></a></h3>
			<p class="item-desc">
				<b>Size:</b> <TMPL_VAR NAME="size">,&nbsp; 
				<b>Modified:</b> <TMPL_VAR NAME="modified">
			</p>
		</TMPL_LOOP>
		<div class="pager">
			<TMPL_VAR NAME="pager">
		</div>
		<button type="submit" id="x" name="action" value="unlink">Delete selected</button>
		</form>
	
		</div>
	</div>
</div>

<TMPL_VAR NAME="footer">

EndOfHTML


my $upload = <<EndOfHTML;

<TMPL_VAR NAME="header">

<div id="content">
	<div class="post">
		<h2 class="title"><span class="dingbat">&#x273b;</span> Upload Files</h2>
		<form method="POST" enctype="multipart/form-data">
			<div>
				<p class="edit"><input type="file" name="file" />
				<p class="edit"><input type="file" name="file" />
				<p class="edit"><input type="file" name="file" />
				<p class="edit"><input type="file" name="file" />
				<p class="edit"><input type="file" name="file" />
			</div>
			<button type="submit" id="x" name="action" value="upload">Upload files</button>
			<button name="action" value="files" id="x">Cancel</button>
			</p>
		</form>
	</div>
</div>

<TMPL_VAR NAME="footer">

EndOfHTML

my $footer = <<EndOfHTML;

<TMPL_IF NAME="authenticated"><TMPL_VAR NAME="sidebar"></TMPL_IF>
<div style="clear: both;">&nbsp;</div>
</div>
<!-- end page -->
<!-- start footer -->
<div id="footer">
	<!--
	<div id="footer-menu">
		<ul>
			<li class="active"><a href="#">homepage</a></li>
			<li><a href="#">photo gallery</a></li>
			<li><a href="#">about us</a></li>
			<li><a href="#">links</a></li>
			<li><a href="#">contact us</a></li>
		</ul>
	</div>
	-->
	<p id="legal">Powered by <a href="http://www.miril.org">Miril</a></p>
</div>
<!-- end footer -->
</body>
</html>

EndOfHTML

my $header = <<EndOfHTML;

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<!--

Design by Free CSS Templates
http://www.freecsstemplates.org
Released for free under a Creative Commons Attribution 2.5 License

Title      : FlashyWeb
Version    : 1.0
Released   : 20081102
Description: A two-column, fixed-width and lightweight template ideal for 1024x768 resolutions. Suitable for blogs and small websites.

-->
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<title>Miril</title>
<meta name="keywords" content="" />
<meta name="description" content="" />
<style><TMPL_VAR NAME="css"></style>
</head>
<body>
<!-- start header -->
<div id="header">
	<div id="logo">
		<h1><a href="?">Miril</a></h1>
		<h2>Static Content Publishing</h2>
	</div>
	<TMPL_IF NAME="authenticated">
	<div id="menu">
		<ul>
			<li class="active"><a href="?action=list">articles</a></li>
			<li><a href="?action=files">files</a></li>
			<li><a href="?action=publish">publish</a></li>
			<li><a href="?action=account">account</a></li>
			<li><a href="?action=logout">logout</a></li>
		</ul>
	</div>
	</TMPL_IF>
</div>
<!-- end header -->

<!-- start page -->
<div id="page">

<TMPL_IF NAME="has_error">
	<div id="error">
	<h2>miril encountered problems:</h2>
		<ul>
			<TMPL_LOOP NAME="warnings"><li class="warning"><TMPL_VAR NAME="message"><pre><TMPL_VAR NAME="errorvar"></pre></li></TMPL_LOOP>
			<TMPL_LOOP NAME="fatals"><li class="fatal"><TMPL_VAR NAME="message"><pre><TMPL_VAR NAME="errorvar"></pre></li></TMPL_LOOP>
		</ul>
	</div>
</TMPL_IF>

EndOfHTML

my $list = <<EndOfHTML;

<TMPL_VAR NAME="header">

<div id="content">
	<div class="post">
		<h2 class="title"><span class="dingbat">&#x273b;</span> List of entries</h2>
		<div class="meta">
			<p class="links"><a href="?action=search" class="more">Search</a></p>
			<p class="links"><a href="?action=create" class="more">Post new article</a></p>
		</div>
		<div class="entry">
				
		<TMPL_LOOP NAME="posts.list">
			<h3><span class="dingbat">&#8226;</span><a href='?action=view&id=<TMPL_VAR NAME="this.id">'><TMPL_VAR NAME="this.title"></a></h3>
			<p class="item-desc">
				<b>Status:</b> <TMPL_VAR NAME="this.status">,&nbsp; 
				<b>Modified:</b> <TMPL_VAR NAME="this.modified.strftime('%d/%m/%Y %H:%M')">
			</p>
		</TMPL_LOOP>

		</div>
		<div class="pager">
			<TMPL_VAR NAME="pager">
		</div>
	</div>
</div>

<TMPL_VAR NAME="footer">

EndOfHTML

my $search = <<EndOfHTML;

<TMPL_VAR NAME="header">

<div id="content">
	<div class="post">
		<h2 class="title"><span class="dingbat">&#x273b;</span> Search entries</h2>
		<div class="entry">
				
			<form>
					
				<p class="edit">Title contains:<br />
				<input type="text" name="title" />
				</p>
				<p class="edit">Type:<br>
				<select name="type">
					<option value=''>--Any--</option>
				<TMPL_LOOP NAME="types">
					<option value='<TMPL_VAR NAME="id">'><TMPL_VAR NAME="name"></option>
				</TMPL_LOOP>
				</select>
				</p>

				<TMPL_IF NAME="authors">
				<p class="edit">Author:<br>
				<select name="author">
					<option value=''>--Any--</option>
				<TMPL_LOOP NAME="authors">
					<option value='<TMPL_VAR NAME="id">'><TMPL_VAR NAME="name"></option>
				</TMPL_LOOP>
				</select>
				</p>
				</TMPL_IF>
				
				<p class="edit">Status:<br>
				<select name="status">
					<option value=''>--Any--</option>
				<TMPL_LOOP NAME="statuses">
					<option value='<TMPL_VAR NAME="id">'><TMPL_VAR NAME="name"></option>
				</TMPL_LOOP>
				</select>
				</p>

				<TMPL_IF NAME="topics">
				<p class="edit">Topic:<br>
				<select name="topic">
					<option value=''>--Any--</option>
				<TMPL_LOOP NAME="topics">
					<option value='<TMPL_VAR NAME="id">'><TMPL_VAR NAME="name"></option>
				</TMPL_LOOP>
				</select>
				</p>
				</TMPL_IF>

				<button id="x" name="action" value="list">search</button>

			</form>
		</div>
	</div>
</div>

<TMPL_VAR NAME="footer">

EndOfHTML

my $login = <<EndOfHTML;

<TMPL_VAR NAME="header">

<div id="content">
	<div class="post">
		<h2 class="title"><span class="dingbat">&#x273b;</span> Sign in</h2>

			<div class="login">
				<form method="POST">

					<p class="edit">Username:<br>
					<input type="text" name="authen_username" class="textbox" value='<TMPL_VAR NAME="title">' /></p>

					<p class="edit">Password:<br>
					<input type="password" name="authen_password" class="textbox" value='<TMPL_VAR NAME="id">' /></p>

					<p><input type="checkbox" name="authen_rememberuser" />Remember me!</p>

					<button type="submit" id="x" name="action" value="list">Sign in</button>
  
				</form>
			</div>
	</div>
</div>

<TMPL_VAR NAME="footer">

EndOfHTML

my $publish = <<EndOfHTML;

<TMPL_VAR NAME="header">

<div id="content">
	<div class="post">
		<h2 class="title"><span class="dingbat">&#x273b;</span> Publish</h2>
		
		<form method="POST">
			<input type="hidden" name="action" value="publish">
			<p>
			<select name="rebuild">
				<option value="">Publish new and modified content</option>
				<option value="1">Rebuild the whole website</option>
			</select>
			</p>
			<input type="hidden" name="action" value="publish">
			<p><button type="submit" id="x" name="do" value="1">Publish</button></p>
		</form>
		
		
	</div>
</div>

<TMPL_VAR NAME="footer">

EndOfHTML

my $sidebar = <<EndOfHTML;

	<!-- start sidebar -->
	<div id="sidebar">
		<ul>
			<li id="search">
				<h2><b class="text1">Quick Open</b></h2>
				<form method="get">
					<fieldset>
					<input type="text" id="s" name="id" />
					<button id="x" name="action" value="view" />Go</button>
					</fieldset>
				</form>
			</li>
			<li>
				<h2 class="bold">Last edited</h2>
				<ul>
				<TMPL_LOOP NAME="latest">
					<li><div class="dingbat">&#x2726;</div>
						<a href="?action=view&id=<TMPL_VAR NAME="id">">
						<TMPL_VAR NAME="title">
						</a>
					</li>
				</TMPL_LOOP>
				</ul>
			</li>
		</ul>
	</div>
	<!-- end sidebar -->

EndOfHTML

my $view = <<EndOfHTML;

<TMPL_VAR NAME="header">

	<!-- start content -->
	<div id="content">
		<div class="post">
			<h2 class="title"><span class="dingbat">&#x273b;</span> <TMPL_VAR NAME="post.title"></h2>
			<div class="entry">
				<TMPL_VAR NAME="post.body">
			</div>
			<form method="get">
			<input type="hidden" name="id" value='<TMPL_VAR NAME="post.id">' />
			<button name="action" value="edit" id="x">Edit</button>&nbsp;&nbsp;&nbsp;&nbsp;
			<button name="action" value="list" id="x">Cancel</button>
			</form>
		</div>
	</div>
	<!-- end content -->

<TMPL_VAR NAME="footer">

EndOfHTML


my $error = <<EndOfHTML;

<TMPL_VAR NAME="header">
<TMPL_VAR NAME="footer">

EndOfHTML

my $pager = <<EndOfHTML;

<TMPL_IF NAME="first"><a class='pager' href='<TMPL_VAR NAME="first">'>first</a><TMPL_ELSE>first</TMPL_IF>
<TMPL_IF NAME="previous"><a class='pager' href='<TMPL_VAR NAME="previous">'>&laquo;previous</a><TMPL_ELSE>&laquo;previous</TMPL_IF>
<TMPL_IF NAME="next"><a class='pager' href='<TMPL_VAR NAME="next">'>next&raquo;</a><TMPL_ELSE>next&raquo;</TMPL_IF>
<TMPL_IF NAME="last"><a class='pager' href='<TMPL_VAR NAME="last">'>last</a><TMPL_ELSE>last</TMPL_IF>

EndOfHTML

### METHODS ###

sub new {
	return bless {}, shift;
}

sub get {
	my $self = shift;
	my $name = shift;

	$name eq "css"      && return Miril::Theme::Flashyweb::Stylesheet::get();

	$name eq "account"  && return $account;
	$name eq "edit"     && return $edit;
	$name eq "files"    && return $files;
	$name eq "footer"   && return $footer;
	$name eq "header"   && return $header;
	$name eq "list"     && return $list;
	$name eq "login"    && return $login;
	$name eq "publish"  && return $publish;
	$name eq "sidebar"  && return $sidebar;
	$name eq "view"     && return $view;
	$name eq "upload"   && return $upload;
	$name eq "error"    && return $error;
	$name eq "search"   && return $search;
	$name eq "pager"    && return $pager;
}

1;
