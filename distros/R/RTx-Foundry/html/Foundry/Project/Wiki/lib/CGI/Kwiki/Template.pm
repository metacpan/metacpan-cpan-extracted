package CGI::Kwiki::Template;
use base 'CGI::Kwiki', 'CGI::Kwiki::Privacy';
$VERSION = '0.18';
use strict;

CGI::Kwiki->rebuild if @ARGV and $ARGV[0] eq '--rebuild';

sub directory { 'template' }
sub suffix { 
    my ($self, $file) = @_;
    $file =~ /README/ ? '' : '.html';
}

sub process {
    my ($self, $template, %vars) = @_;
    my @vars = (
        $self->config->all,
        $self->cgi->all,
        $self->prefs->all,
        $self->driver->metadata->all,
        $self->all,
        %vars,
    );
    my @templates = ref $template ? @$template : $template;
    return join '', map {
        $self->render($self->read_template($_), @vars)
    } @templates;
}

sub read_template {
    my ($self, $template) = @_;
    my $template_file = -f "local/template/$template.html"
      ? "local/template/$template.html"
      : "template/$template.html";
    open TEMPLATE, $template_file
      or die "Can't open $template_file for input\n";
    binmode(TEMPLATE, ':utf8') if $self->use_utf8;
    my $template_text = do {local $/; <TEMPLATE>};
    close TEMPLATE;
    return $template_text;
}

sub render {
    my ($self, $template, %v) = @_;
    $template =~ s{\[%\s+IF\s+(\w+)\s+%\]
                   (.*?)
                   \[%\s+ELSE\s+%\]
                   (.*?)
                   \[%\s+END\s+%\]
                  }
                  {${\(defined $v{$1} && $v{$1} ? $2 : $3)}}gxs;
    $template =~ s{\[%\s+IF\s+(\w+)\s+%\]
                   (.*?)
                   \[%\s+END\s+%\]
                  }
                  {${\(defined $v{$1} && $v{$1} ? $2 : '')}}gxs;
    $template =~ s{([\?=])\{\{(.*?)\}\}}
                  {$1.$self->escape($self->interpolate($2, \%v))}eg;
    $template =~ s{\{\{(.*?)\}\}}
                  {$self->interpolate($1, \%v)}eg;
    $template =~ s{([\?=])\[%\s+(\w+)\s+%\]\n?}
                  {$1${\(defined $v{$2} ? $self->escape($v{$2}) : "")}}g;
    $template =~ s{\[%\s+(\w+)\s+%\]\n?}
                  {${\(defined $v{$1} ? $v{$1} : "<!-- '$1' not defined -->")}}g;
    $template =~ s{\[%\s+(\w+)\(([^()]*?)\)\s+%\]\n?}
                  {${\ $self->call_function($1, $2)}}g;
    $template =~ s{\[%\s+(\w+\.\w+)\(([^()]*?)\)\s+%\]\n?}
                  {${\ $self->call_plugin($1, $2)}}g;
    return $template;
}

sub interpolate {
    my ($self, $text, $v) = @_;
    my $re;
    $text = $self->loc($text);
    $re = qr/\[((?:(?>[^\[\]]+)|(??{$re}))*)\]/;
    $text =~ s{$re}
              {<a href="[% script %]?$1">$1</a>}g;
    $text =~ s{\[%\s+(\w+)\s+%\]\n?}
              {${\(defined $v->{$1} ? $v->{$1} : "<!-- '$1' not defined -->")}}g;
    $text;
}

sub can_call {
    my ($self, $function) = @_;
    $function eq 'checkbox';
}

sub call_function {
    my ($self, $function, $args) = @_;
    my @args = split /\s+/, $args;
    if ($self->can_call($function)) {
        return $self->$function(@args);
    }
    else {
        return "<!-- Can't call $function() -->"
    }
}

sub call_plugin {
    my ($self, $packed1, $packed2) = @_;
    my $return;
    eval {
        $return = $self->driver->plugin->call_packed($1, $2);
    };
    return "<!-- $@ -->" if $@;
    return $return;
}

sub checkbox {
    my ($self, $boxname) = @_;
    my $prefs = $self->driver->cookie->prefs;
    my $checked = $prefs->{$boxname} ? ' checked' : '';
    return qq{<input type="checkbox" name="$boxname"$checked>};
}

1;

__DATA__

=head1 NAME 

CGI::Kwiki::Template - HTML Template Base Class for CGI::Kwiki

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

