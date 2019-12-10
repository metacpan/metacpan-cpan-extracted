package Net::Info;

$VERSION = '0.104';

use strict;
use Exporter;
use Carp;
use IO::File;
use Text::Tabs;
use Scalar::Util qw( weaken );

@ISA       = qw( Exporter );
@EXPORT    = qw( readconfig );
@EXPORT_OK = qw( readconfig stringconfig $minus_one_indent_rx );

use overload
  'bool'     => \&defined,
  '""'       => \&text,
  'fallback' => 1;

my $io_string;
our $allow_minus_one_indent = qr/class /;
our $allow_plus_one_indent  = qr/service-policy |quit$/;
our $bad_indent_policy      = 'DIE';


BEGIN {
  eval " use IO::String ";
  $io_string = $@ ? 0 : 1;
}

my $debug_get     = 0;
my $debug_mget    = 0;
my $debug_set     = 0;
my $debug_context = 0;
my $debug_text    = 0;
my $ddata
  = $debug_get
  || $debug_mget
  || $debug_set
  || $debug_context
  || $debug_text
  || 0;    # add debugging data to data structures

my $spec      = qr{^_};
my $text      = "_text";
my $subs      = "_subs";
my $next      = "_next";
my $cntx      = "_cntx";
my $word      = "_word";
my $seqn      = "_seqn";
my $dupl      = "_dupl";
my $debg      = "_debg";
my $bloc      = "_bloc";
my $UNDEFDESC = "! undefined\n";
my $undef     = bless {$debg => $UNDEFDESC, $text => ''}, __PACKAGE__;
my $dseq      = "O0000000";
our $nonext;

my ($fh, $line);

sub stringconfig {
  croak 'IO::String must installed when use "stringconfig"'
    . ' install it or use "readconfig" instead.'
    unless $io_string;
  readconfig(IO::String->new(join("\n", @_)));
}

sub readconfig {
  my ($file) = @_;
  $fh   = ref($file) ? $file : IO::File->new($file, "r");
  $line = <$fh>;
  return rc1(0, 'aaaa', $undef, "! whole enchalada\n");
}

