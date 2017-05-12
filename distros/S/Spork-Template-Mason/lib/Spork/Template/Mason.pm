package Spork::Template::Mason;

use strict;
use warnings;

use vars qw($VERSION);

use Spoon::Template::Mason '-base';
use Spoon::Installer '-base';

$VERSION = 0.04;

sub plugins { {} }

sub extract_to
{
    my $self = shift;
    $self->hub->config->template_directory;
}

sub path
{
    my $self = shift;
    $self->hub->config->template_path ||
      [ $self->hub->config->template_directory ];
}

1;

__DATA__
__autohandler__
<& top.mas, %ARGS &>
% $m->call_next;
<& bottom.mas, %ARGS &>
__top.mas__
<!-- BEGIN top.mas -->
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title><% $slide_heading | h %></title>
<meta name="Content-Type" content="text/html; charset=<% $character_encoding %>">
<meta name="generator" content="<% $spork_version | h %>">
<link rel='stylesheet' href='slide.css' type='text/css'>
<link rel='icon' HREF='favicon.png'>
<style>
% if ( $hub->can('css') ) {
%   foreach my $f ( $hub->css->files ) {
<link rel="stylesheet" type="text/css" href="<% $f | h %>" />
%   }
% }
<style type="text/css"><!--
<& slide.css, %ARGS &>
--></style>
<script type="text/javascript">
<& controls.js, %ARGS &>
</script>
</head>
<body>
<div id="topbar">
 <table width='100%'>
  <tr>
   <td width="13%"><% $presentation_topic | h %></td>
   <td align="center" width="73%">
    <a accesskey="s" href="<% $index_slide | h %>"><% $presentation_title | h %></a>
   </td>
   <td align="right" width="13%">
% if ($slide_num) {
    <% $slide_num | h %>
% } else {
    &nbsp;
% }
   </td>
  </tr>
 </table>
</div>
<!-- END top.html -->
<%args>
$slide_heading => ''
$spork_version => ''
$character_encoding => 'utf-8'
$background_image => ''
$index_slide => ''
$presentation_topic => ''
$presentation_title => ''
$slide_num => 0
$hub
</%args>
__bottom.mas__
<!-- BEGIN bottom.html -->
<div id="bottombar">
 <table width="100%">
  <tr>
   <td align="left" valign="middle">
    <div<% $show_controls ? '' : ' style="display:none"' %>>
<&| .no_empty_links &>
     <a accesskey='p' href="<% $prev_slide | h %>"><% $link_previous %></a> |
     <a accesskey='i' href="<% $index_slide | h %>"><% $link_index %></a> |
     <a accesskey='n' href="<% $next_slide %>"><% $link_next %></a>
</&>
    </div>
   </td>
   <td align="right" valign="middle">
    <% $copyright_string %>
   </td>
  </tr>
 </table>
</div>
<div id="logo"></div>

<div id="spacer">
 <a name="end"></a>
</div>
</body>
</html>
<!-- END bottom.html -->
<%args>
$prev_slide => ''
$index_slide => ''
$next_slide => ''
$copyright_string
$show_controls => 0
$link_previous => ''
$link_index => ''
$link_next => ''
</%args>

<%init>
$prev_slide ||= 'start.html'
    unless $m->request_comp->source_file =~ /start\.html/;
</%init>

<%def .no_empty_links>\
<% $c %>\
<%init>
my $c = $m->content;
$c =~ s{<a href="">([^<]+)</a>}{$1}g;
</%init>
</%def>
__index.html__
<!-- BEGIN bottom.html -->
<div id="content"><p />
 <div class="top_spacer"></div>
 <ol>
% foreach my $slide (@slides) {
  <li> <a href="<% $slide->{slide_name} | h %>"><% $slide->{slide_heading} | h %></a>
% }
 </ol>
</div>
<!-- END index.html -->
<%args>
@slides
</%args>
__start.html__
<!-- BEGIN start.html -->
<div id="content"><p />
 <div class="top_spacer"></div>
 <center>
 <h4><% $presentation_title | h %></h4>
 <p />
 <h4><% $author_name | h %></h4>
 <h4><% $author_email | h %></h4>
 <p />
 <h4><% $presentation_place | h %></h4>
 <h4><% $presentation_date | h %></h4>
 </center>
