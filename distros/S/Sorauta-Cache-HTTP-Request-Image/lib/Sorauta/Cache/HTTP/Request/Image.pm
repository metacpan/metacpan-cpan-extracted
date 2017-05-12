#============================================
# 画像キャッシュプログラム(BASIC認証突破)
# -------------------------------------------
# アクセサ
# cache_path         String         画像のキャッシュディレクトリ
#                                         ex)/Library/WebServer/Documents/cache/
# log_path           String         画像キャッシュ生成ログ保存ディレクトリ
#                                         ex)/Library/WebServer/Documents/cache_log/
# url                String         画像URL
#                                       ex)http://example.com/example.jpg
# check              Integer        画像の更新を確認するか
#                                         0 ... 確認しない(デフォルト)
#                                         1 ... 確認する
# render             Integer        取得画像を表示するか
#                                         0 ... 表示しない
#                                         1 ... 表示する（デフォルト）
# debug              Integer        デバッグモード
#                                         0 ... ログ表示しない(デフォルト)
#                                         1 ... ログ表示する
# logger             Integer        ログ保存するか
#                                         0 ... ログ保存しない(デフォルト)
#                                         1 ... ログ保存する
#
# file_name          String         キャッシュ画像のファイル名
#                                         一部replaceされてるので画像URLそのままのファイル名ではないので.
# file_path          String         キャッシュ画像の保存先
#                                         めんどくさいので用意
#============================================
package Sorauta::Cache::HTTP::Request::Image;
use base qw/Class::Accessor::Fast/;

use 5.012003;
use strict;
use warnings;
use utf8;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use LWP::UserAgent;
use Sorauta::Utility;

our $VERSION = '0.01';

# 許可するMIME一覧
our %CONTENT_TYPE_LIST = (
  jpg => 'image/jpg',
  gif => 'image/gif',
  png => 'image/png',
  mov => 'video/quicktime',
  f4v => 'video/f4v',
  flv => 'video/x-flv',
);

__PACKAGE__->mk_accessors(
  qw/cache_path log_path url check render debug logger file_name file_path/);

#==========================================
# ファイル取得の取得、保存を実行
# req:
# res:
#==========================================
sub execute {
  my $self = shift;

  # must be defined accessors
  if (!$self->cache_path || !$self->url) {
    die 'must be define accessor cache_path(/var/www/cache/), url(http://example.com/example.jpg)';
  }

  # set default params
  unless (length $self->render) {
    $self->render(1);
  }
  $self->file_name('');
  $self->file_path('');

  # replace system character
  my $file_name = $self->url;
  $file_name =~ s/:/_/g;
  $file_name =~ s/\//__/g;
  $file_name =~ s/&/--/g;
  $self->file_name($file_name);

  # set file_path
  $self->file_path(cat($self->cache_path, $self->file_name));

  # exists cache file
  if (-e $self->file_path) {
    # check update request
    if ($self->check) {
      $self->get();
    }

    if ($self->render) {
      $self->show($self->file_name);
    }
  }
  else {
    $self->get();
  }

  return 1;
}

#==========================================
# 画像を取得
# req:
# res:
#==========================================
sub get {
  my $self = shift;

  my $is_binary = 1;
  my $res = get_from_http($self->url);
  unless ($res->headers->content_type =~ /text/) {
    # 既にキャッシュファイルが存在する場合
    if (-e $self->file_path) {
      my $last_local_modified = (stat $self->file_path)[9];
      my $last_web_modified = get_epoch_from_formated_http(
        $res->headers->{'last-modified'});

      # logger
      if ($self->logger) {
        $self->add_log('[exists]'.$self->file_name);
      }

      # debug
      if ($self->debug) {
        warn("last_local_modified:". $last_local_modified. $/);
        warn("last_web_modified:". $last_web_modified. $/);
      }

      # 日付が変わっていれば保存
      if ($last_local_modified != $last_web_modified) {
        save_file($self->file_path, $res->content, $is_binary);
      }
    }
    # 新規取得時
    else {
      save_file($self->file_path, $res->content, $is_binary);

      # logger
      if ($self->logger) {
        $self->add_log('[new]'.$self->file_name);
      }

      # ファイル更新日を変える
      my $last_web_modified = get_epoch_from_formated_http(
        $res->headers->{'last-modified'});
      utime(time,
        $last_web_modified,
        ($self->file_path));
    }
  }

  # show binary image
  if ($self->render) {
    unless ($res->headers->content_type =~ /text/) {
      print 'content-type:', $res->headers->content_type, $/, $/;
      print $res->content;
    }
    else {
      my $msg = 'couldn\'t reach url: '.$self->url;

      print 'content-type:text/plain;', $/, $/;
      print $msg;

      warn $msg;
    }
  }
}

#==========================================
# 保存した画像を表示
# req:
#   file_name: ファイル名
# res:
#==========================================
sub show {
  my($self, $file_name) = @_;
  my $content_type = 'application/octet-stream';

  # extract content-type
  my($suffix) = (split(/\./, $file_name))[-1];
  if (exists($CONTENT_TYPE_LIST{$suffix})) {
    $content_type = $CONTENT_TYPE_LIST{$suffix};
  }
  if ($self->debug) {
    warn $self->file_path.', content-type:'.$content_type.', suffix:'.$suffix;
  }

  # show binary image
  open(my $F, $self->file_path) or die 'Can\'t open: '.$!;
  binmode($F);
  print "content-type:", $content_type, $/, $/;
  while (my $line = <$F>) {
    print $line;
  }
  close $F;
}

#==========================================
# ログ保存
# req:
#   txt: 保存メッセージ
# res:
#==========================================
sub add_log {
  my($self, $txt) = @_;
  my $today = get_date(time);
  my $log_file = sprintf("%04d%02d%02d_log.txt", $today->{year}, $today->{month}, $today->{day});
  my $date = sprintf("[%02d:%02d:%02d]", $today->{hour}, $today->{min}, $today->{sec});

  open my $F, '>>', cat($self->log_path, $log_file);
  print $F $date, $txt, $/;
  close $F;
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sorauta::Cache::HTTP::Request::Image - create cache image when you got http request.

=head1 SYNOPSIS

  use Sorauta::Cache::HTTP::Request::Image;

  my $CACHE_PATH = '/tmp/';
  my $SAMPLE_URLS = [
    'http://www.google.co.jp/images/srpr/logo3w.png',
  #  'http://sorauta.net/images/common/author.jpg',
  ];
  my $MAX_WIDTH = 900;
  my $MAX_HEIGHT = 1600;
  my $DEBUG = 0; # show debug log
  my $CHECK = 0; # check updated cache image
  my $RENDER = 0; # show image

  # get test
  {
    # test url
    my $url = $SAMPLE_URLS->[int(rand(@$SAMPLE_URLS))];

    # create new cache image
    Sorauta::Cache::HTTP::Request::Image->new({
      cache_path            => $CACHE_PATH,
      url                   => $url,
      check                 => $CHECK,
      render                => $RENDER,
      debug                 => $DEBUG,
    })->execute;
  }

=head1 DESCRIPTION

create cache image when you got http request.

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
