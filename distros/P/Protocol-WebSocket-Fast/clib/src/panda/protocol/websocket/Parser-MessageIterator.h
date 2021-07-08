// this file is included into struct Parser
// ! no namespaces here or #includes here !

struct MessageIterator : std::iterator<std::input_iterator_tag, MessageSP> {
    using MessageIteratorPair = IteratorPair<MessageIterator>;
    #include "Parser-FrameIterator.h"

    MessageIterator (Parser* parser, const MessageSP& start_message) : parser(parser), cur(start_message) {}
    MessageIterator (const MessageIterator& oth)                     : parser(oth.parser), cur(oth.cur) {}

    MessageIterator& operator=  (const MessageIterator&)           = default;
    MessageIterator& operator=  (MessageIterator&&)                = default;
    MessageIterator& operator++ ()                                 { if (cur) cur = parser->_get_message(); return *this; }
    MessageIterator  operator++ (int)                              { MessageIterator tmp(*this); operator++(); return tmp; }
    bool             operator== (const MessageIterator& rhs) const { return parser == rhs.parser && cur.get() == rhs.cur.get(); }
    bool             operator!= (const MessageIterator& rhs) const { return parser != rhs.parser || cur.get() != rhs.cur.get();}
    MessageSP        operator*  ()                                 { return cur; }
    MessageSP        operator-> ()                                 { return cur; }

    FrameIteratorPair get_frames () {
        cur = NULL; // invalidate current iterator
        return FrameIteratorPair(FrameIterator(parser, parser->_get_frame()), FrameIterator(parser, NULL));
    }
protected:
    Parser*   parser;
    MessageSP cur;
};

using FrameIterator       = MessageIterator::FrameIterator;
using FrameIteratorPair   = MessageIterator::FrameIteratorPair;
using MessageIteratorPair = MessageIterator::MessageIteratorPair;
