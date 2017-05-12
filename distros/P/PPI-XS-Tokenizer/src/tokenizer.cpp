#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <map>


#include "tokenizer.h"
#include "numbers.h"
#include "operator.h"
#include "symbol.h"
#include "quotes.h"
#include "whitespace.h"
#include "word.h"
#include "structure.h"
#include "unknown.h"

using namespace PPITokenizer;

//=====================================
// Token Cache
//=====================================

class TokenCache {
public:
	TokenCache(size_t size) : head(NULL), m_size(size) {};
	Token *get() {
		if ( head == NULL) 
			return NULL;
		Token *t = head;
		head = head->next;
		return t;
	}
	void store( Token *t) {
		t->next = head;
		head = t;
	}
	Token *alloc() {
		Token *t = (Token*)malloc(m_size);
		return t;
	}
	~TokenCache() {
		Token *t;
		while ( ( t = head ) != NULL ) {
			head = head->next;
			free( t->text );
			free( t );
		}
	}
private:
	Token *head;
	size_t m_size;
};

class PPITokenizer::TokensCacheMany {
public:
	TokensCacheMany() : standard(sizeof(Token)), quote(sizeof(ExtendedToken)) {}
	TokenCache standard;
	TokenCache quote;
};


//=====================================
// AbstractTokenType
//=====================================

CharTokenizeResults AbstractTokenType::commit(Tokenizer *t) { 
	t->_new_token(type);
	return my_char;
}

bool AbstractTokenType::isa( TokenTypeNames is_type ) const {
	return ( is_type == type );
}

Token *AbstractTokenType::GetNewToken( Tokenizer *t, TokensCacheMany *tc, unsigned long line_length ) {
	unsigned long needed_size = line_length - t->line_pos;
	if ( needed_size < 200 ) needed_size = 200;

	Token *tk = _get_from_cache(tc);

	if ( tk == NULL ) {
		tk = _alloc_from_cache(tc);
		if ( tk == NULL )
			return NULL; // die
		tk->text = NULL;
		tk->allocated_size = needed_size;
	} else {
		if ( tk->allocated_size < needed_size ) {
			free( tk->text );
			tk->text = NULL;
			tk->allocated_size = needed_size;
		}
	}

	if ( tk->text == NULL ) {
		tk->text = (char *)malloc(sizeof(char) * needed_size);
		if (tk->text == NULL) {
			free(tk);
			return NULL; // die
		}
	}

	tk->ref_count = 0;
	tk->length = 0;
	tk->next = NULL;
	_clean_token_fields( tk );
	return tk;
}

void AbstractTokenType::VerifySufficientBufferLength(Token *token, unsigned long line_length) {
	if (token == NULL)
		return;
	unsigned long needed_size = token->length + line_length;
	if ( needed_size <= token->allocated_size )
		return;
	char *new_buf = (char *)malloc(sizeof(char) * needed_size * 2);
	memcpy(new_buf, token->text, token->length);
	char *old_buf = token->text;
	token->text = new_buf;
	token->allocated_size = needed_size * 2;
	free(old_buf);
}

Token *AbstractTokenType::_get_from_cache(TokensCacheMany *tc) {
	return tc->standard.get();
}

Token *AbstractTokenType::_alloc_from_cache(TokensCacheMany *tc) {
	return tc->standard.alloc();
}

void AbstractTokenType::_clean_token_fields( Token *t ) {
}

void AbstractTokenType::FreeToken( TokensCacheMany *tc, Token *token ) {
	tc->standard.store( token );
}

//=====================================
// AbstractExtendedTokenType
//=====================================

Token *AbstractExtendedTokenType::_get_from_cache(TokensCacheMany *tc) {
	return tc->quote.get();
}

Token *AbstractExtendedTokenType::_alloc_from_cache(TokensCacheMany *tc) {
	return tc->quote.alloc();
}

void AbstractExtendedTokenType::_clean_token_fields( Token *t ) {
	ExtendedToken *t2 = static_cast<ExtendedToken*>( t );
	t2->seperator = 0;
	t2->state = 0;
	t2->current_section = 0;
	t2->modifiers.size = 0;
}

void AbstractExtendedTokenType::FreeToken( TokensCacheMany *tc, Token *token ) {
	ExtendedToken *t2 = static_cast<ExtendedToken*>( token );
	tc->quote.store( t2 );
}

//=====================================
// Tokenizer
//=====================================

