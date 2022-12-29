##----------------------------------------------------------------------------
## REST API Framework - ~/lib/Net/API/REST/Status.pm
## Version v0.200.3
## Copyright(c) 2021 DEGUEST Pte. Ltd.
## Author: Jacques Deguest <jack@deguest.jp>
## Created 2019/12/15
## Modified 2022/06/29
## All rights reserved
## 
## This program is free software; you can redistribute  it  and/or  modify  it
## under the same terms as Perl itself.
##----------------------------------------------------------------------------
package Net::API::REST::Status;
BEGIN
{
    use strict;
    use warnings;
    use common::sense;
    use parent qw( Module::Generic );
    use vars qw( $CODES $HTTP_CODES $MAP_LANG_SHORT );
    use Apache2::Const -compile => qw( :http );
    use Apache2::RequestUtil;
    our $VERSION = 'v0.200.3';
};

use strict;
use warnings;

use utf8;
# Ref:
# <https://datatracker.ietf.org/doc/html/rfc7231#section-8.2>
# <http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>
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
208 => Apache2::Const::HTTP_ALREADY_REPORTED,
226 => Apache2::Const::HTTP_IM_USED,
## Redirect 3xx
300 => Apache2::Const::HTTP_MULTIPLE_CHOICES,
301 => Apache2::Const::HTTP_MOVED_PERMANENTLY,
302 => Apache2::Const::HTTP_MOVED_TEMPORARILY,
303 => Apache2::Const::HTTP_SEE_OTHER,
304 => Apache2::Const::HTTP_NOT_MODIFIED,
305 => Apache2::Const::HTTP_USE_PROXY,
307 => Apache2::Const::HTTP_TEMPORARY_REDIRECT,
308 => Apache2::Const::HTTP_PERMANENT_REDIRECT,
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
# 421 => Apache2::Const::HTTP_MISDIRECTED_REQUEST,
#W WebDAV
422 => Apache2::Const::HTTP_UNPROCESSABLE_ENTITY,
## WebDAV
423 => Apache2::Const::HTTP_LOCKED,
## WebDAV
424 => Apache2::Const::HTTP_FAILED_DEPENDENCY,
426 => Apache2::Const::HTTP_UPGRADE_REQUIRED,
428 => Apache2::Const::HTTP_PRECONDITION_REQUIRED,
429 => Apache2::Const::HTTP_TOO_MANY_REQUESTS,
431 => Apache2::Const::HTTP_REQUEST_HEADER_FIELDS_TOO_LARGE,
# 451 => Apache2::Const::HTTP_UNAVAILABLE_FOR_LEGAL_REASONS,
## Server error 5xx
500 => Apache2::Const::HTTP_INTERNAL_SERVER_ERROR,
501 => Apache2::Const::HTTP_NOT_IMPLEMENTED,
502 => Apache2::Const::HTTP_BAD_GATEWAY,
503 => Apache2::Const::HTTP_SERVICE_UNAVAILABLE,
504 => Apache2::Const::HTTP_GATEWAY_TIME_OUT,
506 => Apache2::Const::HTTP_VARIANT_ALSO_VARIES,
## WebDAV
507 => Apache2::Const::HTTP_INSUFFICIENT_STORAGE,
508 => Apache2::Const::HTTP_LOOP_DETECTED,
510 => Apache2::Const::HTTP_NOT_EXTENDED,
511 => Apache2::Const::HTTP_NETWORK_AUTHENTICATION_REQUIRED,
};

