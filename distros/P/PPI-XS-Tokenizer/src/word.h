#ifndef __TOKENIZER_WORD_H__
#define __TOKENIZER_WORD_H__

namespace PPITokenizer {

class WordToken : public AbstractTokenType {
public:
	WordToken() : AbstractTokenType( Token_Word, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	CharTokenizeResults commit(Tokenizer *t);
};

class LabelToken : public AbstractTokenType {
public:
	LabelToken() : AbstractTokenType( Token_Label, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class AttributeToken : public AbstractTokenType {
public:
	AttributeToken() : AbstractTokenType( Token_Attribute, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class DashedWordToken : public AbstractTokenType {
public:
	DashedWordToken() : AbstractTokenType( Token_DashedWord, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class SeparatorToken : public AbstractTokenType {
public:
	SeparatorToken() : AbstractTokenType( Token_Separator, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

};

#endif
