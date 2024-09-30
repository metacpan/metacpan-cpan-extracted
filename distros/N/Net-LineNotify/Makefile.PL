use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Net::LineNotify',
    VERSION_FROM => 'lib/Net/LineNotify.pm', # バージョン番号を取得するファイル
    PREREQ_PM    => {
        'LWP::UserAgent' => 0,               # 依存モジュール
        'HTTP::Request::Common' => 0,        
    },
    ABSTRACT     => 'A simple wrapper for LINE Notify API',
    AUTHOR       => 'Kawamura Shingo <pannakoota@gmail.com>',
    dist         => {
        COMPRESS => 'gzip -9f',  # 圧縮コマンド
        SUFFIX   => 'gz',        # 圧縮後のファイル拡張子
        DIST_DEFAULT => 'all tardist',  # デフォルトのターゲット
    },
);

