##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Status.pm
## Version v0.200.1
## Copyright(c) 2019 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <@sitael.tokyo.deguest.jp>
## Created 2019/12/15
## Modified 2020/05/16
## 
##----------------------------------------------------------------------------
package Net::API::REST::Status;
BEGIN
{
    use strict;
    use common::sense;
    use Apache2::Const -compile => qw( :http );
    use Apache2::RequestUtil;
    our $VERSION = 'v0.200.1';
};

{
    use utf8;
    our $CODES =
    {
    ## Info 1xx
    100 => Apache2::Const::HTTP_CONTINUE,
    101 => Apache2::Const::HTTP_SWITCHING_PROTOCOLS,
    102 => Apache2::Const::HTTP_PROCESSING,
    ## Success 2xx
    200 => Apache2::Const::HTTP_OK,
    201 => Apache2::Const::HTTP_CREATED,
    202 => Apache2::Const::HTTP_ACCEPTED,
    203 => Apache2::Const::HTTP_NON_AUTHORITATIVE,
    204 => Apache2::Const::HTTP_NO_CONTENT,
    205 => Apache2::Const::HTTP_RESET_CONTENT,
    206 => Apache2::Const::HTTP_PARTIAL_CONTENT,
    207 => Apache2::Const::HTTP_MULTI_STATUS,
    ## Redirect 3xx
    300 => Apache2::Const::HTTP_MULTIPLE_CHOICES,
    301 => Apache2::Const::HTTP_MOVED_PERMANENTLY,
    302 => Apache2::Const::HTTP_MOVED_TEMPORARILY,
    303 => Apache2::Const::HTTP_SEE_OTHER,
    304 => Apache2::Const::HTTP_NOT_MODIFIED,
    305 => Apache2::Const::HTTP_USE_PROXY,
    307 => Apache2::Const::HTTP_TEMPORARY_REDIRECT,
    ## Client error 4xx
    400 => Apache2::Const::HTTP_BAD_REQUEST,
    401 => Apache2::Const::HTTP_UNAUTHORIZED,
    402 => Apache2::Const::HTTP_PAYMENT_REQUIRED,
    403 => Apache2::Const::HTTP_FORBIDDEN,
    404 => Apache2::Const::HTTP_NOT_FOUND,
    405 => Apache2::Const::HTTP_METHOD_NOT_ALLOWED,
    406 => Apache2::Const::HTTP_NOT_ACCEPTABLE,
    407 => Apache2::Const::HTTP_PROXY_AUTHENTICATION_REQUIRED,
    408 => Apache2::Const::HTTP_REQUEST_TIME_OUT,
    409 => Apache2::Const::HTTP_CONFLICT,
    410 => Apache2::Const::HTTP_GONE,
    411 => Apache2::Const::HTTP_LENGTH_REQUIRED,
    412 => Apache2::Const::HTTP_PRECONDITION_FAILED,
    413 => Apache2::Const::HTTP_REQUEST_ENTITY_TOO_LARGE,
    414 => Apache2::Const::HTTP_REQUEST_URI_TOO_LARGE,
    415 => Apache2::Const::HTTP_UNSUPPORTED_MEDIA_TYPE,
    416 => Apache2::Const::HTTP_RANGE_NOT_SATISFIABLE,
    417 => Apache2::Const::HTTP_EXPECTATION_FAILED,
    #W WebDAV
    422 => Apache2::Const::HTTP_UNPROCESSABLE_ENTITY,
    ## WebDAV
    423 => Apache2::Const::HTTP_LOCKED,
    ## WebDAV
    424 => Apache2::Const::HTTP_FAILED_DEPENDENCY,
    426 => Apache2::Const::HTTP_UPGRADE_REQUIRED,
    ## Server error 5xx
    500 => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR,
    501 => Apache2::Const::HTTP_NOT_IMPLEMENTED,
    502 => Apache2::Const::HTTP_BAD_GATEWAY,
    503 => Apache2::Const::HTTP_SERVICE_UNAVAILABLE,
    504 => Apache2::Const::HTTP_GATEWAY_TIME_OUT,
    506 => Apache2::Const::HTTP_VARIANT_ALSO_VARIES,
    ## WebDAV
    507 => Apache2::Const::HTTP_INSUFFICIENT_STORAGE,
    510 => Apache2::Const::HTTP_NOT_EXTENDED,
    };

    our $HTTP_CODES =
    {
    'fr_FR' =>
        {
        100 => "Continuer",
        101 => "Changement de protocole",
        102 => "En traitement",
        200 => "OK",
        201 => "Créé",
        202 => "Accepté",
        203 => "Information non certifiée",
        204 => "Pas de contenu",
        205 => "Contenu réinitialisé",
        206 => "Contenu partiel",
        207 => "Multi-Status",
        208 => "Déjà rapporté",
        226 => "IM Used",
        300 => "Choix multiples",
        301 => "Changement d'adresse définitif",
        302 => "Changement d'adresse temporaire",
        303 => "Voir ailleurs",
        304 => "Non modifié",
        305 => "Utiliser le proxy",
        307 => "Redirection temporaire",
        308 => "Redirection permanente",
        400 => "Mauvaise requête",
        401 => "Non autorisé",
        402 => "Paiement exigé",
        403 => "Interdit",
        404 => "Non trouvé",
        405 => "Méthode non autorisée",
        406 => "Aucun disponible",
        407 => "Authentification proxy exigée",
        408 => "Requête hors-délai",
        409 => "Conflit",
        410 => "Parti",
        411 => "Longueur exigée",
        412 => "Précondition échouée",
        413 => "Corps de requête trop grand",
        414 => "URI trop long",
        415 => "Format non supporté",
        416 => "Plage demandée invalide",
        417 => "Comportement erroné",
        418 => "I'm a teapot",
        421 => "Requête mal dirigée",
        422 => "Entité intraitable",
        423 => "Vérouillé",
        424 => "Dépendence échouée",
        426 => "Mis-à-jour requise",
        428 => "Précondition requise",
        429 => "Trop de requête",
        431 => "Champs d'entête de la requête trop large",
        444 => "Connexion clôturée sans réponse",
        451 => "Indisponible pour des raisons légales",
        499 => "Le client a terminé la requête",
        500 => "Erreur interne du serveur",
        501 => "Non implémenté",
        502 => "Mauvais intermédiaire",
        503 => "Service indisponible",
        504 => "Intermédiaire hors-délai",
        505 => "Version HTTP non supportée",
        506 => "Variant Also Negotiates",
        507 => "Stoquage insuffisant",
        508 => "Boucle detectée",
        509 => "Limite de bande passante dépassée",
        510 => "Pas étendu",
        511 => "Autentification réseau requise",
        599 => "Erreur de timeout connexion réseau",
        },
    'en_GB' => 
        {
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",
        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        208 => "Already Reported",
        226 => "IM Used",
        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary Redirect",
        308 => "Permanent Redirect",
        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Payload Too Large",
        414 => "Request-URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Requested Range Not Satisfiable",
        417 => "Expectation Failed",
        418 => "I'm a teapot",
        421 => "Misdirected Request",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        426 => "Upgrade Required",
        428 => "Precondition Required",
        429 => "Too Many Requests",
        431 => "Request Header Fields Too Large",
        444 => "Connection Closed Without Response",
        451 => "Unavailable For Legal Reasons",
        499 => "Client Closed Request",
        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        506 => "Variant Also Negotiates",
        507 => "Insufficient Storage",
        508 => "Loop Detected",
        509 => "Bandwidth Limit Exceeded",
        510 => "Not Extended",
        511 => "Network Authentication Required",
        599 => "Network Connect Timeout Error",
        },
    'ja_JP' =>
        {
        100 => "継続",
        101 => "プロトコル切替",
        102 => "処理中",
        200 => "成功",
        201 => "作成完了",
        202 => "受理",
        203 => "信頼できない情報",
        204 => "内容なし",
        205 => "内容をリセット",
        206 => "部分的内容",
        207 => "複数のステータス",
        208 => "既に報告",
        226 => "IM使用",
        300 => "複数の選択",
        301 => "恒久的に移動した",
        302 => "発見した",
        303 => "他を参照せよ",
        304 => "未更新",
        305 => "プロキシを使用せよ",
        307 => "一時的リダイレクト",
        308 => "恒久的リダイレクト",
        400 => "リクエストが不正である",
        401 => "認証が必要である",
        402 => "支払いが必要である",
        403 => "禁止されている",
        404 => "未検出",
        405 => "許可されていないメソッド",
        406 => "受理できない",
        407 => "プロキシ認証が必要である",
        408 => "リクエストタイムアウト",
        409 => "競合",
        410 => "消滅した",
        411 => "長さが必要",
        412 => "前提条件で失敗した",
        413 => "ペイロードが大きすぎる",
        414 => "URIが大きすぎる",
        415 => "サポートしていないメディアタイプ",
        416 => "レンジは範囲外にある",
        417 => "Expectヘッダによる拡張が失敗",
        418 => "私はティーポット",
        421 => "誤ったリクエスト",
        422 => "処理できないエンティティ",
        423 => "ロックされている",
        424 => "依存関係で失敗",
        426 => "アップグレード要求",
        428 => "条件付きリクエストを要求",
        429 => "リクエスト過大で拒否した",
        431 => "ヘッダサイズが過大",
        444 => "Connection Closed Without Response",
        451 => "法的理由により利用不可",
        499 => "Client Closed Request",
        500 => "サーバ内部エラー",
        501 => "実装されていない",
        502 => "不正なゲートウェイ",
        503 => "サービス利用不可",
        504 => "ゲートウェイタイムアウト",
        505 => "サポートしていないHTTPバージョン",
        506 => "Variant Also Negotiates",
        507 => "容量不足",
        508 => "ループを検出",
        509 => "帯域幅制限超過",
        510 => "拡張できない",
        511 => "ネットワーク認証が必要",
        599 => "ネットワーク接続タイムアウトエラー",
        }
    };
}