</div>
<!-- END start.html -->
<%args>
$presentation_title
$author_name => ''
$author_email => ''
$presentation_place => ''
$presentation_date => ''
</%args>
__slide.html__
<!-- BEGIN slide.html -->
<div id="content"><p />
 <div class="top_spacer"></div>
 <% $image_html %>
 <% $slide_content %>
% unless ($last) {
 <small>continued...</small>
% }
</div>
<!-- END slide.html -->
<%args>
$image_html
$slide_content
$last
</%args>
__slide.css__
/* BEGIN slide.css */
hr {
    color: #202040;
    height: 0px;
    border-top: 0px;
    border-bottom: 3px #202040 ridge;
    border-left: 0px;
    border-right: 0px;
}

a:link {
    color: #123422;
    text-decoration: none;
}

a:visited {
    color: #123333;
    text-decoration: none;
}

a:hover {
    text-decoration: underline;
}

p {
    font-size: 24pt;
    margin: 6pt;
}

div p {
    font-size: 18pt;
    margin-top: 12pt;
    margin-bottom: 12pt;
    margin-left: 6pt;
    margin-right: 6pt;
}

small {
    font-size: 9pt;
    font-style: italic;
}

#topbar {
    background: <% $banner_bgcolor %>;
    color: blue;
    position:absolute;
    right: 5px;
    left: 5px;
    top: 5px;
}

#bottombar {
    background: <% $banner_bgcolor %>;
    color: blue;
    position: fixed;
    right: 5px;
    left: 5px;
    bottom: 5px;
    height: 50px;
    z-index: 0;
}

.top_spacer {
    height: 0px;
    margin: 0px 0px 0px 0px;
    padding: 1px 0px 0px 0px;
}

.spacer {
    bottom: 5px;
    height: 50px;
}

#content {
    background:#fff;
    margin-left: 20px;
    margin-right:20px;
    margin-top: 80px;
}


#logo {
    position: fixed;
    right: 40px;
    bottom: 51px;
    width: 130px;
    height: 150px;
    z-index:3;
% if ( defined $logo_image ) {
    background-image: url(<% $images_directory %>/<% $logo_image %>);
% }
    background-repeat: no-repeat;
}
/* END index.css */
<%args>
$banner_bgcolor
$images_directory => ''
$logo_image => undef
</%args>

<%flags>
inherit => undef
</%flags>
__controls.js__
// BEGIN controls.js
function nextSlide() {
    window.location = '<% $next_slide %>';
}

function prevSlide() {
    window.location = '<% $prev_slide %>';
}

function indexSlide() {
    window.location = 'index.html';
}

function startSlide() {
    window.location = 'start.html';
}

function closeSlide() {
    window.close();
}

function handleKey(e) {
    var key;
    if (e == null) {
        // IE
        key = event.keyCode
    } 
    else {
        // Mozilla
        if (e.altKey || e.ctrlKey) {
            return true
        }
        key = e.which
    }
    switch(key) {
        case 8: prevSlide(); break
        case 13: nextSlide(); break
        case 32: nextSlide(); break
        case 81: closeSlide(); break
        case 105: indexSlide(); break
        case 110: nextSlide(); break
        case 112: prevSlide(); break
        case 115: startSlide(); break
        default: //xxx(e.which)
    }
}

document.onkeypress = handleKey
% if ($mouse_controls) {
document.onclick = nextSlide
% }
// END controls.js
<%args>
$prev_slide => ''
$next_slide => ''
$mouse_controls
</%args>


__END__

=head1 NAME

Spork::Template::Mason - Spork templating with Mason

=head1 SYNOPSIS

  # in your config.yaml file

  template_class: Spork::Template::Mason
  files_class: Spork::Template::Mason

=head1 DESCRIPTION

At present, this module's only purpose it to provide a default set of
Mason templates for Spork.  These templates are more or less identical
to the TT2 templates included in the main Spork distro.  You'll
probably want to customize these.

=head1 USAGE

Just set "template_class" and "files_class" in your F<config.yaml>
file to C<Spork::Template::Mason>.

=head1 SUPPORT

Support questions can be sent to me via email.

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/ReportBug.html?Queue=spork-template-mason or
via email at bug-spork-template-mason@rt.cpan.org.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
