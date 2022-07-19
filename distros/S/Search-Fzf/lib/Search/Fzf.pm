#!/usr/bin/perl
package Search::Fzf;
use strict;
use utf8;
use Encode;
use Term::ANSIColor qw(uncolor color);
use Text::ANSI::Util qw( ta_split_codes );
use List::Util qw( first any uniqstr pairs reduce );
use List::MoreUtils qw(firstidx qsort minmax indexes);
use Time::HiRes qw(usleep);
use Scalar::Util qw(openhandle);

use lib '.';
require Search::Fzf::Tui;
use Search::Fzf::AlgoCpp;
# require Search::Fzf::Algo;

use Exporter;
# use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
use vars qw(@ISA @EXPORT @EXPORT_OK);

#缺省export 函数fzf
our $VERSION = '0.01';
@ISA = qw(Exporter);
@EXPORT = qw(fzf);
# @EXPORT_OK = qw(fzf);

#####################################################################################
#全局变量
#运行时的一些过程控制信息
my %runStatus=( 
  previewStatus => 0,
  spinnerID => 0,
  isSpinner => 0,
  maxLen => 0,
);
#CONFIG init
# my %keymap = (
#   # 'ctrl-p' => 'COMMAND_UP',
#   # 'ctrl-n' => 'COMMAND_DOWN',
# );

#缺省配置信息
my $DEFAULTCONFIG = {
  # Search
  prompt => "> Your Entered: ",
  pointer => '>',
  marker => '*',
  algo => 'v2', #v1, v2, exact, regex
  caseInsensitive => 1,
  sort => 1,
  delimiter => "\\s+",
  # nth => [1,2,3],
  # nth => [1..3],
  nth => undef,
  # withNth => [1,2,3,4],
  # withNth => [1..4],
  withNth => undef,
  tac => 0,
  disable => 0,
  expect => undef,
  
  #Interface
  # header => "abcdefghijklmnopqrstuvwxyz1234567890abcdefghijklmnopqrstuvwxyz1234567890",
  multi => 0,
  cycle => 1,
  mouse => 1,
  #next test
  keepRight => 0,
  #缺省为5, 若小于0, 则当行长超过显示宽度时不会跟踪显示最后匹配的字符
  hScrollOff => 5,
  # hScrollOff => 0,
  hScroll => 1,
  jumpLabels => ['a'..'z'],
  # jumpLabels => ['d', 'e', 'f'],
  # jumpLabels => undef,
  header => undef,
  headerLines => 0,
  headerFirst => 0,

  border => 0,
  topMargin => 0,
  bottomMargin => 0,
  leftMargin => 0,
  rightMargin => 0,
  topPadding => 0,
  bottomPadding => 0,
  leftPadding => 0,
  rightPadding => 0,
  layout => 0, #0 default 1 reverse 2 reverse list
  info => 0, #0 default 1 incline 2 hidden

  #Color
  color => 1,
  colorFg => 'default',
  colorBg => 'default',
  colorFgPlus => 'default',
  colorBgPlus => 'cyan',
  colorHl => 'red',
  colorHlPlus => 'red',
  # colorHlPlus => 'magenta',
  colorPointer => 'blue',
  colorMarker => 'green',
  colorGutter => 'default',
  colorInfo => 'white',
  colorPrompt => 'grey8',
  colorHeader => 'grey5',
  colorQuery => 'yellow',
  colorDisabled => 'grey5',
  colorSpinner => 'green',
  colorFgPreview => 'default',
  colorBgPreview => 'default',
  

  # keymap => \%keymap,
  keymap => {},

  preview => 0,
  # previewFunc => \&defaultPreviewFunc,
  # previewWithColor => 0,
  previewWithColor => 1,
  previewPosition => 1, #0 up 1 down 2 left 3 right
  previewBorder => 1,
  previewWrap => 0,
  previewScrollOff => 0, #scroll off
  previewCyclic => 0,
  previewHead => 0,
  previewFollow => 0,
  previewFunc => \&batPreviewFunc,

  #getch timeout
  timeout => 100,
  # timeout => 0,
  rowDelimeter => "\n",
  execFunc => \&defaultExecFunc,

  #input thread config
  asynRead => 0,
  #match threads num
  threads => 4,
};
#####################################################################################


#流式输入时的动画字符
my %spinnerHash = (0 => '/', 1 => '-', 2 => "\\", 3 => '|');
#TODO
sub getSpinnerChar {
  return ' ' if not $runStatus{isSpinner};

  my $spinnerChar = $spinnerHash{$runStatus{spinnerID}};
  $runStatus{spinnerID} = ($runStatus{spinnerID} + 1) % 4;
  $runStatus{isSpinner} = 0;
  return $spinnerChar;
}

#min函数, 两个标量参数, 返回较小的
sub min {
  my ($a, $b) = @_;
  return $a<$b? $a:$b;
}
#max函数, 两个标量参数, 返回较大的
sub max {
  my ($a, $b) = @_;
  return $a>$b? $a:$b;
}

#用于重置屏幕的左右尺寸信息
#home=1为从左侧定位, home=0为从右侧定位
sub resetLeftRight {
  my ($CONFIG, $home) = @_;

  my $hoff = $CONFIG->{leftMargin} + $CONFIG->{rightMargin};
  $hoff = 2 + $CONFIG->{leftPadding} + $CONFIG->{rightPadding} if ($CONFIG->{border});

  if ($home == 1) {
    $runStatus{left} = 0;
    $runStatus{right} = $runStatus{width} +$runStatus{left} - 2 - $hoff;
  }else{
    $runStatus{right} = &max($runStatus{maxLen}+2, $runStatus{width}-2-$hoff) ;
    $runStatus{left} = $runStatus{right} - $runStatus{width} + 2 + $hoff;
  }
}

#用于设置屏幕的右对齐信息
#$right为最后的匹配结束结束位置, 留出hScrollOff, 作为最右侧的定位
sub alignRight {
  my ($CONFIG, $right) = @_;

  my $hoff = 0;
  $hoff = 2 + $CONFIG->{leftPadding} + $CONFIG->{rightPadding} if ($CONFIG->{border});

  if ($right + $CONFIG->{hScrollOff} > $runStatus{right}){
    $runStatus{right} = $right + $CONFIG->{hScrollOff};
    $runStatus{left} = $runStatus{right} - $runStatus{width} + 2 + $hoff;
  }
}

