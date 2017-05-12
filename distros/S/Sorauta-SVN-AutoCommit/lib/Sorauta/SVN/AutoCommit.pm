#============================================
# SVN自動コミットクラス
#
# -------------------------------------------
# アクセサ
# svn_mode         String         SVNのコミットモード
#                                       commit ... 自動コミットモード
#                                       update ... アップデート実行
# work_dir_path    String         作業フォルダまでのパス
#                                       ex)c:\projects\hoge_svn_dir
# debug            Integer        デバッグモード(コミット防止)
#                                       0 ... コミットする(デフォルト)
#                                       1 ... アップデートされたファイル一覧の列挙などはやるが、AddやCommit自体はしない
# thumbnail_width  Integer        サムネイル横幅
#                                       デフォルトは$THUMBNAI_WIDTHの値
# thumbnail_height Integer        サムネイル縦幅
#                                       デフォルトは$THUMBNAI_HEIGHTの値
#
# changes          Integer        ローカルのSVNに更新があったか
#                                       0 ... 更新なし(デフォルト)
#                                       1 ... 更新あり
# commit_comment   String         コミット時のコメント
#                                       デフォルトは$COMMIT_COMMENTの値
#
#============================================
package Sorauta::SVN::AutoCommit;
use base qw/Class::Accessor::Fast/;

use 5.012003;
use strict;
use warnings;
use utf8;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use SVN::Agent;
use SVN::Agent::Dummy;
use Image::Magick;
use Sorauta::Utility;

our $VERSION = '0.02';

# サムネイルの縦横
our($THUMBNAIL_WIDTH, $THUMBNAIL_HEIGHT) = (160, 90);

# コミット時のコメント
our $COMMIT_COMMENT = "auto commit from Sorauta::SVN::AutoCommit";

# コミットするか否か
our $DEBUG = 0;

__PACKAGE__->mk_accessors(
  qw/svn_mode work_dir_path debug thumbnail_width thumbnail_height changes commit_comment/);

#==========================================
# コミットを実行
# req:
# res:
#==========================================
sub execute {
  my $self = shift;

  if (!$self->thumbnail_width) {
    $self->thumbnail_width($THUMBNAIL_WIDTH);
  }
  if (!$self->thumbnail_height) {
    $self->thumbnail_height($THUMBNAIL_HEIGHT);
  }
  if (!$self->commit_comment) {
    $self->commit_comment($COMMIT_COMMENT);
  }

  # must be defined accessors
  if (!$self->svn_mode || !$self->work_dir_path) {
    die 'must be define accessor svn_mode(auto_commit|update), work_dir_path(/Users/user/Desktop/svn_work_folder)';
  }

  # set svn agent
  my $sa;
  if ($self->debug) {
    $sa = SVN::Agent::Dummy->load({
      path => $self->work_dir_path
    });
  }
  else {
    $sa = SVN::Agent->load({
      path => $self->work_dir_path
    });
  }
  #print Dumper($sa);

  # execute command
  if ($self->svn_mode eq 'auto_commit') {
    $self->_auto_commit($sa);
  }
  elsif ($self->svn_mode eq 'update') {
    $self->update($sa);
  }
  else {
    die 'must be define svn_mode(auto_commit|update)';
  }
}

#==========================================
# 自動コミットを実行
#   TortoiseSVNの画面で全てチェック入れてコミットするイメージ
# req:
#   sa: SVN::Agent(or SVN::Agent::Dummy)のインスタンス
# res:
#   result: updateした結果
#==========================================
sub _auto_commit {
  my($self, $sa) = @_;

  # show files before commit
  $self->_show($sa);

  # add unknown files to commit file
  $self->_add_unknown_files($sa);

  # scheduling missing file to delete file
  $self->_remove_missing_files($sa);

  # show changed files
  print $sa->prepare_changes, $/;
  my @changes_files = @{ $sa->changes };
  if (scalar(@changes_files) > 0) {
    $self->changes(1);
  }

  # execute commit
  print "[commit]", $/;
  unless ($self->debug) {
    if ($self->changes) {
      print $sa->commit($self->commit_comment);
    }
    else {
      print "the file which should commit does not exist. ", $/;
    }
  }
  else {
    print "this is debug mode.", $/;
  }
  print $/;

  # update latest revision
  $self->_update($sa);
}

#==========================================
# アップデートを実行
# req:
#   sa: SVN::Agentのインスタンス
# res:
#   result: updateした結果
#==========================================
sub _update {
  my($self, $sa) = @_;

  print "[update]", $/;
  print $sa->update;
}

#==========================================
# 削除されたファイル等、コミット前の状態を表示
# req:
#   sa: SVN::Agentのインスタンス
# res:
#   result: null
#==========================================
sub _show {
  my($self, $sa) = @_;

  # find out unknown files
  my @unknown_files = @{ $sa->unknown };
  print "====== unknown(will add)", $/;
  print join($/, @unknown_files), $/, $/;

  # find out missing files
  my @missing_files = @{ $sa->missing };
  print "====== missing(will remove)", $/;
  print join($/, @missing_files), $/, $/;

  # find out modified files
  my @modified_files = @{ $sa->modified };
  print "====== modified", $/;
  print join($/, @modified_files), $/, $/;

  # find out deleted files
  my @deleted_files = @{ $sa->deleted };
  print "====== deleted", $/;
  print join($/, @deleted_files), $/, $/;

  # 変更がある場合、変更フラグ(changes)をたてておく
  if (scalar(@modified_files) > 0 || scalar(@deleted_files) > 0) {
    $self->changes(1);
  }
}

