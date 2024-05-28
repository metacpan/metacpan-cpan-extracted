#!/usr/bin/perl
package Search::Fzf::Tui;

# use 5.32.1;
use strict;
use utf8;
use Encode;
use Curses;
use Term::Terminfo;
use Term::ANSIColor qw(color);
use List::Util qw(reduce);
use List::MoreUtils qw( firstidx );

#127以内的asc码所对应的数组
our @ASC = (
'ctrl-@', 'ctrl-a', 'ctrl-b', 'ctrl-c', 'ctrl-d', 'ctrl-e', 'ctrl-f', 'ctrl-g', 'ctrl-h', 'ctrl-i', 'ctrl-j', 'ctrl-k', 'ctrl-l',
'ctrl-m', 'ctrl-n', 'ctrl-o', 'ctrl-p', 'ctrl-q', 'ctrl-r', 'ctrl-s', 'ctrl-t', 'ctrl-u', 'ctrl-v', 'ctrl-w', 'ctrl-x', 'ctrl-y', 'ctrl-z',
'ctrl-[', 'ctrl-\\', 'ctrl-]', 'ctrl-^', 'ctrl--',
" ", '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/',
'0'..'9',
':', ';', '<', '=', '>', '?', '@',
'A'..'Z',
'[', '\\', ']', '^', '_', '`',
'a'..'z',
'{', '|', '}', '~', 'bs',
);

#所有的perl Curses中定义的Key所对应的键名字符串
our %CURSESKEY = (
  KEY_A1, 'KEY_A1',
  KEY_BACKSPACE, 'KEY_BACKSPACE',
  KEY_BTAB, 'KEY_BTAB',
  KEY_CANCEL, 'KEY_CANCEL',
  KEY_CLOSE, 'KEY_CLOSE',
  KEY_CREATE, 'KEY_CREATE',
  KEY_DL, 'KEY_DL',
  KEY_END, 'KEY_END',
  KEY_EOS, 'KEY_EOS',
  KEY_F0, 'KEY_F0',
  KEY_FIND, 'KEY_FIND',
  KEY_IC, 'KEY_IC',
  KEY_LL, 'KEY_LL',
  KEY_MESSAGE, 'KEY_MESSAGE',
  KEY_NEXT, 'KEY_NEXT',
  KEY_OPTIONS, 'KEY_OPTIONS',
  KEY_PRINT, 'KEY_PRINT',
  KEY_REFRESH, 'KEY_REFRESH',
  KEY_RESIZE, 'KEY_RESIZE',
  KEY_RIGHT, 'KEY_RIGHT',
  KEY_SAVE, 'KEY_SAVE',
  KEY_SCOMMAND, 'KEY_SCOMMAND',
  KEY_SDC, 'KEY_SDC',
  KEY_SEND, 'KEY_SEND',
  KEY_SF, 'KEY_SF',
  KEY_SHOME, 'KEY_SHOME',
  KEY_SMESSAGE, 'KEY_SMESSAGE',
  KEY_SOPTIONS, 'KEY_SOPTIONS',
  KEY_SR, 'KEY_SR',
  KEY_SRESET, 'KEY_SRESET',
  KEY_SSAVE, 'KEY_SSAVE',
  KEY_SUNDO, 'KEY_SUNDO',
  KEY_UP, 'KEY_UP',
  KEY_A3, 'KEY_A3',
  KEY_BEG, 'KEY_BEG',
  KEY_C1, 'KEY_C1',
  KEY_CATAB, 'KEY_CATAB',
  KEY_COMMAND, 'KEY_COMMAND',
  KEY_CTAB, 'KEY_CTAB',
  KEY_DOWN, 'KEY_DOWN',
  KEY_ENTER, 'KEY_ENTER',
  # KEY_EVENT, 'KEY_EVENT',
  KEY_HELP, 'KEY_HELP',
  KEY_IL, 'KEY_IL',
  KEY_MARK, 'KEY_MARK',
  KEY_MIN, 'KEY_MIN',
  KEY_NPAGE, 'KEY_NPAGE',
  KEY_PPAGE, 'KEY_PPAGE',
  KEY_REDO, 'KEY_REDO',
  KEY_REPLACE, 'KEY_REPLACE',
  KEY_RESTART, 'KEY_RESTART',
  KEY_SBEG, 'KEY_SBEG',
  KEY_SCOPY, 'KEY_SCOPY',
  KEY_SDL, 'KEY_SDL',
  KEY_SEOL, 'KEY_SEOL',
  KEY_SFIND, 'KEY_SFIND',
  KEY_SIC, 'KEY_SIC',
  KEY_SMOVE, 'KEY_SMOVE',
  KEY_SPREVIOUS, 'KEY_SPREVIOUS',
  KEY_SREDO, 'KEY_SREDO',
  KEY_SRIGHT, 'KEY_SRIGHT',
  KEY_SSUSPEND, 'KEY_SSUSPEND',
  KEY_SUSPEND, 'KEY_SUSPEND',
  KEY_MOUSE, 'KEY_MOUSE',
  KEY_B2, 'KEY_B2',
  KEY_BREAK, 'KEY_BREAK',
  KEY_C3, 'KEY_C3',
  KEY_CLEAR, 'KEY_CLEAR',
  KEY_COPY, 'KEY_COPY',
  KEY_DC, 'KEY_DC',
  KEY_EIC, 'KEY_EIC',
  KEY_EOL, 'KEY_EOL',
  KEY_EXIT, 'KEY_EXIT',
  KEY_HOME, 'KEY_HOME',
  KEY_LEFT, 'KEY_LEFT',
  KEY_MAX, 'KEY_MAX',
  KEY_MOVE, 'KEY_MOVE',
  KEY_OPEN, 'KEY_OPEN',
  KEY_PREVIOUS, 'KEY_PREVIOUS',
  KEY_REFERENCE, 'KEY_REFERENCE',
  KEY_RESET, 'KEY_RESET',
  KEY_RESUME, 'KEY_RESUME',
  KEY_SCANCEL, 'KEY_SCANCEL',
  KEY_SCREATE, 'KEY_SCREATE',
  KEY_SELECT, 'KEY_SELECT',
  KEY_SEXIT, 'KEY_SEXIT',
  KEY_SHELP, 'KEY_SHELP',
  KEY_SLEFT, 'KEY_SLEFT',
  KEY_SNEXT, 'KEY_SNEXT',
  KEY_SPRINT, 'KEY_SPRINT',
  KEY_SREPLACE, 'KEY_SREPLACE',
  KEY_SRSUME, 'KEY_SRSUME',
  KEY_STAB, 'KEY_STAB',
  KEY_UNDO, 'KEY_UNDO',
  KEY_F(4), 'KEY_F(4)',
  KEY_F(5), 'KEY_F(5)',
);

