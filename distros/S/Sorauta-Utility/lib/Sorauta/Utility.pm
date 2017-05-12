#============================================
# 便利関数群
#   基本的に全関数、exportして使う
#   BASIC認証については、必要に応じてパッケージ変数(BASIC_AUTH_LIST)を上書きする
# -------------------------------------------
# アクセサ
# xxx_xxx           String         xxxxxx
#                                       デフォルトは$XXX_XXX
#============================================
package Sorauta::Utility;
use base 'Exporter';

use 5.012003;
use strict;
use warnings;
use utf8;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use LWP::UserAgent;
use Time::Local; # for timegm

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Sorauta::Utility ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

# 利用可能なサブルーチン一覧
our @EXPORT = qw/get_from_http save_file create_get_url get_timestamp get_date get_epoch_from_formated_http cat is_hidden_file is_unnecessary_copying_file/;

our $VERSION = '0.02';

# Preloaded methods go here.

# ベーシック認証情報
# override: %Sorauta::Utility::BASIC_AUTH_LIST = ();
our %BASIC_AUTH_LIST = (
  #'host.example.com' => {
  #  id   => 'user_id',
  #  pass => 'user_pass',
  #},
);

# HTTPリクエストのタイムアウト時間
our $TIMEOUT = 20;

# HTTPリクエスト失敗時のリトライ回数
our $RETRY_COUNT = 1;

# デバッグ出力するか
our $DEBUG = 0;

#==========================================
# httpリクエスト送る
# req:
#   url        : リクエスト先のURL
#   timeout    : リクエストのタイムアウト時間
#   retry_count: リクエスト失敗時にリトライする回数
# res:
#   response: LWP::UserAgentのレスポンスオブジェクト
#==========================================
sub get_from_http {
  my($url, $timeout, $retry_count) = @_;
  unless ($timeout) {
    $timeout = $TIMEOUT;
  }
  unless ($retry_count) {
    $retry_count = $RETRY_COUNT;
  }

  if ($DEBUG) {
    print '[Sorauta::Utility][get_from_http]', $url, $/;
  }

  # create agent
  my $ua = LWP::UserAgent->new(
  );
  $ua->timeout($timeout);

  # create request
  my $req = HTTP::Request->new(
    GET => $url
  );
  while (my($key, $basic_auth) = each(%BASIC_AUTH_LIST)) {
    if ($url =~ /$key/) {
      $req->authorization_basic($basic_auth->{id}, $basic_auth->{pass});
      last;
    }
  }

  my $try_count = 0;
  my $response;
  while ($try_count++ < $retry_count) {
    $response = $ua->request($req);
    if ($response->is_success) {
      last;
    }
    else {
      if ($DEBUG) {
        print '[Sorauta::Utility][get_from_http]', $url, ' got ', $response->status_line, ' ... retry', $/;
      }
    }
  }

  return $response;
}

#==========================================
# ファイルを保存
# req:
#   path:      保存ファイルのパス
#   content:   ファイルの内容
#   is_binary: バイナリの場合は1、それ以外は0
# res:
#   result: 成功時は1、失敗時は2
#==========================================
sub save_file {
  my($path, $content, $is_binary) = @_;

  if ($DEBUG) {
    print "[Sorauta::Utility][save_file]", $path, $/;
  }

  open(my $F, '>', $path) or die 'Can\'t open('.$path.'): '.$!;
  if ($is_binary) {
    binmode($F);
  }
  print $F $content;
  close $F;
}

#==========================================
# パラメータをGET引数に変換
# ※文字列エスケープ等は引数に渡す前に既に行っている前提
# req:
#   url: 元になるURL
#     ex) http://localhost/index.pl
#   params: 引数をハッシュで表現
#     ex) { id => 1, name => "test" }
# res:
#   url_str: 文字列化されたURL
#     ex) http://localhost/index.pl?id=1&name=test
#==========================================
sub create_get_url {
  my($url, $params) = @_;

  # GET引数に変換
  my $get_param = q{};
  while (my($key, $val) = each(%$params)) {
    $get_param .= $key . '=' . $val . '&';
  }

  return $url . '?' . $get_param;
}

#==========================================
# 指定した時刻をタイムスタンプで取得
# req:
#   unix_time: 取得したい時刻のエポックタイム、指定しなければ現在時刻
# res:
#   timestamp: タイムスタンプを文字列に変換したもの
#==========================================
sub get_timestamp {
  my $time = shift || time;
  my($sec, $min, $hour, $day, $month, $year) = (localtime($time))[0..5];

  return sprintf("%04d/%02d/%02d %02d:%02d:%02d",
    $year + 1900, $month + 1, $day, $hour, $min, $sec);
}