__README__
Any templates that you modify should be copied to a "local/template/"
directory first. This will keep them from being clobbered by upgrades to
CGI::Kwiki. CGI::Kwiki automatically looks for templates in the
local/template/ directory before searching the template/ directory.
__basic_footer__
  </div><!-- close "blogbody" -->
</div><!-- close "blog" -->
</div><!-- close "content" -->

<div id="links">

<div class="sidetitle">
{{Search}}
</div><!-- close "sidetitle" -->

<div class="side">
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="search" size="15" value="{{Search}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
</div><!-- close "side" -->

<div class="sidetitle">
{{Import}}
</div><!-- close "sidetitle" -->

<div class="side">
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="search" size="15" value="{{Import}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="import" />
</form>
</div><!-- close "side" -->

<div class="sidetitle">
{{KwikiNavigation}}
</div><!-- close "sidetitle" -->

<div class="side">
<span><a href="[% script %]?[% top_page %]" accesskey="1">[% loc_top_page %]</a></span>
[% IF has_privacy %]
<span><a href="blog.cgi">[% loc_blog_page %]</a></span>
[% END %]
<span><a href="[% script %]?[% changes_page %]">[% loc_changes_page %]</a></span>
<span><a href="[% script %]?action=prefs">[% loc_preferences_page %]</a></span>
</div><!-- close "side" -->

<div class="powered">
Powered by:<br /><a href="http://kwiki.org">Kwiki 0.18</a>
</div><!-- close "powered" -->

</div><!-- close "links" -->

</body>
</html>
__blog_entry__
  <div class="blogbody">
    <div class="blog-meta">
    <span class="blog-date"><h2 class="date"><a href="blog.cgi?[% blog_id %]">[% blog_date %]</a></h2></span>
    <a id="[% blog_id %]"></a>
    <span class="blog-title"><h3 class="title"><a href="kwiki.cgi?[% page_id %]">[% page_id %]</a></h3></span>
    </div>
[% entry_text %]
  </div><!-- close "blogbody" -->
__blog_footer__
</div><!-- close "blog" -->
</div><!-- close "content" -->

<div id="links">

<div class="sidetitle">
{{Search}}
</div><!-- close "sidetitle" -->

<div class="side">
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="search" size="15" value="{{Search}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
</div><!-- close "side" -->

<div class="sidetitle">
{{Import}}
</div><!-- close "sidetitle" -->

<div class="side">
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="search" size="15" value="{{Import}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="import" />
</form>
</div><!-- close "side" -->

<div class="sidetitle">
{{KwikiNavigation}}
</div><!-- close "sidetitle" -->

<div class="side">
<span><a href="[% script %]?[% top_page %]" accesskey="1">[% loc_top_page %]</a></span>
[% IF has_privacy %]
<span><a href="blog.cgi">[% loc_blog_page %]</a></span>
[% END %]
<span><a href="[% script %]?[% changes_page %]">[% loc_changes_page %]</a></span>
<span><a href="[% script %]?action=prefs">[% loc_preferences_page %]</a></span>
</div><!-- close "side" -->

<div class="powered">
Powered by:<br /><a href="http://kwiki.org">Kwiki 0.18</a>
</div><!-- close "powered" -->

</div><!-- close "links" -->

</body>
</html>
__blog_header__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=[% encoding %]" />
  <title>[% title_prefix %]: {{Blog}}</title>
  <link rel="stylesheet" type="text/css" href="css/[% stylesheet %]">
  <link rel="stylesheet" type="text/css" href="css/Display.css">
  <link rel="shortcut icon" href="[% favicon %]" />
  <link rel="start" href="index.cgi" title="Home" />
  <!-- <script src="javascript/Blog.js"></script> -->
</head>

<body>

<div id="banner">
<img src="[% kwiki_image %]" style="float:right" title="[% slogan %]" alt="">
<h1><a href="blog.cgi">{{Kwiki Blog}}</a></h1>
<span class="description">[% slogan %]</span>
</div>

<div id="content">
<div class="blog">

<h1><a href="blog.cgi">{{Kwiki Blog}}</a></h1>

<div class="upper-nav"><a href="#skip-upper-nav" style="display:none">{{Kwiki Blog}}</a><a href="[% script %]?[% top_page %]" accesskey="1">[% loc_top_page %]</a> | 
[% IF has_privacy %]
<a href="blog.cgi">[% loc_blog_page %]</a> | 
[% END %]
<a href="[% script %]?[% changes_page %]">[% loc_changes_page %]</a> | 
<a href="[% script %]?action=prefs">[% loc_preferences_page %]</a> | 
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="search" size="15" value="{{Search}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
</div><!-- close "upper-nav" -->
<a id="skip-upper-nav"></a>
__display_body__
<div class="wiki">
[% display %]
</div>

