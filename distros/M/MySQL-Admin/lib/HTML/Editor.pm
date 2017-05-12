package HTML::Editor;
use MySQL::Admin qw(translate);
use utf8;
use strict;
use warnings;
use vars qw(
  $defaultconfig
  $catlist
  $class
  $DefaultClass @EXPORT  @ISA
  $path
  $right
  $server
  $style
  $title
  $body
  $action
  $reply
  $thread
  $headline
  $html
  $template
  $atemp
  $attach
  $button
  );
$style = 'mysql';
require Exporter;
@HTML::Editor::ISA         = qw( Exporter Template::Quick);
@HTML::Editor::EXPORT_OK   = qw(initEditor show JsEnabled );
%HTML::Editor::EXPORT_TAGS = ('all' => [qw(initEditor show JsEnabled)]);

$HTML::Editor::VERSION = '1.12';

$DefaultClass = 'HTML::Editor' unless defined $HTML::Editor::DefaultClass;

$defaultconfig = '%CONFIG%';

our $m_bJsEnabled = 1;
$right = 0;

=head1 NAME

HTML::Editor - BBCODE and HTML Editor

=head3 export_ok

initEditor show JsEnabled

=head3 function sets

Here is a list of the function sets you can import:

:all initEditor show JsEnabled

=head2 new()

=cut

sub new {
    my ($class, @initializer) = @_;
    my $self = {};
    bless $self, ref $class || $class || $DefaultClass;
    $self->initEditor(@initializer) if (@initializer);
    return $self;
}

=head2 initEditor()

       my %parameter =(

                action   = > 'action',

                body     => 'body of the message',

                class    => "min",

                attach   => '1.01',

                path   => "/srv/www/cgi-bin/templates",#default : '/srv/www/cgi-bin/templates'

                reply    =>  '', #default : ''

                server   => "http://localhost", #default : 'http://localhost'

                style    =>  $style, #default : 'mysql'

                thread   =>  'news',#default : ''

                headline    => "&New Message", #default : 'headline'

                html     => 1 , # html enabled ? 0 for bbcode default : 0

                text     => 'the body', #default : 'headline'

       );

       my $editor = new HTML::Editor(\%parameter);

       print $editor->show();

=cut

sub initEditor {
    my ($self, @p) = getSelf(@_);
    my $hash = $p[0];
    $server       = defined $hash->{server}     ? $hash->{server}     : 'http://localhost';
    $style        = defined $hash->{style}      ? $hash->{style}      : 'mysql';
    $title        = defined $hash->{title}      ? $hash->{title}      : 'Editor';
    $m_bJsEnabled = defined $hash->{javascript} ? $hash->{javascript} : 1;
    $path =
      defined $hash->{path}
      ? $hash->{path}
      : '/srv/www/cgi-bin/templates';
    $body     = defined $hash->{body}     ? $hash->{body}     : 'Text';
    $action   = defined $hash->{action}   ? $hash->{action}   : 'addMessage';
    $reply    = defined $hash->{reply}    ? $hash->{reply}    : '';
    $thread   = defined $hash->{thread}   ? $hash->{thread}   : 'news';
    $headline = defined $hash->{headline} ? $hash->{headline} : 'headline';
    $catlist  = defined $hash->{catlist}  ? $hash->{catlist}  : '';
    $right    = defined $hash->{right}    ? $hash->{right}    : 0;
    $html     = $hash->{html}             ? $hash->{html}     : 0;
    $template = defined $hash->{template} ? $hash->{template} : 'editor.htm';
    $atemp    = defined $hash->{atemp}    ? $hash->{atemp}    : '';
    $attach   = defined $hash->{attach}   ? $hash->{attach}   : '';
    my $config = defined $hash->{config} ? $hash->{config} : $defaultconfig;
    $class = 'min' unless (defined $class);
    my %template = (
                    path     => $hash->{path},
                    style    => $style,
                    template => $template,
                    config   => $config,
                   );
    $self->SUPER::initTemplate(\%template);
}

=head2 show()

=cut

