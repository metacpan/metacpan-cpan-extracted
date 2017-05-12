#ifndef __TOKENIZER_WHITESPACE_H__
#define __TOKENIZER_WHITESPACE_H__

namespace PPITokenizer {

class WhiteSpaceToken : public AbstractTokenType {
public:
	WhiteSpaceToken() : AbstractTokenType( Token_Whitespace, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class CommentToken : public AbstractTokenType {
public:
	CommentToken() : AbstractTokenType( Token_Comment, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	CharTokenizeResults commit(Tokenizer *t);
};

class PodToken : public AbstractTokenType {
public:
	PodToken() : AbstractTokenType( Token_Pod, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class EndToken : public AbstractTokenType {
public:
	EndToken() : AbstractTokenType( Token_End, false ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class DataToken : public AbstractTokenType {
public:
	DataToken() : AbstractTokenType( Token_Data, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};


};

#endif