our $HTTP_CODES =
{
# Ref: <https://developer.mozilla.org/de/docs/Web/HTTP/Status/100>
# <https://www.dotcom-monitor.com/wiki/de/knowledge-base/http-status-codes/>
'de_DE' =>
    {
    100 => "Weiter",
    101 => "Protokolle wechseln",
    102 => "Verarbeitung",
    103 => "Frühe Hinweise",
    200 => "OK",
    201 => "Erstellt",
    202 => "Akzeptiert",
    203 => "Nicht autorisierende Informationen",
    204 => "Kein Inhalt",
    205 => "Inhalt zurücksetzen",
    206 => "Teilinhalt",
    207 => "Multi-Status",
    208 => "Bereits gemeldet",
    226 => "IM verwendet",
    300 => "Mehrfachauswahlmöglichkeiten",
    301 => "Dauerhaft verschoben",
    302 => "Gefunden",
    303 => "Andere sehen",
    304 => "Nicht geändert",
    305 => "Proxy verwenden",
    307 => "Temporäre Weiterleitung",
    308 => "Permanente Weiterleitung",
    400 => "Schlechte Anfrage",
    401 => "Nicht autorisiert",
    402 => "Zahlung erforderlich",
    403 => "Verboten",
    404 => "Nicht gefunden",
    405 => "Methode nicht erlaubt",
    406 => "Nicht akzeptabel",
    407 => "Proxy-Authentifizierung erforderlich",
    408 => "Anfrage timeout",
    409 => "Konflikt",
    410 => "Gegangen",
    411 => "Länge erforderlich",
    412 => "Vorbedingung fehlgeschlagen",
    413 => "Nutzlast zu groß",
    414 => "Anfrage-URI zu lang",
    415 => "Nicht unterstützter Medientyp",
    416 => "Reichweite nicht erfüllbar",
    417 => "Erwartung fehlgeschlagen",
    418 => "Ich bin eine Teekanne",
    421 => "Fehlgeleitete Anfrage",
    422 => "Nicht verarbeitbare Entität",
    423 => "Gesperrt",
    424 => "Fehlgeschlagene Abhängigkeit",
    425 => "Zu früh",
    426 => "Upgrade erforderlich",
    428 => "Vorbedingung erforderlich",
    429 => "Zu viele Anfragen",
    431 => "Headerfelder zu groß anfordern",
    444 => "Verbindung ohne Antwort geschlossen",
    451 => "Aus rechtlichen Gründen nicht verfügbar",
    499 => "Client die Verbindung schließt",
    500 => "Interner Serverfehler",
    501 => "Nicht implementiert",
    502 => "Schlechtes Gateway",
    503 => "Dienst nicht verfügbar",
    504 => "Gateway-Zeitüberschreitung",
    505 => "HTTP-Version nicht unterstützt",
    506 => "Variante verhandelt auch",
    507 => "Unzureichende Lagerung",
    508 => "Schleife erkannt",
    509 => "Bandbreitenlimit überschritten",
    510 => "Nicht erweitert",
    511 => "Netzwerkauthentifizierung erforderlich",
    599 => "Timeout-Fehler bei Netzwerkverbindung",
    },
'en_GB' => 
    {
    100 => "Continue",
    101 => "Switching Protocols",
    102 => "Processing",
    103 => "Early Hints",
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
    ## Humour: April's fool
    ## <https://en.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol>
    418 => "I'm a teapot",
    421 => "Misdirected Request",
    422 => "Unprocessable Entity",
    423 => "Locked",
    424 => "Failed Dependency",
    425 => "Too Early",
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
'fr_FR' =>
    {
    100 => "Continuer",
    101 => "Changement de protocole",
    102 => "En traitement",
    103 => "Premiers indices",
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
    406 => "Pas acceptable",
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
    ## Humour; poisson d'avril
    ## <https://fr.wikipedia.org/wiki/Hyper_Text_Coffee_Pot_Control_Protocol>
    418 => "Je suis une théière",
    421 => "Requête mal dirigée",
    422 => "Entité intraitable",
    423 => "Vérouillé",
    424 => "Dépendence échouée",
    425 => "Trop tôt",
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
'ja_JP' =>
    {
    100 => "継続",
    101 => "プロトコル切替",
    102 => "処理中",
    103 => "早期のヒント",
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
    425 => "早期すぎ",
    426 => "アップグレード要求",
    428 => "条件付きリクエストを要求",
    429 => "リクエスト過大で拒否した",
    431 => "ヘッダサイズが過大",
    444 => "応答なしで接続が閉じられました",
    451 => "法的理由により利用不可",
    499 => "クライアントによるリクエストの終了",
    500 => "サーバ内部エラー",
    501 => "実装されていない",
    502 => "不正なゲートウェイ",
    503 => "サービス利用不可",
    504 => "ゲートウェイタイムアウト",
    505 => "サポートしていないHTTPバージョン",
    506 => "バリアントもコンテンツネゴシエーションを行う",
    507 => "容量不足",
    508 => "ループを検出",
    509 => "帯域幅制限超過",
    510 => "拡張できない",
    511 => "ネットワーク認証が必要",
    599 => "ネットワーク接続タイムアウトエラー",
    },
## Ref: <https://developer.mozilla.org/ko/docs/Web/HTTP/Status>
## <https://ko.wikipedia.org/wiki/HTTP_%EC%83%81%ED%83%9C_%EC%BD%94%EB%93%9C>
## <http://wiki.hash.kr/index.php/HTTP>
'ko_KR'=>
    {
    100 => "계속",
    101 => "스위칭 프로토콜",
    102 => "처리 중",
    103 => "사전로딩",
    200 => "확인",
    201 => "만든",
    202 => "수락",
    203 => "비 권한 정보",
    204 => "내용 없음",
    205 => "콘텐츠 재설정",
    206 => "부분적인 내용",
    207 => "다중 상태",
    208 => "이미보고",
    226 => "IM 사용",
    300 => "다중 선택",
    301 => "영구 이동",
    302 => "발견",
    303 => "다른 참조",
    304 => "수정되지 않음",
    305 => "프록시 사용",
    307 => "임시 리디렉션",
    308 => "영구 리디렉션",
    400 => "잘못된 요청",
    401 => "권한 없음",
    402 => "결제 필요",
    403 => "금지됨",
    404 => "찾을 수 없음",
    405 => "허용되지 않는 방법",
    406 => "허용되지 않음",
    407 => "프록시 인증 필요",
    408 => "요청 시간초과",
    409 => "충돌",
    410 => "사라짐",
    411 => "길이 필요",
    412 => "사전조건 실패",
    413 => "요청 속성이 너무 큼",
    414 => "요청 URI가 너무 긺",
    415 => "지원되지 않는 미디어 유형",
    416 => "처리할 수 없는 요청범위",
    417 => "예상 실패",
    418 => "나는 주전자입니다",
    421 => "잘못된 요청",
    422 => "처리할 수 없는 엔티티",
    423 => "잠김",
    424 => "실패된 의존성",
    425 => "너무일찍요청",
    426 => "업그레이드 필요",
    428 => "전제조건 필요",
    429 => "너무 많은 요청",
    431 => "요청 헤더 필드가 너무 큼",
    444 => "응답없이 연결이 닫힘",
    451 => "법적인 이유로 이용 불가",
    499 => "요청 헤더가 너무 큼",
    500 => "내부 서버 오류",
    501 => "구현되지 않음",
    502 => "불량 게이트웨이",
    503 => "서비스를 사용할 수 없음",
    504 => "게이트웨이 시간초과",
    505 => "HTTP 버전이 지원되지 않음",
    ## This is left in English by design
    506 => "Variant Also Negotiates",
    507 => "용량 부족",
    508 => "루프 감지됨",
    509 => "대역폭 제한 초과",
    510 => "확장되지 않음",
    511 => "네트워크 인증 필요",
    599 => "네트워크 연결 시간초과 오류",
    },
## Ref: <https://ru.wikipedia.org/wiki/%D0%A1%D0%BF%D0%B8%D1%81%D0%BE%D0%BA_%D0%BA%D0%BE%D0%B4%D0%BE%D0%B2_%D1%81%D0%BE%D1%81%D1%82%D0%BE%D1%8F%D0%BD%D0%B8%D1%8F_HTTP>
## <https://developer.roman.grinyov.name/blog/80>
'ru_RU' => 
    {
    100 => "продолжай",
    101 => "переключение протоколов",
    102 => "идёт обработка",
    103 => "ранняя метаинформация",
    200 => "хорошо",
    201 => "создано",
    202 => "принято",
    203 => "информация не авторитетна",
    204 => "нет содержимого",
    205 => "сбросить содержимое",
    206 => "частичное содержимое",
    207 => "многостатусный",
    208 => "уже сообщалось",
    226 => "использовано IM",
    300 => "множество выборов",
    301 => "перемещено навсегда",
    302 => "найдено",
    303 => "смотреть другое",
    304 => "не изменялось",
    305 => "использовать прокси",
    307 => "временное перенаправление",
    308 => "постоянное перенаправление",
    400 => "неправильный запрос",
    401 => "не авторизован",
    402 => "необходима оплата",
    403 => "запрещено",
    404 => "не найдено",
    405 => "метод не поддерживается",
    406 => "неприемлемо",
    407 => "необходима аутентификация прокси",
    408 => "истекло время ожидания",
    409 => "конфликт",
    410 => "удалён",
    411 => "необходима длина",
    412 => "условие ложно",
    413 => "полезная нагрузка слишком велика",
    414 => "URI слишком длинный",
    415 => "неподдерживаемый тип данных",
    416 => "диапазон не достижим",
    417 => "ожидание не удалось",
    418 => "я — чайник",
    421 => "Неверно адресованный запрос",
    422 => "необрабатываемый экземпляр",
    423 => "заблокировано",
    424 => "невыполненная зависимость",
    425 => "слишком рано",
    426 => "необходимо обновление",
    428 => "необходимо предусловие",
    429 => "слишком много запросов",
    431 => "поля заголовка запроса слишком большие",
    444 => "Соединение закрыто без ответа",
    451 => "недоступно по юридическим причинам",
    499 => "клиент закрыл соединение",
    500 => "внутренняя ошибка сервера",
    501 => "не реализовано",
    502 => "ошибочный шлюз",
    503 => "сервис недоступен",
    504 => "шлюз не отвечает",
    505 => "версия HTTP не поддерживается",
    506 => "вариант тоже проводит согласование",
    507 => "переполнение хранилища",
    508 => "обнаружено бесконечное перенаправление",
    509 => "исчерпана пропускная ширина канала",
    510 => "не расширено",
    511 => "требуется сетевая аутентификация",
    599 => "Ошибка тайм-аута сетевого подключения",
    },
## Ref: <https://zh.wikipedia.org/zh-tw/HTTP%E7%8A%B6%E6%80%81%E7%A0%81>
## <https://developer.mozilla.org/zh-TW/docs/Web/HTTP/Status>
## <https://www.websitehostingrating.com/zh-TW/http-status-codes-cheat-sheet/>
'zh_TW' =>
    {
    100 => "繼續",
    101 => "交換協議",
    102 => "處理",
    103 => "早期提示",
    200 => "OK",
    201 => "已創建",
    202 => "已收到請求",
    203 => "非權威信息",
    204 => "沒有內容",
    205 => "重設內容",
    206 => "部分內容",
    207 => "種多狀態",
    208 => "已報告",
    226 => "使用了IM",
    300 => "種選擇",
    301 => "永久移動",
    302 => "找到了",
    303 => "查看其他",
    304 => "未修改",
    305 => "使用代理",
    307 => "臨時重定向",
    308 => "永久重定向",
    400 => "錯誤的請求",
    401 => "未經授權",
    402 => "需要付款",
    403 => "故宮",
    404 => "未找到",
    405 => "方法不允許",
    406 => "不可接受",
    407 => "要求代理身份驗證",
    408 => "請求超時",
    409 => "衝突",
    410 => "已經過時了",
    411 => "長度必需",
    412 => "前提條件失敗",
    413 => "有效負載過大",
    414 => "請求URI太長",
    415 => "不支持的媒體類型",
    416 => "請求的範圍不滿足",
    417 => "期望失敗",
    418 => "我是茶壺",
    421 => "錯誤的請求",
    422 => "無法處理的實體",
    423 => "已鎖定",
    424 => "依賴失敗",
    425 => "太早了",
    426 => "需要升級",
    428 => "需要先決條件",
    429 => "請求太多",
    431 => "請求標頭字段太大",
    444 => "連接關閉而沒有響應",
    451 => "由於法律原因不可用",
    499 => "個客戶關閉的請求",
    500 => "內部服務器錯誤",
    501 => "未實施",
    502 => "錯誤的網關",
    503 => "服務不可用",
    504 => "網關超時",
    505 => "不支持HTTP版本",
    506 => "變種還可以協商",
    507 => "存儲空間不足",
    508 => "檢測到環路",
    509 => "超過帶寬限制",
    510 => "未擴展",
    511 => "要求網絡身份驗證",
    599 => "網絡連接超時錯誤",
    },
};
our $MAP_LANG_SHORT =
{
de		=> 'de_DE',
en		=> 'en_GB',
fr		=> 'fr_FR',
ja		=> 'ja_JP',
ko      => 'ko_KR',
ru      => 'ru_RU',
zh		=> 'zh_TW',
};

sub init
{
    my $self = shift( @_ );
    my $r = shift( @_ );
    $self->SUPER::init( @_ );
    return( $self );
}

sub convert_short_lang_to_long
{
	my $self = shift( @_ );
	my $lang = shift( @_ );
	## Nothing to do; we already have a good value
	return( $lang ) if( $lang =~ /^[a-z]{2}_[A-Z]{2}$/ );
	return( $MAP_LANG_SHORT->{ lc( $lang ) } ) if( CORE::exists( $MAP_LANG_SHORT->{ lc( $lang ) } ) );
	return( '' );
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

sub supported_languages
{
    my $self = shift( @_ );
    return( [sort( keys( %$HTTP_CODES ) )] );
}

1;
# NOTE: pod
__END__

=encoding utf8

=head1 NAME

Net::API::REST::Status - Apache2 Status Codes

=head1 SYNOPSIS

    say $Net::API::REST::Status::CODES->{429};
    # returns Apache constant Apache2::Const::HTTP_TOO_MANY_REQUESTS

    say $Net::API::REST::Status::HTTP_CODES->{fr_FR}->{429} # Trop de requête
    # In Japanese: リクエスト過大で拒否した
    say $Net::API::REST::Status::HTTP_CODES->{ja_JP}->{429}

But maybe more simply:

    my $status = Net::API::REST::Status->new;
    say $status->status_message( 429 => 'ja_JP' );
    # Or without the language code parameter, it will default to en_GB
    say $status->status_message( 429 );

    # Is success
    say $status->is_info( 102 ); # true
    say $status->is_success( 200 ); # true
    say $status->is_redirect( 302 ); # true
    say $status->is_error( 404 ); # true
    say $status->is_client_error( 403 ); # true
    say $status->is_server_error( 501 ); # true

=head1 VERSION

    v0.200.3

=head1 DESCRIPTION

This module allows the access of Apache2 http constant using their numeric value, and also allows to get the localised version of the http status for a given code for currently supported languages: fr_FR (French), en_GB (British English) and ja_JP (Japanese)

It also provides some functions to check if a given code is an information, success, redirect, error, client error or server error code.

=head1 METHODS

=head2 init

Creates an instance of L<Net::API::REST::Status> and returns the object.

=head2 convert_short_lang_to_long

Given a 2 characters language code (not case sensitive) and this will return its iso 639 5 characters equivalent for supported languages.

For example:

    Net::API::REST::Status->convert_short_lang_to_long( 'zh' );
    # returns: zh_TW

=head2 is_client_error

Returns true if the 3-digits code provided is between 400 and 500

=head2 is_error

Returns true if the 3-digits code provided is between 400 and 600

=head2 is_info

Returns true if the 3-digits code provided is between 100 and 200

=head2 is_redirect

Returns true if the 3-digits code provided is between 300 and 400

=head2 is_server_error

Returns true if the 3-digits code provided is between 500 and 600

=head2 is_success

Returns true if the 3-digits code provided is between 200 and 300

=head2 status_message

Provided with a 3-digits http code and an optional language code such as C<en_GB> and this will return the status message in its localised form.

This is useful to provide response to error in the user preferred language. L<Net::API::REST/reply> uses it to set a json response with the http error code along with a localised status message.

If no language code is provided, this will default to C<en_GB>.

See L</supported_languages> for the supported languages.

=head2 supported_languages

This will return a sorted array reference of support languages for status codes.

The following language codes are currently supported: de_DE (German), en_GB (British English), fr_FR (French), ja_JP (Japanese), ko_KR (Korean), ru_RU (Russian) and zh_TW (Traditional Chinese as spoken in Taiwan).

Feel free to contribute those codes in other languages.

=head2 SEE ALSO

Apache distribution and file C<httpd-2.x.x/include/httpd.h>

L<IANA HTTP codes list|http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml>

=cut
