# RexInline

Rex::Inline 是一个在perl中直接调用rex的接口

### 适用场景

虽然 `rex` 的命令行工具很好用，
可是有时不想写 Rexfile，
并且如果想把 Rex 的功能模块化 给其他App调用的时候，
就需要用到这个 API 了。

### 调用方法
1. 匿名调用 Rex

  use Rex -feature => ['1.0'];
  use Rex::Inline;

  my $rex_inline = Rex::Inline->new;
  $rex_inline->add_task(
      {
        user => $user,
        server => [@server],
        password => $password,
        # private_key => $private_key_path,
        # public_key => $public_key_path,
        func => sub {
          # 这里写要在 Rex 中执行的语句
        }
      }
  );

  $rex_inline->execute;
  my $reports = $rex_inline->reports;

2. 写成模块
  #### Test.pm

  package Test;
  use Moose; # or Moo
  use Rex -feature => ['1.0'];

  extends 'Rex::Inline::Base';

  sub func {
    my $self = shift;
    return sub { 
      say run "uptime" 
      say $self->input;
    }
  }

  1;

  ### t.pl
  use Test;
  use Rex::Inline;

  my $rex_inline = Rex::Inline->new;
  $rex_inline->add_task( Test->new(
      user => $user,
      server => [@server],
      password => $password,
      # private_key => $private_key_path,
      # public_key => $public_key_path,
      input => 'test', # 任何想传给模块的参数
  ) );

  $rex_inline->execute;
  my $reports = $rex_inline->reports;
