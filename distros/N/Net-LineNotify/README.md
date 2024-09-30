# Net::LineNotify

`Net::LineNotify` は、LINE Notify APIを使用してLINEに通知を送信するための簡単なPerlモジュールです。このモジュールを使うことで、Perlスクリプトから手軽にLINEへメッセージを送信できます。

## インストール

このモジュールをインストールするには、標準のPerlモジュールのインストール手順を使用します。リポジトリをクローンするか、パッケージをダウンロードしてから、以下のコマンドを実行してください。

```bash
perl Makefile.PL
make
make test
make install
```

## 使い方

モジュールをインストールした後、アクセストークンを指定することでLINEに通知を送信できます。

### 使用例

```perl
use Net::LineNotify;

# Net::LineNotifyオブジェクトの作成
my $line = Net::LineNotify->new(access_token => 'YOUR_ACCESS_TOKEN');

# メッセージを送信
$line->send_message('PerlからのLINE通知です！');
```

### パラメータ

- `access_token`: [LINE Notify](https://notify-bot.line.me/) から取得したアクセストークン。
- `message`: 送信したいメッセージ（最大1000文字まで）。

## LINE Notify アクセストークンの取得

このモジュールを使用するには、LINE Notifyのアクセストークンが必要です。以下の手順でトークンを取得してください。

1. [LINE Notifyウェブサイト](https://notify-bot.line.me/my/)にアクセスし、LINEアカウントでログインします。
2. 「トークンを発行する」をクリックして、指示に従います。
3. 発行されたアクセストークンをコピーし、Perlスクリプトで使用してください。

## メソッド

### `new`

```perl
my $line = Net::LineNotify->new(access_token => 'YOUR_ACCESS_TOKEN');
```

`Net::LineNotify` オブジェクトを作成します。`access_token` は必須で、APIリクエストを認証するために使用されます。

### `send_message`

```perl
$line->send_message('ここにメッセージを入力');
```

LINEアカウントにメッセージを送信します。`access_token` で認証されたアカウントに通知が届きます。

## 依存モジュール

このモジュールは以下の依存モジュールを必要とします。

- `LWP::UserAgent`
- `HTTP::Request::Common`

これらのモジュールはCPANからインストール可能です。

```bash
cpan install LWP::UserAgent HTTP::Request::Common
```

## 作者

Kawamura Shingo <pannakoota@gmail.com>

## ライセンス

このライブラリはフリーソフトウェアです。Perlの同じ条件の下で再配布および修正が可能です。詳細については [PerlのArtisticライセンス](https://dev.perl.org/licenses/artistic.html) を参照してください。

