#============================================
# SVN自動アップデートクラス
#   updateだと競合するので、毎度ファイルを削除してcheckoutするようにしている
# -------------------------------------------
# アクセサ
# repository_url        String         リポジトリへのURL
#                                               http://svn_url/repository_path
# work_dir_path         String         作業フォルダまでのパス
#                                               ex)c:\batch\images
# tmp_dir_path          String         SVNの最新版をチェックアウトするテンポラリフォルダ
# os                    String         OSの種類
#                                               Win ... windows
#                                               Mac ... mac os
# debug                 Integer        デバッグモード
#                                               0 ... コミットする(デフォルト)
#                                               1 ... リストの列挙などはやるが、コミット自体はしない
#============================================
package Sorauta::SVN::Updater;
use base qw/Class::Accessor::Fast/;

use strict;
use warnings;
use utf8;
use CGI::Carp qw/fatalsToBrowser/;
use Data::Dumper;
use SVN::Agent;
use SVN::Agent::Dummy;
use File::Copy::Recursive qw/dircopy/;
use Sorauta::Utility;

our $VERSION = '0.01';

__PACKAGE__->mk_accessors(
  qw/repository_url work_dir_path tmp_dir_path os debug/);

#==========================================
# SVNのアップデートを実行
# req:
# res:
#   result: 成功の時は1、失敗時はそれ以外
#==========================================
sub execute {
  my $self = shift;

  # must be defined accessors
  if (!$self->work_dir_path || !$self->os || !$self->repository_url || !$self->tmp_dir_path) {
    die 'must be define accessor work_dir_path(/Users/yuki/Desktop/svn_work_folder), os(Win|Mac), '.
        'repository_url(http://svn_url/repository_path/), tmp_dir_path(/tmp/dir_path/)';
  }

  # set svn agent
  my $sa;
  my $tmp_dir_path = $self->tmp_dir_path;
  if ($self->debug) {
    $sa = SVN::Agent::Dummy->new({
      path => $tmp_dir_path
    });
  }
  else {
    $sa = SVN::Agent->new({
      path => $tmp_dir_path
    });
  }
  #print Dumper($sa);

  # remove tmp_dir
  if ($self->os eq 'Win') {
    system("del", "/q", $tmp_dir_path);
  }
  elsif ($self->os eq 'Mac') {
    my $cmd = "rm -rf $tmp_dir_path";
    `$cmd`;
  }

  # execute command
  print $sa->checkout($self->repository_url);

  # remove .svn folders
  if ($self->os eq 'Win') {
    # TODO: system("del", "/q", $destination_path);
    print "[warnings]remove .svn folders for Win";
  }
  elsif ($self->os eq 'Mac') {
    my $cmd = "cd $tmp_dir_path; rm -rf \$(find ./ -name \".svn\")";
    `$cmd`;
  }

  # copy checkout files to www folder
  $File::Copy::Recursive::CPRFComp = 1;
  dircopy($tmp_dir_path.'*', $self->work_dir_path);

  return 1;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Sorauta::SVN::Updater - svn updater

=head1 SYNOPSIS
  use Sorauta::SVN::Updater;

  my $WORK_DIR_PATH = '/Users/user/Desktop/hogehoge';
  my $OS = "Mac"; # or Win
  my $REPOSITORY_URL = 'http://svn_url/path/to';
  my $TMP_DIR_PATH = '/Users/user/Desktop/hogehoge_tmp';
  my $DEBUG = 1;

  # svn update test
  {
    Sorauta::SVN::Updater->new({
      os                    => $OS,
      repository_url        => $REPOSITORY_URL,
      work_dir_path         => $WORK_DIR_PATH,
      tmp_dir_path          => $TMP_DIR_PATH,
      debug                 => $DEBUG,
    })->execute;
  }

=head1 DESCRIPTION

svn updater

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
