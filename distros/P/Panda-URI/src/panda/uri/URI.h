#pragma once
#include <map>
#include <vector>
#include <cctype>
#include <typeinfo>
#include <stdexcept>
#include <panda/refcnt.h>
#include <panda/string.h>
#include <panda/uri/Query.h>
#include <panda/uri/encode.h>
#include <panda/string_view.h>
#include <panda/lib/from_chars.h>

namespace panda { namespace uri {

using panda::string;
using std::string_view;

extern char unsafe_query[256];

class URIError : public std::logic_error {
public:
  explicit URIError (const std::string& what_arg) : logic_error(what_arg) {}
};

class WrongScheme : public URIError {
public:
  explicit WrongScheme (const std::string& what_arg) : URIError(what_arg) {}
};

class URI : public virtual panda::RefCounted {

public:
    enum flags_t {
        ALLOW_LEADING_AUTHORITY = 1, // allow urls to begin with authority (i.e. 'google.com', 'login@mysite.com:8080/mypath', etc (but NOT with IPV6 [xx:xx:...])
        PARAM_DELIM_SEMICOLON   = 2, // allow query string param to be delimiter by ';' rather than '&'
    };

    class Strict;
    class httpX;
    class UserPass;

    class http;
    class https;
    class ftp;

    typedef URI* (*uricreator) (const URI& uri);

    static void register_scheme (const string& scheme, const std::type_info*, uricreator, uint16_t default_port, bool secure = false);

    static URI* create (const string& source, int flags = 0) {
        URI temp(source, flags);
        if (temp.scheme_info) return temp.scheme_info->creator(temp);
        else                  return new URI(temp);
    }

    static URI* create (const URI& source) {
        if (source.scheme_info) return source.scheme_info->creator(source);
        else                    return new URI(source);
    }

    URI ()                                    : scheme_info(NULL), _port(0), _qrev(1), _flags(0)     {}
    URI (const string& source, int flags = 0) : scheme_info(NULL), _port(0), _qrev(1), _flags(flags) { parse(source); }
    URI (const URI& source)                                                                          { assign(source); }

    URI& operator= (const URI& source)    { if (this != &source) assign(source); return *this; }
    URI& operator= (const string& source) { assign(source); return *this; }

    const string& scheme        () const { return _scheme; }
    const string& user_info     () const { return _user_info; }
    const string& host          () const { return _host; }
    const string& path          () const { return _path; }
    const string& fragment      () const { return _fragment; }
    uint16_t      explicit_port () const { return _port; }
    uint16_t      default_port  () const { return scheme_info ? scheme_info->default_port : 0; }
    uint16_t      port          () const { return _port ? _port : default_port(); }
    bool          secure        () const { return scheme_info ? scheme_info->secure : false; }

    virtual void assign (const URI& source) {
        _scheme     = source._scheme;
        scheme_info = source.scheme_info;
        _user_info  = source._user_info;
        _host       = source._host;
        _path       = source._path;
        _qstr       = source._qstr;
        _query      = source._query;
        _query.rev  = source._query.rev;
        _qrev       = source._qrev;
        _fragment   = source._fragment;
        _port       = source._port;
        _flags      = source._flags;
    }

    void assign (const string& uristr, int flags = 0) {
        clear();
        _flags = flags;
        parse(uristr);
    }

    const string& query_string () const {
        sync_query_string();
        return _qstr;
    }

    const string raw_query () const {
        sync_query_string();
        return decode_uri_component(_qstr);
    }

    Query& query () {
        sync_query();
        return _query;
    }

    const Query& query () const {
        sync_query();
        return _query;
    }

    virtual void scheme (const string& scheme) {
        _scheme = scheme;
        sync_scheme_info();
    }

    void user_info (const string& user_info) { _user_info = user_info; }
    void host      (const string& host)      { _host      = host; }
    void fragment  (const string& fragment)  { _fragment  = fragment; }
    void port      (uint16_t port)           { _port      = port; }

    void path (const string& path) {
        if (path && path.front() != '/') {
            _path = '/';
            _path += path;
        }
        else _path = path;
    }

    void query_string (const string& qstr) {
        _qstr = qstr;
        ok_qstr();
    }

    void raw_query (const string& rq) {
        _qstr.clear();
        encode_uri_component(rq, _qstr, unsafe_query);
        ok_qstr();
    }

    void query (const string& qstr) { query_string(qstr); }
    void query (const Query& query) {
        _query = query;
        ok_query();
    }

    void add_query (const string& addstr) {
        if (!addstr) return;
        sync_query_string();
        ok_qstr();
        if (_qstr) {
            _qstr.reserve(_qstr.length() + addstr.length() + 1);
            _qstr += '&';
            _qstr += addstr;
        }
        else _qstr = addstr;
    }

    void add_query (const Query& addquery);

