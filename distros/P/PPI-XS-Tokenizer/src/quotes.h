#ifndef __TOKENIZER_QUOTES_H__
#define __TOKENIZER_QUOTES_H__

namespace PPITokenizer {

class AbstractQuoteTokenType : public AbstractExtendedTokenType {
public:
	// my_type, sign, num_sections, accept_modifiers
	AbstractQuoteTokenType( 
		TokenTypeNames my_type,  
		bool sign, 
		unsigned char num_sections, 
		bool accept_modifiers ) 
		: 
		AbstractExtendedTokenType( my_type, sign, num_sections, accept_modifiers) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	virtual bool isa( TokenTypeNames is_type ) const;
protected:
	CharTokenizeResults StateFuncInSectionBraced(Tokenizer *t, ExtendedToken *token);
	CharTokenizeResults StateFuncInSectionUnBraced(Tokenizer *t, ExtendedToken *token);
	CharTokenizeResults StateFuncBootstrapSection(Tokenizer *t, ExtendedToken *token);
	CharTokenizeResults StateFuncConsumeWhitespaces(Tokenizer *t, ExtendedToken *token);
	CharTokenizeResults StateFuncConsumeModifiers(Tokenizer *t, ExtendedToken *token);
	virtual CharTokenizeResults StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token);
};

class AbstractBareQuoteTokenType : public AbstractQuoteTokenType {
public:
	AbstractBareQuoteTokenType( 
		TokenTypeNames my_type,  
		bool sign, 
		unsigned char num_sections, 
		bool accept_modifiers ) 
		: 
	AbstractQuoteTokenType( my_type, sign, num_sections, accept_modifiers ) {} 
protected:
	virtual CharTokenizeResults StateFuncExamineFirstChar(Tokenizer *t, ExtendedToken *token);
};

// Quote type simple - normal quoted string '' or "" or ``
class AbstractSimpleQuote : public AbstractTokenType {
public:
	AbstractSimpleQuote(TokenTypeNames my_type,  bool sign, unsigned char sep) : AbstractTokenType( my_type, sign ), seperator(sep) {}
	CharTokenizeResults tokenize(Tokenizer *t, Token *token, unsigned char c_char);
	virtual bool isa( TokenTypeNames is_type ) const;
private:
	unsigned char seperator;
};

class ParameterizedAttributeToken : public AbstractBareQuoteTokenType {
public:
	virtual bool isa( TokenTypeNames is_type ) const;
	// my_type, sign, num_sections, accept_modifiers
	ParameterizedAttributeToken() : AbstractBareQuoteTokenType( Token_Attribute_Parameterized, true, 1, false ) {}
};
};

#endif
