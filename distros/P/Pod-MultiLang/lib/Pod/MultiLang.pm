## ----------------------------------------------------------------------------
#  Pod::MultiLang::Html
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright YAMASHINA Hio
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/lib/Pod/MultiLang.pm 624 2008-02-06T09:15:55.362158Z hio  $
# -----------------------------------------------------------------------------
package Pod::MultiLang;
use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.14';

use Pod::Parser;
use Pod::InputObjects;
our @ISA = qw(Pod::Parser);
use Carp;

use constant
{
  PARA_VERBATIM  => 1,
  PARA_TEXTBLOCK => 2,
  PARA_HEAD      => 3,
  PARA_OVER      => 4,
  PARA_BACK      => 5,
  PARA_ITEM      => 6,
  PARA_BEGIN     => 7,
  PARA_END       => 8,
  PARA_FOR       => 9,
  PARA_ENCODING  => 10,
  PARA_POD       => 11,
  PARA_CUT       => 12,
};
use constant
{
  PARAINFO_TYPE     => 0,
  PARAINFO_PARAOBJ  => 1,
  # =head
  PARAINFO_CONTENT  => 2,
  PARAINFO_ID       => 3,
  PARAINFO_HEADSIZE => 4,
  # =over,item,back
  PARAINFO_LISTTYPE => 2,
  #PARAINFO_ID       => 3,
};
use constant
{
  LISTTYPE_UL => 'ul',
  LISTTYPE_OL => 'ol',
  LISTTYPE_DL => 'dl',
};
use constant
{
  DEFAULT_LANG => 'en',
  LANGS => 'en',
};


# -----------------------------------------------------------------------------
# new
#
sub new
{
  my $pkg = shift;
  my $this = $pkg->SUPER::new(@_);
  my %arg = @_;
  if( !$arg{langs} )
  {
    $this->{opt_langs} = [split(/[,:]/,LANGS)];
  }elsif( ref($arg{langs})eq'ARRAY' )
  {
    $this->{opt_langs} = $arg{langs};
  }elsif( !ref($arg{langs}) )
  {
    $this->{opt_langs} = [split(/[,:]/,$arg{langs})];
  }else
  {
    croak "invalid langs (is ref, but not ARRAY-ref): [$arg{langs}]";
  }
  
  $this;
}

# =============================================================================
# Pod::Parser handler.
# =============================================================================

# -----------------------------------------------------------------------------
# begin_pod
#  initialize pod parsing.
#
sub begin_pod
{
  my ($parser, $command, $paragraph, $line_num) = @_;
  $parser->{langs} = [@{$parser->{opt_langs}}];
  $parser->{paras} = [];
  $parser->{heads} = [];
  $parser->{items} = [];
  
  $parser->{_neststack} = [];
  $parser->{_skipblock} = undef;
}

sub end_pod
{
}