#调用方案：rc1(缩进，序列号，父节点，描述信息)
sub rc1 {
  my ($indent, $seq, $parent, $desc) = @_;
  my $config = bless {$bloc => 1}, __PACKAGE__;
  $config->{$debg} = "BLOCK:$dseq:$desc" if $ddata;

  $config->{$cntx} = $parent;
  weaken $config->{$cntx};

  $dseq++;
  my ($last, $prev, $ciscobug);

#借助<>方法读取IO::File对象依次取出每行配置文件，通过缩进构建配置树结构
  for (; $line; $prev = $line, $line = <$fh>) {
    $_ = $line;
    s/^( *)//;      #去除前导空白字符
    s/^(no +)//;    #改写no打头的命令行
    my $in = length($1);

    #情况1：新行向右缩进需要判断是否含有子节点
    if ($in > $indent) {

      #如果存在上下文，则将新行视为上一配置的子节点；
      if ($last) {
        $last->{$subs} = rc1($in, "$last->{$seqn}aaa", $last, $line);
        undef $last;      #重置$last变量
        redo if $line;    #代码跳转到循环体下第一条代码
      }
      else {
        #正常缩进不会出现此情况，捕捉异常情景并排除
        if ( $indent + 1 == $in
          && $allow_plus_one_indent
          && $line =~ /^\s*$allow_plus_one_indent/)
        {
          $indent = $indent + 1;
          redo;
        }

#如果新行不存在父节点，改行向右缩进且先前命令缩进不为0，设置标记
        if ($indent != 0 || ($prev ne "!\n" && $prev !~ /^!.*<removed>$/)) {
          if ($bad_indent_policy eq 'IGNORE') {

            # okay then
          }
          elsif ($bad_indent_policy eq 'WARN') {
            warn "Unexpected indentation change <$.:$_>";
          }
          else {
            confess "Unexpected indentation change <$.:$_>";
          }
        }
        $ciscobug = 1;
        $indent   = $in
          ;  #改写父节点缩进值为子节点缩进（父子缩进相同）
      }
    }

#情况2：新行向左缩进，需要判断代码块是否结束即子节点跳出父节点
    elsif ($in < $indent) {

#子节点缩进小于父节点缩进，且命中BUG标记（父子缩进相同）
      if ($ciscobug && $in == 0) {
        $indent = 0;
      }

      #父节点缩进深度大于子节点（正常逻辑不存在），代表
      elsif ($last
        && $indent - 1 == $in
        && $allow_minus_one_indent
        && $line =~ /^\s*$allow_minus_one_indent/)
      {
        confess unless $last->{$seqn};    #检查是否唯一
        $last->{$subs} = rc1($in, "$last->{$seqn}aaa", $last, $line)
          ;                               #构建子节点的配置子类
        undef $last;
        redo if $line;
      }

      #其他情况则返回当前代码块
      else {
        return $config;
      }
    }
    next if /^$/;                         #跳过空行
    next if /^\s*!/;                      #跳过^!配置行（思科）
    next if /^\s*#/;                      #跳过^#配置行（华为）
    my $context = $config
      ;    #深度复制，对$context进行数据操作即对$config操作
    my (@x) = split;    #将一行命令行分解为数组对象

#判断先前是否解析过子类，如已解析则弹出该元素（深度优先）
    while (@x && ref $context->{$x[0]}) {
      $context = $context->{$x[0]};
      shift @x;
    }

    #判断数组是否为空，如果为空则代表重复配置项
    #一般ACL可能会存在这种情况
    if (!@x) {
      $context->{$dupl} = [] unless $context->{$dupl};
      my $n = bless {
        $ddata ? ($debg => "$dseq:DUP:$line", $word => $context->{$word},) : (),
        },
        __PACKAGE__;
      $dseq++;

      push(@{$context->{$dupl}}, $n);
      $context = $n;
    }
    elsif (defined $context->{$x[0]}) {
      carp "already $.: '$x[0]' $line";
    }

    #数组不为空为构建Net::Info对象
    while (@x) {
      my $x = shift @x;
      confess unless defined $x;
      confess unless defined $dseq;
      $line = "" unless defined $line;

      $context = $context->{$x}
        = bless {$ddata ? ($debg => "$dseq:$x:$line", $word => $x,) : (),},
        __PACKAGE__;
      $dseq++;
    }

    $context->{$seqn} = $seq++;
    $context->{$text} = $line;
    confess if $context->{$cntx};

    $context->{$cntx} = $config;
    weaken $context->{$cntx};

    #父节点
    if ($last) {
      $last->{$next} = $context;
      weaken $last->{$next};
    }

    #根节点（先有根节点）
    else {
      $config->{$next} = $context;
      weaken $config->{$next};
    }

    #将当前上下文设置赋值给父节点
    $last = $context;

    if ($line && ($line =~ /(\^C)/ && $line !~ /\^C.*\^C/)
      || ($line =~ /banner [a-z\-]+ ((?!\^C).+)/))
    {
      #
      # big special case for banners 'cause they don't follow
      # normal indenting rules
      #
      die unless defined $1;
      my $sep = qr/\Q$1\E/;
      my $sub = $last->{$subs} = bless {$bloc => 1}, __PACKAGE__;

      $sub->{$cntx} = $last;
      weaken $sub->{$cntx};

      my $subnull = $sub->{''} = bless {$bloc => 1, $dupl => []}, __PACKAGE__;
      $subnull->{$cntx} = $sub;
      weaken $subnull->{$cntx};

      #递归循环，循环体内有跳出逻辑
      for (;;) {
        $line = <$fh>;
        last unless $line;    #如果解析完毕则跳出循环体

        my $l = bless {$ddata ? ($debg => "$dseq:DUP:$line") : (),},
          __PACKAGE__;
        $dseq++;
        $l->{$seqn} = $seq++;
        $l->{$text} = $line;

        $l->{$cntx} = $subnull;
        weaken($l->{$cntx});

        push(@{$subnull->{$dupl}}, $l);
        last if $line =~ /$sep[\r]?$/;
      }

      #如果未解析到成对的代码块告警
      warn "parse probably failed" unless $line && $line =~ /$sep[\r]?$/;
    }
  }
  return $config;
}