#fzf 中执行的各类动作的定义
our @ACTION=qw(
    COMMAND_IDLE
    COMMAND_ABORT
    COMMAND_ACCEPT 
    COMMAND_EXPECT_ACCEPT
    COMMAND_ACCEPT_NON_EMPTY
    COMMAND_BACKWARD_CHAR
    COMMAND_BACKWARD_DELETE_CHAR 
    COMMAND_BACKWARD_DELETE_CHAR_EOF
    COMMAND_BACKWARD_KILL_WORD
    COMMAND_BACKWARD_WORD
    COMMAND_BEGINNING_OF_LINE
    COMMAND_CANCEL
    COMMAND_CLEAR_SELECTION
    COMMAND_CLEAR_QUERY
    COMMAND_DELETE_CHAR
    COMMAND_DELETE_CHAR_EOF
    COMMAND_DESELECT
    COMMAND_DESELECT_ALL
    COMMAND_DISABLE_SEARCH
    COMMAND_DOWN 
    COMMAND_ENABLE_SEARCH
    COMMAND_END_OF_LINE
    COMMAND_EXECUTE
    COMMAND_EXECUTE-SILENT
    COMMAND_FIRST
    COMMAND_FORWARD_CHAR
    COMMAND_FORWARD_WORD
    COMMAND_JUMP
    COMMAND_JUMP_ACCEPT
    COMMAND_KILL_LINE
    COMMAND_KILL_WORD
    COMMAND_LAST
    COMMAND_PAGE_DOWN
    COMMAND_PAGE_UP
    COMMAND_HALF_PAGE_DOWN
    COMMAND_HALF_PAGE_UP
    COMMAND_PREVIEW_DOWN
    COMMAND_PREVIEW_UP
    COMMAND_PREVIEW_PAGE_DOWN
    COMMAND_PREVIEW_PAGE_UP
    COMMAND_PREVIEW_HALF_PAGE_DOWN
    COMMAND_PREVIEW_HALF_PAGE_UP
    COMMAND_PREVIEW_BOTTOM
    COMMAND_PREVIEW_TOP
    COMMAND_SELECT 
    COMMAND_SELECT_ALL
    COMMAND_TOGGLE
    COMMAND_TOGGLE_ALL
    COMMAND_TOGGLE_DOWN
    COMMAND_TOGGLE_PREVIEW
    COMMAND_TOGGLE_PREVIEW_POSITION
    COMMAND_TOGGLE_PREVIEW_WRAP
    COMMAND_TOGGLE_SEARCH
    COMMAND_TOGGLE_SORT
    COMMAND_TOGGLE_UP
    COMMAND_UP 
    COMMAND_LEFT 
    COMMAND_RIGHT 
    COMMAND_HOME
    COMMAND_END 
    COMMAND_CLICKED 
    COMMAND_CLICKED_ACCEPT
    COMMAND_CHECK
    COMMAND_TOGGLE_ALGO
    COMMAND_RESIZE
);
#CHANGE_PROMPT
#CLEAR_SCREEN
#CLOSE
#IGNORE
#NEXT_HISTORY
#PREVIOUS_HISTORY
#PRINT_QUERY
#PREVIEW
#PUT
#REPLACE_QUERY
# RELOAD
# TOGGLE_IN
# TOGGLE_OUT
#UNBIND
#UNIX_LINE_DISCARD
#UNIX_WORD_RUBOUT
#YANK

#键名和动作的对应表
#键名包括两类, 一类是127以内的asc编码, 第二类是Curses定义的各种功能键
our %DEFAULT_MAP = (
  'ctrl-u' => 'COMMAND_IDLE',
  'ctrl-]' => 'COMMAND_IDLE',
  'ctrl-^' => 'COMMAND_IDLE',
  'ctrl--' => 'COMMAND_IDLE',
  'ctrl-[' => 'COMMAND_ABORT',
  # 'ctrl-g' => 'COMMAND_ABORT',
  'ctrl-m' => 'COMMAND_ACCEPT',
  # 'ctrl-g' => 'COMMAND_ACCEPT_NON_EMPTY',
  'ctrl-h' => 'COMMAND_BACKWARD_CHAR', #ctrl-h
  'KEY_BACKSPACE' => 'COMMAND_BACKWARD_DELETE_CHAR',
  # 'bs' => 'COMMAND_BACKWARD_DELETE_CHAR_EOF',
  # 'bs' => 'COMMAND_BACKWARD_KILL_WORD',
  # 'ctrl-b' => 'COMMAND_BACKWARD_WORD',
  # 'ctrl-w' => 'COMMAND_BEGINNING_OF_LINE',
  # 'ctrl-w' => 'COMMAND_CANCEL',
  # 'ctrl-w' => 'COMMAND_CLEAR_SELECTION',
  # 'ctrl-w' => 'COMMAND_CLOSE', #no_use
  # 'ctrl-w' => 'COMMAND_CLEAR_QUERY',
  'ctrl-x' => 'COMMAND_DELETE_CHAR',
  # 'ctrl-x' => 'COMMAND_DELETE_CHAR_EOF',
  # 'KEY_BTAB'=> 'COMMAND_DESELECT',
  # 'KEY_BTAB'=> 'COMMAND_DESELECT_ALL',
  # 'ctrl-d'=> 'COMMAND_DISABLE_SEARCH',
  'ctrl-j' => 'COMMAND_DOWN',
  # 'ctrl-e'=> 'COMMAND_ENABLE_SEARCH',
  # 'ctrl-w' => 'COMMAND_END_OF_LINE',
  # 'ctrl-w' => 'COMMAND_FIRST',
  'ctrl-l' => 'COMMAND_FORWARD_CHAR',
  # 'ctrl-w' => 'COMMAND_FORWARD_WORD',
  'ctrl-t' => 'COMMAND_JUMP',
  # 'ctrl-t' => 'COMMAND_JUMP_ACCEPT',
  # 'ctrl-x' => 'COMMAND_KILL_LINE',
  # 'ctrl-x' => 'COMMAND_KILL_WORD',
  # 'ctrl-w' => 'COMMAND_LAST',
  # 'KEY_NPAGE'=> 'COMMAND_PAGE_DOWN',
  # 'KEY_PPAGE'=> 'COMMAND_PAGE_UP',
  'KEY_NPAGE'=> 'COMMAND_HALF_PAGE_DOWN',
  'KEY_PPAGE'=> 'COMMAND_HALF_PAGE_UP',
  'ctrl-k' => 'COMMAND_UP',
  # 'ctrl-i' => 'COMMAND_SELECT',
  # 'ctrl-i' => 'COMMAND_SELECT_ALL',
  'KEY_UP'=> 'COMMAND_UP',
  'KEY_DOWN'=> 'COMMAND_DOWN',
  'KEY_LEFT'=> 'COMMAND_LEFT',
  'KEY_RIGHT'=> 'COMMAND_RIGHT',
  'KEY_HOME'=> 'COMMAND_HOME',
  'KEY_END'=> 'COMMAND_END',
  # 'ctrl-n' => 'COMMAND_PREVIEW_DOWN',
  # 'ctrl-p' => 'COMMAND_PREVIEW_UP',
  # 'ctrl-n' => 'COMMAND_PREVIEW_PAGE_DOWN',
  # 'ctrl-p' => 'COMMAND_PREVIEW_PAGE_UP',
  'ctrl-n' => 'COMMAND_PREVIEW_HALF_PAGE_DOWN',
  'ctrl-p' => 'COMMAND_PREVIEW_HALF_PAGE_UP',
  # 'ctrl-n' => 'COMMAND_PREVIEW_BOTTOM',
  # 'ctrl-p' => 'COMMAND_PREVIEW_TOP',
  'KEY_F(4)' => 'COMMAND_TOGGLE_PREVIEW',
  'KEY_F(5)' => 'COMMAND_TOGGLE_PREVIEW_POSITION',
  'KEY_F(6)' => 'COMMAND_TOGGLE_PREVIEW_WRAP',
  'KEY_F(12)' => 'COMMAND_EXPECT_ACCEPT',
  'ctrl-r' => 'COMMAND_TOGGLE_ALGO',
  'ctrl-i' => 'COMMAND_TOGGLE',
  'KEY_BTAB' => 'COMMAND_TOGGLE_ALL',
  # 'ctrl-b' => 'COMMAND_TOGGLE_UP',
  # 'ctrl-b' => 'COMMAND_TOGGLE_DOWN',
  # 'ctrl-b' => 'COMMAND_TOGGLE_SORT',
  'ctrl-d' => 'COMMAND_TOGGLE_SEARCH',
);
#ctrl-a
#ctrl-c

