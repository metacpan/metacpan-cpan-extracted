#ifndef __TOKENIZER_STRUCTURE_H__
#define __TOKENIZER_STRUCTURE_H__

namespace PPITokenizer {

class StructureToken : public AbstractTokenType {
public:
	StructureToken() : AbstractTokenType( Token_Structure, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	CharTokenizeResults commit(Tokenizer *t);
};

class CastToken : public AbstractTokenType {
public:
	CastToken() : AbstractTokenType( Token_Cast, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class PrototypeToken : public AbstractTokenType {
public:
	PrototypeToken() : AbstractTokenType( Token_Prototype, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class BOMToken : public AbstractTokenType {
public:
	BOMToken() : AbstractTokenType( Token_BOM, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};
};

#endif