sub block   { $_[0]->{$bloc} }
sub seqn    { $_[0]->{$seqn} || $_[0]->endpt->{$seqn} || confess }
sub subs    { $_[0]->{$subs} || $_[0]->zoom->{$subs} || $undef }
sub next    { $_[0]->{$next} || $_[0]->zoom->{$next} || $undef }
sub defined { $_[0]->{$debg} ? $_[0]->{$debg} ne $UNDEFDESC : 1 }

sub destroy {
  warn "Net::Info::destroy is deprecated";
}

#优先返回text对象
sub single {
  my $self = shift;
  return $self if defined $self->{$text};
  my @kids = grep { !/$spec/o } keys %{$self};
  return undef if @kids > 1;                    #kids大于1
  return $self unless @kids;                    #kids等于0
  return $self->{$kids[0]}->single || $self;    #根节点对象
}

#获取当前keys对象，返回数组
sub kids {
  my $self = shift;
  return $self unless $self;
  my @kids = $self->sortit(grep { !/$spec/o } keys %{$self});
  return $self unless @kids;
  return (map { $self->{$_} } @kids);
}

#快速检索
sub zoom {
  my $self = shift;
  return $self if defined $self->{$text};
  my @kids = $self->sortit(grep { !/$spec/o } keys %{$self});
  return $self if @kids > 1;         #kids大于1（父节点）
  return $self unless @kids;         #kids等于0
  return $self->{$kids[0]}->zoom;    #根节点对象（根节点）
}

#最里面的子节点
sub endpt {
  my $self = shift;
  return $self unless $self;
  my @kids = grep { !/$spec/o } keys %{$self};
  return $self if defined($self->{$text}) && !@kids;
  confess unless @kids;
  return $self->{$kids[0]}->endpt;
}

#返回数组对象
sub text {
  my $self = shift;
  return '' unless $self;
  if (defined $self->{$text}) {
    return $debug_text ? $self->{$word} . " " . $self->{$text} : $self->{$text};
  }
  my @kids = $self->sortit(grep { !/$spec/o } keys %{$self});
  if (@kids > 1) {
    my %temp = map { $self->{$_}->sequenced_text(0) } @kids;
    return join('', map { $temp{$_} } sort keys %temp);
  }
  elsif ($self->{$dupl}) {
    return join('', map { $_->{$word} . " " . $_->{$text} } @{$self->{$dupl}})
      if $debug_text;
    return join('', map { $_->{$text} } @{$self->{$dupl}});
  }
  confess unless @kids;
  return $self->{$kids[0]}->text;
}

#按序输出命令行
sub sequenced_text {
  my ($self, $all) = @_;
  my @text = ();
  if (defined $self->{$text}) {
    push(@text,
      $debug_text
      ? ($self->seqn => $self->{$word} . " " . $self->{$text})
      : ($self->seqn => $self->{$text}));
  }
  if (exists $self->{$dupl}) {
    push(@text,
      $debug_text
      ? map { $_->seqn => $_->{$word} . " " . $_->{$text} } @{$self->{$dupl}}
      : map { $_->seqn => $_->{$text} } @{$self->{$dupl}});
  }

  my @kids = $self->sortit(grep { !/$spec/o } keys %{$self});
  if (@kids) {
    return (@text, map { $self->{$_}->sequenced_text($all) } @kids);
  }

  push(@text, $self->{$subs}->sequenced_text($all)) if $all && $self->{$subs};
  return @text                                      if @text;
  confess unless @kids;
  return $self->{$kids[0]}->sequenced_text($all);
}