Token *Tokenizer::pop_one_token() {
	if (tokens_found_head == NULL)
		return NULL;
	Token *tk = tokens_found_head;
	tokens_found_head = tokens_found_head->next;
	if ( NULL == tokens_found_head )
		tokens_found_tail = NULL;
	return tk;
}

void Tokenizer::freeToken(Token *t) {
	if (t->ref_count > 0) {
		t->ref_count--;
		return;
	}
	t->ref_count = 0;
	t->length = 0;
	AbstractTokenType *type = t->type;
	t->type = NULL;
	type->FreeToken( this->m_TokensCache, t );
}

void Tokenizer::_new_token(TokenTypeNames new_type) {
	Token *tk;
	if (c_token == NULL) {
		tk = TokenTypeNames_pool[new_type]->GetNewToken(this, this->m_TokensCache, line_length);
	} else {
		if (c_token->length > 0) {
			_finalize_token();
			tk = TokenTypeNames_pool[new_type]->GetNewToken(this, this->m_TokensCache, line_length);
		} else {
			changeTokenType(new_type);
			tk = c_token;
		}
	}
	tk->type = TokenTypeNames_pool[new_type];
	c_token = tk;
}

void Tokenizer::keep_significant_token(Token *t) {
	unsigned char oldest = ( m_nLastSignificantPos + 1 ) % NUM_SIGNIFICANT_KEPT;
	if (m_LastSignificant[oldest] != NULL) {
		freeToken(m_LastSignificant[oldest]);
	}
	t->ref_count++;
	m_LastSignificant[oldest] = t;
	m_nLastSignificantPos = oldest;
}
static inline void chain_token(Token *tkn, Token * &head, Token * &tail) {
	tkn->next = NULL;
	if ( NULL == tail ) {
		head = tkn;
	} else {
		tail->next = tkn;
	}
	tail = tkn;
}

TokenTypeNames Tokenizer::_finalize_token() {
	if (c_token == NULL)
		return zone;

	if (c_token->length != 0) {
		c_token->text[c_token->length] = '\0';
		if ( NULL == tokens_posponded_head ) {
			chain_token(c_token, tokens_found_head, tokens_found_tail);
		} else {
			chain_token(c_token, tokens_posponded_head, tokens_posponded_tail);
		}
		if (c_token->type->significant) {
			keep_significant_token(c_token);
		}
	} else {
		freeToken(c_token);
	}

	c_token = NULL;
	return zone;
}

TokenTypeNames Tokenizer::_pospond_token() {
	chain_token(c_token, tokens_posponded_head, tokens_posponded_tail);
	c_token = NULL;
	return zone;
}

using namespace std;
typedef pair <const char *, unsigned char> uPair;
//std::map <string, char> Tokenizer::operators;

bool Tokenizer::is_operator(const char *str) {
	map <string, char> :: const_iterator m1_AcIter = operators.find( str );
	return !( m1_AcIter == operators.end());
}

bool Tokenizer::is_magic(const char *str) {
	map <string, char> :: const_iterator m1_AcIter = magics.find( str );
	return !( m1_AcIter == magics.end());
}

		// Operators:
		//-> ++ -- ** ! ~ + -
		//=~ !~ * / % x + - . << >>
		//< > <= >= lt gt le ge
		//== != <=> eq ne cmp ~~
		//& | ^ && || // .. ...
		//? : = += -= *= .= /= //=
		//=> <> ,
		//and or xor not

#define OPERATORS_COUNT 58

		// Magics:
		// $1 $2 $3 $4 $5 $6 $7 $8 $9
		// $_ $& $` $' $+ @+ %+ $* $. $/ $|
		// $\\ $" $; $% $= $- @- %- $)
		// $~ $^ $: $? $! %! $@ $$ $< $>
		// $( $0 $[ $] @_ @*
		// $^L $^A $^E $^C $^D $^F $^H
		// $^I $^M $^N $^O $^P $^R $^S
		// $^T $^V $^W $^X %^H
		// $::| $}, "$,", '$#', '$#+', '$#-'

#define MAGIC_COUNT 70

