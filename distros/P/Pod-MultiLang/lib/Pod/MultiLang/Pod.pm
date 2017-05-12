## ----------------------------------------------------------------------------
#  Pod::MultiLang::Pod
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2003 YMIRLINK,Inc.
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/lib/Pod/MultiLang/Pod.pm 624 2008-02-06T09:15:55.362158Z hio  $
# -----------------------------------------------------------------------------
package Pod::MultiLang::Pod;
use strict;

use File::Spec::Functions;
use Hash::Util qw(lock_keys);
use Cwd;
use UNIVERSAL qw(isa can);
use List::Util qw(first);
use Pod::ParseLink qw(parselink);

use Pod::MultiLang;
use Pod::MultiLang::Dict;
our @ISA = qw(Pod::MultiLang Pod::Parser);
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
  DEFAULT_LANG => 'en',
};
use constant
{
  VERBOSE_NONE     =>   0,
  VERBOSE_ERROR    =>  10,
  VERBOSE_NOLINK   =>  20,
  VERBOSE_WARN     =>  30,
  VERBOSE_DEFAULT  =>  50,
  VERBOSE_FINDLINK =>  90,
  VERBOSE_VERBOSE  =>  80,
  VERBOSE_DEBUG    =>  95,
  VERBOSE_FULL     => 100,
};

