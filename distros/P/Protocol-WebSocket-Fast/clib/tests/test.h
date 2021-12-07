#pragma once
#include <panda/optional.h>
#include <panda/protocol/websocket.h>
#include <catch2/catch_test_macros.hpp>
#include <catch2/matchers/catch_matchers_string.hpp>

namespace test {

using namespace panda;
using namespace panda::protocol::websocket;
using panda::protocol::http::Headers;

struct ReMatcher : Catch::Matchers::MatcherBase<string> {
    ReMatcher (const string& regex, bool case_sen = false) : re(regex), case_sen(case_sen) {}
    bool match (const string& matchee) const override;
    std::string describe () const override;
private:
    string re;
    bool   case_sen;
};

inline ReMatcher MatchesRe (const string& regex, bool case_sen = false) { return ReMatcher(regex, case_sen); }

void regex_replace (string&, const std::string&, const std::string&);

template <class T>
string join (T&& v) {
    string ret;
    for (auto& s : v) ret += s;
    return ret;
}

string repeat (string_view, int);

std::vector<string> accept_packet   ();
inline string       accept_packet_s () { return join(accept_packet()); }

struct EstablishedServerParser : ServerParser {
    EstablishedServerParser (bool deflate = false) : EstablishedServerParser({}, deflate) {}
    EstablishedServerParser (const Parser::Config& cfg, bool deflate = false);
};

struct EstablishedClientParser : ClientParser {
    EstablishedClientParser (bool deflate = false) : EstablishedClientParser({}, deflate) {}
    EstablishedClientParser (const Parser::Config& cfg, bool deflate = false);
};

struct FMChecker {
    FMChecker (FrameSP f)   : _frame(f)   {}
    FMChecker (MessageSP m) : _message(m) {}

    FMChecker& opcode           (Opcode v)   { _opcode = v; return *this; }
    FMChecker& final            (bool v)     { _fin = v; return *this; }
    FMChecker& final            ()           { return final(true); }
    FMChecker& rsv1             ()           { _rsv1 = true; return *this; }
    FMChecker& rsv2             ()           { _rsv2 = true; return *this; }
    FMChecker& rsv3             ()           { _rsv3 = true; return *this; }
    FMChecker& payload          (string v)   { _payload = v; return *this; }
    FMChecker& paylen           (size_t v)   { _paylen = v; return *this; }
    FMChecker& nframes          (uint32_t v) { _nframes = v; return *this; }
    FMChecker& close_code       (int v)      { _close_code = v; return *this; }
    FMChecker& close_message    (string v)   { _close_message = v; return *this; }

    ~FMChecker () noexcept(false);

private:
    FrameSP            _frame;
    MessageSP          _message;
    optional<Opcode>   _opcode;
    optional<bool>     _fin;
    optional<bool>     _rsv1;
    optional<bool>     _rsv2;
    optional<bool>     _rsv3;
    optional<string>   _payload;
    optional<size_t>   _paylen;
    optional<int>      _close_code;
    optional<string>   _close_message;
    optional<uint32_t> _nframes;
};

inline FMChecker CHECK_FRAME   (FrameSP f)   { return FMChecker(f); }
inline FMChecker CHECK_MESSAGE (MessageSP m) { return FMChecker(m); }

struct FrameGenerator {
    FrameGenerator () {}
    FrameGenerator (string bin) : _bin(bin) {}

    FrameGenerator& opcode           (Opcode v)   { _opcode = v; return *this; }
    FrameGenerator& mask             (string v)   { _mask = v; return *this; }
    FrameGenerator& mask             ()           { return mask("autogen"); }
    FrameGenerator& final            (bool v)     { _final = v; return *this; }
    FrameGenerator& final            ()           { return final(true); }
    FrameGenerator& rsv1             ()           { _rsv1 = true; return *this; }
    FrameGenerator& rsv2             ()           { _rsv2 = true; return *this; }
    FrameGenerator& rsv3             ()           { _rsv3 = true; return *this; }
    FrameGenerator& payload          (string v)   { _payload = v; return *this; }
    FrameGenerator& nframes          (uint32_t v) { _nframes = v; return *this; }
    FrameGenerator& close_code       (int v)      { _close_code = v; return *this; }
    FrameGenerator& close_code_check (int v)      { _close_code_check = v; return *this; }
    FrameGenerator& binlen           (size_t v)   { _binlen = v; return *this; }

    Opcode   opcode           () const { return _opcode; }
    string   is_masked        () const { return _mask; }
    bool     is_final         () const { return _final; }
    bool     has_rsv1         () const { return _rsv1; }
    bool     has_rsv2         () const { return _rsv2; }
    bool     has_rsv3         () const { return _rsv3; }
    string   payload          () const { return _payload; }
    uint32_t nframes          () const { return _nframes; }
    int      close_code       () const { return _close_code; }
    int      close_code_check () const { return _close_code_check; }
    size_t   binlen           () const { return _binlen; }

    operator string () const { return str(); }

    string              str() const;
    std::vector<string> vec() const;

    FrameGenerator& msg_mode () { _msg_mode = true; return *this; }

    ~FrameGenerator () noexcept(false);

private:
    Opcode   _opcode = Opcode::TEXT;
    string   _mask;
    bool     _final = false;
    bool     _rsv1 = false;
    bool     _rsv2 = false;
    bool     _rsv3 = false;
    string   _payload;
    int      _close_code = 0;
    int      _close_code_check = 0;
    uint32_t _nframes = 1;
    bool     _msg_mode = false;
    string   _bin;
    size_t   _binlen = 0;

    string              _gen_frame   () const;
    std::vector<string> _gen_message () const;
};

inline FrameGenerator gen_frame   () { return {}; }
inline FrameGenerator gen_message () { return FrameGenerator().msg_mode(); }

inline FrameGenerator CHECK_BINFRAME (string bin) { return FrameGenerator(bin); }

inline FrameSP get_frame (Parser& parser, string str = {}) {
    auto range = parser.get_frames(str);
    if (range.begin() == range.end()) return {};
    return *(range.begin());
}

inline std::vector<FrameSP> get_frames (Parser& parser, string str = {}) {
    std::vector<FrameSP> ret;
    auto frames = parser.get_frames(str);
    for (auto f : frames) ret.push_back(f);
    return ret;
}

inline MessageSP get_message (Parser& parser, string str = {}) {
    auto msgs = parser.get_messages(str);
    if (msgs.begin() == msgs.end()) return {};
    return *(msgs.begin());
}

inline std::vector<MessageSP> get_messages (Parser& parser, string str = {}) {
    std::vector<MessageSP> ret;
    auto msgs = parser.get_messages(str);
    for (auto m : msgs) ret.push_back(m);
    return ret;
}

void reset (Parser&);

void      test_frame   (Parser&, FrameGenerator, const ErrorCode& = {}, int suggested_close_code = 0);
MessageSP test_message (Parser&, FrameGenerator, const ErrorCode& = {});

}

using namespace test;
using namespace Catch::Matchers;

namespace panda { namespace protocol { namespace websocket {
    inline bool operator== (const HeaderValue& lhs, const HeaderValue& rhs) {
        return lhs.name == rhs.name && lhs.params == rhs.params;
    }
}}}