#顺序输出匹配到的所有文本
sub alltext {
  my $self = shift;
  return '' unless $self;
  my %temp = $self->sequenced_text(1);
  return join('', map { $temp{$_} } sort keys %temp);
}

#去除文本换行符
sub chomptext {
  my $self = shift;
  my $t    = $self->text;
  chomp($t);
  return $t;
}

sub returns {
  my (@result) = @_;
  for my $ret (@result) {
    $ret .= "\n" if defined($o) && $o !~ /\n$/;
  }
  return $result[0] unless wantarray;
  return @result;
}

sub openangle {
  my (@l) = grep { defined && / \S / } @_;
  my $x = 0;
  for my $l (@l) {
    substr($l, 0, 0) = (' ' x $x++);
  }
  return $l[0] unless wantarray;
  return @l;
}

sub closeangle {
  my (@l) = grep { defined && / \S / } @_;
  my $x = $#l;
  for my $l (@l) {
    substr($l, 0, 0) = (' ' x $x--);
  }
  return $l[0] unless wantarray;
  return @l;
}

sub context {
  defined($_[0]->{$cntx}) ? $_[0]->{$cntx} : $_[0]->endpt->{$cntx}
    || ($_[0] ? confess "$_[0]" : $undef);
}


sub setcontext {
  my ($self, @extras) = @_;
  print STDERR "\nSETCONTEXT\n" if $debug_context;
  unless ($self->block) {
    print STDERR "\nNOT_A_BLOCK $self->{$debg}\n" if $debug_context;
    $self = $self->context;
  }
  printf STDERR "\nSELF %sCONTEXT %sCCONTEXT %sEXTRAS$#extras @extras\n",
    $self->{$debg}, $self->context->{$debg}, $self->context->context->{$debg}
    if $debug_context;
  my $x = $self->context;
  return (grep defined, $x->context->setcontext, trim($x->zoom->{$text}),
    @extras)
    if $x;
  return @extras;
}

sub contextcount {
  my $self = shift;
  my (@a) = $self->setcontext(@_);
  printf STDERR "CONTEXTCOUNT = %d\n", scalar(@a) if $debug_context;
  print STDERR map {"CC: $_\n"} @a if $debug_context;
  return scalar(@a);
}

sub unsetcontext {
  my $self = shift;
  return (("exit") x $self->contextcount(@_));
}

sub teql {
  my ($self, $b) = @_;
  my $a = $self->text;
  $a =~ s/^\s+/ /g;
  $a =~ s/^ //;
  $a =~ s/ $//;
  chomp($a);
  $b =~ s/^\s+/ /g;
  $b =~ s/^ //;
  $b =~ s/ $//;
  chomp($b);
  return $a eq $b;
}