[% IF is_editable %]
<hr />
<form class="edit">
<input type="submit" name="button-edit" value="{{EDIT}}">
[% ELSE %]
<form action="admin.cgi" class="admin">
<input type="submit" name="button-login" value="{{LOGIN}}">
[% END %]
<input type="hidden" name="action" value="edit">
<input type="hidden" name="page_id" value="[% page_id %]">
</form>

[% IF show_changed %]
    <div class="posted">
    <i>{{This page last changed on [[% edit_time %]] by [[% edit_by %]]}}</i><br />
    </div><!-- close "posted" -->
[% END %]

  </div><!-- close "blogbody" -->

  <div class="comments-head">
[% Diff.entry_form() %]
  </div><!-- close "comments-head" -->

  <div class="comments-body">
  <br /><a id="diff"></a>
[% Diff.display_diff() %]
__display_footer__
  </div><!-- close "comments-body" -->
</div><!-- close "blog" -->
</div><!-- close "content" -->

<div id="links">

<div class="sidetitle">
{{Search}}
</div><!-- close "sidetitle" -->

<div class="side">
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="search" size="15" value="{{Search}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
</div><!-- close "side" -->

<div class="sidetitle">
{{Import}}
</div><!-- close "sidetitle" -->

<div class="side">
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded">
<input type="text" name="import" size="15" value="{{Import}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="import" />
</form>
</div><!-- close "side" -->

<div class="sidetitle">
{{KwikiNavigation}}
</div><!-- close "sidetitle" -->

<div class="side">
<span><a href="[% script %]?[% top_page %]" accesskey="1">[% loc_top_page %]</a></span>
[% IF has_privacy %]
<span><a href="blog.cgi">[% loc_blog_page %]</a></span>
[% END %]
<span><a href="[% script %]?[% changes_page %]">[% loc_changes_page %]</a></span>
<span><a href="[% script %]?action=prefs">[% loc_preferences_page %]</a></span>
</div><!-- close "side" -->

<div class="powered">
Powered by:<br /><a href="http://kwiki.org">Kwiki 0.18</a>
</div><!-- close "powered" -->

</div><!-- close "links" -->

</body>
</html>
__display_header__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=[% encoding %]" />
  <title>[% title_prefix %]: [% page_id %]</title>
  <link rel="stylesheet" type="text/css" href="css/[% stylesheet %]">
  <link rel="stylesheet" type="text/css" href="css/Display.css">
  <link rel="shortcut icon" href="[% favicon %]" />
  <link rel="start" href="index.cgi" title="Home" />
  <!-- <script src="javascript/Display.js"></script> -->
</head>

[% IF is_diff %]
<body class="diff">
[% ELSE %]
<body>
[% END %]

<div id="banner">
<img src="[% kwiki_image %]" style="float:right" title="[% slogan %]" alt="">
<h1>[% title_prefix %]</h1>
<span class="description">[% slogan %]</span>
<span style="display: none"><a href="#skip-upper-nav">&gt;&gt;</a></span>
</div>

<!-- sister_html not available yet -->

<div id="content">
<div class="blog">
  <div class="blogbody">

  <a id="entry"></a>
  <h2 class="title"><a href="[% script %]?action=search&search=[% page_id %]">[% page_id %]</a></h2>

<div class="upper-nav">
<a href="[% script %]?[% top_page %]" accesskey="1">[% loc_top_page %]</a> | 
[% IF has_privacy %]
<a href="blog.cgi">[% loc_blog_page %]</a> | 
[% END %]
<a href="[% script %]?[% changes_page %]">[% loc_changes_page %]</a> | 
<a href="[% script %]?action=prefs">[% loc_preferences_page %]</a> | 
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded" style="display: inline">
<input type="text" name="search" size="15" value="{{Search}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="search" />
</form>
|
<form method="post" action="[% script %]" enctype="application/x-www-form-urlencoded" style="display: inline">
<input type="text" name="import" size="15" value="{{Import}}" onfocus="this.value=''" />
<input type="hidden" name="action" value="import" />
</form>
</div><!-- close "upper-nav" -->
<a id="skip-upper-nav"></a>

  <hr />
__edit_body__
<h2 class="comments-head">{{EDIT}}</h2>