sub verbmsg
{
  my ($parser,$level) = @_;
  if( $parser->{_verbose}>=$level )
  {
    my $verbout = $parser->{_verbout};
    print $verbout @_[2..$#_];
  }
}

# -----------------------------------------------------------------------------
# $parser->_map_head_word($ptree)
#  head のテキストに基本訳を付ける
#
sub _map_head_word
{
  my ($parser,$ptree) = @_;
  ref($ptree) or $ptree = Pod::Paragraph->new(-text=>$ptree);
  
  my $text = $ptree->text();
  $text =~ s/^\s+//;
  $text =~ s/\s+$//;
  
  my @text = Pod::MultiLang::Dict->find_word($parser->{langs},$text);
  my $num_found = grep{defined($_)}@text;
  if( $num_found==0 )
  {
    return $ptree;
  }
  if( $num_found==1 )
  {
    my $i = 0;
    foreach(@text)
    {
      if( defined($_) && $parser->{langs}[$i] && $parser->{langs}[$i]eq'en' )
      {
        # default only.
        return $ptree;
      }
      ++$i;
    }
  }
  my $i=0;
  my $result = $text;
  foreach(@text)
  {
    if( defined($_) )
    {
      $result .= "\nJ<$parser->{langs}[$i];$_>";
    }
    ++$i;
  }
  $ptree->text($result);
  $ptree;
}

# -----------------------------------------------------------------------------
# new
#   コンストラクタ
# 
sub new
{
  my $pkg = shift;
  ref($pkg) and $pkg = ref($pkg);
  my %arg = @_&&ref($_[0])eq'HASH'?%{$_[0]}:@_;
  
  # SUPER クラスを使ってインスタンスを生成.
  #
  my @passarg = map{exists($arg{$_})?($_=>$arg{$_}):()}qw(langs);
  my $parser = $pkg->SUPER::new(@passarg);
  
  # 見出し変換辞書のロード
  #
  exists($arg{langs}) and Pod::MultiLang::Dict->load_dict($arg{langs});
  
  # 設定を記録
  #
  $parser->{opt_use_index} = 1;
  $parser->{opt_default_lang} = $arg{default_lang} || DEFAULT_LANG;
  $parser->{_in_charset}  = $arg{in_charset} || 'utf-8';
  $parser->{_out_charset} = $arg{out_charset} || 'utf-8';
  $parser->{_langstack} = undef;
  $parser->{linkcache} = {};
  
  @$parser{qw(_verbose _verbout
	      langs _expandlangs _default_lang _fetchlangs
	      _langstack _neststack _skipblock _iseqstack
	       paras heads items
	      _cssprefix
	      out_outfile out_outdir out_topdir
	      )} = ();
  @$parser{qw( _INFILE _OUTFILE _PARSEOPTS _CUTTING
	       _INPUT _OUTPUT _CALLBACKS _TOP_STREAM _ERRORSUB
	       _INPUT_STREAMS
	      )} = ();
  #_SELECTED_SECTIONS
  #lock_keys(%$parser);
  
  $parser;
}

# -----------------------------------------------------------------------------
# begin_pod
#  初期化
#
sub begin_pod
{
  my $parser = shift;
  $parser->SUPER::begin_pod(@_);
  
  $parser->{_verbose} = VERBOSE_DEFAULT;
  $parser->{_verbout} = \*STDERR;
  $parser->{_expandlangs} = undef;
  $parser->{_default_lang} = $parser->{opt_default_lang};
  $parser->{_fetchlangs} = undef;
  $parser->{_langstack} = [undef];
  
  my $outfile = $parser->output_file();
  file_name_is_absolute($outfile) or $outfile = File::Spec->rel2abs($outfile);
  my $outdir = (File::Spec->splitpath($outfile))[1];
  $parser->{out_outfile} = $outfile;
  $parser->{out_outdir} = $outdir;
  $parser->{out_topdir} = File::Spec->abs2rel(cwd(),$outdir)||'';
  
  # ディレクトリは末尾/付きに正規化
  foreach(@$parser{qw(out_topdir out_outdir)})
  {
    defined($_) && !m/\/$/ and $_.='/';
  }
  
  if( $parser->{_verbose}>=VERBOSE_FULL )
  {
    my $out = $$parser{_verbout};
    print $out $parser->input_file()."\n";
    print $out "scan...\n";
  }
}

# -----------------------------------------------------------------------------
# interior_sequence
#   装飾符号の展開
#
sub interior_sequence
{ 
  my ($parser, $seq_command, $seq_argument,$seq_obj) = @_;
  my $ldelim = $seq_obj->left_delimiter();
  my $rdelim = $seq_obj->right_delimiter();
  
  if( $seq_command eq 'I' )
  {
  }elsif( $seq_command eq 'B' )
  {
  }elsif( $seq_command eq 'C' )
  {
  }elsif( $seq_command eq 'L' )
  {
    die "L<> not processed here..";
  }elsif( $seq_command eq 'E' )
  {
  }elsif( $seq_command eq 'F' )
  {
  }elsif( $seq_command eq 'S' )
  {
  }elsif( $seq_command eq 'X' )
  {
  }elsif( $seq_command eq 'Z' )
  {
  }elsif( $seq_command eq 'J' )
  {
    die "J<> not processed here..";
  }
  return "$seq_command$ldelim$seq_argument$rdelim";
}

# -----------------------------------------------------------------------------
# buildtext
#  paraobj から text を生成
# 
sub buildtext
{
  my ($parser,$paraobj) = @_;
  
  my $ptree;
  if( isa($paraobj,'Pod::Paragraph') )
  {
    $ptree = $parser->parse_text($paraobj->text(),($paraobj->file_line())[1]);
  }else
  {
    $ptree = $paraobj;
  }
  
  # @list containts [langs..,,no-lang];
  my @list = $parser->parse_mlpod($ptree);
  
  my @text;
  for( my $i=0; $i<=$#{$parser->{langs}}; ++$i )
  {
    my $lang = $parser->{langs}[$i];
    if( defined($list[$i]) )
    {
      # has text for this language.
      #
      push(@text,$list[$i]);
    }elsif( $parser->{langs}[$i] eq $parser->{_default_lang} )
    {
      # no text for this language, but this is original language.
      #
      unshift(@text,$list[-1]);
    }
  }
  my $ret = join('',map{s/\n(\s*\n)+/\n/g;"$_\n"}grep{/\S/}@text);
  
  if( $ret eq '' )
  {
    $ret = (grep{defined($_)&&/\S/} @list[-1,0..$#list-1],'Z<>')[0];
  }
  $ret;
}
sub _a2s{ join('-',map{defined($_)?"[$_]":'{undef}'}@_) }

# -----------------------------------------------------------------------------
# $idx = $parser->_find_lang_index($lang);
#   if not found, returns undef.
#
sub _find_lang_index
{
  my ($this,$lang) = @_;
  for( my $i=0; $i<=$#{$this->{langs}}; ++$i )
  {
    if( $this->{langs}[$i] eq $lang )
    {
      return $i;
    }
  }
  undef;
}

# -----------------------------------------------------------------------------
# $ret = $parser->on_mlpod_plain($text);
#
sub on_mlpod_plain
{
  my $parser = shift;
  my $text = shift;
  $text;
}
# -----------------------------------------------------------------------------
# $ret = $parser->on_mlpod_link($parselink,$seq_obj);
#
sub on_mlpod_link
{
  my $parser = shift;
  my $parselink = shift;
  my $seq_obj = shift;
  my ($text, $inferred, $name, $section, $type) = @$parselink;
  
  my $seq_command = 'L';
  my $seq_argument = "";
  defined($text)    and $seq_argument .= "$text|";
  defined($name)    and $seq_argument .= "$name";
  defined($section) and $seq_argument .= "/$section";
  
  my $ldelim = $seq_obj->left_delimiter();
  my $rdelim = $seq_obj->right_delimiter();
  return "$seq_command$ldelim$seq_argument$rdelim";
}

# -----------------------------------------------------------------------------
# @ret = $parser->parse_mlpod($ptree,$inlang);
#   Pod::Parser, InteriorSequence 等の処理.
# @ret: 言語毎の変換結果.
#
sub parse_mlpod
{
  my ($parser,$ptree,$inlang) = @_;

  # @ret[0..$#langs]: for that lang.
  # $ret[-1], $ret[@langs]: fallback.
  my @ret = ((undef)x@{$parser->{langs}},'');

  # find index for default lang.
  my $idx_default_lang = $parser->_find_lang_index($parser->{_default_lang})||0;
  
  if( can($ptree,'parse_tree') )
  {
    $ptree = $ptree->parse_tree();
  }
  my @children = can($ptree,'children')?$ptree->children():isa($ptree,'ARRAY')?@$ptree:die "unknown object : $ptree";
  #print STDERR "in: @{[scalar@children]} ",_a2s(@children),"\n";
  foreach (@children)
  {
    if( !ref($_) )
    {
      # plain text.
      $ret[-1] .= $parser->on_mlpod_plain($_);
      next;
    }
    my $cmd_name = $_->cmd_name();
    if( $cmd_name ne 'J' && $cmd_name ne 'L' )
    {
      # normal iseq.
      #print STDERR "normal iseq\n";
      
      # iseq の中身を mlpod 分解. 
      #
      my @child = $parser->parse_mlpod($_->parse_tree());
      #print STDERR"  child : $#child "._a2s(@child)."\n";
      
      # default_lang が未定義だったら, 言語指定なし部分を充てる.
      #
      if( !defined($child[$idx_default_lang]) 
          && grep{defined($_)} @child[0..$#{$parser->{langs}}] )
      {
        $child[$idx_default_lang] = $child[-1];
      }
      # 装飾符号の展開.
      # 
      my $cmd_name = $_->cmd_name();
      for( my $i=0; $i<=$#child; ++$i )
      {
	if( defined($child[$i]) )
	{
	  my $ret = $parser->interior_sequence($cmd_name,$child[$i],$_);
	  defined($ret[$i]) or $ret[$i] = '';
	  $ret[$i] .= $ret;
        }
      }
    }elsif( $cmd_name eq 'L' )
    {
      # link iseq.
      #print STDERR "link iseq\n";
      #
      my $content = $_->raw_text();
      $content =~ s/^L\<+\s*//;
      $content =~ s/\s*\>+$//;
      my ($text, $inferred, $name, $section, $type) = parselink($content);
      if( !$section && $name =~ / / )
      {
        $section = $name;
        $name = '';
      }
      
      if( $content !~ /J\</ )
      {
        # if there is no J<> sequences.
        my $parselink = [$text,$inferred,$name,$section,$type];
        my $link = $parser->on_mlpod_link($parselink,$_);
        defined($ret[-1]) or $ret[-1] = '';
        $ret[-1] .= $link;
        next;
      }
      
      my $line = ($_->file_line())[1];
      foreach($text, $name, $section)
      {
	if( !defined($_) )
	{
	  $_ = [(undef)x$#ret];
	  next;
	}
	my $ptree = $parser->parse_text($_,$line);
	my @child = $parser->parse_mlpod($ptree);
	# default_lang が未定義だったら, 言語指定なし部分を充てる.
	# (全部未定義なら必要ない)
	if( defined($idx_default_lang) 
	    && !defined($child[$idx_default_lang])
	    && grep{defined($_)}@child[0..$#{$parser->{langs}}] )
	{
	  $child[$idx_default_lang] = $child[-1];
        }
	foreach(grep{defined($_)}@child)
	{
	  s/^\s+//;
	  s/\s+$//;
	}
	$_ = \@child;
      }

      # 装飾符号の展開.
      # expand interior sequences.
      #
      my $cmd_name = $_->cmd_name();
      my $lang = $parser->{_langstack}[-1]||$parser->{_default_lang};
      my $idx = $parser->_find_lang_index($lang);
      defined($idx) or $idx = $idx_default_lang;

      my $select_proper_text = sub{
        my $text1 = shift;
        my $text2 = shift;
        if( defined($text1) && $text1 ne '' )
        {
          $text1;
        }elsif( defined($text2) && $text2 ne '' )
        {
          $text2;
        }elsif( defined($text1) || defined($text2) )
        {
          '';
        }else
        {
          undef;
        }
      };
      my $text_lang = $text->[$idx];
      my $text_def  = $text->[$idx_default_lang];
      my $text_sel  = $select_proper_text->($text_lang, $text_def);

      my $name_lang = $name->[$idx];
      my $name_def  = $name->[$idx_default_lang];
      my $name_sel  = $select_proper_text->($name_lang, $name_def);

      my $section_lang = $section->[$idx];
      my $section_def  = $$section[$idx_default_lang];
      my $section_sel  = $select_proper_text->($section_lang, $section_def);
      
      my $parselink = [$text_sel,$inferred,$name_sel,$section_sel,$type];
      my $link = $parser->on_mlpod_link($parselink,$_);
      defined($ret[-1]) or $ret[-1] = '';
      $ret[-1] .= $link;
      # if cmd_name eq 'L'
    }else
    {
      # lang iseq.
      #
      my $iseq = $_;
      my $first = ($iseq->parse_tree()->children())[0] || '';
      push(@{$parser->{_langstack}},$first=~/^\s*(\w+)\s*[\/;]/?$1:$parser->{_langstack}[-1]);
      my @child = $parser->parse_mlpod($iseq->parse_tree());
      pop(@{$parser->{_langstack}});
      $child[-1] =~ s,^\s*(\w+)\s*[/;]\s*,,;
      my $lang = $1;
      if( !defined($lang) )
      {
        $parser->verbmsg(VERBOSE_ERROR,"no lang in J<>, use default-lang [$parser->{_default_lang}] at ".$iseq->file_line()."\n");
        $lang = $parser->{_default_lang};
      }
      for( my $i=0; $i<=$#{$parser->{langs}}; ++$i )
      {
        $parser->{langs}[$i] ne $lang and next;
        $ret[$i] .= $child[-1];
        last;
      }
      #print STDERR "  iseq: $#ret ",_a2s(@ret),"\n";
    }
  }
  $ret[-1]=~/\S/ or $ret[-1]='';
  #print "out: @{[scalar@ret]} ",_a2s(@ret),"\n";
  @ret;
}

# -----------------------------------------------------------------------------
# end_pod
#   at end of parsing pod.
#   build html and output it.
#
sub end_pod
{
  my $parser = shift;
  my ($command, $paragraph, $line_num) = @_;
	$parser->SUPER::end_pod(@_);
  
  if( !@{$parser->{paras}} )
  {
    warn "input has no paragraphs";
  }
  
  $parser->rebuild();
  $parser->output_pod();
}

# -----------------------------------------------------------------------------
# rebuild
#   build infomations needed for html.
#
sub rebuild
{
  my ($parser, $command, $paragraph, $line_num) = @_;
  
  if( $parser->{_verbose}>=VERBOSE_FULL )
  {
    my $out = $$parser{_verbout};
    print $out "scan done, rebuild...\n";
  }
  
  # build indices from "head"s.
  # 
  foreach (@{$parser->{heads}})
  {
    my ($paraobj) = $$_[PARAINFO_PARAOBJ];
    
    if( $paraobj->text() !~ /[^\w\s&]/ )
    {
      $paraobj = $parser->_map_head_word($paraobj);
      $_->[PARAINFO_PARAOBJ] = $paraobj;
    }
    
    $_->[PARAINFO_CONTENT]  = $parser->buildtext($paraobj);
    $_->[PARAINFO_HEADSIZE] = ($paraobj->cmd_name()=~/(\d)/)[0]||0;
    
    $_->[PARAINFO_ID]       = q/id is not used/;
  }
  
  # build indices from "item"s too.
  # 
  foreach (@{$parser->{items}})
  {
    my ($paraobj,$listtype) = @$_[PARAINFO_PARAOBJ,PARAINFO_LISTTYPE];
    
    $listtype ne 'dl' and next;
    
    if( $paraobj->text() !~ /[^\w\s&]/ )
    {
      $paraobj = $parser->_map_head_word($paraobj);
      $_->[PARAINFO_PARAOBJ] = $paraobj;
    }
    
    $_->[PARAINFO_ID]       = q/id is not used/;
  }
}

# -----------------------------------------------------------------------------
# output_pod
#   podを出力
#
sub output_pod
{
  my ($parser, $command, $paragraph, $line_num) = @_;
  
  my $out_fh = $parser->output_handle();
  
  if( $parser->{_verbose}>=VERBOSE_FULL )
  {
    $parser->vermbsg(VERBOSE_FULL,"ok, output...\n");
  }
  
  #binmode($out_fh,":encoding($parser->{_out_charset})");
  #print defined($out_fh)?"[$out_fh]\n":"{undef}\n";
  binmode($out_fh,":bytes");
  
  # 出力開始
  # 
  
  # 本文の出力.
  #
  my $in_item = 0;
  my $first_item = 1;
  my @verbpack;
  my @blockstack;
  use constant {STK_PARAOBJ=>0,STK_BEHAVIOR=>1,};
  use constant {BHV_NONE=>'none',BHV_NORMAL=>'normal',BHV_VERBATIM=>'verbatim',BHV_IGNORE=>'ignore'};
  
  foreach (@{$parser->{paras}})
  {
    my ($paratype,$paraobj) = @$_[PARAINFO_TYPE,PARAINFO_PARAOBJ];
    $parser->{_iseqstack} = [];
    
    # ignore 状態の確認
    # 
    if( grep{$_->[STK_BEHAVIOR]eq BHV_IGNORE}@blockstack )
    {
      #print $out_fh "  in ignore ...\n";
      if( $paratype==PARA_END
	  && $_->[PARAINFO_CONTENT] eq $blockstack[-1]->[STK_PARAOBJ][PARAINFO_CONTENT] )
      {
	my $fin = pop(@blockstack);
	my $mode = $_->[PARAINFO_CONTENT];
	my $outtext = "";
	print $out_fh $parser->_from_to($outtext);
      }
      next;
    }
    
    # 連続する verbose の連結処理. 
    # 
    my $blk = first{(ref($_)||'')eq'ARRAY'&&$$_[STK_BEHAVIOR]ne BHV_IGNORE}reverse @blockstack;
    if( $paratype==PARA_VERBATIM || ($paratype!=PARA_END&&$blk&&$blk->[STK_BEHAVIOR]eq BHV_VERBATIM) )
    {
      my $text = $paraobj->text();
      $text = $parser->_from_to($text);
      $text !~ /^\n*$/ and push(@verbpack,$text);
      next;
    }elsif( @verbpack )
    {
      my $text = join('',@verbpack);
      $text =~ s/\s*$//;
      if( $text !~ /^\n*$/ )
      {
        $text =~ s/\n+$/\n/;
	my $outtext = "$text\n\n";
	$outtext = $parser->_from_to($outtext);
	print $out_fh $outtext;
      }
      @verbpack = ();
    }
    
    # 普通に出力処理.
    # $outtext には _from_to 済みのテキストを追加.
    # 
    my $outtext;
    if( $paratype==PARA_TEXTBLOCK )
    {
      my $text = $parser->buildtext($paraobj);
      $text = $parser->_from_to($text);
      $text =~ /^\s*$/ and next;
      $outtext = $text."\n";
    }elsif( $paratype==PARA_HEAD )
    {
      my $text = $_->[PARAINFO_CONTENT];
      my $cmd = $paraobj->cmd_name();
      $text = $parser->_from_to($text);
      $text =~ s/\n(\s*\n)+/\n/g;
      $outtext = "=$cmd $text\n";
    }elsif( $paratype==PARA_OVER )
    {
      $outtext = $paraobj->raw_text();
      
      my ($type) = $_->[PARAINFO_LISTTYPE];
      $first_item = 1;
      my $stk = [];
      $stk->[STK_PARAOBJ]  = $_;
      $stk->[STK_BEHAVIOR] = BHV_NORMAL;
      push(@blockstack,$stk);
    }elsif( $paratype==PARA_BACK )
    {
      $outtext = '';
      if( $in_item )
      {
	--$in_item;
      }
      pop(@blockstack);
      
      $outtext .= "=back\n\n";
    }elsif( $paratype==PARA_ITEM )
    {
      my ($type,$id) = @$_[PARAINFO_LISTTYPE,PARAINFO_ID];
      $outtext = '';
      if( !@blockstack )
      {
        my $stk = [];
        $stk->[STK_PARAOBJ]  = $type;
        $stk->[STK_BEHAVIOR] = BHV_NORMAL;
	push(@blockstack,$stk);
        $outtext .= "=over\n\n";
      }
      if( $type eq 'ul' || $type eq 'ol' ) 
      {
        $outtext .= "=item ".$parser->buildtext($paraobj)."\n\n";
      }elsif( $type eq 'dl' ) 
      {
	my $item = $parser->buildtext($paraobj);
	$item =~ s/^\s+//;
	$item =~ s/\s+$//;
	$item = $parser->_from_to($item);
        $outtext .= "=item $item\n\n";
      }else
      {
	$parser->vermsg(VERBOSE_ERROR,"unknown list type [$type]");
      }
      $first_item and undef($first_item),++$in_item;
    }elsif( $paratype==PARA_BEGIN || $paratype==PARA_END
            || $paratype==PARA_FOR || $paratype==PARA_ENCODING
            || $paratype==PARA_POD || $paratype==PARA_CUT )
    {
      my $text = $_->[PARAINFO_CONTENT];
      my $cmd = $paraobj->cmd_name();
			if( $text ne '' )
			{
				$text = $parser->_from_to($text);
				$text =~ s/\n(\s*\n)+/\n/g;
				$outtext = "=$cmd $text\n\n";
			}else
			{
				$outtext = "=$cmd\n\n";
			}
    }else
    {
      $parser->verbmsg(VERBOSE_ERROR,"what\'s got?? [$paratype]");
      next;
    }
    if( defined($outtext) )
    {
      # $outtext は _from_to 済み.
      print $out_fh $outtext;
    }
  }
  if( @verbpack )
  {
    my $text = join('',@verbpack);
    if( $text !~ /^\n*$/ )
    {
      my $outtext = "$text\n\n";
      $outtext = $parser->_from_to($outtext);
      print $out_fh $outtext;
    }
  }
  
  # output done.
}

# =============================================================================
# ユーティリティ関数群
# =============================================================================

1;
__END__
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