sub show {
    my ($self, @p) = getSelf(@_);
    $self->initEditor(@p) if (@p);
    my %parameter = (
                     path   => $path,
                     style  => $style,
                     title  => $title,
                     server => $server,
                     id     => 'winedit',
                     class  => $class,
                    );
    my $cf = translate('choosefile');
    my $att =
      ($right >= 2)
      ? qq|<div id="divInputFile" class="divInpuFile" onclick="document.getElementById('inputFile').click();"><a id="" class="label">$cf<input class="inputFile" name="file" type="file" id="inputFile" /></div>|
      : $attach;

    my %editor = (
                  name     => 'editor',
                  server   => $server,
                  style    => $style,
                  title    => $title,
                  body     => $body,
                  action   => $action,
                  reply    => $reply,
                  thread   => $thread,
                  headline => $headline,
                  catlist  => $catlist,
                  attach   => $att,
                  html     => $html,
                  atemp    => $atemp,
                  buttons  => $m_bJsEnabled ? buttons() : '',
                 );
    return $self->SUPER::appendHash(\%editor);

}

=head1

return the browser buttons

=cut

sub buttons {
    $style = $_[0] ? shift : $style;
    $button  = $_[0] ? shift : 1;
    my $buttons = qq|
     <table class="batch">
     <tr>
     <td>
     <a style ="cursor:pointer;" onclick="left();" class="editorButtons" title="left">&#xea77;</a>
     
     <a style ="cursor:pointer;" onclick="center();" class="editorButtons" title="center">&#xea78;</a>
     
     <a style ="cursor:pointer;" onclick="aright()" class="editorButtons" title="right">&#xea79;</a>
     
     <a style ="cursor:pointer;" onclick="bold();" class="editorButtons" title="bold">&#xea62;</a>
          
     <a style ="cursor:pointer;" onclick="italicize();" class="editorButtons" title="italic">&#xea64;</a>
     
     <a style ="cursor:pointer;" onclick="strike();" class="editorButtons" title="strike">&#xea65;</a>
     
     <a style ="cursor:pointer;" onclick="underline();" class="editorButtons" title="underline">&#xea63;</a>
     
     <a style ="cursor:pointer;" onclick="sub();" class="editorButtons" title="sub">&#xea6b;</a>
     
     <a style ="cursor:pointer;" onclick="sup();" class="editorButtons" title="sup">&#xea6c;</a>
     
     <a style ="cursor:pointer;" onclick="img();" class="editorButtons" title="image">&#xe90d;</a>
     
     <a style ="cursor:pointer;" onclick="link();" class="editorButtons" title="link">&#xe9cb;</a>
     
     <a style ="cursor:pointer;" onclick="email();" class="editorButtons" title="email">&#xea84;</a>
     </td>|;

    if ($right >= 2 && $button) {
        $buttons .=
            '<td class="'
          . ($html ? 'htmlButtonChecked' : 'htmlButton')
          . q|" style ="cursor:pointer;" onclick="enableHtml();checkButton('htmlButton',this)"><input type="checkbox" onclick="enableHtml();" id="htmlButton" class="markBoxEditor" name="format"|
          . ($html ? 'checked="checked"' : '')
          . '/><a class="label">html</a></td>';
    }
    $buttons .= '</tr></table>';
    return $buttons;
}

=head2 JsEnabled()

default: 1;

=cut

sub JsEnabled {
    my ($self, @p) = getSelf(@_);
    if (defined $p[0] && $p[0] =~ /(\w+)/) {
        $m_bJsEnabled = $1;
    } else {
        return $m_bJsEnabled;
    }
}

=head2 getSelf()

=cut

sub getSelf {
    return @_
      if defined($_[0])
      && (!ref($_[0]))
      && ($_[0] eq 'HTML::Editor');
    return (
            defined($_[0]) && (ref($_[0]) eq 'HTML::Editor'
                               || UNIVERSAL::isa($_[0], 'HTML::Editor'))
           ) ? @_ : ($HTML::Editor::DefaultClass->new, @_);
}

=head1 AUTHOR

Dirk Lindner <lze@cpan.org>

L<CGI> L<HTML::Editor::BBCODE> L<MySQL::Admin::GUI>

=head1 LICENSE

Copyright (C) 2005 - 201 by Hr. Dirk Lindner

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public License
as published by the Free Software Foundation;
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Lesser General Public License for more details.

=cut

1;