static void fill_maps( std::map <string, char> &omap, std::map <string, char> &mmap ) {
	const char o_list[OPERATORS_COUNT][4] = {
		"->", "++", "--", "**", "!", "~", "+", "-",
		"=~", "!~", "*", "/", "%" ,"x" ,"+" ,"-" ,"." ,"<<" ,">>",
		"<" ,">" ,"<=" ,">=" ,"lt" ,"gt" ,"le" ,"ge",
		"==" ,"!=" ,"<=>" ,"eq" ,"ne" ,"cmp" ,"~~",
		"&" ,"|" ,"^" ,"&&" ,"||" ,"//" ,".." ,"...",
		"?" ,":" ,"=" ,"+=" ,"-=" ,"*=" ,".=" ,"/=" ,"//=",
		"=>" ,"<>" ,",",
		"and" ,"or" ,"xor" ,"not" };
	for ( unsigned long ix = 0; ix < OPERATORS_COUNT; ix++ )
		omap.insert( uPair ( o_list[ix], 1 ) );

	const char m_list[MAGIC_COUNT][5] = {
		 "$1", "$2", "$3", "$4", "$5", "$6" ,"$7" ,"$8", "$9",
		 "$_", "$&", "$`", "$'", "$+", "@+", "%+" ,"$*", "$.", "$/", "$|",
		 "$\\", "$\"", "$;", "$%", "$=", "$-", "@-", "%-", "$)",
		 "$~", "$^", "$:", "$?", "$!", "%!", "$@", "$$", "$<", "$>",
		 "$(", "$0", "$[", "$]", "@_", "@*",
		 "$^L", "$^A", "$^E", "$^C", "$^D", "$^F", "$^H",
		 "$^I", "$^M", "$^N", "$^O", "$^P", "$^R", "$^S",
		 "$^T", "$^V", "$^W", "$^X", "%^H",
		 "$::|", "$}", "$,", "$#", "$#+", "$#-"
	};
	for ( unsigned long ix = 0; ix < MAGIC_COUNT; ix++ )
		mmap.insert( uPair ( m_list[ix], 1 ) );
}

