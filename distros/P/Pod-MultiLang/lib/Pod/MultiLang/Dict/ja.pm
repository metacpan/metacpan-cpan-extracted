## ----------------------------------------------------------------------------
#  Pod::MultiLang::Dict::ja
# -----------------------------------------------------------------------------
# Mastering programed by YAMASHINA Hio
#
# Copyright 2003 YMIRLINK,Inc.
# -----------------------------------------------------------------------------
# $Id: /perl/Pod-MultiLang/lib/Pod/MultiLang/Dict/ja.pm 216 2006-11-14T15:01:52.545337Z hio  $
# -----------------------------------------------------------------------------
package Pod::MultiLang::Dict::ja;
use strict;
use vars qw($VERSION);
BEGIN{
$VERSION = '0.01';
}

# -----------------------------------------------------------------------------
# $pkg->static_table()
#   簡単なマッピングテーブル
#
sub static_table
{
  {
   'TABLE OF CONTENTS' => '目次',
   'NAME'         => '名前',
   'SYNOPSIS'     => '概要', # (書式)
   'DESCRIPTION'  => '説明',
   'SEE ALSO'     => '関連項目',
   'BUG'          => 'バグ',
   'AUTHOR'       => '著者',
   'COPYRIGHT'    => '著作権',
   'INDEX'        => '索引',
   
   'ABSTRACT'     => '要約',
   'ACKNOWLEDGEMENTS' => '謝辞',
   'AND'          => '及び',
   'APPENDIX'     => '付録',
   'ARGUMENTS'    => '引数',
   'CALLBACKS'    => 'コールバック',
   'CAVEATS'      => '警告',
   'CHANGES'      => '変更点',
   'CONSTRUCTOR'  => 'コンストラクタ',
   'COPYRIGHT'    => '著作権',
   'DEPENDENCIES' => '依存',
   'ENVIRONMENT'  => '環境',
   'ENVIRONMENT VARIABLES'  => '環境変数',
   'EVENTS'       => 'イベント',
   'EXAMPLE'      => '例',
   'EXPORTS'      => 'エクスポート',
   'FEATURES'     => '機能',
   'FILES'        => 'ファイル',
   'FUNCTIONS'    => '関数',
   'HISTORY'      => '履歴',
   'INSTALL'      => 'インストール',
   'INSTALLATION' => 'インストール',
   'LICENSE'      => 'ライセンス',
   'LIMITATION'   => '制限',
   'METHODS'      => 'メソッド',
   'NOTES'        => '留意事項',
   'OPTIONS'      => 'オプション',
   'REQUIREMENTS' => '依存',
   'REQUIRES'     => '依存',
   'SUMMARY'      => '要約',
   'SUPPORT'      => 'サポート',
   'SYNTAX'       => '構文',
   'TO DO'        => '今後の予定',
   'TODO'         => '今後の予定',
   'USAGE'        => '使用方法',
   'VERSION'      => 'バージョン',
   'WARNING'      => '警告',
 };
}

# -----------------------------------------------------------------------------
# $pkg->make_linktext($lang,$name,$section)
#   ラベルを持たない L<name/section> のラベル付け
#
sub make_linktext
{
  my ($pkg,$lang,$name,$section) = @_;
  $name
    ? $section ? qq($name 内 "$section") : $name
    : $section ? qq("$section") : undef;
}

1;
__END__
# -----------------------------------------------------------------------------
# End of File.
# -----------------------------------------------------------------------------