sub set {
  my $self          = shift;
  my $new           = pop;
  my (@designators) = @_;

  #my ($self, $designator, $new) = @_;
  print STDERR "\nSET\n" if $debug_set;
  return undef unless $self;
  my $old;

  #my @designators;
  print STDERR "\nSELF $self->{$debg}" if $debug_set;

  # move into the block if possible
  $self = $self->subs if $self->subs;
  print STDERR "\nSELF $self->{$debg}" if $debug_set;

  #if (ref $designator eq 'ARRAY') {
  #	@designators = @$designator;
  #	$old = $self->get(@designators);
  #	$designator = pop(@designators);
  #} elsif ($designator) {
  #	$old = $self->get($designator);
  #} else {
  #	$old = $self;
  #}
  my $designator;
  if (@designators) {
    $old        = $self->get(@designators);
    $designator = pop(@designators);
  }
  else {
    $old = $self;
  }
  print STDERR "\nOLD $old->{$debg}" if $debug_set;
  my (@lines) = expand(grep (/./, split(/\n/, $new)));
  if ($lines[0] =~ /^(\s+)/) {
    my $ls = $1;
    my $m  = 1;
    map { substr($_, 0, length($ls)) eq $ls or $m = 0 } @lines;
    map { substr($_, 0, length($ls)) = '' } @lines if $m;
  }
  my $indent = (' ' x $self->contextcount(@designators));
  for $_ (@lines) {
    s/(\S)\s+/$1 /g;
    s/\s+$//;
    $_ = 'exit' if /^\s*!\s*$/;
    $_ = "$indent$_";
  }
  print STDERR "SET TO {\n@lines\n}\n" if $debug_set;
  my $desig = shift(@lines);
  my @o;
  undef $old if !$old;
  if (!$old) {
    print STDERR "NO OLD\n" if $debug_set;
    push(@o, openangle($self->setcontext(@designators)));
    push(@o, $desig);
  }
  elsif (!$designator && !looks_like_a_block($desig, @lines)) {
    if ($self->block && $self->context) {
      unshift(@lines, $desig);
      $old = $self->context;
      undef $desig;
    }
    else {
      unshift(@lines, $desig);
      print STDERR "IN NASTY BIT\n" if $debug_set;
      #
      # this is a messy situation: we've got a random
      # block of stuff to set inside a random block.
      # In theorey we could avoid the die, I'll leave
      # that as an exercise for the reader.
      #
      confess
        "You cannot set nested configurations with set(undef, \$config) -- use a designator on the set method"
        if grep (/^$indent\s/, @lines);
      my (@t) = split(/\n/, $self->text);
      my (%t);
      @t{strim(@t)} = @t;
      while (@lines) {
        my $l = strim(shift(@lines));
        if ($t{$l}) {
          delete $t{$l};
        }
        else {
          push(@o, "$indent$l");
        }
      }
      for my $k (keys %t) {
        unshift(@o, iinvert($indent, $k));
      }
      unshift(@o, $self->setcontext) if @o;
    }
  }
  elsif ($old->teql($desig)) {
    print STDERR "DESIGNATOR EQUAL\n" if $debug_set;

    # okay
  }
  else {
    print STDERR "DESIGNATOR DIFERENT\n" if $debug_set;
    push(@o, openangle($self->setcontext(@designators)));
    if (defined $designator) {
      push(@o, iinvert($indent, $designator));
    }
    else {
      push(@o, iinvert($indent, split(/\n/, $self->text)));
    }
    push(@o, $desig);
  }
  if (@lines) {
    if ($old && !@o && $old->subs && $old->subs->next) {
      print STDERR "OLD= $old->{$debg}" if $debug_set;
      my $ok = 1;
      my $f  = $old->subs->next;
      print STDERR "F= $f->{$debg}" if $debug_set;
      for my $l (@lines) {
        next                             if $l =~ /^\s*exit\s*$/;
        next                             if $f->teql($l);
        print STDERR "LINE DIFF ON $l\n" if $debug_set;
        $ok = 0;
        last;
      }
      continue {
        $f = $f->next;
        print STDERR "F= $f->{$debg}" if $debug_set;
      }
      if (!$ok || $f) {
        push(@o, openangle($self->setcontext(@designators)));
        push(@o, iinvert($indent, $designator));
        push(@o, $desig);
      }
    }
    push(@o, @lines) if @o;
  }
  @o = grep (defined, @o);
  push(@o, closeangle($self->unsetcontext(@designators))) if @o;
  return join('', returns(@o)) unless wantarray;
  return returns(@o);
}

sub looks_like_a_block {
  my ($first, @l) = @_;
  my $last = pop(@l);
  return 1 if !defined $last;
  return 0 if grep (/^\S/, @l);
  return 0 if $first =~ /^\s/;
  return 0 if $last =~ /^\s/;
  return 1;
}