Tokenizer::Tokenizer() 
	: 
	c_token(NULL),
	c_line(NULL),
	line_pos(0),
	line_length(0),
	local_newline('\n'),
	tokens_found_head(NULL), 
	tokens_found_tail(NULL),
	tokens_posponded_head(NULL),
	tokens_posponded_tail(NULL),
	zone(Token_Whitespace),
	m_nLastSignificantPos(0)
{
	m_TokensCache = new TokensCacheMany();
	for (int ix = 0; ix < Token_LastTokenType; ix++) {
		TokenTypeNames_pool[ix] = NULL;
	}
	TokenTypeNames_pool[Token_NoType] = NULL;
	TokenTypeNames_pool[Token_Whitespace] = new WhiteSpaceToken;
	TokenTypeNames_pool[Token_Comment] = new CommentToken;
	TokenTypeNames_pool[Token_Structure] = new StructureToken;
	TokenTypeNames_pool[Token_Magic] = new MagicToken;
	TokenTypeNames_pool[Token_Operator] = new OperatorToken;
	TokenTypeNames_pool[Token_Unknown] = new UnknownToken;
	TokenTypeNames_pool[Token_Symbol] = new SymbolToken;
	TokenTypeNames_pool[Token_Operator_Attribute] = new AttributeOperatorToken;
	TokenTypeNames_pool[Token_Quote_Double] = new AbstractSimpleQuote( Token_Quote_Double, true, '"' );
	TokenTypeNames_pool[Token_Quote_Single] = new AbstractSimpleQuote( Token_Quote_Single, true, '\'' );
	TokenTypeNames_pool[Token_QuoteLike_Backtick] = new AbstractSimpleQuote( Token_QuoteLike_Backtick, true, '`' );
	TokenTypeNames_pool[Token_Word] = new WordToken;
	TokenTypeNames_pool[Token_Quote_Literal] = new AbstractQuoteTokenType( Token_Quote_Literal, true, 1, false );
	TokenTypeNames_pool[Token_Quote_Interpolate] = new AbstractQuoteTokenType( Token_Quote_Interpolate, true, 1, false );
	TokenTypeNames_pool[Token_QuoteLike_Words] = new AbstractQuoteTokenType( Token_QuoteLike_Words, true, 1, false );
	TokenTypeNames_pool[Token_QuoteLike_Command] = new AbstractQuoteTokenType( Token_QuoteLike_Command, true, 1, false );
	TokenTypeNames_pool[Token_QuoteLike_Readline] = new AbstractBareQuoteTokenType( Token_QuoteLike_Readline, true, 1, false );
	TokenTypeNames_pool[Token_Regexp_Match] = new AbstractQuoteTokenType( Token_Regexp_Match, true, 1, true );
	TokenTypeNames_pool[Token_Regexp_Match_Bare] = new AbstractBareQuoteTokenType( Token_Regexp_Match_Bare, true, 1, true );
	TokenTypeNames_pool[Token_QuoteLike_Regexp] = new AbstractQuoteTokenType( Token_QuoteLike_Regexp, true, 1, true );
	TokenTypeNames_pool[Token_Regexp_Substitute] = new AbstractQuoteTokenType( Token_Regexp_Substitute, true, 2, true );
	TokenTypeNames_pool[Token_Regexp_Transliterate] = new AbstractQuoteTokenType( Token_Regexp_Transliterate, true, 2, true );
	TokenTypeNames_pool[Token_Number] = new NumberToken;
	TokenTypeNames_pool[Token_Number_Float] = new FloatNumberToken;
	TokenTypeNames_pool[Token_Number_Hex] = new HexNumberToken;
	TokenTypeNames_pool[Token_Number_Binary] = new BinaryNumberToken;
	TokenTypeNames_pool[Token_Number_Octal] = new OctalNumberToken;
	TokenTypeNames_pool[Token_Number_Exp] = new ExpNumberToken;
	TokenTypeNames_pool[Token_ArrayIndex] = new ArrayIndexToken;
	TokenTypeNames_pool[Token_Label] = new LabelToken;
	TokenTypeNames_pool[Token_Attribute] = new AttributeToken;
	TokenTypeNames_pool[Token_Attribute_Parameterized] = new ParameterizedAttributeToken;
	TokenTypeNames_pool[Token_Pod] = new PodToken;
	TokenTypeNames_pool[Token_Cast] = new CastToken;
	TokenTypeNames_pool[Token_Prototype] = new PrototypeToken;
	TokenTypeNames_pool[Token_DashedWord] = new DashedWordToken;
	TokenTypeNames_pool[Token_Number_Version] = new VersionNumberToken;
	TokenTypeNames_pool[Token_BOM] = new BOMToken;
	TokenTypeNames_pool[Token_Separator] = new SeparatorToken;
	TokenTypeNames_pool[Token_End] = new EndToken;
	TokenTypeNames_pool[Token_Data] = new DataToken;
	TokenTypeNames_pool[Token_HereDoc] = new HereDocToken;
	//TokenTypeNames_pool[Token_HereDoc_Body] = new HereDocBodyToken;
	

	for (int ix = 0; ix < NUM_SIGNIFICANT_KEPT; ix++) {
		m_LastSignificant[ix] = NULL;
	}
	fill_maps( operators, magics );
}

Tokenizer::~Tokenizer() {
	Reset();
	for (int ix = 0; ix < Token_LastTokenType; ix++) {
		if ( TokenTypeNames_pool[ix] != NULL ) {
			delete(TokenTypeNames_pool[ix]);
			TokenTypeNames_pool[ix] = NULL;
		}
	}
	delete m_TokensCache;
}

void Tokenizer::Reset() {
	Token *t;
	EndOfDocument();

	while ( ( t = pop_one_token() ) != NULL ) {
		freeToken( t );
	}
	for (int ix = 0; ix < NUM_SIGNIFICANT_KEPT; ix++) {
		if (m_LastSignificant[ix] != NULL) {
			freeToken(m_LastSignificant[ix]);
			m_LastSignificant[ix] = NULL;
		}
	}
	c_token = NULL;
	c_line = NULL;
	line_pos = 0;
	line_length = 0;
	zone = Token_Whitespace;
	m_nLastSignificantPos = 0;
}

unsigned int count_waiting_tokens(Token *head) {
	if (head == NULL)
		return 0;
	unsigned int x = 0;
	while (head!=NULL) {
		x++;
		head = head->next;
	}
	return x;
}

void Tokenizer::EndOfDocument() {
	if ( c_token != NULL )
		_finalize_token();
	while ( NULL != tokens_posponded_head ) {
		Token *tkn = tokens_posponded_head;
		tkn->text[tkn->length] = '\0';
		tokens_posponded_head = tkn->next;
		chain_token(tkn, tokens_found_head, tokens_found_tail);
	}
	tokens_posponded_tail = NULL;
}

