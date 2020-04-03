#include "ConnectResponse.h"
#include "Error.h"
#include "utils.h"
#include <openssl/sha.h>
#include <panda/encode/base64.h>

namespace panda { namespace protocol { namespace websocket {

void ConnectResponse::process_headers () {
    if (code == 426) {
        _ws_version = headers.get("Sec-WebSocket-Version");
        error = errc::unsupported_version;
        return;
    }

    if (code != 101) {
        error = errc::response_code_101;
        return;
    }

    auto it = headers.find("Connection");
    if (it == headers.end() || !string_contains_ci(it->value, "upgrade")) {
        error = errc::connection_mustbe_upgrade;
        return;
    }

    it = headers.find("Upgrade");
    if (it == headers.end() || !string_contains_ci(it->value, "websocket")) {
        error = errc::upgrade_mustbe_websocket;
        return;
    }

    it = headers.find("Sec-WebSocket-Accept");
    if (it == headers.end() || it->value != _calc_accept_key(_ws_key)) {
        error = errc::sec_accept_missing;
        return;
    }
    else _ws_accept_key = it->value;


    auto ext_range = headers.get_multi("Sec-WebSocket-Extensions");
    for (auto& val : ext_range) {
        parse_header_value(val, _ws_extensions);
    }

    ws_protocol = headers.get("Sec-WebSocket-Protocol");
}

string ConnectResponse::_calc_accept_key (string ws_key) {
    auto key_base = ws_key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    unsigned char sha1bin[21];
    SHA1((const unsigned char*)key_base.data(), key_base.length(), sha1bin);
    return panda::encode::encode_base64(string_view((const char*)sha1bin, 20), false, true);
}

string ConnectResponse::to_string() {
    code    = 101;
    message = "Switching Protocols";
    headers.add("Upgrade", "websocket");
    headers.add("Connection", "Upgrade");

    if (ws_protocol) headers.add("Sec-WebSocket-Protocol", ws_protocol);

    headers.add("Sec-WebSocket-Accept", _calc_accept_key(_ws_key));
    if (!headers.has("Server")) headers.add("Server", "Panda-WebSocket");

    if (_ws_extensions.size()) headers.add("Sec-WebSocket-Extensions", compile_header_value(_ws_extensions));

    body.parts.clear(); // body not supported in WS responses

    return http::Response::to_string();
}

}}}
