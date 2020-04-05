// this file is included into struct Parser
// ! no namespaces here or #includes here !

struct FrameSender {
    FrameSender (FrameSender&& other) : _parser(other._parser) {}
    FrameSender (FrameSender&) = delete;

    string     send (bool final = false)                  { return _parser.send_frame(final); }
    StringPair send (string& payload, bool final = false) { return _parser.send_frame(payload, final); }

    template<class Begin, class End>
    StringChain<Begin, End> send (Begin payload_begin, End payload_end, bool final = false) { return _parser.send_frame(payload_begin, payload_end, final); }

protected:
    FrameSender (Parser& parser) : _parser(parser) {}

    Parser& _parser;

private:
    friend Parser;
};