Token *Tokenizer::_last_significant_token(unsigned int n) {
	if (( n < 1) || (n > NUM_SIGNIFICANT_KEPT ))
		return NULL;
	unsigned int ix = ( m_nLastSignificantPos + NUM_SIGNIFICANT_KEPT - n + 1 ) % NUM_SIGNIFICANT_KEPT;
	return m_LastSignificant[ix];
}

OperatorOperandContext Tokenizer::_opcontext() {
	Token *t0 = _last_significant_token(1);
	if ( t0 == NULL )
		return ooc_Operand;
	TokenTypeNames p_type = t0->type->type;
	if ( t0->type->isa( Token_Symbol ) || t0->type->isa( Token_Number ) ||
		t0->type->isa( isToken_QuoteOrQuotaLike ) || ( p_type == Token_ArrayIndex ) ) {
		return ooc_Operator;
	}
	if ( t0->type->isa( Token_Operator ) )
		return ooc_Operand;
	
	// FIXME: Are we searching for Structure tokens?
	if ( t0->length != 1 )
		return ooc_Unknown;

	unsigned char c_char = t0->text[0];
	if ( ( c_char == '(' ) || ( c_char == '{' ) || ( c_char == '[' ) ||  ( c_char == ';' ) ) {
		return ooc_Operand;
	}
	if ( c_char == '}' )
		return ooc_Operator;

	return ooc_Unknown;
}

//=====================================

LineTokenizeResults Tokenizer::_tokenize_the_rest_of_the_line() {
	AbstractTokenType::VerifySufficientBufferLength(c_token, line_length);
    while (line_length > line_pos) {
		CharTokenizeResults rv = c_token->type->tokenize(this, c_token, c_line[line_pos]);
        switch (rv) {
            case my_char:
				c_token->text[c_token->length++] = c_line[line_pos++];
                break;
            case done_it_myself:
                break;
            case error_fail:
                return tokenizing_fail;
        };
    }
	if ( ( c_token != NULL ) && ( c_token->type->type == Token_Whitespace ) ) {
	}
    return reached_eol;
}

LineTokenizeResults Tokenizer::tokenizeLine(char *line, unsigned long line_length) {
	line_pos = 0;
	c_line = line;
	this->line_length = line_length;
	if (c_token == NULL)
		_new_token(Token_BOM);
	while ( NULL != tokens_posponded_head ) {
		if ( tokens_posponded_head->type->isa( Token_HereDoc ) ) {
			ExtendedToken *tkn = (ExtendedToken *)tokens_posponded_head;
			AbstractTokenType::VerifySufficientBufferLength(tkn, line_length);
			if ( heredocbody_ended == ((HereDocToken*)(tokens_posponded_head->type))->Unpospone( this, tkn, line, line_length ) ) {
				// release all posponded tokens, as long as they are not an another heredoc token
				Token *tkn = tokens_posponded_head;
				tokens_posponded_head = tkn->next;
				chain_token(tkn, tokens_found_head, tokens_found_tail);
				while ( ( NULL != tokens_posponded_head ) && ( ! tokens_posponded_head->type->isa( Token_HereDoc ) ) ) {
					Token *tkn = tokens_posponded_head;
					tokens_posponded_head = tkn->next;
					chain_token(tkn, tokens_found_head, tokens_found_tail);
				}
				if ( NULL == tokens_posponded_head )
					tokens_posponded_tail = NULL;
			}
			return reached_eol;
		}
		Token *tkn = tokens_posponded_head;
		tokens_posponded_head = tkn->next;
		chain_token(tkn, tokens_found_head, tokens_found_tail);
	}
	tokens_posponded_tail = NULL;
	return _tokenize_the_rest_of_the_line();

}

void Tokenizer::changeTokenType(TokenTypeNames new_type) {
	AbstractTokenType *oldType = c_token->type;
	AbstractTokenType *newType = TokenTypeNames_pool[new_type];

	if (oldType->isa(isToken_Extended) != newType->isa(isToken_Extended)) {
		Token *newToken = newType->GetNewToken( this, m_TokensCache, line_pos + 1 );
		char *temp_text = c_token->text;
		c_token->text = newToken->text;
		newToken->text = temp_text;

		newToken->length = c_token->length;
		c_token->length = 0;

		unsigned long aSize = c_token->allocated_size;
		c_token->allocated_size = newToken->allocated_size;
		newToken->allocated_size = aSize;

		freeToken( c_token );
		c_token = newToken;
	}
	c_token->type = newType;
}
