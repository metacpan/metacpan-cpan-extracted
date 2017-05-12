#============================================
# USB監視 & ディレクトリ同期モジュール
# 　USBが接続されると特定のディレクトリを同期する
# 　親はUSB側なので、PC側にUSB側で削除されているファイルがある場合削除される
# -------------------------------------------
# アクセサ
# target_dir_path       String         USBと同期するディレクトリのフルパス
#                                               ex)/Library/WebServer/Documents/resource/projects
# synchronized_dir_list ArrayRef       同期したいディレクトリ一覧
#                                               ex) [pic, flv, init_pic]
# os                    String         OSの種類
#                                               Win ... windows
#                                               Mac ... mac os
# interval_time         Integer        バッチの実行周期
#                                               0の場合は一度のみ実行
# allow_override_file   Integer        同一ファイルがUSBに入っている場合更新するか?
#                                               0 ... 更新しない(デフォルト)
#                                               1 ... 更新する
# debug                 Integer        デバッグモード
#                                               0 ... ログ表示しない(デフォルト)
#                                               1 ... ログ表示する
#
# connected_event_ref   FunctionRef    監視対象USB接続時のイベント
#                                               USBへのファイルコピーなど行う
# updated_event_ref     FunctionRef    監視対象ディレクトリ更新時のイベント
#                                               何か色々やるかなーと
# driver_check_list     Hash           接続中のドライバを保持するHash
#                                               デフォルトは{}
# update_flag           Integer        バッチの実行結果、pattern.xmlを更新するかフラグ
#                                               0 ... 更新しない
#                                               1 ... 更新する
#============================================
package Sorauta::Device::USB::Synchronizer;
use base qw/Class::Accessor::Fast/;

use 5.012003;
use strict;
use warnings;
use utf8;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use LWP::UserAgent;
use File::Copy;
use Sorauta::Utility;

our $VERSION = '0.01';

my $MAC_ROOT_DIR = "/Volumes";
my $WIN_DRIVER_LIST = ['A'..'Z'];

__PACKAGE__->mk_accessors(qw/
    target_dir_path synchronized_dir_list os interval_time allow_override_file debug
    connected_event_ref updated_event_ref driver_check_list update_flag/);

#==========================================
# USBの監視を実行する
# req:
# res:
#   result: 成功時は1、失敗時はそれ以外
#==========================================
sub execute {
  my $self = shift;

  # debug
  if ($self->debug == 1) {
    #print Dumper($self);
  }

  # must be defined accessors
  if (!$self->target_dir_path
   || !$self->synchronized_dir_list
   || !$self->os
   || !length($self->interval_time)
   || !length($self->allow_override_file)
  ) {
    die 'must be define accessor '.
    'target_dir_path(/Library/WebServer/Documents/resource/hogehoge), synchronized_dir_list([hoge, fuga]), '.
    'os(Win|Mac), interval_time(10), allow_override_file(0|1)';
  }

  # インスタンス変数を初期化
  $self->driver_check_list({});
  $self->update_flag(0);

  # 監視対象のディレクトリが存在しない場合作成
  if (!-e $self->target_dir_path) {
    print 'mkdir: ', $self->target_dir_path, $/;
    mkdir($self->target_dir_path, 0755);
  }
  for (@{$self->synchronized_dir_list}) {
    my $npath = cat($self->target_dir_path, $_);
    if (!-e $npath) {
      print 'mkdir: ', $npath, $/;
      mkdir($npath, 0755);
    }
  }

  print '=================================', $/;
  print ' Batch Start', $/;
  print '=================================', $/;

  while (1) {
    $self->execute_batch;
    if ($self->interval_time) {
      sleep $self->interval_time;
    }
    else {
      last;
    }
  }

  return 1;
}

#==========================================
# 定期バッチ実行
# req:
# res:
#==========================================
sub execute_batch {
  my $self = shift;

  # 監視対象フォルダ更新フラグを初期化
  $self->update_flag(0);

  # 接続されたドライブから、目的のUSBが無いか検索、更新
  $self->check_drivers;

  # アップデート時に実行するイベント
  if ($self->update_flag == 1 && $self->updated_event_ref) {
    $self->updated_event_ref->($self);
  }

  print "[", get_timestamp(time), "]execute ok, wait ", $self->interval_time, "sec", $/;
}