sub init
{
    my $self = shift( @_ );
    my $r = shift( @_ );
    $self->SUPER::init( @_ );
    return( $self );
}

sub is_info         { $_[ 1 ] >= 100 && $_[ 1 ] < 200; }
sub is_success      { $_[ 1 ] >= 200 && $_[ 1 ] < 300; }
sub is_redirect     { $_[ 1 ] >= 300 && $_[ 1 ] < 400; }
sub is_error        { $_[ 1 ] >= 400 && $_[ 1 ] < 600; }
sub is_client_error { $_[ 1 ] >= 400 && $_[ 1 ] < 500; }
sub is_server_error { $_[ 1 ] >= 500 && $_[ 1 ] < 600; }

## Returns a status line for a given code
## e.g. status_message( 404 ) would yield "Not found"
## sub status_message { return( Apache2::RequestUtil::get_status_line( $_[1] ) ); }
sub status_message
{
    my $self = shift( @_ );
    my( $code, $lang );
    if( scalar( @_ ) == 2 )
    {
        ( $code, $lang ) = @_;
    }
    else
    {
        $code = shift( @_ );
        $lang = 'en_GB';
    }
    $lang = 'en_GB' if( !exists( $HTTP_CODES->{ $lang } ) );
    my $ref = $HTTP_CODES->{ $lang };
    return( $ref->{ $code } );
}

1;

__END__