sub iinvert {
  my ($indent, @l) = @_;
  confess unless @l;
  for $_ (@l) {
    next unless defined;
    s/^\s*no /$indent/ or s/^\s*(\S)/${indent}no $1/;
  }
  return $l[0] unless wantarray;
  return @l;
}

sub all {
  my ($self, $regex) = @_;
  $self = $self->zoom;
  return (map { $self->{$_} }
      $self->sortit(grep (/$regex/ && !/$spec/o, keys %$self)))
    if $regex;
  return (map { $self->{$_} } $self->sortit(grep (!/$spec/o, keys %$self)));
}

sub get {
  my ($self, @designators) = @_;
  return $self->mget(@designators) if wantarray && @designators > 1;

  print STDERR "\nGET <@designators> $self->{$debg}" if $debug_get;

  return $self unless $self;
  my $zoom = $self->zoom->subs;
  $self = $zoom if $zoom;

  print STDERR "\nZOOMSUB $self->{$debg}" if $debug_get;

  while (@designators) {
    my $designator = shift(@designators);

    #		$self = $self->zoom;
    #	$self = $self->single || $self;
    print STDERR "\nDESIGNATOR: $designator.  ZOOMED: $self->{$debg}\n"
      if $debug_get;
    for my $d (split(' ', $designator)) {
      print STDERR "\nDO WE HAVE A: $d?\n" if $debug_get;
      return $undef unless $self->{$d};
      $self = $self->{$d};
      print STDERR "\nWE DO: $self->{$debg}\n" if $debug_get;
    }
    last unless @designators;
    if ($self->single) {
      $self = $self->subs;
      print STDERR "\nSINGLETON: $self->{$debg}\n" if $debug_get;
    }
    else {
      print STDERR "\nNOT SINGLE\n" if $debug_get;
      return $undef;
    }
  }
  print STDERR "\nDONE\n" if $debug_get;
  if (wantarray) {
    $self = $self->zoom;
    my (@k) = $self->kids;
    return @k if @k;
    return $self;
  }
  return $self;
}

sub strim {
  my (@l) = @_;
  for $_ (@l) {
    s/^\s+//;
    s/\s+$//;
    s/\n$//;
  }
  return $l[0] unless wantarray;
  return @l;
}

sub trim {
  my (@l) = @_;
  for $_ (@l) {
    s/^\s+//;
    s/\s+$//;
  }
  return $l[0] unless wantarray;
  return @l;
}

sub display {
  my ($self) = @_;
  my @o;
  push(@o, $self->setcontext);
  push(@o, trim($self->single->{$text}))
    if $self->single && $self->single->{$text} && $self->subs->undefined;
  push(@o, "! the whole enchalada") if $self->context->undefined;
  my (@r) = returns(openangle(@o));
  return @r if wantarray;
  return join('', @r);
}

sub callerlevels {
  my $n = 1;
  1 while caller($n++);
  return $n;
}

sub mget {
  my ($self, @designators) = @_;

  my $cl = callerlevels;
  my @newset;
  if (@designators > 1) {

    print STDERR "\nGET$cl $designators[0]----------\n" if $debug_mget;

    my (@set) = $self->get(shift @designators);
    for my $item (@set) {

      print STDERR "\nMGET$cl $item ----------\n" if $debug_mget;
      print STDERR "\nMGET$cl $item->{$debg}\n"   if $debug_mget;

      my (@got) = $item->mget(@designators);

      print STDERR map {"\nRESULTS$cl: $_->{$debg}\n"} @got if $debug_mget;

      push(@newset, @got);
    }
  }
  else {

    print STDERR "\nxGET$cl $designators[0] -------\n" if $debug_mget;

    (@newset) = $self->get(shift @designators);

    print STDERR map {"\nxRESULTS$cl: $_->{$debg}\n"} @newset if $debug_mget;

  }
  return @newset;
}

sub sortit {
  my $self = shift;
  return sort { $self->{$a}->seqn cmp $self->{$b}->seqn } @_;
}

1;