#------------------------------------------
# 各ドライブが接続されたか監視する
# req:
# res:
#------------------------------------------
sub check_drivers {
  my $self = shift;

  if ($self->os eq 'Mac') {
    opendir(my $DIR, $MAC_ROOT_DIR) or die 'Can\'t open('.$MAC_ROOT_DIR.'): '.$!;
    while (my $driver_name = readdir($DIR)) {
      next if ($driver_name eq '.' || $driver_name eq '..');
      my $driver_path = cat($MAC_ROOT_DIR, $driver_name);
      $self->check_connect_usb($driver_path, $driver_name);
    }
    close $DIR;
  }
  elsif ($self->os eq 'Win') {
    foreach my $driver_name(@$WIN_DRIVER_LIST) {
      my $driver_path = $driver_name . ':/';
      $self->check_connect_usb($driver_path, $driver_name);
    }
  }
}

#------------------------------------------
# USBが接続されたか判断、接続時は同期していく
# req:
#   driver_path: ドライバ(USB)までのフルパス
#                  ex)C:/ or /Volumes/usb-name-hoge
#   driver_name: ドライバ名(USB)
#                  ex)C or usb-name-hoge
# res:
#------------------------------------------
sub check_connect_usb {
  my($self, $driver_path, $driver_name) = @_;

  # 新たに接続された場合
  if (-e $driver_path) {
    print '# ', $driver_path, "\t connected. ";

    # 監視対象のUSBが接続されたら，内容をコピーする.
    if ($self->is_signage_usb($driver_path)) {
      # 接続時のイベント発行
      if ($self->connected_event_ref) {
        $self->connected_event_ref->($self, $driver_path);
      }
      # 内容コピー
      $self->recrusive_copy($driver_path, $self->target_dir_path);
    }

    # update check list
    $self->driver_check_list->{$driver_name} = 1;
  }

  # 取り外された場合
  if ($self->driver_check_list->{$driver_name} && !(-e $driver_path)) {
    print '# ', $driver_path, "\t disconnected", $/;

    # update check list
    $self->driver_check_list->{$driver_name} = 0;
  }
}

#------------------------------------------
# 監視対象のUSBか判断
# req:
#   driver_path: ドライバ(USB)までのフルパス
#                  ex)C:/ or /Volumes/usb-name-hoge
# res:
#   result: 監視対象USBの場合は1、それ以外は0
#------------------------------------------
sub is_signage_usb {
  my($self, $driver_path) = @_;

  # 監視対象のディレクトリが含まれているか確認
  my $cnt = 0;
  for my $search_dir_name(@{$self->synchronized_dir_list}) {
    if (-e cat($driver_path, $search_dir_name)) {
      $cnt++;
    }
  }

  # 全て含まれている場合は同期対象と判断
  if ($cnt == scalar(@{$self->synchronized_dir_list})) {
    print "And, this drive is signage usb", $/;
    return 1;
  }
  else {
    print "But, this drive is not signage usb", $/;
    return 0;
  }
}

