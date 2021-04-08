// this file is included into struct Parser
// ! no namespaces here or #includes here !

struct MessageBuilder {
    MessageBuilder (MessageBuilder&&) = default;

    Opcode      opcode  () const noexcept { return _opcode; }
    DeflateFlag deflate () const noexcept { return _deflate; }

    MessageBuilder& opcode  (Opcode v)      noexcept { _opcode = v; return *this; }
    MessageBuilder& deflate (DeflateFlag v) noexcept { _deflate = v; return *this; }
    MessageBuilder& deflate (bool v)        noexcept { _deflate = v ? DeflateFlag::YES : DeflateFlag::NO; return *this; }

    string send (string_view payload) {
        auto apply_deflate = maybe_deflate(payload.length());
        return _parser.start_message(_opcode, apply_deflate).send(payload, IsFinal::YES);
    }

    template <class B, class E, class T = decltype(*std::declval<B>()), class = std::enable_if_t<std::is_convertible<T, string_view>::value>>
    string send (B&& payload_begin, E&& payload_end) {
        size_t payload_length = 0;
        for (auto it = payload_begin; it != payload_end; ++it) payload_length += (*it).length();
        auto apply_deflate = maybe_deflate(payload_length);
        return _parser.start_message(_opcode, apply_deflate).send(std::forward<B>(payload_begin), std::forward<E>(payload_end), IsFinal::YES);
    }

    template <class B, class E, class T = decltype(*std::declval<B>()), class = std::enable_if_t<std::is_convertible<T, string_view>::value>>
    std::vector<string> send_multiframe (B&& cont_begin, E&& cont_end) {
        std::vector<string> ret;
        size_t frame_count = 0, idx = 0, total_length = 0, last_nonempty = 0;

        for (auto it = cont_begin; it != cont_end; ++it) {
            auto frame_length = it->length();
            if (frame_length) {
                ++frame_count;
                last_nonempty = idx;
                total_length += frame_length;
            }
            ++idx;
        }

        auto sender = _parser.start_message(_opcode, maybe_deflate(total_length));

        if (!total_length) {
            ret.push_back(sender.send(IsFinal::YES));
            return ret;
        }

        ret.reserve(frame_count);

        idx = 0;
        for (auto it = cont_begin; it != cont_end; ++it) {
            if (it->length()) ret.push_back(sender.send(*it, idx == last_nonempty ? IsFinal::YES : IsFinal::NO));
            if (idx == last_nonempty) break;
            ++idx;
        }

        return ret;
    }

    template <class B, class E, class T = decltype(*((*std::declval<B>()).begin()))>
    std::enable_if_t<std::is_convertible<T, string_view>::value, std::vector<string>>
    send_multiframe (B&& cont_begin, E&& cont_end) {
        std::vector<string> ret;
        size_t frame_count = 0, idx = 0, total_length = 0, last_nonempty = 0;

        for (auto it = cont_begin; it != cont_end; ++it) {
            size_t frame_length = 0;
            for (const auto& s : *it) frame_length += s.length();
            if (frame_length) {
                ++frame_count;
                last_nonempty = idx;
                total_length += frame_length;
            }
            ++idx;
        }

        auto sender = _parser.start_message(_opcode, maybe_deflate(total_length));

        if (!total_length) {
            ret.push_back(sender.send(IsFinal::YES));
            return ret;
        }

        ret.reserve(frame_count);

        idx = 0;
        for (auto it = cont_begin; it != cont_end; ++it) {
            size_t frame_length = 0;
            for (const auto& s : *it) frame_length += s.length();
            if (frame_length) {
                ret.push_back(sender.send(it->begin(), it->end(), idx == last_nonempty ? IsFinal::YES : IsFinal::NO));
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
