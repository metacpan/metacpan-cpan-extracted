// this file is included into struct Parser
// ! no namespaces here or #includes here !

struct MessageBuilder {
    MessageBuilder (MessageBuilder&&) = default;

    Opcode      opcode  () const noexcept { return _opcode; }
    DeflateFlag deflate () const noexcept { return _deflate; }

    MessageBuilder& opcode  (Opcode v)      noexcept { _opcode = v; return *this; }
    MessageBuilder& deflate (DeflateFlag v) noexcept { _deflate = v; return *this; }
    MessageBuilder& deflate (bool v)        noexcept { _deflate = v ? DeflateFlag::YES : DeflateFlag::NO; return *this; }

    StringPair send (string& payload) {
        auto apply_deflate = maybe_deflate(payload.length());
        return _parser.start_message(_opcode, apply_deflate).send(payload, true);
    }

    template <class Begin, class End, typename = typename std::enable_if<std::is_same<typename std::decay<decltype(*std::declval<Begin>())>::type, string>::value>::type>
    StringChain<Begin, End> send (Begin payload_begin, End payload_end) {
        size_t payload_length = 0;
        for (auto it = payload_begin; it != payload_end; ++it) payload_length += (*it).length();
        auto apply_deflate = maybe_deflate(payload_length);
        return _parser.start_message(_opcode, apply_deflate).send(payload_begin, payload_end, true);
    }

    template <class Begin, class End, typename = typename std::enable_if<std::is_same<decltype(*((*Begin()).begin())), string&>::value>::type>
    std::vector<string> send (Begin cont_begin, End cont_end) {
        std::vector<string> ret;

        size_t sz = 0, idx = 0, payload_sz = 0, last_nonempty = 0;
        auto cont_range = make_iterator_pair(cont_begin, cont_end);

        for (const auto& range : cont_range) {
            size_t piece_sz = 0;
            for (const auto& it : range) {
                auto length = it.length();
                piece_sz += length;
                if (length) ++sz;
            }
            if (piece_sz) { last_nonempty = idx; };
            payload_sz += piece_sz;
            ++idx;
        };

        auto sender = _parser.start_message(_opcode, maybe_deflate(payload_sz));

        if (!payload_sz) {
            ret.reserve(1);
            ret.push_back(sender.send(true));
            return ret;
        }

        ret.reserve(sz);

        idx = 0;
        for (auto& range : cont_range) {
            size_t piece_sz = 0;
            for (const auto& it: range) piece_sz += it.length();
            if (piece_sz) {
                auto frame_range = sender.send(range.begin(), range.end(), idx == last_nonempty);
                for (const auto& s : frame_range) ret.push_back(s);
            }
            if (idx == last_nonempty) break;
            ++idx;
        }

        return ret;
    }

private:
    friend Parser;

    Parser&     _parser;
    Opcode      _opcode  = Opcode::BINARY;
    DeflateFlag _deflate = DeflateFlag::DEFAULT;

    MessageBuilder (Parser& parser) : _parser(parser) {}
    MessageBuilder (MessageBuilder&) = delete;

    DeflateFlag maybe_deflate (size_t payload_length) {
        switch (_deflate) {
            case DeflateFlag::NO      : return _deflate;
            case DeflateFlag::YES     : return _deflate;
            case DeflateFlag::DEFAULT :
                return _opcode == Opcode::TEXT &&
                       _parser._deflate_cfg &&
                       _parser._deflate_cfg->compression_threshold <= payload_length &&
                       payload_length > 0
                       ? DeflateFlag::YES : DeflateFlag::NO;
        }
        return DeflateFlag::NO;
    }
};
