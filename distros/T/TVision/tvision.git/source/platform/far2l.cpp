#include <tvision/tv.h>

#include <internal/far2l.h>
#include <internal/win32con.h>
#include <internal/base64.h>
#include <internal/events.h>
#include <internal/conctl.h>
#include <internal/endian.h>

#include <time.h>

namespace tvision
{

// Request IDs
const char
    f2lNoAnswer = '\0',
    f2lClipGetData = '\xA0';

static char f2lClientIdData[32 + 1];
static TStringView f2lClientId =
(
    sprintf(f2lClientIdData, "%032llu", (unsigned long long) time(nullptr)),
    f2lClientIdData
);

ParseResult parseFar2lInput(GetChBuf &buf, TEvent &ev, InputState &state) noexcept
// Pre: "\x1B_f2l" has just been read.
{
    enum { k = 32 };
    char s[4*k];
    size_t len = 0;
    int c;
    while (c = buf.getUnbuffered(), c != -1 && c != '\x07')
        if (len < sizeof(s))
            s[len++] = (char) c;
    char o[3*k];
    TStringView out = decodeBase64({s, len}, o);
    if (!out.empty())
    {
        if (out.back() == 'K' && out.size() - 1 == 14)
        {
            KEY_EVENT_RECORD kev {};
            kev.bKeyDown = 1;
            memcpy(&kev.wRepeatCount,      &out[0],  2);
            memcpy(&kev.wVirtualKeyCode,   &out[2],  2);
            memcpy(&kev.wVirtualScanCode,  &out[4],  2);
            memcpy(&kev.dwControlKeyState, &out[6],  4);
            memcpy(&kev.uChar.UnicodeChar, &out[10], 4);

#ifdef TV_BIG_ENDIAN
            // The protocol states that "all integer values are in
            // little-endian format", so convert them.
            reverseBytes(kev.wRepeatCount);
            reverseBytes(kev.wVirtualKeyCode);
            reverseBytes(kev.wVirtualScanCode);
            reverseBytes(kev.dwControlKeyState);
            reverseBytes((uint32_t &) kev.uChar.UnicodeChar);
#endif

            regenerateMissingScanCodeFromVirtualKeyCode(kev);

            if (getWin32Key(kev, ev, state))
            {
                TermIO::normalizeKey(ev.keyDown);
                return Accepted;
            }
        }
        else if (out.back() == 'M' && out.size() - 1 == 16)
        {
            MOUSE_EVENT_RECORD mev {};
            memcpy(&mev.dwMousePosition.X, &out[0],  2);
            memcpy(&mev.dwMousePosition.Y, &out[2],  2);
            memcpy(&mev.dwButtonState,     &out[4],  4);
            memcpy(&mev.dwControlKeyState, &out[8],  4);
            memcpy(&mev.dwEventFlags,      &out[12], 4);

#ifdef TV_BIG_ENDIAN
            reverseBytes((uint16_t &) mev.dwMousePosition.X);
            reverseBytes((uint16_t &) mev.dwMousePosition.Y);
            reverseBytes(mev.dwButtonState);
            reverseBytes(mev.dwControlKeyState);
            reverseBytes(mev.dwEventFlags);
#endif

            getWin32Mouse(mev, ev, state);
            return Accepted;
        }
    }
    return Ignored;
}

ParseResult parseFar2lAnswer(GetChBuf &buf, TEvent &, InputState &state) noexcept
// Pre: "\x1B_far2l" has just been read.
{
    ParseResult res = Ignored;
    if (char *s = TermIO::readUntilBelOrSt(buf))
    {
        TStringView encoded(s);
        if (encoded == "ok")
            state.far2l.enabled = true;
        else if (char *pDecoded = (char *) malloc((encoded.size() * 3)/4 + 3))
        {
            TStringView decoded = decodeBase64(encoded, pDecoded);
            if (decoded.size() >= 5 && decoded.back() == f2lClipGetData && state.putPaste)
            {
                uint32_t dataSize;
                memcpy(&dataSize, &decoded[decoded.size() - 5], 4);
#ifdef TV_BIG_ENDIAN
                reverseBytes(dataSize);
#endif
                if (dataSize < UINT_MAX - 5 && decoded.size() >= 5 + dataSize)
                {
                    TStringView text = decoded.substr(decoded.size() - 5 - dataSize, dataSize);
                    // Discard null terminator.
                    if (dataSize > 0 && text.back() == '\0')
                        text = text.substr(0, text.size() - 1);
                    state.putPaste(text);
                }
            }
            free(pDecoded);
        }
        free(s);
    }
    return res;
}

template <bool write = true, class... Args>
size_t concat(char *out, TStringView, Args ...args) noexcept;
template <bool write = true, class... Args>
size_t concat(char *out, char c, Args ...args) noexcept;
template <bool write = true, class... Args>
size_t concat(char *out, uint32_t i, Args ...args) noexcept;

template <bool write = true, class... Args>
inline size_t concat(char *) noexcept
{
    return 0;
}

template <bool write, class... Args>
inline size_t concat(char *out, TStringView s, Args ...args) noexcept
{
    size_t len = s.size();
    if (write)
        memcpy(out, s.data(), len);
    return len + concat<write>(out + len, args...);
}

template <bool write, class... Args>
inline size_t concat(char *out, char c, Args ...args) noexcept
{
    size_t len = sizeof(c);
    if (write)
        memcpy(out, &c, len);
    return len + concat<write>(out + len, args...);
}

template <bool write, class... Args>
inline size_t concat(char *out, uint32_t i, Args ...args) noexcept
{
    size_t len = sizeof(i);
    if (write)
    {
#ifdef TV_BIG_ENDIAN
        reverseBytes(i);
#endif
        memcpy(out, &i, len);
    }
    return len + concat<write>(out + len, args...);
}

template <class... Args>
inline size_t concatLength(Args ...args) noexcept
{
    return concat<false>(nullptr, args...);
}

template <class... Args>
inline void pushFar2lRequest(std::vector<char> &out, std::vector<char> &tmp, Args ...args)
{
    size_t headLen = out.size();
    size_t argsLen = concatLength(args...);
    out.resize(headLen + argsLen);
    concat(&out[headLen], args...);
    tmp.resize((argsLen * 4)/3 + 4);
    TStringView b64 = encodeBase64({&out[headLen], argsLen}, &tmp[0]);
    TStringView prefix = "\x1B_far2l:";
    TStringView suffix = "\x1B\\";
    size_t pushLen = concatLength(prefix, b64, suffix);
    out.resize(headLen + pushLen);
    concat(&out[headLen], prefix, b64, suffix);
}

bool setFar2lClipboard(ConsoleCtl &con, TStringView text, InputState &state) noexcept
{
    if (state.far2l.enabled)
    {
        std::vector<char> out, tmp;
        // CLIP_OPEN
        pushFar2lRequest(out, tmp,
            f2lClientId,
            (uint32_t) f2lClientId.size(),
            "oc",
            f2lNoAnswer
        );
        // CLIP_SETDATA
        if (text.size() > UINT_MAX - 1)
            text = text.substr(0, UINT_MAX - 1);
        pushFar2lRequest(out, tmp,
            text,
            '\0',
            (uint32_t) (text.size() + 1),
            (uint32_t) CF_TEXT,
            "sc",
            f2lNoAnswer
        );
        // CLIP_CLOSE
        pushFar2lRequest(out, tmp,
            "cc",
            f2lNoAnswer
        );
        con.write(out.data(), out.size());
        return true;
    }
    return false;
}

bool requestFar2lClipboard(ConsoleCtl &con, InputState &state) noexcept
{
    if (state.far2l.enabled)
    {
        std::vector<char> out, tmp;
        // CLIP_OPEN
        pushFar2lRequest(out, tmp,
            f2lClientId,
            (uint32_t) f2lClientId.size(),
            "oc",
            f2lNoAnswer
        );
        // CLIP_GETDATA
        pushFar2lRequest(out, tmp,
            (uint32_t) CF_TEXT,
            "gc",
            f2lClipGetData
        );
        // CLIP_CLOSE
        pushFar2lRequest(out, tmp,
            "cc",
            f2lNoAnswer
        );
        con.write(out.data(), out.size());
        return true;
    }
    return false;
}

} // namespace tvision
