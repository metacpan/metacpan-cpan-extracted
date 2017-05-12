#ifndef __TOKENIZER_OPERATOR_H__
#define __TOKENIZER_OPERATOR_H__

namespace PPITokenizer {

class OperatorToken : public AbstractTokenType {
public:
	OperatorToken() : AbstractTokenType( Token_Operator, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
};

class AttributeOperatorToken : public OperatorToken {
public:
	AttributeOperatorToken();
};

enum HeredocBodyStates {
	heredocbody_still_in_effect,
	heredocbody_ended
};

class HereDocToken : public AbstractExtendedTokenType {
public:
	HereDocToken() : AbstractExtendedTokenType( Token_HereDoc, true, 2, true ) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	HeredocBodyStates Unpospone( Tokenizer *t, ExtendedToken *token, const char *line, unsigned long length);
};


//class HereDocBodyToken : public AbstractExtendedTokenType {
//public:
//	// my_type, sign, num_sections, accept_modifiers
//	HereDocBodyToken() : AbstractExtendedTokenType( Token_HereDoc_Body, true, 2, false ) {}
//	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
//};

};

#endif