#ANSI定义的16种预定义颜色
my @defaultColorList = qw(black red green yellow blue magenta cyan white bright_black bright_red bright_green bright_yellow bright_blue bright_magenta bright_cyan bright_white);

# #debug函数, 在Curses窗口的第1行输出调试信息
# sub debug {
#   my ($self, $str) = @_;
#   addstring($self->{win}, 0, 0, $str);
# }

#min函数, 两个标量参数, 返回较小的
sub min {
  my ($a, $b) = @_;
  return $a<$b? $a:$b;
}


#对象生成函数
sub new {
  my $class = shift();
  my $self = {
    CONFIG => shift(),
    #Curses 窗口变量
    win => undef,
    #状态变量
    #显示的buffer数据结构
    #buffer数据结构是一个数组, 数组中的每个元素代表1行
    #每行中含有若干段, 代表一段带有格式的字符串
    #每个段包含两个元素, 分别是字符串和格式, 格式由1个整数表示
    buffer => [],
    #buffer中最长行的长度
    maxLen => 0,
    #展示位置信息, 当前行, 底部, 顶部, 左, 右位置信息
    #当前行, 底部和顶部使用的都是buffer中的相对位置
    pointer => 0,
    # left => 0,
    # right => 0,
    #缺省的keymap
    map => \%DEFAULT_MAP,
    #跳转label
    jumpLabels => [],
    #是否在跳转的状态中
    inJump => 0,
    colorList => \@defaultColorList,
    hasColors => 0,
    color => {},
    #光标缓存信息
    cursorInfo => {},
  };
  #定义功能键
  #将所有的动作定义加入到$self中, 并且分配一个唯一的整数作为标识
  my %d = map {$ACTION[$_], $_} (0 .. $#ACTION);
  while(my ($k, $v) = each(%d)) { $self->{$k} = $v; }

  #在缺省值的基础上建立键名和动作之间的对应
  if (defined $self->{CONFIG}->{keymap}) {
    while(my ($k, $v) = each (%{$self->{CONFIG}->{keymap}})) {
      $self->{map}->{$k} = $v;
    }
  }

  #缺省的跳转标签a-zA-Z
  $self->{jumpLabels} = ['a'..'z'];
  push @{$self->{jumpLabels}}, ('A'..'Z');
  if (defined $self->{CONFIG}->{jumpLabels}) {
    $self->{jumpLabels} = $self->{CONFIG}->{jumpLabels};
  }

  #$self->{color}为哈希, 保存了每种颜色对应的颜色标识
  #将缺省颜色的索引装入hash
  foreach my $i (0 .. $#{$self->{colorList}}) {
    my $colorName = $self->{colorList}->[$i];
    $self->{color}->{$colorName} = $i;
  }
  #建立一个颜色的缺省值
  $self->{color}->{'default'} = -1;

  bless $self, $class;
  
  # init Curses
  # my ($maxrow, $maxcol);
  use POSIX ();
  my $loc = POSIX::setlocale(&POSIX::LC_ALL, "");

  initscr();
  # getmaxyx($maxrow, $maxcol);
  $self->{maxrow} = $LINES;
  $self->{maxcol} = $COLS;
   
  #使用颜色
  if ($self->{CONFIG}->{color}){
    if (has_colors()) {
      my $ti = Term::Terminfo->new;
      if ($ti->getnum('colors') == 256 ) {
        start_color();
        use_default_colors();
        $self->{hasColors} = 1;
      }
    }
  }else {
    $self->{hasColors} = 0;
  }

  #没有回显
  noecho();
  #raw();
  cbreak();
  #使用\n作为回车键
  nonl();
  #不同的输出格式
  # init_pair(0, -1, -1);
  if ($self->{hasColors}) {
    #根据颜色配置信息, 使用配置的颜色名, 调用getColorID取出颜色标识, 并组成颜色对
    #颜色对20以前, 缺省保留, 20以后用于对应preview中的颜色转义配置
    init_pair(1, $self->getColorID($self->{CONFIG}->{colorFg}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(2, $self->getColorID($self->{CONFIG}->{colorFgPlus}), $self->getColorID($self->{CONFIG}->{colorBgPlus}));
    init_pair(3, $self->getColorID($self->{CONFIG}->{colorHl}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(4, $self->getColorID($self->{CONFIG}->{colorHlPlus}), $self->getColorID($self->{CONFIG}->{colorBgPlus}));
    init_pair(5, $self->getColorID($self->{CONFIG}->{colorMarker}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(6, $self->getColorID($self->{CONFIG}->{colorMarker}), $self->getColorID($self->{CONFIG}->{colorBgPlus}));
    init_pair(7, $self->getColorID($self->{CONFIG}->{colorPointer}), $self->getColorID($self->{CONFIG}->{colorGutter}));
    init_pair(8, $self->getColorID($self->{CONFIG}->{colorInfo}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(9, $self->getColorID($self->{CONFIG}->{colorPrompt}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(10, $self->getColorID($self->{CONFIG}->{colorHeader}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(11, $self->getColorID($self->{CONFIG}->{colorQuery}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(12, $self->getColorID($self->{CONFIG}->{colorDisabled}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(13, $self->getColorID($self->{CONFIG}->{colorSpinner}), $self->getColorID($self->{CONFIG}->{colorBg}));
    init_pair(14, $self->getColorID($self->{CONFIG}->{colorFgPreview}), $self->getColorID($self->{CONFIG}->{colorBgPreview}));
  }
  #开启所有鼠标事件侦听
  if ($self->{CONFIG}->{mouse}) {
    my $old;
    mousemask(ALL_MOUSE_EVENTS, $old);
  }
  return $self;
}

#函数initPair, Curses库中init_pair方法的封装, 用于生成显示对
#参数
#$no, 显示对id
#$fg, 前景颜色标识
#$bg, 后景颜色标识
sub initPair{
  my ($self, $no, $fg, $bg) = @_;
  init_pair($no, $fg, $bg) if $self->{hasColors} == 1;
}

# my $size_changed = 0;
# $SIG{'WINCH'} = sub { $size_changed = 1;};

#检查屏幕尺寸是否发生变化
sub isResized {
  my ($self) = @_;

  refresh($self->{win});
  if (($self->{maxrow} == $LINES) && ($self->{maxcol} == $COLS)){
    return 0;
  }else{
    return 1;
  }
}

#返回是否具备显示颜色能力
sub hasColors {
  my ($self) = @_;
  return $self->{hasColors};
}

#getColorID, 将配置的颜色名转换为ANSI256的颜色标识
#颜色名包括4类, 一是16种预定义颜色, 二是灰度颜色名, 用grey\d+描述
#三是红绿兰各6级的rgb表示, 使用rgb\d\d\d描述, 每种颜色用0~5的数字表示, 一共216中颜色
#四rgb24位颜色名, 使用r\d+g\d+b\d+描述, 处理中将其线性缩放为第三种方式转换为ANSI256颜色
sub getColorID {
  my ($self, $colorName) = @_;
  my $id;

  #如果缓存中包含, 则直接返回缓存颜色
  return $self->{color}->{$colorName} if (exists $self->{color}->{$colorName});

  if ($colorName =~ /rgb(\d+)/){
    #调用Term::ANSIColor中的color函数转化为esc转义序列, 并提取其颜色值
    my $c = color($colorName);
    if ($c =~ /38;5;(\d+)/){
      $id = int($1);
    }
  } elsif ($colorName =~ /r(\d+)g(\d+)b(\d+)/) {
    #转化为6级的rgb名后, 再转化为ANSI256颜色值
    my $r = int(int($1)/256*6);
    my $g = int(int($2)/256*6);
    my $b = int(int($3)/256*6);
    my $c = color("rgb$r$g$b");
    if ($c =~ /38;5;(\d+)/){
      $id = int($1);
    }
  } elsif ($colorName =~ /grey(\d+)/){
    #ANSI中231以后是灰度颜色值
    $id = int($1) + 231;
  } else {
    $id = -1;
  }

  #将颜色值加入缓存
  $self->{color}->{$colorName} = $id if ($id != -1);
  return $id;
}

#返回屏幕宽度
sub getWidth {
  my ($self) = @_;
  return $self->{width};
}

#获得Curses的height信息
sub getHeight {
  my ($self) = @_;
  return $self->{height};
}

#函数getPreviewLines, 获得preview窗口支持的行数
sub getPreviewLines {
  my ($self) = @_;
  my $rvoff = 1;
  $rvoff = $rvoff + 2 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
  return $self->{r_height} - $rvoff - $self->{CONFIG}->{previewHead};
}

#函数getPreviewCols, 获得preview窗口支持的列数
sub getPreviewCols {
  my ($self) = @_;
  my $rhoff = 0;
  $rhoff = 2 + $self->{CONFIG}->{leftPadding} + $self->{CONFIG}->{rightPadding} if ($self->{CONFIG}->{border});
  return $self->{r_width} - $rhoff;
}

#函数initWinParam, 配置主窗口的高, 宽, 左上角x, y坐标
sub initWinParam {
  my ($self) = @_;

  $self->{height} = $self->{maxrow} - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
  $self->{width} = $self->{maxcol} - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
  $self->{startY} = $self->{CONFIG}->{topMargin};
  $self->{startX} = $self->{CONFIG}->{leftMargin};

  if ($self->{CONFIG}->{preview} == 1) {
    if ($self->{CONFIG}->{previewPosition} == 0){ #up
      $self->{height} = $self->{maxrow} - int($self->{maxrow} /2)  - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
      $self->{startY} = int($self->{maxrow}/2) + $self->{CONFIG}->{topMargin};
    }elsif ($self->{CONFIG}->{previewPosition} == 1) { #down
      $self->{height} = int($self->{maxrow} /2)  - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
    }elsif ($self->{CONFIG}->{previewPosition} == 2) { #left
      $self->{startX} = int($self->{maxcol}/2) + $self->{CONFIG}->{leftMargin};
      $self->{width} = $self->{maxcol} - int($self->{maxcol} /2)  - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
    }elsif ($self->{CONFIG}->{previewPosition} == 3) { #right
      $self->{width} = int($self->{maxcol} /2)  - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
    }
  }
}

#函数initPreviewWinParam, 配置preview窗口的高, 宽, 左上角x, y坐标
sub initPreviewWinParam {
  my ($self) = @_;
  #
  #preview window
  if ($self->{CONFIG}->{preview} == 1) {
    if ($self->{CONFIG}->{previewPosition} == 0){ #up
      $self->{r_height} = int($self->{maxrow}/2) - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
      $self->{r_width} = $self->{maxcol} - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
      $self->{r_startY} = $self->{CONFIG}->{topMargin};
      $self->{r_startX} = $self->{CONFIG}->{leftMargin};
    }elsif ($self->{CONFIG}->{previewPosition} == 1) { #down
      $self->{r_height} = $self->{maxrow} - int($self->{maxrow}/2) - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
      $self->{r_width} = $self->{maxcol} - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
      $self->{r_startY} = int($self->{maxrow}/2) + $self->{CONFIG}->{topMargin};
      $self->{r_startX} = $self->{CONFIG}->{leftMargin};
    }elsif ($self->{CONFIG}->{previewPosition} == 2) { #left
      $self->{r_height} = $self->{maxrow} - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
      $self->{r_width} = int($self->{maxcol} /2)  - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
      $self->{r_startY} = $self->{CONFIG}->{topMargin};
      $self->{r_startX} =$self->{CONFIG}->{leftMargin};
    }elsif ($self->{CONFIG}->{previewPosition} == 3) { #right
      $self->{r_height} = $self->{maxrow} - $self->{CONFIG}->{topMargin} - $self->{CONFIG}->{bottomMargin};
      $self->{r_width} = $self->{maxcol} - int($self->{maxcol} /2)  - $self->{CONFIG}->{leftMargin} - $self->{CONFIG}->{rightMargin};
      $self->{r_startY} = $self->{CONFIG}->{topMargin};
      $self->{r_startX} = int($self->{maxcol}/2) + $self->{CONFIG}->{leftMargin};
    }
  }
}

#函数initWinOff, 初始化主窗口的显示缓存指针信息
#top, 缓存开始指针, bottom缓存显示结束位置
#left, 左边界, right, 右边界
# sub initWinOff {
#   my ($self) = @_;
#
#   #计算border和padding占据的位置宽度
#   my $voff = 0;
#   $voff = 2 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
#   my $hoff = 0;
#   $hoff = 2 + $self->{CONFIG}->{leftPadding} + $self->{CONFIG}->{rightPadding} if ($self->{CONFIG}->{border});
#
#   #显示信息初始化, 预留info和header高度
#   # my $before = 2;
#   # $before = 3 if ($self->{CONFIG}->{info} == 0);
#   # $before += scalar(@{$self->{CONFIG}->{headerList}}) if (exists $self->{CONFIG}->{headerList});
#   #
#   # $self->{bottom} = 0;
#   # $self->{top} = $self->{height} - $before - $voff;
#   # $self->{left} = 0;
#   # $self->{right} = $self->{width} - 2 - $hoff;
# }

#函数initPreviewOff, 初始化Preview窗口的显示缓存指针信息
#top, 缓存开始指针, bottom缓存显示结束位置
#left, 左边界, right, 右边界
sub initPreviewOff {
  my ($self) = @_;
  #计算border和padding占据的位置宽度
  my $rvoff = 1;
  $rvoff = $rvoff + 2 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding} + $self->{CONFIG}->{previewHead} if ($self->{CONFIG}->{previewBorder});
  my $rhoff = 2;
  $rhoff = $rhoff + 1 + $self->{CONFIG}->{leftPadding} + $self->{CONFIG}->{rightPadding} if ($self->{CONFIG}->{previewBorder});

  #是否滚动特定行
  if ($self->{CONFIG}->{previewScrollOff} >= 0) {
    $self->{r_top} = 0 + $self->{CONFIG}->{previewScrollOff};
  }else {
    $self->{r_top} = $#{$self->{r_buffer}} + $self->{CONFIG}->{previewScrollOff} - $self->{r_height} + $rvoff;
  }
  $self->{r_bottom} =  $self->{r_top} + $self->{r_height} - $rvoff;
  $self->{r_left} = 0;
  $self->{r_right} =  $self->{r_left} + $self->{r_width} - $rhoff;
}

#函数openWin, 创建主窗口和preview窗口
sub openWin {
  my ($self) = @_;

  $self->{maxrow} = $LINES;
  $self->{maxcol} = $COLS;

  #创建主窗口
  $self->initWinParam;
  $self->{win} = newwin($self->{height}, $self->{width}, $self->{startY}, $self->{startX});
  keypad($self->{win}, 1);
  timeout($self->{win}, $self->{CONFIG}->{timeout});
  # $self->initWinOff;

  #创建preview窗口
  if ($self->{CONFIG}->{preview} == 1){
    $self->initPreviewWinParam;
    $self->{r_win} = newwin($self->{r_height}, $self->{r_width}, $self->{r_startY}, $self->{r_startX}) ;
    $self->initPreviewOff;
  }

  return ($self->{height}, $self->{width});
}

#清除屏幕
sub clearWin {
  my ($self) = @_;
  clear($self->{win});
}

#清除Preview屏幕
sub clearPreviewWin{
  my ($self) = @_;
  clear($self->{r_win}) if defined $self->{r_win};
}
#关闭Curses窗口
sub closeWin {
  my ($self) = @_;
  endwin();
}

#setBuffer函数, 设置buffer变量$self->{buffer}
#参数:
#$buffer, buffer地址引用
sub setBuffer {
  my ($self, $buffer) = @_;
  $self->{buffer} = $buffer;
  #寻找buffer中最长显示字符串的长度
  my $maxLen = 0;
  foreach my $line (@{$self->{buffer}}) {
    my $strLen = 0;
    foreach my $c (0 .. $#{$line}) {
      $strLen += length($line->[$c][0]) if $c>0;
    }
    $maxLen = $strLen if $strLen > $maxLen;
  }
  $self->{maxLen} = $maxLen;
}

#setBuffer函数, 设置preview buffer变量$self->{r_buffer}和$self->{r_headbuf}
#参数:
#$buffer, buffer地址引用
sub setPreviewBuffer {
  my ($self, $buffer) = @_;
  #固定的头部信息
  if ($self->{CONFIG}->{previewHead} > 0){
    my @headBuf = @{$buffer}[0 .. $self->{CONFIG}->{previewHead} - 1];
    $self->{r_headbuf} = \@headBuf;
    #正文信息
    my @buf = @{$buffer}[$self->{CONFIG}->{previewHead} .. $#{$buffer}];
    $self->{r_buffer} = \@buf;
  }else{
    $self->{r_buffer} = $buffer;
  }
  $self->initPreviewOff;
}

#打印正文列表信息
sub print {
  my ($self, $left, $right) = @_;
  #清除窗口
  erase($self->{win});
  # clear($self->{win});

  #计算边界信息
  border($self->{win}, 0, 0, 0, 0, 0, 0, 0, 0) if ($self->{CONFIG}->{border});
  my $vboff = 0;
  $vboff = 1 + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
  my $vtoff = 0;
  $vtoff = $vtoff + 1 + $self->{CONFIG}->{topPadding} if ($self->{CONFIG}->{border});
  my $voff = 0;
  $voff = 2 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
  my $hloff = 0;
  $hloff = 1 + $self->{CONFIG}->{leftPadding} if ($self->{CONFIG}->{border});

  #计算正文前的提示, 信息以及header所占行数
  my $before = 1;
  $before =2 if ($self->{CONFIG}->{info} == 0);
  $before += ($#{$self->{CONFIG}->{headerList}} + 1) if (exists $self->{CONFIG}->{headerList});


  my $buf_out = $self->{buffer};
  #$i为行迭代索引
  foreach my $i (0 .. $#{$buf_out}) {
    my $line = $buf_out->[$i];
    #$c为输出的每行字符串段的列表索引
    #输出的字符索引, 逐字符输出
    my $charIndex = 0;
    #当前光标所处位置
    my $cursor = $hloff;
    #是否超过
    my $ex = 0;
    CLABEL: foreach my $c (0 .. $#{$line}) {
      #将每字符串切分成为字符数组
      my @chars;
      if ($c >0 ){
        @chars = split //, $line->[$c][0];
      } else {
        @chars = split //, substr($line->[$c][0], 0, $right - $left);
      }

      #临时变量, 用于储存cusese模块getyx的行信息
      my $t;
      foreach my $char (@chars) {
        #若不在left和right范围内, 不做处理
        if ($i>=$before && $c>0) {
          $charIndex ++;
          next if ($charIndex <= $left);
        }

        #若带有格式
        if($line->[$c][1]!=0 && $self->{hasColors}) {
          attron($self->{win}, A_BOLD);
          attron($self->{win}, COLOR_PAIR($line->[$c][1]));
        }

        if ($self->{CONFIG}->{layout} == 0){
          addstring($self->{win}, $self->{height}-1-$i-$vboff, $cursor, $char);
        }elsif($self->{CONFIG}->{layout} == 1){ #reverse
          addstring($self->{win}, 0+$i+$vtoff, $cursor, $char);
        }elsif($self->{CONFIG}->{layout} == 2){ #reverse list
          my $b = min($self->{height}, scalar(@{$self->{buffer}})+$voff);
          addstring($self->{win}, $b-1-$i-$vboff, $cursor, $char);
        }
        #调取当前字符输出后光标所处的位置, 由于存在宽字符不确定占用屏幕宽度的问题
        #逐字符输出后, 使用getyx获取当前光标位置
        getyx($self->{win}, $t, $cursor);
        last CLABEL if ($ex == 1);
        
        #若带有格式
        if($line->[$c][1]!=0 && $self->{hasColors}) {
          attroff($self->{win}, A_BOLD);
          attroff($self->{win}, COLOR_PAIR($line->[$c][1]));
        }

        if ($i>=$before && $c>0){
            # 对于一些带有中文的行, 留出缓冲区域2, 所以从+1变为-1
            # $ex = 1 if ($cursor >= $right - $left + 1 + $hloff);
            $ex = 1 if ($cursor >= $right - $left - 1 + $hloff);
        }
      }
    }
  }
  refresh($self->{win});
}

#函数setPreviewOff, 前滚或后滚preview窗口
#参数
#$topDiff, 设置top指针的位移, 大于0代表前向滚动, 小于0代表后向滚动
sub setPreviewOff {
  my ($self, $topDiff) = @_;

  my $rvoff = 1;
  $rvoff = $rvoff + 2 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding} + $self->{CONFIG}->{previewHead} if ($self->{CONFIG}->{previewBorder});
  
  if ($topDiff>0) { #前向滚动
    $self->{r_bottom} += $topDiff;
     if ($self->{r_bottom} > $#{$self->{r_buffer}}) {
       #是否循环滚动
       if ($self->{CONFIG}->{previewCyclic}){
          $self->{r_bottom} = 0 + $self->{r_height} - $rvoff;
       }else{
        $self->{r_bottom} = $#{$self->{r_buffer}};
       }
     }
    $self->{r_top} = $self->{r_bottom} - $self->{r_height} + $rvoff;
    $self->{r_top} = 0 if $self->{r_top} < 0;
  }else{#后向滚动
    $self->{r_top} += $topDiff;
    if ($self->{r_top} < 0) {
       if ($self->{CONFIG}->{previewCyclic}){
          $self->{r_top} = $#{$self->{r_buffer}} - $self->{r_height} + $rvoff;
       }else{
        $self->{r_top} = 0;
       }
    }
    $self->{r_bottom} =  $self->{r_top} + $self->{r_height} - $rvoff;
    $self->{r_bottom} = $#{$self->{r_buffer}} if $self->{r_bottom} > $#{$self->{r_buffer}};
  }
  #调用previewPrint函数刷新显示
  $self->previewPrint;
}

#函数setPreviewHead, 设置到preview窗口的头部
sub setPreviewHead {
  my ($self) = @_;

  my $rvoff = 3 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding};
  # my $rhoff = 3 + $self->{CONFIG}->{leftPadding} + $self->{CONFIG}->{rightPadding};
  $self->{r_top} = 0;
  $self->{r_bottom} =  $self->{r_top} + $self->{r_height} - $rvoff;
  $self->previewPrint;
}

#函数setPreviewTail, 设置到preview窗口的尾部
sub setPreviewTail {
  my ($self) = @_;

  my $rvoff = 3 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding};
  # my $rhoff = 3 + $self->{CONFIG}->{leftPadding} + $self->{CONFIG}->{rightPadding};
  $self->{r_bottom} = $#{$self->{r_buffer}};
  $self->{r_top} = $self->{r_bottom} - $self->{r_height} + $rvoff;
  $self->{r_top} =0 if $self->{r_top} < 0;
  $self->previewPrint;
}

#函数previewPrint, 显示preview窗口信息, 并刷新
sub previewPrint {
  my ($self) = @_;
  #清除窗口
  erase($self->{r_win});
  # clear($self->{win});

  #绘制边界
  border($self->{r_win}, 0, 0, 0, 0, 0, 0, 0, 0) if ($self->{CONFIG}->{previewBorder});
  #预留padding空间
  my $vboff = 0;
  $vboff = 1 + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{previewBorder});
  my $hloff = 0;
  $hloff = 1 + $self->{CONFIG}->{leftPadding} if ($self->{CONFIG}->{previewBorder});

  #取出头部打印信息
  my @buf;
  push @buf, $_ foreach (@{$self->{r_headbuf}});
  #取出正文打印信息
  foreach my $row ($self->{r_top} .. &min($#{$self->{r_buffer}}, $self->{r_bottom})) {
    push @buf, $self->{r_buffer}->[$row];
  }
  
  #$row为行迭代索引
  my $row = 0;
  foreach my $line (@buf) {
    #itemIndex为每行的分段索引, 每段是不同的显示颜色属性设置
    my $itemIndex = 0;
    #cursor是显示当前的列位置信息
    my $cursor = $hloff;
    ITEMLABEL: for my $itemIndex (0 .. $#{$line}){
      #获得每段显示字符串的字符列表
      my @chars = split //, $line->[$itemIndex][0];
      #临时变量
      my $t;
      foreach my $char (@chars) {
        #若带有格式
        if($line->[$itemIndex][1]!=0 && $self->{hasColors}) {
          attron($self->{r_win}, A_BOLD && $self->{hasColors});
          attron($self->{r_win}, COLOR_PAIR($line->[$itemIndex][1]));
        }

        addstring($self->{r_win}, $row + $vboff, $cursor, $char);
        getyx($self->{r_win}, $t, $cursor);
      
        #若带有格式
        if($line->[$itemIndex][1]!=0 && $self->{hasColors}) {
          attroff($self->{r_win}, A_BOLD);
          attroff($self->{r_win}, COLOR_PAIR($line->[$itemIndex][1]));
        }

        #是否超出右部边界
        if ($cursor >= $self->{r_right} - $self->{r_left} + $hloff + 1) {
          #是否绕回或阶段
          if ($self->{CONFIG}->{previewWrap}){
            $cursor = $hloff;
            $row ++;
            #是否超出底部边界
            last if ($row> $self->{r_bottom} + $self->{CONFIG}->{previewHead} - $self->{r_top});
          } else {
            last ITEMLABEL;
          }
        }
      }
    }
    $row ++;
    last if ($row> $self->{r_bottom} + $self->{CONFIG}->{previewHead} - $self->{r_top});
  }
  refresh($self->{r_win});
}


sub resetCursor {
  my ($self) = @_;
  
  my $cursorInfo = $self->{cursorInfo};
  my $row = $cursorInfo->{row};
  my $col = $cursorInfo->{col};

  move($self->{win}, $row, $col);
  refresh($self->{win});
}

#函数setCursor, 设置输入的光标位置
#参数
#$cursor, 光标的列位置
sub printQuery {
  my ($self, $inputRow, $cursor, $pattArr, $spinnerChar) = @_;

  #设置缓存
  my $cursorInfo = $self->{cursorInfo};

  $cursorInfo->{cursor} = $cursor;
  if (defined $pattArr) {
    $cursorInfo->{pattArr} = $pattArr;
  }else {
    if (exists $cursorInfo->{pattArr}) {
      $pattArr = $cursorInfo->{pattArr};
    }
  }

  #判读prompt行的输出位置
  my $voff = 0;
  $voff = 2 + $self->{CONFIG}->{bottomPadding} + $self->{CONFIG}->{topPadding} if ($self->{CONFIG}->{border});
  my $vtoff = 0;
  $vtoff = $vtoff + 1 + $self->{CONFIG}->{topPadding} if ($self->{CONFIG}->{border});
  my $vboff = 0;
  $vboff = $vboff + 1 + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});

  #从buffer信息中挑出input query的行
  my $inputLine = $self->{buffer}->[$inputRow];
  #确定输入的行位置
  my $row;
  if ($self->{CONFIG}->{layout} == 0) {
    $row = $self->{height} - $inputRow - $vboff - 1;
  }elsif ($self->{CONFIG}->{layout} == 1) {
    $row = $inputRow + $vtoff;
  }elsif($self->{CONFIG}->{layout} == 2){ #reverse list
    my $b = min($self->{height}, scalar(@{$self->{buffer}})+$voff);
    $row = $b - $vboff - $inputRow - 1;
  }

  #打印prompt和query信息
  my $col = 0;
  $col = $col + 1 + $self->{CONFIG}->{leftPadding} if ($self->{CONFIG}->{border});

  #重新打印query信息
  my $screenCursor;
  foreach my $i (0 .. $#{$inputLine}) {
    if($inputLine->[$i][1]!=0 && $self->{hasColors}) {
      attron($self->{win}, A_BOLD);
      attron($self->{win}, COLOR_PAIR($inputLine->[$i][1]));
    }

    if ($i == 1) {#i=0是prompt信息, #i=1是query信息
      #对query行, 使用pattArr的数据结构重新打印
      my $pattern = $inputLine->[$i][0];
      my @leftArr = @{$pattArr}[0 .. $cursor-1];
      my @rightArr = @{$pattArr}[$cursor .. $#{$pattArr}];
      my $left = reduce {$a . $b} @leftArr;
      my $right = reduce {$a . $b} @rightArr;

      addstring($self->{win}, $row, $col, $left);
      my $t;
      getyx($self->{win}, $t, $col);
      $screenCursor = $col;
      addstring($self->{win}, $row, $col, $right);
    }else{
      addstring($self->{win}, $row, $col, $inputLine->[$i][0]);
      my $t;
      getyx($self->{win}, $t, $col);
    }

    if($inputLine->[$i][1]!=0 && $self->{hasColors}) {
      attroff($self->{win}, A_BOLD);
      attroff($self->{win}, COLOR_PAIR($inputLine->[$i][1]));
    }
  }

  #设置光标和光标缓存信息
  move($self->{win}, $row, $screenCursor);
  $cursorInfo->{row} = $row;
  $cursorInfo->{col} = $screenCursor;
  refresh($self->{win});
}

#函数showJumpLabel, 在光标列显示跳转的label信息
sub showJumpLabel {
  my ($self) = @_;

  my $voff = 0;
  $voff = 2 + $self->{CONFIG}->{bottomPadding} + $self->{CONFIG}->{topPadding} if ($self->{CONFIG}->{border});
  my $vboff = 0;
  $vboff = 1 + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
  my $vtoff = 0;
  $vtoff = $vtoff + 1 + $self->{CONFIG}->{topPadding} if ($self->{CONFIG}->{border});
  my $hloff = 0;
  $hloff = 1 + $self->{CONFIG}->{leftPadding} if ($self->{CONFIG}->{border});

  my $before = 1;
  $before =2 if ($self->{CONFIG}->{info} == 0);
  $before += ($#{$self->{CONFIG}->{headerList}} + 1) if (exists $self->{CONFIG}->{headerList});

  #字符列表
  my @label = @{$self->{jumpLabels}}[0 .. &min($self->{height},$#{$self->{buffer}}) - $before];
  #显示
  foreach my $d (0 .. $#label) {
    if ($self->{hasColors}){
      attron($self->{win}, A_BOLD);
      attron($self->{win}, COLOR_PAIR(7));
    }
    if ($self->{CONFIG}->{layout} == 0){
      addstring($self->{win}, $self->{height}- $before - 1 -$d-$vboff, $hloff, $label[$d]);
    }elsif ($self->{CONFIG}->{layout} == 1) {
      addstring($self->{win}, 0+$before+$d+$vtoff, $hloff, $label[$d]);
    }elsif($self->{CONFIG}->{layout} == 2){ #reverse list
      # my $b = min($self->{height}, $#{$self->{buffer}}+1);
      my $b = min($self->{height}, scalar(@{$self->{buffer}})+$voff);
      addstring($self->{win}, $b-$before-1-$d-$vboff, $hloff, $label[$d]);
    }
    if ($self->{hasColors}) {
      attroff($self->{win}, A_BOLD);
      attroff($self->{win}, COLOR_PAIR(7));
    }
  }
  $self->resetCursor;
  refresh($self->{win});
  #设置下次输入的是跳转信息
  $self->{inJump} = 1;
}

#函数showJumpLabelAccept, 在光标列显示跳转的label信息
sub showJumpLabelAccept {
  my ($self) = @_;

  $self->showJumpLabel;
  #设置下次输入的是跳转信息
  $self->{inJumpAccept} = 1;
}

sub printPointer {
  my ($self, $before, $loc, $left, $right) = @_;
  
  my $vboff = 0;
  $vboff = 1 + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
  my $vtoff = 0;
  $vtoff = $vtoff + 1 + $self->{CONFIG}->{topPadding} if ($self->{CONFIG}->{border});
  my $voff = 0;
  $voff = 2 + $self->{CONFIG}->{topPadding} + $self->{CONFIG}->{bottomPadding} if ($self->{CONFIG}->{border});
  my $hloff = 0;
  $hloff = 1 + $self->{CONFIG}->{leftPadding} if ($self->{CONFIG}->{border});

  #计算bottom和top之间的行
  return if ($#{$self->{buffer}} <= $before - 1);
  
  $self->{loc} = $loc;
  $self->{left} = $left;
  $self->{right} = $right;
 
  #当前指针所指向的行, 
  # my $line = $self->{buffer}->[$ptr  + $before];
  my $line = $self->{buffer}->[$loc + $before];

  my $charIndex = 0;
  my $cursor = $hloff;
  my $ex = 0;
  POINTLABEL: foreach my $c (0 .. $#{$line}) {
    my @chars = split //, $line->[$c][0];
    my $t;
    foreach my $char (@chars) {
      if ($c > 0){ #仅仅显示left和right之间的字符
        $charIndex ++;
        next if ($charIndex <= $left);
      }
      #
      #当前行显示为高亮
      if ($self->{hasColors}){
        attron($self->{win}, A_BOLD);
        attron($self->{win}, COLOR_PAIR($line->[$c][1]+1));
      }
      if ($self->{CONFIG}->{layout} == 0){
        addstring($self->{win}, $self->{height}-$before-1-$loc-$vboff, $cursor, $char);
      } elsif($self->{CONFIG}->{layout} == 1) {
        addstring($self->{win}, 0+$before+$loc+$vtoff, $cursor, $char);
      }elsif($self->{CONFIG}->{layout} == 2){ #reverse list
        my $b = min($self->{height}, scalar(@{$self->{buffer}})+$voff);
        addstring($self->{win}, $b-$before-1-$loc-$vboff, $cursor, $char);
      }
      getyx($self->{win}, $t, $cursor);
     
      #当前行显示为高亮
      if ($self->{hasColors}){
        attroff($self->{win}, A_BOLD);
        attroff($self->{win}, COLOR_PAIR($line->[$c][1]+1));
      }
      last POINTLABEL if $ex == 1;

      if($c > 0) {
          # 对于一些带有中文的行, 留出缓冲区域2, 所以从+1变为-1
          # $ex = 1 if ($cursor >= $right - $left  + 1 + $hloff);
          $ex = 1 if ($cursor >= $right - $left - 1 + $hloff);
      }
    }
  }

  #显示当前行指示标记>
  if ($self->{hasColors}){
    attron($self->{win}, A_BOLD);
    attron($self->{win}, COLOR_PAIR(7));
  }
  if ($self->{CONFIG}->{layout} == 0){
    addstring($self->{win}, $self->{height}-$before-1-$loc-$vboff, $hloff, $self->{CONFIG}->{pointer});
  } elsif($self->{CONFIG}->{layout} == 1) {
    addstring($self->{win}, 0+$before+$loc+$vtoff, $hloff, $self->{CONFIG}->{pointer});
  }elsif($self->{CONFIG}->{layout} == 2){ #reverse list
    my $b = min($self->{height}, scalar(@{$self->{buffer}})+$voff);
    addstring($self->{win}, $b-$before-1-$loc-$vboff, $hloff, $self->{CONFIG}->{pointer});
  }
  if($self->{hasColors}){
    attroff($self->{win}, A_BOLD);
    attroff($self->{win}, COLOR_PAIR(7));
  }
  refresh($self->{win});

}

#getc函数, 获取键盘输入
sub getc {
  my ($self) = @_;

  my $before = 1;
  $before =2 if ($self->{CONFIG}->{info} == 0);
  $before += scalar(@{$self->{CONFIG}->{headerList}}) if (exists $self->{CONFIG}->{headerList});

  # my ($ch, $key) = getchar($self->{win});
  my $ch = getch($self->{win});

  if ($self->isResized() == 1) {
    return (undef, $self->{COMMAND_RESIZE});
  }

  my $key;
  $key = keyname($ch) if $ch > 127;
  # $key = keyname($ch) if ord($ch) > 127;
  # return (undef, $self->{COMMAND_IDLE}) if (ord($ch) > 127 && (not defined $key));
  
  #Jump...
  if ($self->{inJump} == 1) { #是否是跳转的输入信息
    # my $clickrow = List::Util::first {$self->{jumpLabels}->[$_] eq $ch} (0..$#{$self->{jumpLabels}});
    my $clickrow = firstidx {$_ eq $ch} @{$self->{jumpLabels}};
    return (undef, $self->{COMMAND_IDLE}) if $clickrow == -1;

    $self->{inJump} = 0;
    if ($self->{inJumpAccept} == 1){
      $self->{inJumpAccept} == 0;
      return (undef, $self->{COMMAND_CLICKED_ACCEPT}, $clickrow);
    }else{
      return (undef, $self->{COMMAND_CLICKED}, $clickrow);
    }
  }
  
  #COMMAND_CHECK
  return (undef, $self->{COMMAND_CHECK}) if ($ch == -1);

  #功能键
  if (defined $key) {
    # if ($key == KEY_MOUSE){ #鼠标输入
    if ($key eq 'KEY_MOUSE'){ #鼠标输入
      my $event = pack("iiiil", 11,12,13,0);
      my $ok = getmouse($event);
      #$event是c语言的一个结构, 具体参见Curses的头文件
      #使用unpack函数解包
      my @l = unpack("iiiil", $event);
      my $mstate = $l[4];
      #$l[2]是鼠标事件的行位置信息
      my $clickrow;
      if ($self->{CONFIG}->{layout} == 0){
        $clickrow = $self->{height} - $before - 1 - $l[2];
      }elsif ($self->{CONFIG}->{layout} == 1) {
        $clickrow = 0 + $before + $l[2];
      }elsif($self->{CONFIG}->{layout} == 2){ #reverse list
        my $b = min($self->{height}, $#{$self->{buffer}}+1);
        $clickrow = $b - $before - 1 - $l[2];
      }
      return (undef, $self->{COMMAND_CLICKED}, $clickrow) if (($mstate & BUTTON1_CLICKED) != 0);
      return (undef, $self->{COMMAND_EXIT}) if (($mstate & BUTTON1_DOUBLE_CLICKED) != 0);
      # addstring(8, 0, "BUTTON1_PRESSED") if (($mstate & BUTTON1_PRESSED)!=0);
      # addstring(9, 0, "BUTTON1_RELEASED") if (($mstate & BUTTON1_RELEASED)!=0);
      # addstring(10, 0, "BUTTON1_CLICKED") if (($mstate & BUTTON1_CLICKED)!=0);
      # addstring(11, 0, "BUTTON1_DOUBLE_CLICKED") if (($mstate & BUTTON1_DOUBLE_CLICKED)!=0);
      # addstring(12, 0, "BUTTON1_TRIPLE_CLICKED") if (($mstate & BUTTON1_TRIPLE_CLICKED)!=0);
      # addstring(13, 0, "BUTTON2_PRESSED") if (($mstate & BUTTON2_PRESSED)!=0);
      # addstring(14, 0, "BUTTON2_RELEASED") if (($mstate & BUTTON2_RELEASED)!=0);
      # addstring(15, 0, "BUTTON2_CLICKED") if (($mstate & BUTTON2_CLICKED)!=0);
      # addstring(16, 0, "BUTTON2_DOUBLE_CLICKED") if (($mstate & BUTTON2_DOUBLE_CLICKED)!=0);
      # addstring(17, 0, "BUTTON2_TRIPLE_CLICKED") if (($mstate & BUTTON2_TRIPLE_CLICKED)!=0);
      # addstring(18, 0, "BUTTON3_PRESSED") if (($mstate & BUTTON3_PRESSED)!=0);
      # addstring(19, 0, "BUTTON3_RELEASED") if (($mstate & BUTTON3_RELEASED)!=0);
      # addstring(20, 0, "BUTTON3_CLICKED") if (($mstate & BUTTON3_CLICKED)!=0);
      # addstring(21, 0, "BUTTON3_DOUBLE_CLICKED") if (($mstate & BUTTON3_DOUBLE_CLICKED)!=0);
      # addstring(22, 0, "BUTTON3_TRIPLE_CLICKED") if (($mstate & BUTTON3_TRIPLE_CLICKED)!=0);
      # addstring(23, 0, "BUTTON4_PRESSED") if (($mstate & BUTTON4_PRESSED)!=0);
      # addstring(24, 0, "BUTTON4_RELEASED") if (($mstate & BUTTON4_RELEASED)!=0);
      # addstring(25, 0, "BUTTON4_CLICKED") if (($mstate & BUTTON4_CLICKED)!=0);
      # addstring(26, 0, "BUTTON4_DOUBLE_CLICKED") if (($mstate & BUTTON4_DOUBLE_CLICKED)!=0);
      # addstring(27, 0, "BUTTON4_TRIPLE_CLICKED") if (($mstate & BUTTON4_TRIPLE_CLICKED)!=0);
      # addstring(28, 0, "BUTTON_SHIFT") if (($mstate & BUTTON_SHIFT)!=0);
      # addstring(29, 0, "BUTTON_CTRL") if (($mstate & BUTTON_CTRL)!=0);
      # addstring(30, 0, "BUTTON_ALT") if (($mstate & BUTTON_ALT)!=0);
      # addstring(31, 0, "ALL_MOUSE_EVENTS") if (($mstate & ALL_MOUSE_EVENTS)!=0);
      # addstring(32, 0, "REPORT_MOUSE_POSITION") if (($mstate & REPORT_MOUSE_POSITION)!=0);
    }else{ #键盘功能键
      if (exists ($self->{map}->{$key})){
        return ($ch, $self->{$self->{map}->{$key}})
      }
    }
  }else{ #正常输入
    #转换成为ASCII码
    my $asc = ord($ch);

    #在空格和删除键之间的按键
    if (exists ($self->{map}->{$ASC[$asc]}) ) { #是否被映射为action
      return (undef, $self->{$self->{map}->{$ASC[$asc]}});
    }else{ #作为正常输入
      return ($ch, undef);
    }
  }

}

#test
# my $tui = new TUI();
# $tui->openWin();
# while(1) {
#   my ($ch, $key) = $tui->getc();
#
#   my @buf;
#   $buf[0][0] = ["char:".$ch, 0];
#   my $asc = ord($ch);
#   $buf[1][0] = ["Asc:".$asc, 0];
#   $buf[2][0] = ["Key:".KEY_BTAB, 0];
#   $tui->setBuffer(\@buf);
#   $tui->print();
#
# }
# $tui->closeWin();

#package return
1;