    const string& param (const string_view& key) const {
        sync_query();
        const auto& cq = _query;
        auto it = cq.find(key);
        return it == cq.cend() ? _empty : it->second;
    }

    void param (const string& key, const string& val) {
        sync_query();
        auto it = _query.find(key);
        if (it != _query.cend()) it->second.assign(val);
        else _query.emplace(key, val);
    }

    string explicit_location () const {
        if (!_port) return _host;
        return location();
    }

    string location () const {
        string ret(_host.length() + 6); // port is 5 chars max
        if (_host) ret += _host;
        ret += ':';
        char* buf = ret.buf(); // has exactly 5 bytes left
        auto ptr_start = buf + ret.length();
        auto res = std::to_chars(ptr_start, buf + ret.capacity(), port());
        assert(!res.ec); // because buf is always enough
        ret.length(ret.length() + (res.ptr - ptr_start));
        return ret;
    }

    void location (const string& newloc) {
        if (!newloc) {
            _host.clear();
            _port = 0;
            return;
        }

        size_t delim = newloc.rfind(':');
        if (delim == string::npos) _host.assign(newloc);
        else {
            size_t ipv6end = newloc.rfind(']');
            if (ipv6end != string::npos && ipv6end > delim) _host.assign(newloc);
            else {
                _host.assign(newloc, 0, delim);
                _port = 0;
                std::from_chars(newloc.data() + delim + 1, newloc.data() + newloc.length(), _port);
            }
        }
    }

    const std::vector<string> path_segments () const;

    template <class It>
    void path_segments (It begin, It end) {
        _path.clear();
        for (auto it = begin; it != end; ++it) {
            if (!it->length()) continue;
            _path += '/';
            _encode_uri_component_append(*it, _path, unsafe_path_segment);
        }
    }

    string to_string (bool relative = false) const;
    string relative  () const { return to_string(true); }

    bool equals (const URI& uri) const {
        if (_path != uri._path || _host != uri._host || _user_info != uri._user_info || _fragment != uri._fragment || _scheme != uri._scheme) return false;
        if (_port != uri._port && port() != uri.port()) return false;
        sync_query_string();
        uri.sync_query_string();
        return _qstr == uri._qstr;
    }

    void swap (URI& uri);

    virtual ~URI () {}

protected:
    struct scheme_info_t {
        int        index;
        string     scheme;
        uricreator creator;
        uint16_t   default_port;
        bool       secure;
        const std::type_info* type_info;
    };
    typedef std::map<const string, scheme_info_t*> SchemeMap;
    typedef std::map<uint64_t, scheme_info_t*> SchemeTIMap;
    typedef std::vector<scheme_info_t*> SchemeVector;

    scheme_info_t* scheme_info;

    static SchemeMap    scheme_map;
    static SchemeTIMap  scheme_ti_map;
    static SchemeVector schemas;

    virtual void parse (const string& uristr);

private:
    string           _scheme;
    string           _user_info;
    string           _host;
    string           _path;
    string           _fragment;
    uint16_t         _port;
    mutable string   _qstr;
    mutable Query    _query;
    mutable uint32_t _qrev; // last query rev we've synced query string with (0 if query itself isn't synced with string)
    int              _flags;

    static const string _empty;

    void ok_qstr      () const { _qrev = 0; }
    void ok_query     () const { _qrev = _query.rev - 1; }
    void ok_qboth     () const { _qrev = _query.rev; }
    bool has_ok_qstr  () const { return !_qrev || _qrev == _query.rev; }
    bool has_ok_query () const { return _qrev != 0; }

    void clear () {
        _port = 0;
        _scheme.clear();
        scheme_info = NULL;
        _user_info.clear();
        _host.clear();
        _path.clear();
        _qstr.clear();
        _query.clear();
        _fragment.clear();
        ok_qboth();
        _flags = 0;
    }

    inline void guess_leading_authority ();

    void compile_query () const;
    void parse_query   () const;

    void sync_query_string () const { if (!has_ok_qstr()) compile_query(); }
    void sync_query        () const { if (!has_ok_query()) parse_query(); }

    void sync_scheme_info ();

    static inline void _encode_uri_component_append (const string_view& src, string& dest, const char* unsafe) {
        char* buf = dest.reserve(dest.length() + src.length()*3) + dest.length();
        size_t final_size = encode_uri_component(src, buf, unsafe);
        dest.length(dest.length() + final_size);
    }
};

inline std::ostream& operator<< (std::ostream& os, const URI& uri) {
    string tmp = uri.to_string();
    return os.write(tmp.data(), tmp.length());
}

inline bool operator== (const URI& lhs, const URI& rhs) { return lhs.equals(rhs); }
inline bool operator!= (const URI& lhs, const URI& rhs) { return !lhs.equals(rhs); }
inline void swap (URI& l, URI& r) { l.swap(r); }

}}