#重置光标位置, 设置输出到屏幕的底部和头部信息, left和right信息
sub resetPointer {
  my ($CONFIG, $h, $w) = @_;

  $runStatus{height} = $h;
  $runStatus{width} = $w;

  #计算border和padding占据的位置宽度
  my $voff = 0;
  $voff = 2 + $CONFIG->{topPadding} + $CONFIG->{bottomPadding} if ($CONFIG->{border});
  my $hoff = 0;
  $hoff = 2 + $CONFIG->{leftPadding} + $CONFIG->{rightPadding} if ($CONFIG->{border});

  #显示信息初始化, 预留info和header高度
  my $before = 2;
  $before = 3 if ($CONFIG->{info} == 0);
  $before += scalar(@{$runStatus{headerList}}) if (exists $runStatus{headerList});

  $runStatus{bottom} = 0;
  $runStatus{top} = $runStatus{height} - $before - $voff;
  $runStatus{left} = 0;
  $runStatus{right} = $runStatus{width} - 2 - $hoff;
}

#根据光标位置设置输出到屏幕的底部和头部信息
sub setPointer {
  my ($CONFIG, $ptr, $move) = @_;

  my $vboff = 0;
  $vboff = 1 + $CONFIG->{bottomPadding} if ($CONFIG->{border});
  my $voff = 0;
  $voff = 2 + $CONFIG->{topPadding} + $CONFIG->{bottomPadding} if ($CONFIG->{border});
  my $hloff = 0;
  $hloff = 1 + $CONFIG->{leftPadding} if ($CONFIG->{border});

  #正文列表前的输入提示信息所占据的行数
  my $before = 1;
  $before =2 if ($CONFIG->{info} == 0);
  $before += ($#{$runStatus{headerList}} + 1) if (defined $runStatus{headerList});

  #纵向scroll up
  if($ptr > $runStatus{pointer} && $ptr > $runStatus{top}) {
    $runStatus{top} = $ptr;
    $runStatus{bottom} = $runStatus{top} - $runStatus{height} + $before + 1 + $voff;
  }elsif($ptr < $runStatus{pointer} && $ptr < $runStatus{bottom}){
    $runStatus{bottom} = $ptr;
    $runStatus{top} = $runStatus{height} + $runStatus{bottom} - $before - 1 - $voff;
  }
  
  #横向滚动
  if($move<0){
    if($runStatus{left}>0){
      $runStatus{left} -= 1;
      $runStatus{right} -= 1;
    }
  }elsif($move>0){
    if($runStatus{right} < $runStatus{maxLen}+2) {
      $runStatus{left} += 1;
      $runStatus{right} += 1;
    }
  }

  $runStatus{pointer} = $ptr;
  $runStatus{location} = $runStatus{pointer} - $runStatus{bottom};
}

#窗口尺寸变化, 重新绘制窗口
sub resize {
  my ($CONFIG, $tui) = @_;

  $tui->clearWin;
  $tui->clearPreviewWin;
  my ($h, $w) = $tui->openWin();
  &resetPointer($CONFIG, $h, $w);
}

#函数togglePreview, 打开或关闭preview窗口
sub togglePreview {
  my ($CONFIG, $tui) = @_;

  $tui->clearWin;
  $tui->clearPreviewWin;
  $CONFIG->{preview} ++;
  $CONFIG->{preview} %= 2;
  my ($h, $w) = $tui->openWin();
  &resetPointer($CONFIG, $h, $w);
}

#切换preview窗口的位置
sub togglePreviewPosition {
  my ($CONFIG, $tui) = @_;

  $tui->clearWin;
  $tui->clearPreviewWin;
  $CONFIG->{previewPosition} ++;
  $CONFIG->{previewPosition} %= 4;
  my ($h, $w) = $tui->openWin();
  &resetPointer($CONFIG, $h, $w);
}

#函数bufferOutputWithFormat, 带格式的显示输出
#生成buffer数据结构, 作为tui->setBuffer的参数
#buffer数据结构是一个数组, 数组中的每个元素代表1行
#每行中含有若干段, 代表一段带有格式的字符串
#每个段包含两个元素, 分别是字符串和格式, 格式由1个整数表示
#参数:
#$CONFIG: 配置参数
#currList_ref, 匹配信息, 匹配上的行相关信息, 每行包括一个列表, 列表中没项是一串整型编码, 需要调用unpackList解码
#解码后的信息
#位置[0]:score, [1]:匹配起始位置, [2]:匹配结束位置, [3]:对应strList_ref的行号
#$iPattern, 在输入部分显示
#返回值:
#buffer引用
sub bufferOutputWithFormat{
  my ($CONFIG, $algo, $currList_ref, $iPattern) = @_;

  my @buf;
  my $before = 0;
  #整个列表长度
  my $catLen = $algo->getCatArraySize;
  #当前匹配列表长度
  my $currLen = scalar(@{$currList_ref});
  my $hasInput = length($iPattern);

  #输出头部信息
  if ($CONFIG->{headerFirst}) {
    if(exists $runStatus{headerList}) {
      $buf[$before+$_][0] = [$runStatus{headerList}->[$_], 10] foreach (0 .. $#{$runStatus{headerList}});
    }
    $before += scalar(@{$runStatus{headerList}});
  }
  #输出提示信息
  my $queryColorPair = 11;
  $queryColorPair = 12 if ($CONFIG->{disable});
  my $spinnerChar = &getSpinnerChar;
  $buf[$before][0] = [$spinnerChar."$CONFIG->{prompt}", 9];
  $buf[$before][1] = [$iPattern, $queryColorPair];
  $runStatus{inputRow} = $before;
  $before += 1;
  if ($CONFIG->{info} == 0){
    $buf[$before][0] = [" $currLen/$catLen ($CONFIG->{algo})", 8];
    $before += 1;
  }elsif($CONFIG->{info} == 1) {
    $buf[$before-1][2] = ["  <$currLen/$catLen ($CONFIG->{algo})", 8];
  }elsif($CONFIG->{info} == 2) { }
  #输出头部信息
  if (not $CONFIG->{headerFirst}) {
    if(exists $runStatus{headerList}) {
      $buf[$before+$_][0] = [$runStatus{headerList}->[$_], 10] foreach (0 .. $#{$runStatus{headerList}});
    }
    $before += scalar(@{$runStatus{headerList}});
  }
  $runStatus{before} = $before;

  return \@buf if $currLen == 0;
  if($CONFIG->{withNth}) { #设置withNth选项
    my $bi=0;
    foreach my $i ($runStatus{bottom} .. min($runStatus{top}, $#{$currList_ref})) {
      #取出匹配列表所对应的原始字符串, 以及相关匹配信息
      my $currItem = unpackList($currList_ref->[$i]);
      my $id = $currItem->[3];
      my $matchStr = $algo->getStr($id);
      my $start = $currItem->[1];
      my $end = $currItem->[2];
      # 后端算法模块处理的是char数组, 若被查询字符串含有宽字符编码, 需要修正匹配位置信息
      # $matchStr = Encode::decode_utf8($matchStr);
      ($matchStr, $start, $end) = fixUtf8List($matchStr, $start, $end);

      #组装withNth列表中的显示字段
      my @strs = split /$CONFIG->{delimiter}/, $matchStr;
      my @dels = ($matchStr =~ /$CONFIG->{delimiter}/g);
      my @arr = map {join "", ($strs[$_], $dels[$_])} (0 .. $#strs);
      if (not $hasInput){
        #筛选
        my @filter = @{$CONFIG->{withNth}};
        my @arr = grep {defined $_} map {$arr[$_]} @filter;

        #整合筛选后的字符串列表并输出
        my $outStr = join "", @arr;
        #若标记为选中, 输出选择标记
        if ($algo->getMarkLabel($id)==1){
          $buf[$bi+$before][0] = [" ".$CONFIG->{marker}, 5];
        } else{
          $buf[$bi+$before][0] = ["  ", 1];
        }
        push @{$buf[$bi+$before]}, [$outStr, 1];
        if(length($outStr) > $runStatus{maxLen}) {$runStatus{maxLen} = length($outStr)};
      }else{
        #筛选
        my @filter = @{$CONFIG->{withNth}};
        my @charMark;
        #逐位设置筛选标记, 1代表在筛选范围内, 0代表不在筛选范围内
        foreach my $j (0 .. $#arr) {
          if (grep{$_ == $j} @filter){
            push @charMark, (1) x length($arr[$j]) 
          }else {
            push @charMark, (0) x length($arr[$j]);
          }
        }

        #regex position mark, 正则匹配的位置
        my @regxMark;
        push @regxMark, (0) x ($start->[0] - 0);
        #转换成为逐位匹配标记
        for my $j (0 .. $#{$start}) {
          push @regxMark, (1) x ($end->[$j] - $start->[$j]);
          if($j < $#{$start}) {
            push @regxMark, (0) x ($start->[$j+1] - $end->[$j]);
          } else {
            push @regxMark, (0) x (length($matchStr) - $end->[$j]);
          }
        }

        #outPut
        my $outputStr;
        #将字符串拆分成为逐位列表
        my @charArr = split //, $matchStr;
        #输出选择标记
        if ($algo->getMarkLabel($id)==1){
          $buf[$bi+$before][0] = [" ".$CONFIG->{marker}, 5];
        } else{
          $buf[$bi+$before][0] = ["  ", 1];
        }
        #逐位输出, 每个字符带有1个属性值
        my $outLen = 0;
        foreach my $j (0 .. $#regxMark) {
          if ($charMark[$j]) {
            if ($regxMark[$j]){
              push @{$buf[$bi+$before]}, ["$charArr[$j]", 3];
            }else{
              push @{$buf[$bi+$before]}, ["$charArr[$j]", 1];
            }
            $outLen ++;
          }
        }
        if($outLen > $runStatus{maxLen}) {$runStatus{maxLen} = $outLen};
      }
      $bi ++;
    }
  }else { #未设置withNth选项
    my $bi=0;
    foreach my $i ($runStatus{bottom} .. min($runStatus{top}, $#{$currList_ref})) {
      #取出匹配列表所对应的原始字符串, 以及相关匹配信息
      my $currItem = unpackList($currList_ref->[$i]);
      my $id = $currItem->[3];
      #输出选择标记
      if ($algo->getMarkLabel($id)==1){
        $buf[$bi+$before][0] = [" ".$CONFIG->{marker}, 5];
      } else{
        $buf[$bi+$before][0] = ["  ", 1];
      }

      if (not $hasInput) {
        #输出完整的字符串
        my $outStr = $algo->getStr($id);
        $outStr = Encode::decode_utf8($outStr);
        push @{$buf[$bi+$before]}, [$outStr, 1];
        if(length($outStr) > $runStatus{maxLen}) {$runStatus{maxLen} = length($outStr)};
      }else {
        #正则匹配的开始和结束位置
        my $start = $currItem->[1];
        my $end = $currItem->[2];

        my $outStr = $algo->getStr($id);
        # 后端算法模块处理的是char数组, 若被查询字符串含有宽字符编码, 需要修正匹配位置信息
        # $outStr = Encode::decode_utf8($outStr);
        ($outStr, $start, $end) = fixUtf8List($outStr, $start, $end);
        if(length($outStr) > $runStatus{maxLen}) {$runStatus{maxLen} = length($outStr)};
        #第1个匹配位置前的字符串, 正常显示
        my $partStr = substr($outStr, 0, $start->[0]);
        push @{$buf[$bi+$before]}, ["$partStr", 1];
        foreach my $j (0 .. $#{$start}){
          #匹配上的字符串, 格式输出
          $partStr = substr($outStr, $start->[$j], $end->[$j] - $start->[$j]);
          push @{$buf[$bi+$before]}, [$partStr, 3];
          if ($j < $#{$start} ) { #每个匹配位置间隔中的字符串, 正常输出
            $partStr = substr($outStr, $end->[$j], $start->[$j+1] - $end->[$j]);
          } else{ #最后1个匹配位置后的字符串, 正常输出
            $partStr = substr($outStr, $end->[$j]);
          }
          push @{$buf[$bi+$before]}, [$partStr, 1];
        }
      }
      $bi ++;
    }
  }
  return \@buf;
}

#从cpp算法后端返回的匹配信息是一串整型编码
#int[1]=line, int[2]=score, 后面一串匹配位置信息, 每对包括start和end位置
#解码后的匹配信息为[$score, \@start, \@end, $line]
sub unpackList{
    my $packStr = shift @_;
    
    my $len =  length($packStr)/4;
    my @unList = unpack("i$len", $packStr);
    my $line = shift @unList;
    my $score = shift @unList;
    my @start;
    my @end;
    while(scalar(@unList) >0) {
      my $s = shift @unList;
      push @start, $s;
      my $e = shift @unList;
      push @end, $e;
    }
    return [$score, \@start, \@end, $line];
}

# 后端算法模块处理的是char数组, 若被查询字符串含有宽字符编码, 需要修正匹配位置信息
# $inStr被匹配字符串, $start匹配字符的起始位置, $end匹配字符的结束位置
sub fixUtf8List {
  my ($inStr, $start, $end) = @_;
  #复制匹配信息
  my @fixStart = @$start;
  my @fixEnd = @$end;

  #将被匹配字符串拆成char数组
  my @chars = split //, $inStr;
  my $charIdx;
  while($charIdx < length($inStr)) {
    my $ch=$chars[$charIdx];
    if (ord($ch) < 128){ #普通的asc字符编码
      $charIdx ++;
      next;
    }elsif (ord($ch) >=192 && ord($ch) < 224) {#utf8双字节编码
      foreach my $i (0 .. $#{$start}) {
        $fixStart[$i] -= 1 if ($charIdx < $start->[$i]);
        $fixEnd[$i] -=1 if ($charIdx < $start->[$i]);
      }
      $charIdx += 2;
    }elsif (ord($ch) >=224 && ord($ch) < 240) {#utf8三字节编码
      foreach my $i (0 .. $#{$start}) {
        $fixStart[$i] -= 2 if ($charIdx < $start->[$i]);
        $fixEnd[$i] -=2 if ($charIdx < $start->[$i]);
      }
      $charIdx += 3;
    }elsif (ofd($ch) >=240) {
      foreach my $i (0 .. $#{$start}) {#utf8四字节编码
        $fixStart[$i] -= 3 if ($charIdx < $start->[$i]);
        $fixEnd[$i] -=3 if ($charIdx < $start->[$i]);
      }
      $charIdx += 4;
    }
  }
  #将被匹配字符串转化成为utf8编码
  $inStr = Encode::decode_utf8($inStr);
  return ($inStr, \@fixStart, \@fixEnd);
}

#调用后端cpp算法模块的匹配算法
sub matchList {
  my ($CONFIG, $algo, $iPattern) = @_;

  my @algoList = qw(exact v1 v2);
  my $algoIdx = firstidx {$_ eq $CONFIG->{algo}} @algoList;

  my $currList = $algo->matchList($iPattern, $CONFIG->{sort}, $CONFIG->{caseInsensitive}, $algoIdx, $CONFIG->{threads});

  return $currList;
}

#函数movePointerDown, 向下移动匹配项指针
#参数
#$CONFIG, 配置信息
#$currList_ref, 当前匹配记录列表
#$ptr_ref, 指针变量引用
#$off, 移动的位移
sub movePointerDown{
  my ($CONFIG, $currList_ref, $ptr_ref, $off) = @_;
  if (defined $off) {
    ${$ptr_ref} -= $off;
  }else{
    ${$ptr_ref} --;
  }
  #若指针小于0, 则循环为列表结尾, 或者设置为0
  if (${$ptr_ref} < 0) {
    if ($CONFIG->{cycle}) {
      ${$ptr_ref} = $#{$currList_ref};
    }else{
      ${$ptr_ref} = 0;
      return;
    }
  }
}

#函数movePointerUp, 向上移动匹配项指针
#参数
#$CONFIG, 配置信息
#$currList_ref, 当前匹配记录列表
#$ptr_ref, 指针变量引用
#$off, 移动的位移
sub movePointerUp{
  my ($CONFIG, $tui, $currList_ref, $ptr_ref, $off) = @_;
  if (defined $off) {
    ${$ptr_ref} += $off;
  }else{
    ${$ptr_ref} ++;
  }
  #若指针超过列表边界, 则设置为0, 或停留在边界
  if (${$ptr_ref} > $#{$currList_ref}) {
    if ($CONFIG->{cycle}) {
      ${$ptr_ref} = 0;
    }else{
      ${$ptr_ref} = $#{$currList_ref};
      return;
    }
  }
}


#函数bufferPreviewOutput, 生成preview的显示buffer, 不带颜色格式, 仅仅类似catStr
#参数,
#$previewString, preview的字符串列表引用
#返回显示buffer的引用
sub bufferPreviewOutput {
  my ($previewStrings) = @_;
  my @buffer;
  #14是preview文本的显示缺省格式号
  push @buffer, [[$_, 14]] foreach (@{$previewStrings});
  return \@buffer;
}

#函数bufferPreviewOutputWithANSI, 生成preview的显示buffer, 使用ANSI256颜色配置
#参数,
#$previewString, preview的字符串列表引用
#返回显示buffer的引用
#使用Term::ANSIColor中对颜色的命名, 包括有4类形式
#16种缺省颜色, grey\d是灰度颜色, rgb\d\d\d是216种颜色, \d是0到5的rgb数字,
#r\d+g\d+b\d+是24位的rgb颜色, 在代码中被转化为216种颜色配置
sub bufferPreviewOutputWithANSI {
  my ($tui, $previewStrings) = @_;

  #对显示的字符串列表按照分割成为正文和转义序列, 存储在@showList中
  my @showList;
  #所有的转义序列列表
  my @escList;
  #hash, 转义序列为key, 对应的颜色标识
  my %escMap;

  #对每行字符串, 按照转义序列间隔分割为列表, 列表奇数位置为转义字符串
  #将所有的转义字符串, 加入列表@escList, 并排重
  foreach my $input (@{$previewStrings}){
    my @parts = ta_split_codes($input);
    foreach my $i (0 .. $#parts) {
      #去除干扰
      if ($i % 2== 1){
        $parts[$i] =~ s/.*(\e\[.*m).*/\1/;
        push @escList, $parts[$i];
      }
    }
    push @showList, \@parts;
  }
  @escList = uniqstr @escList;

  #将缺省的重置转义命令设置为缺省的Curses颜色对
  my @pairList = ([-1, -1]);
  $escMap{"\e[0m"} = 0;
  
  #处理出现的esc码
  foreach my $escStr (@escList){
    my $p = $escStr;
    $p =~ s/\e\[(.*?)m/\1/;
    my @names = uncolor($p);
    my @cs;
    foreach my $n (@names){
      if (any {$_ eq $n} @{$tui->{colorList}}){
        push @cs, $n;
      }elsif ($n =~ /r\d+g\d+b\d+/){
        push @cs, $n;
      }elsif ($n =~ /rgb\d+/) {
        push @cs, $n;
      }elsif ($n =~ /grey\d+/) {
        push @cs, $n;
      }
    }
    #fg, 前景颜色处理, 将ANSIColor中的颜色名称, 转化为预定义好的颜色对标识
    my $fg = -1;
    my $fgstr = first {not $_ =~ /^on/} @cs;
    if (defined $fgstr) {
      $fg = $tui->getColorID($fgstr);
    }
    #bg, 背景颜色处理
    my $bg = -1;
    my $bgstr = first {$_ =~ /^on/} @cs;
    if (defined $bgstr) {
      $bg = $tui->getColorID($bgstr);
    }
    #以每个转义序列颜色配置作为key, 索引颜色对
    #20之前为保留的颜色对配置
    if (not exists $escMap{escStr}) {
      push @pairList, [$fg, $bg];
      $escMap{$escStr} = $#pairList+20;
      $tui->initPair($#pairList+20, $fg, $bg);
    }
  }

  #将原文中的每个转义颜色配置所对应的文字, 分段组装的显示buffer中
  my @buf;
  foreach my $i (0 .. $#showList) {
    my $line = $showList[$i];
    #在列表开头增加控制序列
    if (not $line->[0] =~ /\e\[.*?m/) {
      unshift @{$line}, "\e[0m";
    }
    my $j = 0;
    foreach my $pair (pairs @{$line}){
      my ($escstr, $str) = @$pair;
      my $attrNum = 0;
      $attrNum = $escMap{$escstr} if (exists $escMap{$escstr});
      $buf[$i][$j] = [$str, $attrNum];
      $j ++;
    }
  }
  return \@buf;
}

#函数setPreviewStatusON, 用于指示preview的外部状态是否发生变化, 是否需要重新调用回调函数更新preview内容
sub setPreviewStatusOn {
    $runStatus{previewStatus} = 1;
}

#函数setPreviewStatusOff, 用于关闭指示preview的外部状态
sub setPreviewStatusOff {
    $runStatus{previewStatus} = 0;
}

#函数getPreviewStatus, 用于获取preview的外部状态
sub getPreviewStatus {
  return $runStatus{previewStatus};
}

#函数showPreview, 负责调用用户定义的显示preview回调函数
#参数
#$CONFIG, 配置信息
#$tui, 显示模块引用
#$currentList, 模式匹配记录集引用
#$pointer, 当前记录指针
sub showPreview {
    my ($CONFIG, $algo, $tui, $currList, $pointer) = @_;
    #若显示列表为空, 直接打印空列表, 并退出
    if (not defined $currList) {return;}
    if (scalar @{$currList} == 0){
      $tui->setPreviewBuffer(undef);
      $tui->previewPrint;
      return;
    }

    #将当前记录的字符串, 切割为列表后, 传递给回调函数
    #回调函数的参数包括, 字符串列表, 显示模块的行和列, 用于控制显示
    my $currItem = unpackList($currList->[$pointer]);
    my $id = $currItem->[3];

    my $str = $algo->getStr($id);
    my @arr = split /$CONFIG->{delimiter}/, $str;
    my $lines = $tui->getPreviewLines();
    my $columns = $tui->getPreviewCols();

    #调用回调函数, 获得显示字符串列表引用
    my $rList = &{$CONFIG->{previewFunc}}(\@arr, $lines, $columns);
    
    #convert to utf8
    foreach my $i (0 .. $#{$rList}) {
      $rList->[$i] = Encode::decode_utf8($rList->[$i]);
    }

    #转换为显示buffer, 按照配置是否显示颜色
    my $buf;
    if ($CONFIG->{previewWithColor}){
      $buf = &bufferPreviewOutputWithANSI($tui, $rList);
    }else{
      $buf = &bufferPreviewOutput($rList);
    }
    
    #设置显示模块的preview buffer, 并调用显示preview打印函数
    $tui->setPreviewBuffer($buf);
    if ($CONFIG->{previewFollow}) {
      $tui->setPreviewTail;
    }else{
      $tui->previewPrint;
    }
}

#执行用户回调函数
#将列表指针指向的字符串取出, 安分割符切分为数组, 作为参数调用回调函数
sub execute {
  my ($CONFIG, $algo, $currList, $pointer) = @_;
  return if (scalar @{$currList} == 0);

  my $currItem = unpackList($currList->[$pointer]);
  my $id = $currItem->[3];
  my $str = $algo->getStr($id);
  my @arr = split /$CONFIG->{delimiter}/, $str;

  #调用配置中的执行回调函数
  &{$CONFIG->{execFunc}}(\@arr);
  return;
}

#切换算法
sub toggleAlgo {
  my ($CONFIG) = @_;
  
  my @algoList = qw(exact v1 v2);
  my $idx = firstidx {$_ eq $CONFIG->{algo}} @algoList;
  $idx = ($idx + 1) % 3;
  $CONFIG->{algo} = $algoList[$idx];
}

#缺省的preview回调函数
sub defaultPreviewFunc {
  my ($strList, $lines, $columns) = @_;

  my @rList;
  if (defined $strList->[8]) {
      open PREVIEWFILE, "<$strList->[8]";
      my $i = 0;
      while (my $input = <PREVIEWFILE>){
        chomp $input;
        push @rList, $input;
        last if ($i >= $lines);
        $i ++;
    }
    close PREVIEWFILE;
  }
  return \@rList;
}

#使用bat做带颜色的输出的preview回调函数
sub batPreviewFunc {
  my ($strList, $lines, $columns) = @_;

  my @rList;
  if (defined $strList->[8]) {
    my $file = $strList->[8];
    my $str;
    # open STDERR, ">>", "/dev/null" or die "cannot redirect err output";
    # open STDERR, ">>", STDOUT or die "cannot redirect err output";
    eval{
      $str = qx (bat --color=always $file 2> /dev/null);
    };
    $str= "" if ($@);

    @rList = split /\n/, $str;
    # @rList = map {$rList[$_]} grep{$_ < $lines} (0 .. $#rList);
  }
  return \@rList;
}

#缺省的执行回调函数
sub defaultExecFunc {
  my ($strList) = @_;
  return;
}

#curse应用, 调试信息输出到文件
# my $DEBUGFILE;
# sub debug {
#   my $str = shift @_;
#   select $DEBUGFILE;
#   $| = 1;
#   print $str;
#   select STDOUT;
#   $| = 1;
# }

# main entrace
#主函数fzf, 根据输入的查询pattrn, 交互式显示查询的结果
#参数$inputs, 被检索的字符数组地址, 或者输入文件句柄用于输入信息
#参数$USERCONFIG, 用户配置hash地址
#返回检索的字符串
sub fzf{
  my ($inputs, $USERCONFIG) = @_;

  # #debug file init
  # open $DEBUGFILE, ">>debug.log";

  #融合用户配置信息和缺省配置信息
  my $CONFIG = $DEFAULTCONFIG;
  if (defined $USERCONFIG) {
    foreach (keys %{$USERCONFIG} ) {
      $CONFIG->{$_}= $USERCONFIG->{$_};
    }
  }
  # $CONFIG->{debug} = \&debug;

  #处理输入
  #输入是否是文件句柄
  my $isFile=0;
  my $algo; 
  #生成后端cpp算法模块对象
  if (not defined $CONFIG->{nth}){
    $algo = Search::Fzf::AlgoCpp->new($CONFIG->{tac}, $CONFIG->{caseInsensitive}, $CONFIG->{headerLines});
  }else{
    $algo = Search::Fzf::AlgoCpp->newAlgoCpp($CONFIG->{tac}, $CONFIG->{caseInsensitive}, $CONFIG->{headerLines}, 1, $CONFIG->{delimiter}, $CONFIG->{nth});
  }
  if (ref($inputs) eq 'ARRAY'){ #数组输入
    $algo->read($inputs);
  }else { #文件句柄输入
    $isFile = 1;
    $algo->asynRead($inputs);
    if (not $CONFIG->{asynRead}){
      while(1) {last if $algo->getReaderStatus == 1;}
    }
  }

  #处理header
  my @header;
  push (@header, $CONFIG->{header}) if(defined $CONFIG->{header});
  my $inputHeader = $algo->getHeaderStr();
  push @header, @{$inputHeader};
  $runStatus{headerList} = \@header;

  #匹配信息列表
  my $currList ;
  my $currLen;
  #当前选择的记录指针
  my $ptr = 0;
  #左右移动的位置
  my $move = 0;
  #光标位置
  my $cursor = 0;
  #处理curses模块getch方法的缓冲区, 用于处理utf8宽字符编码
  my @inBuf = ();
  #输入的查询字符数组
  my @pattArr;
  my $iPattern = "";
  my $isExpect = 0;
  
  #init Curses
  my $tui = new Search::Fzf::Tui($CONFIG); #startx, starty, width, height
  $SIG{INT} = sub {$tui->closeWin;
                   close($inputs) if $isFile;
                   exit;};
  my ($h, $w) = $tui->openWin();
  &resetPointer($CONFIG, $h, $w);

  my $init = 1;
  my $shouldPrint = 1;
  my $seqLen = 1;
  while(1) {
    #读取输入命令
    my ($ch, $command, $clickrow);
    if ($init) {
      $command = $tui->{COMMAND_CHECK};
      $init = 0;
    }else{
      ($ch, $command, $clickrow) = $tui->getc();
    }
    
    if (not defined $command){ #如果是查询字符输入
      #如果设置disable选项, 仅仅功能键可以使用
      next if ($CONFIG->{disable});
      next if (not (defined $ch) || length($ch) == 0);

      #处理宽字符输入
      my $inStr;
      if (ord ($ch) <128) {
        @inBuf = ();
        $inStr = $ch;
      }else{
        if (scalar(@inBuf) == 0) {
          if (ord($ch) >=192 && ord($ch) < 224) {
            $seqLen = 2;
          }elsif (ord($ch) >=224 && ord($ch) < 240) {
            $seqLen = 3;
          }elsif (ord($ch) >=240) {
            $seqLen = 4;
          }
        }
        push @inBuf, $ch;
        if (scalar(@inBuf) < $seqLen) {
          next;
        }
        $inStr = reduce {$a . $b} @inBuf;
        @inBuf = ();
        $seqLen = 1;
      }
      
      #打开utf8编码标志
      Encode::_utf8_on($inStr);
      splice(@pattArr, $cursor, 0, $inStr);
      $cursor += 1;
      $shouldPrint = 1;
    }else{ #function 
      if($command == $tui->{COMMAND_ABORT}) {
        $algo->sendExitSign;
        while(1) {last if $algo->getReaderStatus == 1};
        $tui->closeWin;
        close($inputs) if $isFile;
        exit 0;
      }elsif($command == $tui->{COMMAND_ACCEPT}){
        #退出键
        $algo->sendExitSign;
        while(1) {last if $algo->getReaderStatus == 1};
        last;
      }elsif($command == $tui->{COMMAND_EXPECT_ACCEPT}){
        #退出键
        $isExpect = 1 if ((defined $CONFIG->{expect}) && (length($CONFIG->{expect})>0));
        $algo->sendExitSign;
        while(1) {last if $algo->getReaderStatus == 1};
        last;
      }elsif($command == $tui->{COMMAND_ACCEPT_NON_EMPTY}) {
        if($algo->getMarkedCount() > 0){
          $algo->sendExitSign;
          while(1) {last if $algo->getReaderStatus == 1};
          last;
        }
      }elsif($command == $tui->{COMMAND_BACKWARD_CHAR}) {
        next if $CONFIG->{disable};
        $cursor -= 1;
        $cursor = 0 if $cursor < 0;
        $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr);
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_BACKWARD_DELETE_CHAR}){
        next if $CONFIG->{disable};
        #回退并删除
        if ($cursor > 0) {
          splice(@pattArr, $cursor - 1, 1);
          $cursor -= 1;
          $shouldPrint = 1;
        }else {
          $shouldPrint =0;
        }
      }elsif($command == $tui->{COMMAND_BACKWARD_DELETE_CHAR_EOF}){
        next if $CONFIG->{disable};
        if (scalar(@pattArr) == 0){
          $algo->sendExitSign;
          while(1) {last if $algo->getReaderStatus == 1};
          $tui->closeWin;
          close($inputs) if $isFile;
          exit 0;
        }
        #回退并删除, 若到头则退出
        if ($cursor >0) {
          splice(@pattArr, $cursor - 1, 1);
          $cursor -= 1;
          if (scalar(@pattArr) == 0){
            $algo->sendExitSign;
            while(1) {last if $algo->getReaderStatus == 1};
            $tui->closeWin;
            close($inputs) if $isFile;
            exit 0;
          }
          $shouldPrint = 1;
        }else {
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_BACKWARD_KILL_WORD}){
        next if $CONFIG->{disable};
        
        if ($cursor > 0) {
          my $i = $cursor;
          while ($i > 0 && $pattArr[$i-1] =~ /\s/) {
            $i --;
          }
          if ($i >0) {
            while ($i > 0 && $pattArr[$i-1] =~ /\S/) {
              $i--;
            }
          }
          splice(@pattArr, $i, $cursor - $i);
          $cursor = $i;
          $shouldPrint = 1;
        }else{
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_BACKWARD_WORD}){
        next if $CONFIG->{disable};
        if ($cursor > 0) {
          my $i = $cursor;
          while ($i > 0 && $pattArr[$i-1] =~ /\s/) {
            $i --;
          }
          if ($i >0) {
            while ($i > 0 && $pattArr[$i-1] =~ /\S/) {
              $i--;
            }
          }
          $cursor = $i;
        }
        $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr);
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_BEGINNING_OF_LINE}) {
        next if $CONFIG->{disable};
        $cursor = 0;
        $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr);
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_CANCEL}) {
        next if $CONFIG->{disable};

        if (scalar(@pattArr) > 0){
          @pattArr = ();
          $cursor = 0;
        }else{
          $algo->sendExitSign;
          while(1) {last if $algo->getReaderStatus == 1};
          exit 0;
        }
      }elsif($command == $tui->{COMMAND_CLEAR_SELECTION}) {
        $algo->unSetAllMarkLabel;
        $shouldPrint = 1;
      # }elsif($command == $tui->{COMMAND_CLOSE}) {
      ###########wait implement#####################################
      }elsif($command == $tui->{COMMAND_CLEAR_QUERY}) {
        next if $CONFIG->{disable};
        @pattArr = ();
        $cursor = 0;
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_DELETE_CHAR}) {
        next if $CONFIG->{disable};

        if ($cursor <= $#pattArr) {
          splice(@pattArr, $cursor, 1);
          $shouldPrint = 1;
        }else {
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_DELETE_CHAR_EOF}) {
        next if $CONFIG->{disable};
        if (scalar(@pattArr) == 0){
          $algo->sendExitSign;
          while(1) {last if $algo->getReaderStatus == 1};
          $tui->closeWin;
          close($inputs) if $isFile;
          exit 0;
        }

        if ($cursor <= $#pattArr) {
          splice(@pattArr, $cursor, 1);
          if (scalar(@pattArr) == 0){
            $algo->sendExitSign;
            while(1) {last if $algo->getReaderStatus == 1};
            $tui->closeWin;
            close($inputs) if $isFile;
            exit 0;
          }
          $shouldPrint = 1;
        }else {
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_DESELECT}) {
        #取消选择键, 将字符串数组中的选择标记设置为0
        if ($CONFIG->{multi}){
          my $currItem = unpackList($currList->[$ptr]);
          my $no = $currItem->[3];
          $algo->unSetMarkLabel($no);
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_DESELECT_ALL}) {
        if ($CONFIG->{multi}){
          $algo->unSetAllMarkLabel;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_DISABLE_SEARCH}) {
        $CONFIG->{disable} = 1;
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_DOWN}) {  #向下滚动
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerDown($CONFIG, $currList, \$ptr);
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr);
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_ENABLE_SEARCH}) {
        $CONFIG->{disable} = 0;
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_END_OF_LINE}) {
        next if $CONFIG->{disable};
        $cursor = scalar(@pattArr);
        $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr);
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_EXECUTE}) {
        &execute($CONFIG, $algo, $currList, $ptr);
        $shouldPrint = 0;
      # }elsif($command == $tui->{COMMAND_EXECUTE_SILENT}) {
      ###########wait implement#####################################
      }elsif($command == $tui->{COMMAND_FIRST}) {
        $ptr = 0;
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_FORWARD_CHAR}) {
        next if $CONFIG->{disable};
        $cursor += 1;
        $cursor = scalar(@pattArr) if $cursor >= scalar(@pattArr);
        $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr);
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_FORWARD_WORD}){
        next if $CONFIG->{disable};
        if ($cursor < scalar(@pattArr)) {
          my $i = $cursor;
          while ($i <scalar(@pattArr) && $pattArr[$i+1] =~ /\s/) {
            $i ++;
          }
          if ($i < scalar(@pattArr)) {
            while ($i < scalar(@pattArr) && $pattArr[$i+1] =~ /\S/) {
              $i++;
            }
          }
          $cursor = $i;
        }
        $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr);
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_JUMP}) {
        #跳转
        $tui->showJumpLabel;
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_JUMP_ACCEPT}) {
        #跳转
        $tui->showJumpLabelAccept;
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_KILL_LINE}) {
        next if $CONFIG->{disable};
        splice(@pattArr, $cursor);
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_KILL_WORD}) {
        next if $CONFIG->{disable};
        if ($cursor < scalar(@pattArr)) {
          my $i = $cursor;
          while ($i <scalar(@pattArr) && $pattArr[$i+1] =~ /\s/) {
            $i ++;
          }
          if ($i < scalar(@pattArr)) {
            while ($i < scalar(@pattArr) && $pattArr[$i+1] =~ /\S/) {
              $i++;
            }
          }
          splice(@pattArr, $cursor, $i - $cursor + 1);
          $shouldPrint = 1;
        }else{
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_LAST}) {
        $ptr = $#{$currList};
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }

        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_PAGE_DOWN}) { #向下翻动页
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerDown($CONFIG, $currList, \$ptr, ($tui->getHeight - 3));
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr, ($tui->getHeight - 3));
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_PAGE_UP}) { #向上翻动页
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr, ($tui->getHeight - 3));
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerDown($CONFIG, $currList, \$ptr, ($tui->getHeight - 3));
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_HALF_PAGE_DOWN}) { #向下翻动半页
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerDown($CONFIG, $currList, \$ptr, int($tui->getHeight / 2));
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr, int($tui->getHeight / 2));
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_HALF_PAGE_UP}) { #向上翻动半页
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr, int($tui->getHeight / 2));
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerDown($CONFIG, $currList, \$ptr, int($tui->getHeight / 2));
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      # }elsif($command == $tui->{COMMAND_PREVIEW}) {
      }elsif($command == $tui->{COMMAND_PREVIEW_DOWN}) {
        if ($CONFIG->{preview}){
          $tui->setPreviewOff(1);
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_UP}) {
        if ($CONFIG->{preview}){
          $tui->setPreviewOff(-1);
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_PAGE_DOWN}) {
        if ($CONFIG->{preview}){
          my $lines = $tui->getPreviewLines - 1;
          $tui->setPreviewOff($lines);
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_PAGE_UP}) {
        if ($CONFIG->{preview}){
          my $lines = $tui->getPreviewLines - 1;
          $tui->setPreviewOff(-$lines);
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_HALF_PAGE_DOWN}) {
        if ($CONFIG->{preview}){
          my $lines = int ($tui->getPreviewLines/2);
          $tui->setPreviewOff($lines);
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_HALF_PAGE_UP}) {
        if ($CONFIG->{preview}){
          my $lines = int ($tui->getPreviewLines/2);
          $tui->setPreviewOff(- $lines);
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_BOTTOM}) {
        if ($CONFIG->{preview}){
          $tui->setPreviewTail;
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      }elsif($command == $tui->{COMMAND_PREVIEW_TOP}) {
        if ($CONFIG->{preview}){
          $tui->setPreviewHead;
          # $tui->setCursor($cursor, \@pattArr);
          $tui->resetCursor;
          $shouldPrint = 0;
        }
      # }elsif($command == $tui->{COMMAND_RELOAD}) {
      }elsif($command == $tui->{COMMAND_SELECT}) {
        if ($CONFIG->{multi}) {
          my $currItem = unpackList($currList->[$ptr]);
          my $no = $currItem->[3];
          $algo->setMarkLabel($no);
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_SELECT_ALL}) {
        if ($CONFIG->{multi}){
          $algo->setAllMarkLabel;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_ALGO}) {
        &toggleAlgo($CONFIG);
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE}) {
        if ($CONFIG->{multi}) {
          my $currItem = unpackList($currList->[$ptr]);
          my $no = $currItem->[3];
          $algo->toggleMarkLabel($no);
          my $m = $algo->getMarkLabel($no);
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_ALL}) {
        if ($CONFIG->{multi}){
          $algo->toggleAllMarkLabel();
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_DOWN}) {
        if ($CONFIG->{multi}) {
          my $currItem = unpackList($currList->[$ptr]);
          my $no = $currItem->[3];
          $algo->toggleMarkLabel($no);
        }
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerDown($CONFIG, $currList, \$ptr);
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr);
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      # }elsif($command == $tui->{COMMAND_TOGGLE_IN}) {
      # }elsif($command == $tui->{COMMAND_TOGGLE_OUT}) {
      }elsif($command == $tui->{COMMAND_TOGGLE_PREVIEW}) {
        &togglePreview($CONFIG, $tui);
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_PREVIEW_POSITION}) {
        &togglePreviewPosition($CONFIG, $tui);
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_PREVIEW_WRAP}) {
        $CONFIG->{previewWrap} = ($CONFIG->{previewWrap} + 1) % 2;
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 0;
      }elsif($command == $tui->{COMMAND_TOGGLE_SEARCH}) {
        $CONFIG->{disable} = ($CONFIG->{disable} + 1) % 2;
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_SORT}) {
        $CONFIG->{sort} = ($CONFIG->{sort} + 1) % 2;
        $algo->clearMatchResult;
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_TOGGLE_UP}) {
        if ($CONFIG->{multi}) {
          my $currItem = unpackList($currList->[$ptr]);
          my $no = $currItem->[3];
          $algo->toggleMarkLabel($no);
        }

        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr);
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerDown($CONFIG, $currList, \$ptr);
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_UP}) { #向上滚动
        if ($CONFIG->{layout} == 0 || $CONFIG->{layout} == 2) {
          &movePointerUp($CONFIG, $tui, $currList, \$ptr);
        }elsif ($CONFIG->{layout} == 1) {
          &movePointerDown($CONFIG, $currList, \$ptr);
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_LEFT}) { #向左滚动
        if ($CONFIG->{hScroll}) {$move = -1;};
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_RIGHT}) { #向右滚动
        if ($CONFIG->{hScroll}) {$move = 1;};
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_HOME}) { #滚动到最左侧
        if ($CONFIG->{hScroll}) {
          &resetLeftRight($CONFIG, 1);
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_END}) { #滚动到最右侧
        if ($CONFIG->{hScroll}){
          &resetLeftRight($CONFIG, 0);
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_CLICKED}) {
        #鼠标点击
        if ($CONFIG->{layout} == 0){
          $ptr = $clickrow + $runStatus{bottom};
        }elsif ($CONFIG->{layout} == 1) {
          $ptr = $clickrow - $runStatus{bottom};
        }elsif($CONFIG->{layout} == 2){ #reverse list
          $ptr = $clickrow + $runStatus{bottom};
        }
        #preview out
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn;
        }
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_CLICKED_ACCEPT}) {
        #鼠标点击
        if ($CONFIG->{layout} == 0){
          $ptr = $clickrow + $runStatus{bottom};
        }elsif ($CONFIG->{layout} == 1) {
          $ptr = $clickrow - $runStatus{bottom};
        }elsif($CONFIG->{layout} == 2){ #reverse list
          $ptr = $clickrow + $runStatus{bottom};
        }
        $algo->sendExitSign;
        while(1) {last if $algo->getReaderStatus == 1};
        last;
      }elsif($command == $tui->{COMMAND_RESIZE}) {
        resize($CONFIG, $tui);
        $shouldPrint = 1;
      }elsif($command == $tui->{COMMAND_CHECK}) {
        #check preview
        if($CONFIG->{preview} == 1) {
          &setPreviewStatusOn if $CONFIG->{previewFollow};
          if (&getPreviewStatus == 1) {
            &showPreview($CONFIG, $algo, $tui, $currList, $ptr);
            &setPreviewStatusOff;
            $tui->resetCursor;
            # $shouldPrint = 0;
          }
        }
        #check inputs
        if(($CONFIG->{asynRead} == 1) && ($isFile == 1)) {
          if ($algo->getReaderStatus == 0){
            $shouldPrint = 1;
            $runStatus{isSpinner} = 1;
          }
        }
      }else{ #COMMAND_IDLE
        $shouldPrint = 0;
      }
    }
    
    ##screen out
    #调用后端算法模块, 获得匹配列表, 匹配列表中每项为一串整数编码
    #若模式字符串为"", 着返回全量的NULL匹配列表, 但仅包括行号信息
    if (not $shouldPrint) {next;}
    my $strLen = scalar @pattArr;
    if ($strLen > 0){
      $iPattern = reduce {$a . $b} @pattArr;
      $currList = &matchList($CONFIG, $algo, $iPattern);
    }else{
      $iPattern = "";
      $currList = $algo->getNullMatchList;
    }

    #根据匹配列表长度, 判断pointer指针是否越界
    #判断当前指针是否越界
    $currLen = scalar @{$currList};
    $ptr = $currLen-1 if $ptr > $currLen - 1;
    $ptr = 0 if $ptr <0;
    #根据光标位置设置输出到屏幕的底部和头部信息
    &setPointer($CONFIG, $ptr, $move);

    #生成显示缓冲, 由于currList数量可能很大, 为加快显示速度, 仅对显示尺寸内的列表对象生成显示信息
    $tui->setBuffer(&bufferOutputWithFormat($CONFIG, $algo, $currList, $iPattern));

    #若没有输入, 重置为靠右显示
    # &resetLeftRight(0) if ($CONFIG->{keepRight} && $strLen > 0);
    &resetLeftRight($CONFIG, 0) if ($CONFIG->{keepRight});
    #对输入匹配的位置靠右跟随滚动
    if ($currLen > 0 && $strLen > 0) {
      my $currItem = unpackList($currList->[$ptr]);
      &alignRight($CONFIG, $currItem->[2][-1]) if($CONFIG->{hScrollOff} >= 0) ;
    }

    # 显示部分包括, 显示正文列表, 高亮显示当前行, 重绘显示查询行
    $tui->print($runStatus{left}, $runStatus{right});
    $tui->printPointer($runStatus{before}, $runStatus{location}, $runStatus{left}, $runStatus{right});
    # #preview out
    if($CONFIG->{preview} == 1) {
      &setPreviewStatusOn;
    }
    # #设置输入的光标
    $tui->printQuery($runStatus{inputRow}, $cursor, \@pattArr, &getSpinnerChar);
    $shouldPrint = 0;
  } #end loop
  $tui->closeWin();

  #返回选中的字符串
  my $retArr;
  if ($algo->getMarkedCount > 0) {
    my $sls = $algo->getMarkedCount;
    $retArr = $algo->getMarkedStr();
  }else{
    #返回当前指针指向的记录
    if (scalar @{$currList} > 0) {
      my $currItem = unpackList($currList->[$ptr]);
      my $id = $currItem->[3];
      $retArr = [$algo->getStr($id)];
    }else {
      $retArr = [];
    }
  }
  unshift @{$retArr}, $CONFIG->{expect} if $isExpect;
  return $retArr;
}

1;