# -----------------------------------------------------------------------------
# command
#   parse command paragraph.
#
sub command
{ 
  my ($parser, $command, $paragraph, $line_num, $pod_para) = @_;
  $paragraph =~ s/^\s+//;
  $paragraph =~ s/\s+$//;
  
  # skip non-supported begin-end blocks
  # 対象外の begin-end 間はスキップ
  if( defined($parser->{_skipblock}) )
  {
    if( $command eq 'end' && $parser->{_skipblock} eq $paragraph )
    {
      $parser->{_skipblock} = undef;
    }
    return;
  }
  
  if( $command =~ /^head[1-4]$/ )
  {
    my $para = [PARA_HEAD,$pod_para];
    push(@{$parser->{paras}},$para);
    push(@{$parser->{heads}},$para);
  }elsif( $command eq 'over' )
  {
    my $para = [PARA_OVER,$pod_para];
    push(@{$parser->{_neststack}},[$para]);
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'back' )
  {
    my $para = [PARA_BACK,$pod_para];
    my $info = pop(@{$parser->{_neststack}});
    if( ref($info) )
    {
      #warn "empty =over .. =back, at ".$info->[0][PARAINFO_PARAOBJ]->file_line()."\n";
      foreach(@$info)
      {
	$_->[PARAINFO_LISTTYPE] = LISTTYPE_UL;
      }
      $info = LISTTYPE_UL;
    }
    if( !defined($info) )
    {
      warn "=back without =over at ".$para->[PARAINFO_PARAOBJ]->file_line()."\n";
      $info = LISTTYPE_UL;
    }
    $para->[PARAINFO_LISTTYPE] = $info;
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'item' )
  {
    my $para = [PARA_ITEM,$pod_para];
    if( ref($parser->{_neststack}[-1]) )
    {
      $paragraph =~ s/^\s+//;
      $paragraph =~ s/\s+$//;
      my $type = $paragraph eq '*' ? LISTTYPE_UL
	           : $paragraph =~ /^\d+$/ ? LISTTYPE_OL 
		   : LISTTYPE_DL;
      foreach(@{$parser->{_neststack}[-1]})
      {
	$_->[PARAINFO_LISTTYPE] = $type;
      }
      $parser->{_neststack}[-1] = $type;
    }elsif( !@{$parser->{_neststack}} )
    {
      warn "=item without =over at ".$para->[PARAINFO_PARAOBJ]->file_line()."\n";
      $paragraph =~ s/^\s+//;
      $paragraph =~ s/\s+$//;
      my $type = $paragraph eq '*' ? LISTTYPE_UL
	           : $paragraph =~ /^\d+$/ ? LISTTYPE_OL 
		   : LISTTYPE_DL;
      push(@{$parser->{_neststack}},$type);
    }elsif( !defined$parser->{_neststack}[-1] )
    {
      warn "undefined item type at ".$para->[PARAINFO_PARAOBJ]->file_line()."\n";
      $parser->{_neststack}[-1] = LISTTYPE_UL;
    }
    $para->[PARAINFO_LISTTYPE] = $parser->{_neststack}[-1];
    push(@{$parser->{paras}},$para);
    push(@{$parser->{items}},$para);
  }elsif( $command eq 'begin' )
  {
    my $para = [PARA_BEGIN,$pod_para];
    $para->[PARAINFO_CONTENT] = $paragraph;
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'end' )
  {
    my $para = [PARA_END,$pod_para];
    $para->[PARAINFO_CONTENT] = $paragraph;
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'for' )
  {
    my $para = [PARA_FOR,$pod_para];
    $para->[PARAINFO_CONTENT] = $paragraph;
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'encoding' )
  {
    my $para = [PARA_ENCODING,$pod_para];
    $para->[PARAINFO_CONTENT] = $paragraph;
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'cut' )
  {
    my $para = [PARA_CUT,$pod_para];
    $para->[PARAINFO_CONTENT] = $paragraph;
    push(@{$parser->{paras}},$para);
  }elsif( $command eq 'pod' )
  {
    my $para = [PARA_POD,$pod_para];
    $para->[PARAINFO_CONTENT] = $paragraph;
    push(@{$parser->{paras}},$para);
  }else
  {
    warn "unknown command [$command] [$paragraph]";
  }
}

# -----------------------------------------------------------------------------
# verbatim
#   parse verbatim paragraph.
#
sub verbatim
{ 
  my ($parser, $paragraph, $line_num, $pod_para, ) = @_;
  
  if( defined($parser->{_skipblock}) )
  {
    return;
  }
  
  push(@{$parser->{paras}},[PARA_VERBATIM,$pod_para]);
}

# -----------------------------------------------------------------------------
# textblock
#   parse normal (text) paragraph.
#
sub textblock
{
  my ($parser, $paragraph, $line_num, $pod_para) = @_;
  
  if( defined($parser->{_skipblock}) )
  {
    return;
  }
  
  my $para = [PARA_TEXTBLOCK,$pod_para];
  push(@{$parser->{paras}},$para);
  return;
}

# =============================================================================
# UTILITY METHODS
# =============================================================================

# -----------------------------------------------------------------------------
# $label = $parser->makelinktext($lang,$text,$name,$sec);
#  make link label.
#
sub makelinktext
{
  my ($parser,$lang,$text,$name,$sec) = @_;
  if( !defined($text) || $text eq '' )
  {
    if( $lang eq 'en' )
    {
      $text = $name ? !$sec ? $name : "\"$sec\" in $name" : "\"$sec\"";
    }else
    {
      my $dict = 'Pod::MultiLang::Dict';
      $text = $dict->make_linktext($lang,$name,$sec);
    }
  }
  return $text;
}

# -----------------------------------------------------------------------------
# ($lang,$text) = $parser->parseLang($text);
#  parse J<> sequence.
#   J<> の中身を解析.
#
sub parseLang
{
  my $text = $_[1];
  defined($text) or return ('','');
  my $lang = $text =~ s,^\s*(\w+)\s*[/;]\s*,, ? $1 : '';
  ($lang,$text);
}

# -----------------------------------------------------------------------------
# $out = $this->_from_to($src,$pos);
# charset conversion.
# 文字セット変換
#
sub _from_to
{
  my $this = shift;
  my $text = shift;
  my $pos = shift;
	
  if( $this->{_in_charset} ne $this->{_out_charset} )
  {
		use Encode ();
		my $flag = &Encode::FB_HTMLCREF;# | &Encode::FB_WARN;
    $text = Encode::encode($this->{_out_charset}, Encode::decode($this->{_in_charset}, $text), $flag);
    #$text = encode($this->{_out_charset}, decode($this->{_in_charset}, $text));
    #$text = Unicode::Japanese->new($text, "utf8")->euc;
		#$text =~ s/([^ -~])/sprintf("[%02x]",unpack("C",$1))/ge;
  }
  $text;
}

1;
__END__
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
