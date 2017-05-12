# Copyright (C) 2000-2002, Free Software Foundation FSF.

package PPresenter::Formatter::Markup;

# The markup formatter looks a bit like HTML, but certainly is
# not fully compliant.

use strict;
use PPresenter::Formatter;
use base 'PPresenter::Formatter';

use Tk;
use PPresenter::Formatter::Markup_parser;
use PPresenter::Formatter::Markup_placer;
#use PPresenter::Formatter::Markup_html;


use constant ObjDefaults =>
{ -name             => 'markup'
, -aliases          => [ 'Markup', 'hypertext', 'html', 'default' ]

, logicals          =>
  { BLOCKQUOTE => 'BQ'
  , CITE       => 'I'
  , CODE       => 'TT'
  , EM         => 'I'
  , FONT       => 'TEXT'
  , LARGE      => 'TEXT SIZE=+1'
  , BIG        => 'TEXT SIZE=+2'
  , HUGE       => 'TEXT SIZE=+3'
  , SMALL      => 'TEXT SIZE=-1'
  , STRONG     => 'TEXT SIZE=+1 B'
  , TITLE      => 'CENTER SIZE=+1'
  , FOOTER     => 'RIGHT I SIZE=-1'
  }
, specials          =>
  { amp        => '&'
  , lt         => '<'
  , gt         => '>'
  , quot       => '"'
  , quote      => '"'
  , nbsp       => ' '
  , dash       => '-'
  }
};

sub strip($$$)
{   my ($former, $show, $slide, $string) = @_;
    $string =~ s/<[^>]*>//g;
    $string;
}

sub addLogicals($@)
{   my $former  = shift;

    # The hash is replaced by a copy, and previous slides (if any)
    # will refer to the unchanged definition.
    $former->{logicals} = { %{$former->{logicals}}, @_ };
    $former;
}
sub addLogical($@) {shift->addLogicals(@_)}

sub addSpecialCharacters($@)
{   my $former  = shift;

    # The hash is replaced by a copy, and previous slides (if any)
    # will refer to the unchanged definition.
    $former->{specials} = { %{$former->{specials}}, @_ };
    $former;
}
sub addSpecialCharacter($@) {shift->addSpecialCharacters(@_)}

sub titleFormat($$)
{   my ($former, $view, $contents) = @_;
    return "<TITLE>$contents"
}

sub footerFormat($$)
{   my ($former, $view, $contents) = @_;
    return "<FOOTER>$contents"
}

#
# Export
#

sub toHTML($$$)
{   my ($former, $slide, $view, $contents) = @_;
    my $parsed = $former->parse($slide, $view, $contents);
    $former->html($parsed);
}

1;
