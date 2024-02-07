// this file is included into struct MessageIterator
// ! no namespaces here or #includes here !

struct FrameIterator {
    using difference_type = std::ptrdiff_t;
    using value_type = FrameSP;
    using pointer = value_type*;
    using reference = value_type&;
    using iterator_category = std::input_iterator_tag;

    FrameIterator (Parser* parser, const FrameSP& start_frame) : parser(parser), cur(start_frame) {}
    FrameIterator (const FrameIterator& oth)                   : parser(oth.parser), cur(oth.cur) {}

    FrameIterator& operator++ ()                               { if (cur) cur = parser->_get_frame(); return *this; }
    FrameIterator  operator++ (int)                            { FrameIterator tmp(*this); operator++(); return tmp; }
    bool           operator== (const FrameIterator& rhs) const { return parser == rhs.parser && cur.get() == rhs.cur.get(); }
    bool           operator!= (const FrameIterator& rhs) const { return parser != rhs.parser || cur.get() != rhs.cur.get();}
    FrameSP        operator*  ()                               { return cur; }
    FrameSP        operator-> ()                               { return cur; }

    MessageIteratorPair get_messages () {
        cur = NULL; // invalidate current iterator
        return MessageIteratorPair(MessageIterator(parser, parser->_get_message()), MessageIterator(parser, NULL));
    }

    FrameIterator& operator=(const FrameIterator&) = default;
    FrameIterator& operator=(FrameIterator&&)      = default;
protected:
    Parser* parser;
    FrameSP cur;
};

using FrameIteratorPair = IteratorPair<FrameIterator>;