#==========================================
# SVN未登録のファイルをコミットするようにスケジューリング
# req:
#   sa: SVN::Agentのインスタンス
# res:
#   result: null
#==========================================
sub _add_unknown_files {
  my($self, $sa) = @_;

  my @unknown_files = @{$sa->unknown};
  foreach my $unknown_file(@unknown_files) {
    if (is_hidden_file($unknown_file)) {
      print $unknown_file, " ... Skip.", $/;
      next;
    }

    # ファイルパスをエスケープ
    $unknown_file = _escape($unknown_file);
    #print "scheduling:", $$self->work_dir_path.'/'.$unknown_file, $/;
    print $sa->add($unknown_file);

    # if unknown file is directory,
    # recrusive add including files
    my $d_path = cat($self->work_dir_path, $unknown_file);
    if (-d $d_path) {
      # create thumbnail directory
      my @mathed_pattern = split(/\\/, $unknown_file);
      my $abs_dir_path = cat($$self->work_dir_path, 'thumbnail', $mathed_pattern[0], $mathed_pattern[1]);
      if (!($unknown_file =~ /thumbnail/)) {
        unless (-d $abs_dir_path) {
            mkdir($abs_dir_path);
            print $sa->add($abs_dir_path);
          }

          #print "\t $d_path is dir", $/;
          opendir my($D), $d_path;
          foreach my $file(readdir($D)) {
            next if is_hidden_file($file);

            # ファイルパスをエスケープ
            $file = _escape($file);

            my $new_unknown_file = cat($unknown_file, $file);
            #print "[add]", $new_unknown_file, $/;
            print $sa->add($new_unknown_file);

            # add thumbnail image
            if ($new_unknown_file =~ /^([\w\_\-]+)\\([0-9]+)\\([\w\_\.]+)/) {
              my($type, $id_or_jan_code, $file_name) = ($1, $2, $3);
              my $abs_dir_path = cat($$self->work_dir_path, 'thumbnail', $type, $id_or_jan_code);

              $self->_create_thumbnail_image(
                $sa,
                cat($self->work_dir_path, $new_unknown_file),
                cat($abs_dir_path, $file_name));
            }
          }
          close $D;
      }
    }
    else {
      # add thumbnail image
      if ($unknown_file =~ /^([\w\_\-]+)\\([0-9]+)\\([\w\_\.]+)/) {
          my($type, $id_or_jan_code, $file_name) = ($1, $2, $3);
          my $abs_dir_path = cat($$self->work_dir_path, 'thumbnail', $type, $id_or_jan_code);

          $self->_create_thumbnail_image(
            $sa,
            cat($self->work_dir_path, $unknown_file),
            cat($abs_dir_path, $file_name));
      }
    }
  }
}

#==========================================
# SVNに登録済みだがローカルに存在しない場合削除するようにスケジューリング
# req:
#   sa: SVN::Agentのインスタンス
# res:
#   result: null
#==========================================
sub _remove_missing_files {
  my($self, $sa) = @_;

  my @missing_files = @{$sa->missing};
  foreach my $missing_file(@missing_files) {
    next if is_hidden_file($missing_file);

    # ファイルパスをエスケープ
    $missing_file = _escape($missing_file);

    $sa->remove($missing_file);

    # サムネイル画像も削除
    if ($missing_file =~ /^([\w\_\-]+)\\([0-9]+)\\([\w\_\.]+)/) {
      my($type, $id_or_jan_code, $file_name) = ($1, $2, $3);

      # ファイルパスをエスケープ
      $file_name = _escape($file_name);

      my $dir_path = cat($$self->work_dir_path, 'thumbnail', $type, $id_or_jan_code);
      if (-e cat($dir_path, $file_name)) {
        $sa->remove(cat($dir_path, $file_name));
      }
    }
  }
}

#==========================================
# サムネイルを生成する
# req:
#   sa: SVN::Agentのインスタンス
#   original_file_path: 元ファイルのパス
#   thumbnail_file_path: サムネイルファイルのパス
# res:
#   result: null
#==========================================
sub _create_thumbnail_image {
  my($self, $sa, $original_file_path, $thumbnail_file_path) = @_;
  my $image = Image::Magick->new;

  # 元画像を読み込む
  print $image->Read(
    $original_file_path
  );

  # タテヨコ比率指定
  print $image->Resize(
    geometry => $self->thumbnail_width.'x'.$self->thumbnail_height
  );

  # ファイル保存
  print $image->Write(
    filename    => $thumbnail_file_path,
    compression => 'None'
  );

  # 追加する
  print $sa->add($thumbnail_file_path);
}

#==========================================
# ファイル等をエスケープ
# req:
#   file_str: ファイル文字列
# res:
#   file_str: エスケープ後のファイル文字列
#==========================================
sub _escape {
  return quotemeta(shift);
}

1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sorauta::SVN::AutoCommit - auto recognize new file and deleted file, and commit those files

=head1 SYNOPSIS

  use Sorauta::SVN::AutoCommit;

  my $SVN_MODE = "auto_commit";
  my $SVN_WORK_DIR = "/Users/user/Desktop/svn_dir";
  my $DEBUG = 0;

  my $ssa = Sorauta::SVN::AutoCommit->new({
    svn_mode      => $SVN_MODE,
    work_dir_path => $SVN_WORK_DIR,
    debug         => $DEBUG,
  });

  #print $ssa;
  $ssa->execute();

=head1 DESCRIPTION

auto recognize new file and deleted file, and commit those files.

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
