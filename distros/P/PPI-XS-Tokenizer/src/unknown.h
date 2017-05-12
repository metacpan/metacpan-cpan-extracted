#ifndef __TOKENIZER_UNKNOWN_H__
#define __TOKENIZER_UNKNOWN_H__

namespace PPITokenizer {

class UnknownToken : public AbstractTokenType {
public:
	UnknownToken() : AbstractTokenType( Token_Unknown, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};
};

#endif