#------------------------------------------
# 時刻情報取得
# req:
#   unix_time: 指定したい時刻のエポックタイム、指定しなければ現在時刻
# res:
#   date_obj: 時刻情報をハッシュリファレンスにしたもの
#------------------------------------------
sub get_date {
  my $time = shift || time;
  my($sec, $min, $hour, $day, $month, $year) = (localtime($time))[0..5];

  return {
    year  => $year + 1900,
    month => $month + 1,
    day   => $day,
    hour  => $hour,
    min   => $min,
    sec   => $sec,
  };
}

#==========================================
# http経由で取得した時間からエポックタイムを抽出
# req:
#   date_str: httpリクエストのヘッダにあるlast-modified等
#     ex)"Fri, 13 Jan 2012 23:49:21 GMT"
# res:
#   unix_time: エポックタイム
#==========================================
sub get_epoch_from_formated_http {
  my(@MoY, %MoY);
  @MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
  @MoY{@MoY} = (1..12);

  if ($_[0] =~ /^
    [SMTWF][a-z][a-z],
    \ (\d\d)
    \ ([JFMAJSOND][a-z][a-z])
    \ (\d\d\d\d)
    \ (\d\d):(\d\d):(\d\d)
    \ GMT$/x) {
    return timegm($6, $5, $4, $1, $MoY{$2} - 1, $3 - 1900);
  }
}

#==========================================
# パスを配列で表現したものから文字列のパスを作る
# req:
#   path_list: ('/Users', 'user', 'Desktop', 'Hoge.txt')
# res:
#   path_str: '/Users/user/Desktop/Hoge.txt'
#==========================================
sub cat {
  #return join('/', @_);
  return File::Spec->catfile(@_);
}

#==========================================
# 隠しファイルか判定
#   is_skip_file
# req:
#   file_path: ファイルまでのパス
#       ex) /Users/user/Desktop/.svn
# res:
#   result: 隠しファイルの場合は1、それ以外は0
#==========================================
sub is_hidden_file {
  my $file_path = shift;

  return 1 if(
    $file_path eq '.'  ||
    $file_path eq '..' ||
    $file_path =~ /.svn$/ ||
    $file_path =~ /desktop\.ini$/ ||
    $file_path =~ /.DS_Store$/ ||
    $file_path =~ /Thumbs\.db$/
  );

  return 0;
}

#------------------------------------------
# コピー不要なファイルか
#   copy_filter
# req:
#   file_name: ファイル名
#     ex).svn, desktop.ini
# res:
#   result: コピーすべきファイルの場合は0、それ以外は1
#------------------------------------------
sub is_unnecessary_copying_file {
  my $file_name = shift;

  # .や..等，階層を指定している場合は無視
  if ($file_name =~ /^\./) {
    return 1;
  }
  # サムネイル用ファイルなどは無視
  if ($file_name eq 'Thumbs.db' || !($file_name =~ /[^\.]/)) {
    return 1;
  }
  # .svnはコピーしたくない
  if ($file_name eq '.svn' || $file_name eq 'desktop.ini' || $file_name eq '.DS_Store') {
    return 1;
  }

  # ログファイルのディレクトリは無視
  if ($file_name eq 'log') {
    return 1;
  }

  return 0;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sorauta::Utility - useful sub routeans

=head1 SYNOPSIS

  use Sorauta::Utility;

1.get_from_http
  $url = "http://google.com/";

  # HTTP::Response instance
  my $result = get_from_http($url);

2.save_file
  my $path = "sample.txt";
  my $content = "hoge fuga piyo";
  # if error has occures, return 2(or 0)
  save_file($path, $content);

3.create_get_url
  my $url = "http://google.com/";
  my $params = { id => 1, name => "sample" };

  # return "http://google.com/?name=sample&id=1&"
  my $result = create_get_url($url, $params);

4.get_timestamp
  # return "2012/01/25 15:02:14"
  my $result = get_timestamp(1327471334);

5.get_date
  # return { year => 1, month => 1, dat => 2, hour => 1, min => 1, sec => 1 };
  my $data_obj = get_date();

6.get_epoch_from_formated_http
  # return 1326498561
  my $result = get_epoch_from_formated_http("Fri, 13 Jan 2012 23:49:21 GMT");

7.cat
  my @path_list = ('/Users', 'user', 'Desktop', 'Hoge.txt');

  # return "/Users/user/Desktop/Hoge.txt"
  my $result = cat(@path_list);

8.is_hidden_file
  my $file_path = ".svn";

  # return 1
  my $result = is_hidden_file($file_path);

9.is_unnecessary_copying_file
  my $file_path = ".svn";

  # return 1
  my $result = is_unnecessary_copying_file($file_path);

=head1 DESCRIPTION

useful sub routeans

=head2 EXPORT

None by default.

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Yuki ANAI, E<lt>yuki@apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Yuki ANAI

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.3 or,
at your option, any later version of Perl 5 you may have available.


=cut