#------------------------------------------
# 再帰的なファイルコピー
# req:
#   usb_dir_path:    USB側のフルパス
#   target_dir_path: PC側のフルパス
# res:
#------------------------------------------
sub recrusive_copy {
  my($self, $usb_dir_path, $target_dir_path) = @_;

  opendir(my $D, $usb_dir_path) or die 'Can\'t open('.$usb_dir_path.'): '.$!;
  while (my $file_name = readdir($D)) {
    # コピーするファイル名に制約をつける場合(Sorauta::Utilityにて定義)
    if (is_unnecessary_copying_file($file_name)) {
      next;
    }

    # コピー元とコピー先のディレクトリのフルパス取得
    my($from_path, $destination_path) = (
      cat($usb_dir_path, $file_name), cat($usb_dir_path, $file_name));
    if ($self->os eq 'Mac') {
      $destination_path =~ s/^$MAC_ROOT_DIR\/(?:.*?)\/([\w]+)/$target_dir_path\/$1/g;
    }
    elsif ($self->os eq 'Win') {
      $destination_path =~ s/^[A-Z]{1,2}:[\/\\]([\w]+)/$target_dir_path\/$1/g;
    }

    # ディレクトリの場合，再帰的に探索
    if (-d $from_path) {
      # debug
      if ($self->debug == 1) {
        #print 'recrusive copy this dir: ', $from_path, $/;
      }

      my $fromdir_updated = (stat $from_path)[9];
      my $destdir_updated = (stat $destination_path)[9];

      # コピー先のディレクトリがコピ＾元より古い場合、ディレクトリ削除
      if ($destdir_updated && abs($fromdir_updated - $destdir_updated) > 20) {
        print 'rmdir: ', $destination_path, $/;
        if ($self->os eq 'Win') {
          system("del", "/q", $destination_path);
        }
        elsif ($self->os eq 'Mac') {
          my $cmd = "rm -rf $destination_path";
          `$cmd`;
        }
        utime(time, (stat $destination_path)[9], $from_path);
      }

      # コピー元のディレクトリがコピー先に存在しない場合は, ディレクトリ生成
      if (!-e $destination_path) {
        print 'mkdir: ', $destination_path, $/;
        mkdir($destination_path);

        utime(time, (stat $destination_path)[9], $from_path);
      }

      # 再帰的にコピーを繰り返す
      $self->recrusive_copy($from_path, $self->target_dir_path);
    }
    # ファイルの場合普通にコピー
    else {
      print "[[", $from_path, "]] ";

      # TODO: pattern.xmlを出力する場合，エレメント追加する

      # 既に存在する場合
      if (-e $destination_path) {
        #print "\talready exist", $/;

        # コピー元とコピー先のファイル更新日時を取得，
        my $fromfile_updated = (stat $from_path)[9];
        my $destfile_updated = (stat $destination_path)[9];

        # 上書き禁止な場合スキップ
        if (!$self->allow_override_file) {
          print "\tyou don't have override permission. skip.", $/, $/;
          next;
        }

        # 更新日時が同じ場合スキップ
        if (abs($destfile_updated - $fromfile_updated) < 20) {
          print "\tskip file.", $/;
          next;
        }

        # コピーするよメッセージ
        print "\toverride old file", $/;
      }

      # ディレクトリ更新したよフラグ
      $self->update_flag(1);

      # コピー実行
      {
        print "\tcopy dest: ", $destination_path, $/;
        copy($from_path, $destination_path) or
          print "[copy failed: $!]$/",
            "\tfrom_path: $from_path$/",
            "\tdest_path: $destination_path$/";

        utime(time, (stat $destination_path)[9], $from_path);
      }
    }
  }
  close($D);
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sorauta::Device::USB::Synchronizer - supervising universal serial bus and synchronized selected directories

=head1 SYNOPSIS

  use Sorauta::Device::USB::Synchronizer;

  my $TARGET_DIR_PATH = '/Users/user/Desktop/test_usb_synchronizer';
  my $SYNCHRONIZED_DIR_LIST = ["hoge", "fuga"];
  my $OS = 'Mac';
  my $INTERVAL_TIME = 0;
  my $ALLOW_OVERRIDE_FILE = 0;
  my $DEBUG = 1;
  my $CONNECTED_EVENT_REF = sub {
    my($self, $driver_path) = @_;
    print "connected!!";
  };
  my $UPDATED_EVENT_REF = sub {
    my $self = shift;
    print "updated!!";
  };

  Sorauta::Device::USB::Synchronizer->new({
    target_dir_path       => $TARGET_DIR_PATH,
    synchronized_dir_list => $SYNCHRONIZED_DIR_LIST,
    os                    => $OS,
    interval_time         => $INTERVAL_TIME,
    allow_override_file   => $ALLOW_OVERRIDE_FILE,
    debug                 => $DEBUG,
    connected_event_ref   => $CONNECTED_EVENT_REF,
    updated_event_ref     => $UPDATED_EVENT_REF,
  })->execute;

=head1 DESCRIPTION

supervising universal serial bus and synchronized selected directories

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
