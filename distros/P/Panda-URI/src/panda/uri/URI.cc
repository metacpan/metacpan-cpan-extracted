#include <stdexcept>
#include <panda/lib.h>
#include <panda/uri/all.h>

namespace panda { namespace uri {

typedef unsigned char uchar;
using panda::lib::string_hash;
using panda::unlikely;

enum state_t {
    STATE_NONE   = -1,
    STATE_SCHEME = 0,
    STATE_UINFO,
    STATE_HOST,
    STATE_HOST_IPV6,
    STATE_PORT,
    STATE_PATH,
    STATE_QUERY,
    STATE_FRAGMENT,
    STATE_END
};

enum token_flags_t {
    TF_CROP     = 1,
    TF_SUBSTATE = 2
};

struct token_t {
    state_t seen_state;
    state_t next_state;
    int     flags;
    token_t () : seen_state(STATE_NONE), next_state(STATE_NONE), flags(0) {}
    token_t (state_t ss, state_t ns, int flags = 0) : seen_state(ss), next_state(ns), flags(flags) {}
};

struct mark_t {
    ssize_t start;
    ssize_t end;
};

static token_t parseinfo[STATE_END][256];
static char unsafe_port[256];

const string      URI::_empty;
URI::SchemeMap    URI::scheme_map;
URI::SchemeTIMap  URI::scheme_ti_map;
URI::SchemeVector URI::schemas;

void URI::register_scheme (const string& scheme, const std::type_info* ti, uricreator creator, uint16_t default_port, bool secure) {
    if (scheme_map.find(scheme) != scheme_map.end())
        throw std::invalid_argument("URI::register_scheme: scheme '" + scheme + "' has been already registered");
    scheme_info_t* inf = new scheme_info_t;
    inf->index         = schemas.size();
    inf->scheme        = scheme;
    inf->creator       = creator;
    inf->default_port  = default_port;
    inf->secure        = secure;
    inf->type_info     = ti;
    scheme_map[scheme] = inf;
    scheme_ti_map[string_hash(ti->name())] = inf;
    schemas.push_back(inf);
}

static URI* new_http  (const URI& source) { return new URI::http(source); }
static URI* new_https (const URI& source) { return new URI::https(source); }
static URI* new_ftp   (const URI& source) { return new URI::ftp(source); }

static int init () {
    parseinfo[STATE_SCHEME][0]          = token_t(STATE_PATH,  STATE_END);
    parseinfo[STATE_SCHEME][(uchar)':'] = token_t(STATE_END,   STATE_END); // custom handling
    parseinfo[STATE_SCHEME][(uchar)'/'] = token_t(STATE_PATH,  STATE_PATH,     TF_SUBSTATE);
    parseinfo[STATE_SCHEME][(uchar)'?'] = token_t(STATE_PATH,  STATE_QUERY,    TF_CROP);
    parseinfo[STATE_SCHEME][(uchar)'#'] = token_t(STATE_PATH,  STATE_FRAGMENT, TF_CROP);

    parseinfo[STATE_HOST][0]          = token_t(STATE_HOST,  STATE_END);
    parseinfo[STATE_HOST][(uchar)'/'] = token_t(STATE_HOST,  STATE_PATH);
    parseinfo[STATE_HOST][(uchar)'?'] = token_t(STATE_HOST,  STATE_QUERY,    TF_CROP);
    parseinfo[STATE_HOST][(uchar)'#'] = token_t(STATE_HOST,  STATE_FRAGMENT, TF_CROP);
    parseinfo[STATE_HOST][(uchar)'@'] = token_t(STATE_UINFO, STATE_HOST,     TF_CROP);
    parseinfo[STATE_HOST][(uchar)':'] = token_t(STATE_HOST,  STATE_PORT,     TF_CROP);
    parseinfo[STATE_HOST][(uchar)'['] = token_t(STATE_HOST,  STATE_HOST_IPV6);

    parseinfo[STATE_HOST_IPV6][0]          = token_t(STATE_HOST,  STATE_END);
    parseinfo[STATE_HOST_IPV6][(uchar)']'] = token_t(STATE_HOST,  STATE_HOST,     TF_SUBSTATE);
    parseinfo[STATE_HOST_IPV6][(uchar)'@'] = token_t(STATE_UINFO, STATE_HOST,     TF_CROP);
    parseinfo[STATE_HOST_IPV6][(uchar)'/'] = token_t(STATE_HOST,  STATE_PATH);
    parseinfo[STATE_HOST_IPV6][(uchar)'?'] = token_t(STATE_HOST,  STATE_QUERY,    TF_CROP);
    parseinfo[STATE_HOST_IPV6][(uchar)'#'] = token_t(STATE_HOST,  STATE_FRAGMENT, TF_CROP);

    parseinfo[STATE_PORT][0]          = token_t(STATE_PORT,  STATE_END);
    parseinfo[STATE_PORT][(uchar)'@'] = token_t(STATE_UINFO, STATE_HOST,     TF_CROP);
    parseinfo[STATE_PORT][(uchar)'/'] = token_t(STATE_PORT,  STATE_PATH);
    parseinfo[STATE_PORT][(uchar)'?'] = token_t(STATE_PORT,  STATE_QUERY,    TF_CROP);
    parseinfo[STATE_PORT][(uchar)'#'] = token_t(STATE_PORT,  STATE_FRAGMENT, TF_CROP);

    parseinfo[STATE_PATH][0]          = token_t(STATE_PATH,  STATE_END);
    parseinfo[STATE_PATH][(uchar)'?'] = token_t(STATE_PATH,  STATE_QUERY,    TF_CROP);
    parseinfo[STATE_PATH][(uchar)'#'] = token_t(STATE_PATH,  STATE_FRAGMENT, TF_CROP);

    parseinfo[STATE_QUERY][0]          = token_t(STATE_QUERY,  STATE_END);
    parseinfo[STATE_QUERY][(uchar)'#'] = token_t(STATE_QUERY,  STATE_FRAGMENT, TF_CROP);

    parseinfo[STATE_FRAGMENT][0] = token_t(STATE_FRAGMENT,  STATE_END);

    unsafe_generate(unsafe_port, UNSAFE_DIGIT);

    URI::register_scheme("http",  &typeid(URI::http),  new_http,   80);
    URI::register_scheme("https", &typeid(URI::https), new_https, 443, true);
    URI::register_scheme("ftp",   &typeid(URI::ftp),   new_ftp,    21);

    return 0;
}
static const int __init = init();

inline void URI::guess_leading_authority () {
    // try to find out if it was an url with leading authority ('ya.ru', 'ya.ru:80/a/b/c', 'user@mysite.com/a/b/c')
    // in either case host is always empty and there are 2 cases
    // 1) if no scheme -> host is first path part, port is absent
    // 2) if scheme is present and first path part is a valid port -> scheme is host, first path part is port.
    // otherwise leave parsed url unchanged as it has no leading authority
    if (!_scheme.length()) {
        size_t delim = _path.find('/');
        if (delim == string::npos) {
            _host = _path;
            _path = _empty;
        } else {
            _host.assign(_path, 0, delim);
            _path.erase(0, delim);
        }
        return;
    }

    bool ok = false;
    size_t plen = _path.length();
    const char* p = _path.data();
    size_t i = 0;
    for (; i < plen; ++i) {
        if (unsafe_port[(uchar)p[i]]) {
            _port = _port * 10 + (p[i] - '0');
            ok = true;
            continue;
        }
        if (p[i] != '/') { _port = 0; return; }
        break;
    }

    if (!ok) return;
    _host = _scheme;
    _scheme.clear();
    _path.erase(0, i);
}

void URI::parse (const string& uristr) {
    const char* p = uristr.data();
    size_t len = uristr.length();
    size_t i = 0;

    mark_t marks[STATE_END] = {{0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1}, {0,-1}};
    state_t state;

    if (len >= 2 and *p == '/' and p[1] == '/') {
        state = STATE_HOST;
        i = 2;
        marks[STATE_HOST].start = marks[STATE_UINFO].start = i;
    }
    else
        state = STATE_SCHEME;

    for (; i < len; ++i) {
        if (parseinfo[state][(uchar)p[i]].seen_state == STATE_NONE) continue;
        if (unlikely(p[i] == 0)) break; // null-byte in uri should be treaten as the end of uri

        if (state == STATE_SCHEME && p[i] == ':') {                     // custom processing
            if (len > i + 2 && p[i+1] == '/' && p[i+2] == '/') {        // 'scheme://netloc' case
                state = STATE_HOST;
                _scheme = uristr.substr(0, i);
                i += 2;
                marks[STATE_HOST].start = marks[STATE_UINFO].start = i + 1;
            } else {                                                    // 'scheme:path' case
                state = STATE_PATH;
                _scheme = uristr.substr(0, i);
                marks[STATE_PATH].start = i + 1;
            }
            continue;
        }

        // default case
        token_t token = parseinfo[state][(uchar)p[i]];
        marks[token.seen_state].end = i;
        state = token.next_state;
        if (state != STATE_END && !(token.flags & TF_SUBSTATE)) marks[state].start = i + (token.flags & TF_CROP ? 1 : 0);
    }
    marks[parseinfo[state][0].seen_state].end = i;

    if (marks[STATE_UINFO].end > 0)
        decode_uri_component(string_view(p + marks[STATE_UINFO].start, marks[STATE_UINFO].end - marks[STATE_UINFO].start), _user_info);

    if (marks[STATE_HOST].end > 0) {
        decode_uri_component(string_view(p + marks[STATE_HOST].start, marks[STATE_HOST].end - marks[STATE_HOST].start), _host);
        if (marks[STATE_PORT].end > 0) {
            const char* portp = p + marks[STATE_PORT].start;
            size_t len = marks[STATE_PORT].end - marks[STATE_PORT].start;
            for (size_t n = 0; n < len; ++n) {
                char c = portp[n];
                if (!unsafe_port[(uchar)c]) break;
                _port = _port*10 + c - '0';
            }
        }
    }

    if (marks[STATE_PATH].end > 0)
        _path = uristr.substr(marks[STATE_PATH].start, marks[STATE_PATH].end - marks[STATE_PATH].start);
    if (marks[STATE_QUERY].end > 0) { // assign as is, raw_query getter or parse_query will actually decode
        _qstr = uristr.substr(marks[STATE_QUERY].start, marks[STATE_QUERY].end - marks[STATE_QUERY].start);
        ok_qstr();
    }
    if (marks[STATE_FRAGMENT].end > 0)
        _fragment = uristr.substr(marks[STATE_FRAGMENT].start, marks[STATE_FRAGMENT].end - marks[STATE_FRAGMENT].start);

    if (_flags & ALLOW_LEADING_AUTHORITY && !_host.length()) guess_leading_authority();

    sync_scheme_info();
}

string URI::to_string (bool relative) const {
    sync_query_string();
    size_t approx_len = _path.length() + _fragment.length() + _qstr.length() + 3;
    if (!relative) approx_len += (_scheme.length()+3) + (_user_info.length()*3 + 1) + (_host.length()*3 + 6);
    string str(approx_len);

    if (!relative) {
        if (_scheme.length()) {
            str += _scheme;
            if (_host.length()) str += "://";
            else str += ':';
        }
        else if (_host.length()) str += "//";

        if (_host.length()) {
            if (_user_info.length()) {
                _encode_uri_component_append(_user_info, str, unsafe_uinfo);
                str += '@';
            }

            const auto& chost = _host;
            if (chost.front() == '[' && chost.back() == ']') str += _host;
            else _encode_uri_component_append(_host, str, unsafe_host);

            if (_port) {
                str += ':';
                str += string::from_number(_port);
            }
        }
    }

    if (_path.length()) str += _path;
    else if (relative) str += '/'; // relative path MUST NOT be empty

    if (_qstr.length()) {
        str += '?';
        str += _qstr; // as is, because already encoded either by raw_query setter or by compile_query
    }

    if (_fragment.length()) {
        str += '#';
        str += _fragment;
    }

    return str;
}

void URI::parse_query () const {
    enum { PARSE_MODE_KEY, PARSE_MODE_VAL, PARSE_MODE_WRITE } mode = PARSE_MODE_KEY;
    int key_start = 0;
    int key_end   = 0;
    int val_start = 0;
    const char delim = _flags & PARAM_DELIM_SEMICOLON ? ';' : '&';
    const char* str = _qstr.data();
    int len = _qstr.length();
    _query.clear();

    if (len) for (int i = 0; i <= len; ++i) {
        char c = (i == len) ? delim : str[i];
        if (c == '=' && mode == PARSE_MODE_KEY) {
            key_end = i;
            mode = PARSE_MODE_VAL;
            val_start = i+1;
        }
        else if (c == delim) {
            if (mode == PARSE_MODE_KEY) {
                key_end = i;
                val_start = i;
            }

            string key;
            size_t klen = key_end - key_start;
            if (klen > 0) decode_uri_component(string_view(str+key_start, klen), key);

            string value;
            size_t vlen = i - val_start;
            if (vlen > 0) decode_uri_component(string_view(str+val_start, vlen), value);

            _query.emplace(key, value);

            mode = PARSE_MODE_KEY;
            key_start = i+1;
        }
    }

    ok_qboth();
}

void URI::compile_query () const {
    _qstr.clear();
    const char delim = _flags & PARAM_DELIM_SEMICOLON ? ';' : '&';
    auto begin = _query.cbegin();
    auto end   = _query.cend();

    size_t bufsize = 0;
    for (auto it = begin; it != end; ++it) bufsize += (it->first.length() + it->second.length())*3 + 2;
    if (bufsize) --bufsize;

    _qstr.reserve(bufsize);

    char* bufp = _qstr.buf();
    char* ptr = bufp;
    for (auto it = begin; it != end; ++it) {
        if (it != begin) *ptr++ = delim;
        ptr += encode_uri_component(it->first, ptr);
        *ptr++ = '=';
        ptr += encode_uri_component(it->second, ptr);
    }
    _qstr.length(ptr-bufp);

    ok_qboth();
}

void URI::add_query (const Query& addquery) {
    sync_query();
    auto end = addquery.cend();
    for (auto it = addquery.cbegin(); it != end; ++it) _query.emplace(it->first, it->second);
    ok_query();
}

const std::vector<string> URI::path_segments () const {
    size_t plen = _path.length();
    if (!plen) return std::vector<string>();
    std::vector<string> ret;
    ret.reserve(7);
    const char* p = _path.data();
    size_t start = 0;
    for (size_t i = 0; i < plen; ++i) {
        if (p[i] != '/') continue;
        if (i == start) { start++; continue; }
        ret.push_back(decode_uri_component(string_view(p+start, i-start)));
        start = i+1;
    }
    if (p[plen-1] != '/') ret.push_back(string(p+start, plen-start));
    return ret;
}

void URI::swap (URI& uri) {
    std::swap(_scheme,     uri._scheme);
    std::swap(scheme_info, uri.scheme_info);
    std::swap(_user_info,  uri._user_info);
    std::swap(_host,       uri._host);
    std::swap(_port,       uri._port);
    std::swap(_path,       uri._path);
    std::swap(_qstr,       uri._qstr);
    std::swap(_query,      uri._query);
    std::swap(_qrev,       uri._qrev);
    std::swap(_fragment,   uri._fragment);
    std::swap(_flags,      uri._flags);
}

void URI::sync_scheme_info () {
    if (!_scheme) {
        scheme_info = NULL;
        return;
    }

    // lowercase the scheme
    char* p   = _scheme.buf();
    char* end = p + _scheme.length();
    for (;p != end; ++p) *p = tolower(*p);

    auto it = scheme_map.find(_scheme);
    if (it == scheme_map.cend()) scheme_info = NULL;
    else                         scheme_info = it->second;
}

}}