<div class="comments-post">
<br />
<script src="javascript/Edit.js"></script>
<form method="post" 
      action="[% script %]" 
      enctype="application/x-www-form-urlencoded">
<input type="hidden" name="action" value="edit">
<input type="hidden" name="page_id" value="[% page_id %]">
<input type="hidden" name="version_mark" value="[% version_mark %]">
<input type="submit" name="button-save" value="{{SAVE}}">
<input type="text" name="page_id_new" value="[% page_id_new %]" 
       size="15" onfocus="this.value=''">
<input type="submit" name="button-preview" value="{{PREVIEW}}">
<br />
[% IF error_msg %]
<br />
<div class="error">[% error_msg %]</div>
[% END %]
<br />
[% IF is_admin %]
<br />
<input type="radio" name="privacy" value="public"[% public_checked %]>
<b>{{Public}}</b>
<input type="radio" name="privacy" value="protected"[% protected_checked %]>
<b>{{Protected}}</b>
<input type="radio" name="privacy" value="private"[% private_checked %]>
<b>{{Private}}</b><br />
[% END %]

<textarea name="wiki_text" 
          rows="25"
          cols="65" 
          wrap="virtual"
>[% wiki_text %]</textarea>
<br />
[% history %]
<br />
[% IF is_admin %]
<br />
<input type="checkbox" name="blog"
       onclick="setProtected(this)">
<b>{{Blog this page on SAVE}}</b><br />
<input type="checkbox" name="delete"
       onclick="setForDelete(this)">
<b>{{Permanently delete this page on SAVE}}</b><br />
[% END %]
</form>

</div><!-- close "comments-post" -->
__prefs_body__
[% IF not_admin %]
<form method="post" enctype="application/x-www-form-urlencoded" action="admin.cgi" 
>
<input type="submit" name="button-login" value="{{LOGIN}}">
<input type="hidden" name="action" value="prefs">
<b>{{(You must be a site administrator to login)}}</b>
</form>
<hr />
[% END %]

[% IF is_admin %]
<form method="post" enctype="application/x-www-form-urlencoded" action="kwiki.cgi" 
>
<input type="submit" name="button-logout" value="{{LOGOUT}}">
<input type="hidden" name="action" value="prefs">
</form>
<hr />
[% END %]

<form>
<p>{{Your [KwikiUserName] will be used to indicate who changed a page. This can be viewed in [[% changes_page %]].}}
</p>
<span style="color:red">[% error_msg %]</span>
{{UserName: &nbsp;}}
<input type="text" name="user_name" value="[% user_name %]" size="20"> 
<br /><br />
[% checkbox(show_changed) %] {{Show changed message at bottom of display.}}<br />
[% checkbox(select_diff) %] {{Show diff pulldown at bottom of display.}}<br />
[% checkbox(show_diff) %] {{Show latest diff at bottom of display.}}<br />
<br />
<input type="submit" name="button-save" value="{{SAVE}}">
<b>{{(Click the SAVE button after making changes)}}</b>
<input type="hidden" name="action" value="prefs">
</form>
__preview_body__
<h2 class="comments-head">{{PREVIEW}}</h2>

<div class="comments-post">

[% preview %]

</div><!-- close "comments-post" -->

<hr />
__protected_edit_body__
  <b>{{This is a protected page. Only the site administrator can edit it.}}</b>
__slide_page__
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=[% encoding %]" />
  <title>[% page_id %] - {{KwikiSlides}}</title>
  <link rel="stylesheet" type="text/css" href="css/[% stylesheet %]">
  <link rel="stylesheet" type="text/css" href="css/SlideShow.css">
  <script src="javascript/SlideShow.js"></script>
</head>

<body style="[% IF bgcolor %]background-color:[% bgcolor %];[% END %][% IF fgcolor %]color: [% fgcolor %];[% END %]">

<div class="slide-body">
<div class="blogbody">

<div id="banner" style="line-height:100%">
<h2>[% title %]</h2>
[% IF subtitle %]<h4>( [% subtitle %] )</h4>[% END %]
</div><!-- close "banner" -->

<div style="padding:5%">
[% slide %]
</div>

<form method="POST" action="[% script %]">
<input type="hidden" name="control" value="none">
<input type="hidden" name="slide_num" value="[% slide_num %]">
<input type="hidden" name="line_num" value="[% line_num %]">
<input type="hidden" name="action" value="slides">
<input type="hidden" name="page_id" value="[% page_id %]">
</form>

</div><!-- close "blogbody" -->
</div><!-- close "slide-body" -->

</body>
</html>
