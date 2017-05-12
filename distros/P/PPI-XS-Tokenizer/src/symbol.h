#ifndef __TOKENIZER_SYMBOL_H__
#define __TOKENIZER_SYMBOL_H__

namespace PPITokenizer {

class SymbolToken : public AbstractTokenType {
public:
	SymbolToken() : AbstractTokenType( Token_Symbol, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class ArrayIndexToken : public AbstractTokenType {
public:
	ArrayIndexToken() : AbstractTokenType( Token_ArrayIndex, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class MagicToken : public AbstractTokenType {
public:
	MagicToken() : AbstractTokenType( Token_Magic, true ) {}
	virtual bool isa( TokenTypeNames is_type ) const;
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};
};

#endif
