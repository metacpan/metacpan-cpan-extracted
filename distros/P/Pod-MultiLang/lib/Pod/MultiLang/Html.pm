## ----------------------------------------------------------------------------
#  Pod::MultiLang::Html
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2003 YMIRLINK,Inc.
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/lib/Pod/MultiLang/Html.pm 578 2007-12-14T05:15:38.051888Z hio  $
# -----------------------------------------------------------------------------
package Pod::MultiLang::Html;
use strict;
use vars qw($VERSION);
BEGIN{
$VERSION = '0.03';
}

use File::Spec::Functions;
use Hash::Util qw(lock_keys);
use Cwd;
use UNIVERSAL qw(isa can);
use List::Util qw(first);
use Pod::ParseLink;

use Pod::MultiLang;
use Pod::MultiLang::Dict;
our @ISA = qw(Pod::MultiLang);

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

our $VERBOSE_DEFAULT = VERBOSE_DEFAULT;

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
# makelink
#  L<> から <a href=""></a> を作成
#
sub makelink
{
  my ($parser,$lang,$text,$target,$sec,$sec_anchor) = @_;
  $sec_anchor ||= $sec;
  defined($target) or $target = '';
  
  my $link_info;

  if( exists($parser->{linkcache}{$target}) )
  {
    $link_info = $parser->{linkcache}{$target};
  }elsif( $target eq '' )
  {
    $link_info = {
      base => '',
      path => '',
      href => '',
    };
    $parser->{linkcache}{''} = $link_info;
  }elsif( $target =~ /\(\d+\w?\)$/ )
  {
    # 多分man. 適当に^^;
    # 
    $link_info = {
      base => "man:",
      path => "$target",
      href => undef,
    };
    $parser->{linkcache}{$target} = $link_info;
  }else
  {
    #   Pkg/Class.html
    #   Pkg/Pkg-Class.html
    #   Pkg-Class.html
    #   Pkg/Pkg-Class-[\d\.]+.html
    #   Pkg-Class-[\d\.]+.html
    (my $file1 = $target.'.html') =~ s,::,/,g;
    (my $file3 = $target.'.html') =~ s,::,-,g;
    (my $dir = $file1)=~s,[^/]*$,,;
    my $file2 = $dir ne '' ? $dir.$file3 : undef;
    my $found;
    my $verbout = $parser->{_verbose}>=VERBOSE_FINDLINK && $parser->{_verbout};
    foreach my $poddir(@{$parser->{opt_poddir}})
    {
      $found = $poddir.$file1;
      -f $found and last;
      $parser->{_verbose}>=VERBOSE_FINDLINK and $parser->verbmsg(VERBOSE_FINDLINK,"[$target] ==> x [$found]\n");
      if( defined($file2) )
      {
	$found = $poddir.$file2;
	-f $found and last;
	$parser->{_verbose}>=VERBOSE_FINDLINK and $parser->verbmsg(VERBOSE_FINDLINK,"[$target] ==> x [$found]\n");
      }
      $found = $poddir.$file3;
      -f $found and last;
      $parser->{_verbose}>=VERBOSE_FINDLINK and $parser->verbmsg(VERBOSE_FINDLINK,"[$target] ==> x [$found]\n");
      undef $found;
    }
    if( $found )
    {
      $link_info = {
        base => $parser->{out_topdir},
        path => $found,
        href => undef,
      };
      $parser->{linkcache}{$target} = $link_info,
      $parser->{_verbose}>=VERBOSE_FINDLINK and $parser->verbmsg(VERBOSE_FINDLINK,"[$target] ==> [$found]\n");
    }else
    {
      # not found.
      # 
      my $missing_base;
      if( defined($parser->{opt_missing_poddir}) && $target=~/^perl\w*$/ )
      {
        $missing_base = $parser->{opt_missing_poddir};
      }elsif( defined($parser->{opt_missing_pragmadir}) && $target =~ /^[a-z]/ )
      {
        $missing_base = $parser->{opt_missing_pragmadir};
      }elsif( defined($parser->{opt_missing_dir}) )
      {
        $missing_base = $parser->{opt_missing_dir};
      }else
      {
        $missing_base = $parser->{out_topdir};
      }
      my $href = $missing_base . $parser->escapeUrl($file1);
      $link_info = {
        base => $missing_base,
        path => $file1,
        href => $href,
      };
      $parser->{linkcache}{$target} = $link_info,
      $parser->verbmsg(VERBOSE_NOLINK,"[$target] not found ==> $href\n");
    }
  }

  if( !defined($link_info->{href}) )
  {
    my $base = $link_info->{base};
    my $path = $link_info->{path};
    $link_info->{href} = $base . $parser->escapeUrl($path);
  }

  my $link_to = $link_info->{href};
  if( $sec_anchor )
  {
    $link_to .= '#' . $parser->makelinkanchor($sec_anchor);
  }
  
  if( !defined($text)||$text eq '' )
  {
    $text = $parser->makelinktext(@_[1..$#_]);
  }
  #print STDERR "($lang,$text,$target,$sec) ==> [$link_to]\n";
  $text = $parser->escapeHtml($text);
  $link_to = $parser->escapeHtml($link_to);
  qq(<a href="$link_to">$text</a>);
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
# poddir => []
#   Pkg/Class.html
#   Pkg/Pkg-Class.html
#   Pkg/Pkg-Class-[\d\.]+.html
#   Pkg-Class.html
#   Pkg-Class-[\d\.]+.html
#   あたりかなぁ。。？
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
  $parser->{opt_poddir} = $arg{poddir}||[];
  $parser->{opt_css} = $arg{css};
  $parser->{opt_made} = $arg{made};
  $parser->{opt_missing_poddir} = $arg{missing_poddir};
  $parser->{opt_missing_pragmadir} = $arg{missing_pragmadir};
  $parser->{opt_missing_dir} = $arg{missing_dir};
  $parser->{opt_use_index} = 1;
  $parser->{opt_default_lang} = $arg{default_lang} || DEFAULT_LANG;
  $parser->{_in_charset}  = $arg{in_charset} || 'utf-8';
  $parser->{_out_charset} = $arg{out_charset} || 'utf-8';
  $parser->{_langstack} = undef;
  $parser->{linkcache} = {};
  
  @$parser{qw(_verbose _verbout
	      langs _expandlangs _default_lang _fetchlangs
	      _linkwords _linkwords_keys
	      _langstack _neststack _skipblock _iseqstack
	       paras heads items
	      _cssprefix
	      out_outfile out_outdir out_topdir out_css out_made
	      _outhtml_heading_toc
	      _outhtml_heading_index
	      _outhtml_plain_title
	      _outhtml_block_title
	      )} = ();
  @$parser{qw( _INFILE _OUTFILE _PARSEOPTS _CUTTING
	       _INPUT _OUTPUT _CALLBACKS _TOP_STREAM _ERRORSUB
	       _INPUT_STREAMS
	      )} = ();
  #_SELECTED_SECTIONS
  #lock_keys(%$parser);
  
  # ディレクトリは末尾/付きに正規化
  foreach(@{$parser->{opt_poddir}},@$parser{qw(opt_missing_poddir opt_missing_pragmadir opt_missing_dir)})
  {
    defined($_) && !m/\/$/ and $_.='/';
  }
  $parser;
}

# -----------------------------------------------------------------------------
# begin_pod
#  初期化
#
sub begin_pod
{
  my ($parser) = @_;
  &Pod::MultiLang::begin_pod;
  
  $parser->{_verbose} = $VERBOSE_DEFAULT;
  $parser->{_verbout} = \*STDERR;
  $parser->{_expandlangs} = undef;
  $parser->{_default_lang} = $parser->{opt_default_lang};
  $parser->{_fetchlangs} = undef;
  $parser->{_linkwords} = undef;
  $parser->{_linkwords_keys} = undef;
  $parser->{_langstack} = [undef];
  $parser->{_cssprefix} = 'pod_';
  
  my $outfile = $parser->output_file();
  file_name_is_absolute($outfile) or $outfile = File::Spec->rel2abs($outfile);
  my $outdir = (File::Spec->splitpath($outfile))[1];
  my $css = $parser->{opt_css};
  if( $css && !file_name_is_absolute($css) )
  {
    $css = File::Spec->abs2rel(File::Spec->rel2abs($css),$outdir);
  }
  my $made = $parser->{opt_made};
  $parser->{out_outfile} = $outfile;
  $parser->{out_outdir} = $outdir;
  $parser->{out_topdir} = File::Spec->abs2rel(cwd(),$outdir)||'.';
  $parser->{out_css} = $css;
  $parser->{out_made} = $made;
  
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
  my ($parser, $seq_command, $seq_argument) = @_;
  ## Expand an interior sequence; sample actions might be:
  if( $seq_command eq 'I' )
  {
    return qq(<em class="$parser->{_cssprefix}iseq_I">$seq_argument</em>);
  }elsif( $seq_command eq 'B' )
  {
    return qq(<strong class="$parser->{_cssprefix}iseq_B">$seq_argument</strong>);
  }elsif( $seq_command eq 'C' )
  {
    return qq(<code class="$parser->{_cssprefix}iseq_C">$seq_argument</code>);
  }elsif( $seq_command eq 'L' )
  {
    $parser->resolveLink($seq_argument);
  }elsif( $seq_command eq 'E' )
  {
    return $parser->resolvePodEscape($seq_argument);
  }elsif( $seq_command eq 'F' )
  {
    return qq(<em class="$parser->{_cssprefix}iseq_F">$seq_argument</em>);
  }elsif( $seq_command eq 'S' )
  {
    return qq(<nobr class="$parser->{_cssprefix}iseq_S">$seq_argument</nobr>);
  }elsif( $seq_command eq 'X' )
  {
    return '';
  }elsif( $seq_command eq 'Z' )
  {
    return '';
  }elsif( $seq_command eq 'J' )
  {
    my ($lang,$text) = $parser->parseLang($seq_argument);
    if( $parser->{_expandlangs} )
    {
      if( !grep{$lang eq $_}@{$parser->{_expandlangs}} )
      {
	return '';
      }
      grep{$lang eq $_}@{$parser->{_fetchlangs}} or push(@{$parser->{_fetchlangs}},$lang);
    }
    return qq(<span class="$parser->{_cssprefix}lang_$lang">$text</span>);
  }
}

# -----------------------------------------------------------------------------
# plainize
#   ptreeを単純テキストに.
#
sub plainize
{
  my ($parser,$ptree) = @_;
  if( $ptree->isa('Pod::InteriorSequence') )
  {
    $ptree = $ptree->parse_tree();
  }
  if( $ptree->isa('Pod::ParseTree') )
  {
    my $text = '';
    foreach($ptree->children())
    {
      $text .= ref($_) ? $parser->plainize($_) : $_;
    }
    return $text;
  }
  if( $ptree->isa('Pod::Paragraph') )
  {
    my $text = $ptree->text();
    $text =~ s/^(.+?)(J<)/J<< $parser->{_default_lang}; $1 >>$2/s;
    return $parser->parse_text( { -expand_seq => \&_plainize_iseq,
				  -expand_ptree => \&plainize,
			        },
				$text,
				($ptree->file_line())[1],
				);
  }
  die "unknown type [$ptree]";
}

# -----------------------------------------------------------------------------
# _plainize_iseq
#   装飾符号を単純テキストに.
#
sub _plainize_iseq
{ 
  my ($parser, $iseq) = @_;
  my $cmd = $iseq->cmd_name();
  if( $cmd eq 'I' || $cmd eq 'B' || $cmd eq 'C' || $cmd eq 'F' || $cmd eq 'S' )
  {
    return $parser->plainize($iseq);
  }elsif( $cmd eq 'X' || $cmd eq 'Z' )
  {
    return '';
  }elsif( $cmd eq 'E' )
  {
    return $parser->resolvePodEscape($parser->plainize($iseq->parse_tree()));
  }elsif( $cmd eq 'L' )
  {
    return '_';
  }elsif( $cmd eq 'J' )
  {
    my $text = $parser->plainize($iseq);
    (my $lang,$text) = $parser->parseLang($text);
    if( grep{$_ eq 'en'}@{$parser->{langs}} )
    {
      # if langs contains en, use en.
      return $lang eq 'en' ? $text : '';
    }elsif( $lang eq $parser->{langs}[0] )
    {
      # no en, use first lang.
      return $text;
    }else
    {
      return '';
    }
  }
  '';
}

# -----------------------------------------------------------------------------
# buildhtml
#  paraobj からhtmlを生成
# 
sub buildhtml
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
  
  # [langs..,,no-lang];
  my @list = $parser->_buildhtml_parse($ptree);
  my @html;
  for( my $i=0; $i<=$#{$parser->{langs}}; ++$i )
  {
    if( defined($list[$i]) )
    {
      my $cls = "$parser->{_cssprefix}lang_$parser->{langs}[$i]";
      my $text = $list[$i];
      push(@html,qq(<span class="$cls">$list[$i]</span>));
    }elsif( $parser->{langs}[$i]eq$parser->{_default_lang} )
    {
      if( grep{defined}@list[0..$#{$parser->{langs}}] )
      {
	my $cls = "$parser->{_cssprefix}lang_$parser->{langs}[$i]";
        push(@html,qq(<span class="$cls">$list[-1]</span>));
      }else
      {
	my $cls = "$parser->{_cssprefix}lang";
        push(@html,qq(<span class="$cls">$list[-1]</span>));
      }
    }
  }

  my $ret = join("\n",@html);
  if( $ret eq '' )
  {
    if( defined($list[-1]) && $list[-1] ne '' )
    {
      $ret = $list[-1];
    }else
    {
      foreach (@list,'{empty}')
      {
        defined($_) and $ret = $_,last;
      }
    }
  }
  $ret;
}
sub _a2s{ join('-',map{defined($_)?"[$_]":'{undef}'}@_) }

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
# _buildhtml_parse
#   言語毎に分解.
# 
sub _buildhtml_parse
{
  my ($parser,$ptree,$inlang) = @_;
  my @ret = ((undef)x@{$parser->{langs}},'');
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
      my $text = $parser->escapeHtml($_);
      $ret[-1] .= $text;
      next;
    }
    if( $_->cmd_name() eq 'L' )
    {
      # link iseq.
      #print STDERR "link iseq\n";
      my $link = $_->raw_text();
      $link =~ s/^L\<+\s*//;
      $link =~ s/\s*\>+$//;
      my ($text, undef, $name, $section, $type) = parselink($link);
      if( !$section && $name =~ / / )
      {
        $section = $name;
        $name = '';
      }
      if( $link !~ /J\</ )
      {
	my $link;
	if( $type eq 'man' )
	{
	  $link = $parser->escapeHtml($name);
	}elsif( $type eq 'url' )
	{
	  my $url = $parser->escapeHtml($name);
	  my $text = $parser->escapeHtml($name);
	  $link = qq(<a href="$url">$text</a>);
	}else
	{
	  my $lang = $parser->{_langstack}[-1]||$parser->{_default_lang};
	  $link =$parser->makelink($lang,$text,$name,$section);
        }
	if( defined($ret[-1]) )
	{ 
	  $ret[-1] .= $link;
        }else
        {
	  $ret[-1] = $link;
        }
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
	my @child = $parser->_buildhtml_parse($ptree);
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
      my $cmd_name = $_->cmd_name();
      my $sec_anchor = $$section[-1]||$$section[$idx_default_lang]||'';
      my $lang = $parser->{_langstack}[-1]||$parser->{_default_lang};
      my $i = $parser->_find_lang_index($lang);
      defined($i) or $i = $idx_default_lang;
      {

	my $text     = $$text[$i]||$$text[$idx_default_lang]||'';
        my $name     = $$name[$i]||$$name[$idx_default_lang]||'';
	my $section  = $$section[$i]||$$section[$idx_default_lang]||'';
	my $lang = $parser->{langs}[$i]||$parser->{_default_lang};
	my $link;
	if( $type eq 'man' )
	{
	  $link = $parser->escapeHtml($name);
	}elsif( $type eq 'url' )
	{
	  my $url = $parser->escapeHtml($name);
	  my $text = $parser->escapeHtml($name);
	  $link = qq(<a href="$url">$text</a>);
	}else
	{
	  $link =$parser->makelink($lang,$text,$name,$section,$sec_anchor);
        }
	if( defined($ret[-1]) )
	{
	  $ret[-1] .= $link;
        }else
        {
	  $ret[-1] = $link;
        }
      }
      next;
    } # if cmd_name eq 'L'
    if( $_->cmd_name() ne 'J' )
    {
      # normal iseq.
      #print STDERR "normal iseq\n";
      my @child = $parser->_buildhtml_parse($_->parse_tree());
      #print STDERR"  child : $#child "._a2s(@child)."\n";
      # default_lang が未定義だったら, 言語指定なし部分を充てる.
      for( my $i=0; $i<=$#{$parser->{langs}}; ++$i )
      {
	if( $parser->{langs}[$i] eq $parser->{_default_lang} )
	{
	  !defined($child[$i]) &&grep{defined}@child[0..$#{$parser->{langs}}] and $child[$i] = $child[-1];
	  #print STDERR "  fallback [$child[-1]] ==> [$parser->{_default_lang}#$i]\n";
	  last;
	}
      }
      # 装飾符号の展開.
      my $cmd_name = $_->cmd_name();
      for( my $i=0; $i<=$#child; ++$i )
      {
	if( !defined($child[$i]) )
	{
	  next;
        }
	$child[$i] = $parser->interior_sequence($cmd_name,$child[$i]);
	if( defined($ret[$i]) )
	{
	  $ret[$i] .= $child[$i];
        }else
        {
	  $ret[$i] = $child[$i];
        }
      }
      next;
    } # if cmd_name ne 'J'
    
    # lang iseq.
    my $iseq = $_;
    my $first = ($iseq->parse_tree()->children())[0] || '';
    push(@{$parser->{_langstack}},$first=~/^\s*(\w+)\s*[\/;]/?$1:$parser->{_langstack}[-1]);
    my @child = $parser->_buildhtml_parse($iseq->parse_tree());
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
  $ret[-1]=~/\S/ or $ret[-1]='';
  #print "out: @{[scalar@ret]} ",_a2s(@ret),"\n";
  @ret;
}

# -----------------------------------------------------------------------------
# _parse_iseq_J
#   ($lang,$text) = $parser->_parse_iseq_J($iseq);
# 
sub _parse_iseq_J
{
  my ($parser,$iseq) = @_;
  my @children = $iseq->parse_tree->children();
  for( my $i=0; $i<@children; ++$i )
  {
    ref($children[$i]) and next;
    my ($lang_last,$text_head) = split('/',$_,2)
      or next;
    
    my $lang = [@children[0..$i-1],$lang_last];
    my $text = [$text_head,@children[$i+1..$#children]];
    my ($file,$line) = $iseq->file_line();
    my $text_line = $line + $parser->_countnewline(@$lang);
    my $lang_iseq = Pod::InteriorSequence->new( -name   => '',
						   -file   => $file,
						   -line   => $line,
						   -ldelim => '',
						   -rdelim => '',
						   -ptree  => Pod::ParseTree->new($lang),
						   );
    my $text_iseq = Pod::InteriorSequence->new( -name   => '',
						   -file   => $file,
						   -line   => $text_line,
						   -ldelim => '',
						   -rdelim => '',
						   -ptree  => Pod::ParseTree->new($text),
						   );
    return ($lang_iseq,$text_iseq);
  }
  (undef,$iseq);
}

# -----------------------------------------------------------------------------
# _countnewline
# 
sub _countnewline
{
  my $line=0;
  foreach my $t (@_[1..$#_])
  {
    $line += $t =~ tr/\n/\n/;
  }
  $line;
}

# -----------------------------------------------------------------------------
# buildtitle
#  タイトルを作成. ヘッダ用と本文用.
# 
sub buildtitle
{
  my ($parser,$paraobj) = @_;
  
  # [langs..,,no-lang];
  my @list = $parser->_buildhtml_parse($parser->parse_text($paraobj->text()));
  my $plain_title;
  for( my $i=0; $i<=$#{$parser->{langs}}; ++$i )
  {
    if( defined($list[$i]) )
    {
      $plain_title = $list[$i];
      last;
    }elsif( $parser->{langs}[$i]eq$parser->{_default_lang} )
    {
      $plain_title = $list[-1];
      last;
    }
  }
  if( !defined($plain_title) )
  {
    $plain_title = defined($list[-1]) ? $list[-1] : 'untitled';
  }
  $plain_title =~ s/<.*?>//g;
  $plain_title =~ s/^\s+//;
  $plain_title =~ s/\s+$//;
  
  for( my $i=0; $i<=$#{$parser->{langs}}; ++$i )
  {
    if( $parser->{langs}[$i]eq$parser->{_default_lang} )
    {
      if( !defined($list[$i]) )
      {
	if( grep{defined}@list[0..$#{$parser->{langs}}] )
	{
	  my $cls = "$parser->{_cssprefix}lang_$parser->{langs}[$i]";
	  $list[$i] = qq(<span class="$cls">$list[-1]</span>);
        }else
	{
	  $list[$i] = $list[-1];
        }
      }else
      {
	my $cls = "$parser->{_cssprefix}lang_$parser->{langs}[$i]";
	$list[$i] = qq(<span class="$cls">$list[$i]</span>);
      }
      last;
    }elsif( defined($list[$i]) )
    {
      my $cls = "$parser->{_cssprefix}lang_$parser->{langs}[$i]";
      $list[$i] = qq(<span class="$cls">$list[$i]</span>);
    }
  }
  my $html = join("<br />\n",grep{defined}@list[0..$#{$parser->{langs}}]);
  if( $html eq '' )
  {
    my $txt = defined($list[-1]) ? $list[-1] : 'untitled';
    my $cls = "$parser->{_cssprefix}lang_default";
    $html = qq(<span class="$cls">$txt</span>);
  }
  my $cls = "$parser->{_cssprefix}title_block";
  my $block_title = qq(<div class="$cls">\n$html\n</div>\n\n);
  ($plain_title,$block_title);
}

# -----------------------------------------------------------------------------
# $parser->makelinkanchor($text)
# $parser->makelinkanchor($paraobj)
#   アンカーキーの生成. <a id="xxx"> のxxxの部分.
# 
sub makelinkanchor
{
  my ($parser,$paraobj) = @_;
  my $id = ref($paraobj) ? $parser->plainize($paraobj) : $paraobj;
  $id =~ s/^\s+//;
  $id =~ s/\s+$//;
  $id =~ s/\s+/_/g;
  $id =~ s/([^\a-zA-Z0-9\-\_\.])/join('',map{sprintf('X%02x',$_)}unpack("C*",$1))/ge;
  $id=~/^[a-zA-Z]/ or $id = 'X'.$id;
  $id;
}

# -----------------------------------------------------------------------------
# addindex
#   adding to index.
# 
sub addindex
{
  my ($parser,$hash,$ids,$id,$paraobj) = @_;
  
  # make id unique.
  #
  if( grep{$_ eq $id} @$ids )
  {
    for(my$i=0;;++$i)
    {
      my $add = sprintf('_%02d',$i);
      my $newkey = $id.$add;
      !grep{$_ eq $newkey}@$ids and $id=$newkey,last;
    }
  }
  push(@$ids,$id);
  
  # [langs..,,no-lang];
  # 
  my @list = $parser->_buildhtml_parse($parser->parse_text($paraobj->text()));
  my $i;
  foreach(@list)
  {
    defined($_) or next;
    s/<.*?>//g;
    s/\s+/ /g;
    s/^ //;
    s/ $//;
    if( $_ eq '' )
    {
      #my $src = $paraobj->text();
      #my $lang = $i<$#list ? $parser->{langs}[$i] : 'default';
      #defined($src) or $src = "{undef}";
      #defined($lang) or $lang = "{undef}";
      #$parser->verbmsg(VERBOSE_WARN,"src:[$src] lang:[$lang] is empty.\n");
      next;
    }
    $hash->{$_} = $id;
    ++$i;
  }
  return $id;
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
  $parser->output_html();
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
  
  my %link_keys;
  my @link_ids;
  delete $parser->{_linkwords};
  delete $parser->{_linkwords_keys};
  
  # build indices from "head"s.
  # 
  foreach (@{$parser->{heads}})
  {
    my ($paraobj) = $$_[PARAINFO_PARAOBJ];
    
    if( $paraobj->text() !~ /[^\w\s&]/ )
    {
      $paraobj = $parser->_map_head_word($paraobj);
      $$_[PARAINFO_PARAOBJ] = $paraobj;
    }
    
    my $id = $parser->makelinkanchor($paraobj);
    $id = $parser->addindex(\%link_keys,\@link_ids,$id,$paraobj);
    my $html = $parser->buildhtml($paraobj);
    
    my ($headsize) = $paraobj->cmd_name()=~/(\d)/;
    @$_[PARAINFO_CONTENT,PARAINFO_ID,PARAINFO_HEADSIZE] = ($html,$id,$headsize);
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
      $$_[PARAINFO_PARAOBJ] = $paraobj;
    }
    
    my $id = $parser->makelinkanchor($paraobj);
    $id = $parser->addindex(\%link_keys,\@link_ids,$id,$paraobj);
    
    $$_[PARAINFO_ID] = $id;
  }
  
  # find title block.
  # 
  my $plain_title;
  my $block_title;
  {
    # title is next of paragraph "=head<n> NAME"
    #
    for( my $pos=0; $pos<@{$parser->{paras}}-1; ++$pos )
    {
      my $para = $parser->{paras}[$pos];
      # TODO: ID が NAME だったり 名前 だったり..
      $para->[PARAINFO_TYPE]==PARA_HEAD && ($para->[PARAINFO_ID] =~ /^NAME/ || $para->[PARAINFO_ID] =~ /^Xe5X90X8dXe5X89X8d/ || $para->[PARAINFO_ID] eq 'X')
	or next;
      
      # found "=head<n> NAME"
      # title is next of it.
      #
      $para = $parser->{paras}[$pos+1];
      
      ($plain_title,$block_title) = $parser->buildtitle($para->[PARAINFO_PARAOBJ]);
      last;
    }
    # if no title..
    #
    if( !defined($plain_title) )
    {
      $plain_title = 'untitled';
    }
    if( !defined($block_title) )
    {
      my $cls = "$parser->{_cssprefix}title_block";
      $block_title = qq(<div class="$cls">\n$plain_title\n</div>\n\n);
    }
  }
  
  $parser->{_outhtml_heading_toc} = $parser->buildhtml($parser->_map_head_word('TABLE OF CONTENTS'));
  $parser->{_outhtml_heading_index} = $parser->buildhtml($parser->_map_head_word('INDEX'));
  $parser->{_outhtml_plain_title} = $plain_title;
  $parser->{_outhtml_block_title} = $block_title;
  
  # set link words.
  #
  $parser->{_linkwords} = \%link_keys;
}

# -----------------------------------------------------------------------------
# output_html
#   htmlを出力
#
sub output_html
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
  
  my $plain_title = $parser->{_outhtml_plain_title};
  my $block_title = $parser->{_outhtml_block_title};
  my $made = $parser->{out_made};
  my $charset = $parser->{_out_charset};
  my $css = $parser->{out_css};
  my $xmllang = "ja-JP";
  defined($plain_title) or $plain_title = 'untitled';
  my $cls = "$parser->{_cssprefix}title_block";
  defined($block_title) or $block_title = qq(<div class="$cls">\n$plain_title</div>\n\n);
  if( $parser->{_in_charset} ne $parser->{_out_charset} )
  {
    foreach($plain_title,$block_title,$made,$charset,$css)
    {
      defined($_) or next;
      $_ = $parser->_from_to($_);
    }
  }
  
  # 出力開始
  # 
  print $out_fh qq(<?xml version="1.0" encoding="$charset" ?>\n);
  print $out_fh qq(<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">\n);
  print $out_fh qq(<html xml:lang="$xmllang">\n);
  print $out_fh qq(<head>\n);
  print $out_fh qq(  <meta http-equiv="Content-Type" content="text/html; charset=$charset" />\n);
  if( defined($css) )
  {
    print $out_fh qq(  <meta http-equiv="Content-Style-Type" content="text/css" />\n);
    print $out_fh qq(  <link rel="stylesheet" type="text/css" href="$css" />\n);
  }
  #print $out_fh qq(  <link rel="alternate stylesheet" title="kotastyle Blue" href="../kotastyle_blue.css">\n);
  print $out_fh qq(  <title>$plain_title</title>\n);
  if( defined($made) )
  {
    print $out_fh qq(  <link rev="made"      href="$made" />\n);
  }
  print $out_fh qq(  <link rel="index"     href="./" />\n);
  print $out_fh qq(  <link rel="up"        href="../" />\n);
  print $out_fh qq(</head>\n);
  print $out_fh qq(<body>\n);
  print $out_fh qq(\n);
  
  print $out_fh $block_title;
  
  # table of contents
  #
  if( @{$parser->{heads}} )
  {
    my $heading = $parser->_from_to($parser->{_outhtml_heading_toc},'toc.heading');
    print $out_fh qq(<!-- Begin TABLE_OF_CONTENTS -->\n);
    print $out_fh qq(<div class="$parser->{_cssprefix}toc">\n);
    print $out_fh qq(<p>\n<strong>$heading</strong>\n</p>\n);
    print $out_fh qq(<ul>\n);
    my $curlevel = 0;
    foreach (@{$parser->{heads}})
    {
      my ($text,$id,$headsize) = @$_[PARAINFO_CONTENT,
				     PARAINFO_ID, PARAINFO_HEADSIZE];
      $text = $parser->_from_to($text,$_->[PARAINFO_PARAOBJ]);
      if( !$curlevel )
      {
	# 最初の１個. 
	$curlevel = 1;
      }elsif( $curlevel==$headsize )
      {
	# 同じレベル. 
	print $out_fh qq(</li>\n);
      }elsif( $curlevel<$headsize )
      {
	# レベル増加. 
        print $out_fh qq(<ul>\n);
	++$curlevel;
	print $out_fh qq(<li>*\n<ul>\n)x($headsize-$curlevel);
	$curlevel=$headsize;
      }else
      {
	# レベル減少. 
	print $out_fh qq(</li>\n).(qq(</ul>\n</li>\n)x($curlevel-$headsize));
	$curlevel = $headsize;
      }
      print $out_fh qq(<li><a href="#$id">\n$text</a>\n);
    }
    print $out_fh qq(</li>\n</ul>\n)x$curlevel;
    print $out_fh qq(</div>\n);
    print $out_fh qq(<!-- End TABLE_OF_CONTENTS -->\n);
    print $out_fh qq(\n);
  }
  
  # 本文の出力.
  my $in_item = 0;
  my $first_item = 1;
  my @verbpack;
  my @blockstack;
  use constant {STK_PARAOBJ=>0,STK_BEHAVIOR=>1,};
  use constant {BHV_NONE=>'none',BHV_NORMAL=>'normal',BHV_VERBATIM=>'verbatim',BHV_IGNORE=>'ignore'};
  print $out_fh qq(<!-- Begin CONTENT -->\n);
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
	my $outtext = "<!-- end [$mode] behavior [$fin->[STK_BEHAVIOR]] -->\n";
	print $out_fh $parser->_from_to($outtext);
      }
      next;
    }
    
    # 連続する verbose の連結処理. 
    # 
    my $blk = first{(ref($_)||'')eq'ARRAY'&&$$_[STK_BEHAVIOR]ne BHV_IGNORE}reverse @blockstack;
    if( $paratype==PARA_VERBATIM || ($paratype!=PARA_END&&$blk&&$blk->[STK_BEHAVIOR]eq BHV_VERBATIM) )
    {
      my $text = $parser->escapeHtml($paraobj->text());
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
	my $outtext = qq(<pre class="$parser->{_cssprefix}verbatim"><code>$text</code></pre>\n\n);
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
      my $text = $parser->buildhtml($paraobj);
      $text = $parser->_from_to($text);
      $text =~ /^\s*$/ and next;
      $outtext = "<p>\n$text\n</p>\n\n";
    }elsif( $paratype==PARA_HEAD )
    {
      $outtext = '';
      if( @blockstack )
      {
	foreach(@blockstack)
	{
	  if( ref($_)eq'ARRAY' )
	  {
	    if( $_->[PARAINFO_TYPE]==PARA_OVER )
	    {
	      my ($type) = $_->[PARAINFO_LISTTYPE];
	      $type eq 'dl' and $outtext .= "</dd>";
	      $outtext .= "</$type> <!-- recover at head -->\n\n";
	    }
	  }else
	  {
	    my $type = $_;
	    $type eq 'dl' and $outtext .= "</dd>";
	    $outtext .= "</$type> <!-- recover at head -->\n\n";
	  }
	}
        $#blockstack = -1;
	$first_item = 1;
      }
      my ($text,$id,$headsize) = @$_[PARAINFO_CONTENT,PARAINFO_ID,PARAINFO_HEADSIZE];
      my $tag = "h$headsize";
      $text = $parser->_from_to($text);
      $headsize==1 and $outtext .= qq(\n<hr />\n);
      $outtext .= qq(<$tag><a id="$id">\n$text</a></$tag>\n\n);
    }elsif( $paratype==PARA_OVER )
    {
      my ($type) = $_->[PARAINFO_LISTTYPE];
      $outtext = '';
      if( defined($type) )
      {
        $outtext .= "<$type>\n";
      }else
      {
        warn "over type unknown, using ul";
        $type = 'ul';
        $outtext .= "<!-- listtype of =over undefined, using $type -->\n";
        $outtext .= "<$type>\n";
      }
      $first_item = 1;
      my @stk;
      @stk[STK_PARAOBJ,STK_BEHAVIOR] = ($_,BHV_NORMAL);
      push(@blockstack,\@stk);
    }elsif( $paratype==PARA_BACK )
    {
      my ($type) = @$_[PARAINFO_LISTTYPE];
      $outtext = '';
      if( $in_item )
      {
        $outtext =  $type eq 'dl' ? "</dd>\n" : "</li>\n";
	--$in_item;
      }
      $outtext .= "</$type>\n\n";
      pop(@blockstack);
    }elsif( $paratype==PARA_ITEM )
    {
      my ($type,$id) = @$_[PARAINFO_LISTTYPE,PARAINFO_ID];
      $outtext = '';
      if( !@blockstack )
      {
	push(@blockstack,$type);
        $outtext = qq(<$type> <!-- recover at item -->\n);
      }
      if( $type eq 'ul' || $type eq 'ol' ) 
      {
	$first_item or $outtext .= "</li>\n";
        $outtext .= qq(<li>\n);
      }elsif( $type eq 'dl' ) 
      {
	my $bak = delete $parser->{_linkwords};
	my $item = $parser->buildhtml($paraobj);
	$parser->{_linkwords} = $bak;
	$item =~ s/^\s+//;
	$item =~ s/\s+$//;
	$item = $parser->_from_to($item);
	$first_item or $outtext .= "</dd>\n";
        $outtext .= qq(<dt><a id="$id">$item</a></dt>\n);
        $outtext .= qq(<dd>\n);
      }else
      {
	$parser->vermsg(VERBOSE_ERROR,"unknown list type [$type]");
      }
      $first_item and undef($first_item),++$in_item;
    }elsif( $paratype==PARA_BEGIN )
    {
      my @stk;
      @stk[STK_PARAOBJ,STK_BEHAVIOR] = ($_,BHV_IGNORE);
      push(@blockstack,\@stk);
      my $mode = $_->[PARAINFO_CONTENT];
      if( $mode eq 'html' )
      {
	$outtext .= "<!-- begin [$mode] behavior [normal] -->\n";
	$stk[STK_BEHAVIOR] = BHV_NORMAL;
      }elsif( $mode eq 'text' )
      {
	$outtext .= "<!-- begin [$mode] behavior [verbatim] -->\n";
	$stk[STK_BEHAVIOR] = BHV_VERBATIM;
      }else
      {
	$outtext .= "<!-- begin [$mode] behavior [ignore] -->\n";
      }
    }elsif( $paratype==PARA_END )
    {
      my $fin = pop(@blockstack);
      my $mode = $_->[PARAINFO_CONTENT];
      $outtext .= "<!-- end [$mode] behavior [$fin->[STK_BEHAVIOR]] (started by [$fin->[STK_PARAOBJ][PARAINFO_CONTENT]]) -->\n";
    }elsif( $paratype==PARA_FOR )
    {
    }elsif( $paratype==PARA_ENCODING )
    {
      my $text = $_->[PARAINFO_CONTENT];
      my $cmd = $paraobj->cmd_name();
      $text = $parser->_from_to($text);
      $text =~ s/\n(\s*\n)+/\n/g;
      $outtext = "<!-- =$cmd $text -->\n";
    }elsif( $paratype==PARA_POD )
    {
    }elsif( $paratype==PARA_CUT )
    {
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
      my $outtext = qq(<pre class="$parser->{_cssprefix}verbatim"><code>$text</code></pre>\n\n);
      $outtext = $parser->_from_to($outtext);
      print $out_fh $outtext;
    }
  }
  print $out_fh qq(<!-- End CONTENT -->\n);
  print $out_fh qq(\n);
  
  print $out_fh $block_title;
  
  # 索引
  #
  {
    my $heading = $parser->_from_to($parser->{_outhtml_heading_index});
    print $out_fh qq(<!-- Begin INDEX -->\n);
    print $out_fh qq(<hr />\n);
    print $out_fh qq(<h1><a id="INDEX">$heading</a></h1>\n);
    print $out_fh qq(<div class="$parser->{_cssprefix}idx_outer">\n);
    print $out_fh qq(<ul class="$parser->{_cssprefix}idx">\n);
    foreach(sort keys %{$parser->{_linkwords}})
    {
      #my ($text,$id) = ($parser->escapeHtml($_),$parser->{_linkwords}{$_});
      my ($text,$id) = ($_,$parser->{_linkwords}{$_});
      $text = $parser->_from_to($text);
      print $out_fh qq(<li><a href="#$id">$text</a></li>\n);
    }
    print $out_fh qq(</ul>\n);
    print $out_fh qq(</div>\n);
    print $out_fh qq(<!-- End INDEX -->\n);
    print $out_fh qq(\n);
    
    print $out_fh $block_title;
  }
  
  print $out_fh qq(</body>\n);
  print $out_fh qq(</html>\n);
}

# =============================================================================
# ユーティリティ関数群
# =============================================================================

# -----------------------------------------------------------------------------
# $text = $this->escapeHtml($text);
#   html に埋め込めれる用にエスケープ
#
sub escapeHtml
{
  my @list = @_[1..$#_];
  wantarray or @list = shift @list;
  foreach(@list)
  {
    defined($_) or next;
    s/([&<>\"])/$1 eq '&' ? '&amp;'
                : $1 eq '<' ? '&lt;'
                : $1 eq '>' ? '&gt;'
                : '&quot;' /ge;
  }
  @list!=1?@list:$list[0];
}

# -----------------------------------------------------------------------------
# $text = $this->unescapeHtml($text);
#   escapeHtml によって実体参照に変換された文字を通常の文字に戻す.
#
sub unescapeHtml
{
  my @list = @_[1..$#_];
  wantarray or @list = shift @list;
  foreach(@list)
  {
    s/&(lt|gt|amp|quot);/$1 eq 'amp' ? '&'
                         : $1 eq 'lt' ? '<'
                         : $1 eq 'gt' ? '>'
                         : '"' /ge;
  }
  @list!=1?@list:$list[0];
}

# -----------------------------------------------------------------------------
# $text = $this->escapeUrl($text);
#   url に埋め込めれる用にエスケープ
#
sub escapeUrl
{
  my @list = @_[1..$#_];
  wantarray or @list = $list[0];
  foreach(@list)
  {
    s/([^a-zA-Z0-9\-\_\.\!\~\*\'\(\)\/])/sprintf('%%%02x',unpack("C",$1))/eg;
  }
  @list!=1?@list:$list[0];
}

# -----------------------------------------------------------------------------
# $text = $this->resolvePodEscape($text);
#   E<> の中身を html な実体参照に変換.
#
sub resolvePodEscape
{
  my @list = @_[1..$#_];
  wantarray or @list = shift @list;
  foreach(@list)
  {
    if( $_ eq 'lt' )
    {
      $_ = '&lt;';
    }elsif( $_ eq 'gt' )
    {
      $_ = '&gt;';
    }elsif( $_ eq 'verbar' )
    {
      $_ = '|';
    }elsif( $_ eq 'sol' )
    {
      $_ = '/';
    }elsif( $_ =~ /^0x([0-9a-fA-F]+)$/ )
    {
      $_ = "&#x$1;";
    }elsif( $_ =~ /^0([0-7]+)$/ )
    {
      $_ = "&#".oct($1).";";
    }elsif( $_ =~ /^\d+$/ )
    {
      $_ = "&#$_;";
    }else
    {
      $_ = "&$_;";
    }
  }
  wantarray?@list:$list[0];
}
# -----------------------------------------------------------------------------
# $text = $parser->resolveLink($text);
#
sub resolveLink
{
  my ($parser,@list) = @_;
  @list = $parser->unescapeHtml(wantarray?@list:shift @list);
  foreach(@list)
  {
    if( /^\w+:[^:]/ )
    {
      my $link_to = $parser->escapeHtml($_);
      $_ = qq(<a href="$link_to">$_</a>);
    }else
    {
      my ($text,$target,$sec);
      if( /^"(.*)"$/ )
      {
	($text,$target,$sec) = ('','',$1);
      }else
      {
	$text   = s/^([^\/\|]*)\|// ? $1 : '';
	$target = s/^([^\/\|]*)\/?// ? $1 : '';
	($sec   = $_) =~ s/^\"(.*)\"$/$1/;
      }
      my $lang = $parser->{_expandlangs}[0]||$parser->{_defaultlang} || DEFAULT_LANG;
      return $parser->makelink($lang,$text,$target,$sec);
    }
  }
  wantarray?@list:$list[0];
}

1;
__END__
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
