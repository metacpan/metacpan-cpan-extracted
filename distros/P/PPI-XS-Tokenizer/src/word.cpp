
#include "tokenizer.h"
#include "forward_scan.h"
#include "word.h"

using namespace PPITokenizer;

// /^(?:q|m|s|y)\'/
static inline bool is_letter_msyq( unsigned char c ) {
	return ( c == 'm' ) || ( c == 's' ) || ( c == 'y' ) || ( c == 'q' );
}
// /^(?:qq|qx|qw|qr)\'/
static inline bool is_letter_qxwr( unsigned char c ) {
	return ( c == 'q' ) || ( c == 'x' ) || ( c == 'w' ) || ( c == 'r' );
}
// /^(?:eq|ne|tr|ge|lt|gt|le)\'/
// /^(?:qq|qx|qw|qr)\'/
// assumation: the string is longer then 2 bytes
static inline bool is_quote_like( const char *str ) {
	return ( ( ( str[0] == 'q' ) && is_letter_qxwr( str[1] ) ) || // qq, qx, qw, qr
			 ( ( str[0] == 'e' ) && ( str[1] == 'q' ) ) || // eq
			 ( ( str[0] == 'g' ) && ( str[1] == 'e' ) ) || // ge
			 ( ( str[0] == 'n' ) && ( str[1] == 'e' ) ) || // ne
			 ( ( str[0] == 'l' ) && ( str[1] == 'e' ) ) || // le
			 ( ( str[0] == 'g' ) && ( str[1] == 't' ) ) || // gt
			 ( ( str[0] == 'l' ) && ( str[1] == 't' ) ) || // lt
			 ( ( str[0] == 't' ) && ( str[1] == 'r' ) ) ); // tr
}

static unsigned char oversuck_protection( const char *text, unsigned long len) {
		// /^(?:q|m|s|y)\'/
		if ( ( len >= 2 ) && ( text[1] == '\'' ) && is_letter_msyq( text[0] ) ) {
			return 1;
		} else
		if ( ( len >= 3 ) && ( text[2] == '\'' ) && is_quote_like( text ) ) {
			return 2;
		} else
		if ( ( len >= 5 ) && ( strncmp(text, "pack'", 5) == 0 ) ) {
			return 4;
		} else
		if ( ( len >= 7 ) && ( strncmp(text, "unpack'", 7) == 0 ) ) {
			return 6;
		} else
			return 0;
}

static TokenTypeNames get_quotelike_type( Token *token) {
	TokenTypeNames is_quotelike = Token_NoType;
	if ( token->length == 1 ) {
		unsigned char f_char = token->text[0];
		if (f_char == 'q')
			is_quotelike = Token_Quote_Literal;
		else 
		if (f_char == 'm')
			is_quotelike = Token_Regexp_Match;
		else 
		if (f_char == 's')
			is_quotelike = Token_Regexp_Substitute;
		else 
		if (f_char == 'y')
			is_quotelike = Token_Regexp_Transliterate;
	} else
	if ( token->length == 2 ) {
		unsigned char f_char = token->text[0];
		unsigned char s_char = token->text[1];
		if ( f_char == 'q' ) {
			if (s_char == 'q')
				is_quotelike = Token_Quote_Interpolate;
			else
			if (s_char == 'x')
				is_quotelike = Token_QuoteLike_Command;
			else
			if (s_char == 'w')
				is_quotelike = Token_QuoteLike_Words;
			else
			if (s_char == 'r')
				is_quotelike = Token_QuoteLike_Regexp;
		} else
			if ( ! strcmp( token->text, "tr" ) )
				is_quotelike = Token_Regexp_Transliterate;
	}
	return is_quotelike;
}

bool is_literal( Tokenizer *t, Token *prev ) {
	if ( prev == NULL )
		return false;
	if ( !strcmp( prev->text, "->" ) )
		return true;
	if ( prev->type->isa( Token_Word ) && !strcmp( prev->text, "sub" ) )
		return true;

	PredicateAnd<
		PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
		PredicateIsChar< '}' > > regex1;
	unsigned long pos = t->line_pos;
	if ( ( !strcmp( prev->text, "{" ) ) && regex1.test( t->c_line, &pos, t->line_length ) )
		return true;

	PredicateAnd< 
		PredicateZeroOrMore< PredicateFunc< is_whitespace > >,
		PredicateIsChar< '=' >,
		PredicateIsChar< '>' > > regex2;
	pos = t->line_pos;
	if ( regex2.test( t->c_line, &pos, t->line_length ) )
		return true;

	return false;
}

CharTokenizeResults WordToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// $rest =~ /^(\w+(?:(?:\'|::)(?!\d)\w+)*(?:::)?)/
	PredicateAnd< 
		PredicateOneOrMore<
			PredicateFunc< is_word > >,
		PredicateZeroOrMore< 
			PredicateAnd<
				PredicateOr<
					PredicateIsChar< '\'' >,
					PredicateAnd<
						PredicateIsChar< ':' >,
						PredicateIsChar< ':' > > >,
				PredicateNot< PredicateFunc < is_digit > >,
				PredicateOneOrMore<
					PredicateFunc< is_word > > > >,
		PredicateZeroOrOne<
			PredicateAnd<
				PredicateIsChar< ':' >,
				PredicateIsChar< ':' > > > > regex;
	unsigned long new_pos = t->line_pos;
	if ( regex.test( t->c_line, &new_pos, t->line_length ) ) {
		// copy the string
		while (t->line_pos < new_pos)
			token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
		// oversucking protection
		unsigned char new_len = oversuck_protection( token->text, token->length );
		if ( new_len > 0 ) {
			t->line_pos -= token->length - new_len;
			token->length = new_len;
		}
	}

	Token *prev = t->_last_significant_token(1);
	if ( ( prev != NULL ) && ( prev->type->isa( Token_Operator_Attribute ) ) ) {
		t->changeTokenType( Token_Attribute );
		return done_it_myself;
	}

	token->text[ token->length ] = 0;
	TokenTypeNames is_quotelike = get_quotelike_type(token);
	if ( ( is_quotelike != Token_NoType ) && !is_literal( t, prev ) ) {
		t->changeTokenType( is_quotelike );
		return done_it_myself;
	}

	if ( t->is_operator( token->text ) && !is_literal( t, prev ) ) {
		t->changeTokenType( Token_Operator );
		return done_it_myself;
	}

	for (unsigned long ix=0; ix < token->length; ix++) {
		if ( token->text[ix] == ':' ) {
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token(zone);
			return done_it_myself;
		}
	}

	unsigned char n_char = t->c_line[ t->line_pos ];
	if ( n_char == ':' ) {
		token->text[ token->length++ ] = ':';
		t->line_pos++;
		t->changeTokenType( Token_Label );
	}
	else
	if ( !strcmp( token->text, "_" ) ) {
		t->changeTokenType( Token_Magic );
	}

	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

static inline bool has_a_colon( Token *token ) {
	for (unsigned long ix = 0; ix < token->length; ix++) {
		if ( token->text[ix] == ':' )
			return true;
	}
	return false;
}

static TokenTypeNames commit_detect_type(Tokenizer *t, Token *token, Token *prev, bool *should_finalize) {
	*should_finalize = true;
	if ( has_a_colon( token ) ) {
		return Token_Word;
	}
	if ( t->is_operator( token->text ) )  {
		if ( is_literal( t, prev ) )
			return Token_Word;
		else
			return Token_Operator;
	} 

	TokenTypeNames is_quotelike = get_quotelike_type(token);
	if ( is_quotelike != Token_NoType ) {
		if ( is_literal(t, prev) ) {
			return Token_Word;
		} else {
			*should_finalize = false;
			return is_quotelike;
		}
	}

	// $string =~ /^(\s*:)(?!:)/ )
	PredicateAnd<
		PredicateZeroOrMore<
			PredicateFunc< is_whitespace > >,
		PredicateIsChar< ':' >,
		PredicateNot< PredicateIsChar< ':' > > > regex;
	unsigned long pos = t->line_pos;
	if ( regex.test( t->c_line, &pos, t->line_length ) ) {
		if ( ( prev != NULL ) && ( !strcmp( prev->text, "sub" ) ) ) {
			return Token_Word;
		} else {
			while ( pos > t->line_pos )
				token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
			return Token_Label;
		}
	}

	if ( !strcmp( token->text, "_" ) ) 
		return Token_Magic;

	return Token_Word;
}

void TheRestIsCommentAndNewLine(Tokenizer *t) {
	t->_new_token( Token_Comment );
	Token *comment = t->c_token;
	while ( t->line_length > t->line_pos ) {
		unsigned char c_char = t->c_line[ t->line_pos ];
		if ( c_char == t->local_newline )
			break;
		comment->text[comment->length++] = c_char;
		t->line_pos++;
	}
	t->_finalize_token();
	t->_new_token( Token_Whitespace );
	Token *ws = t->c_token;
	while ( t->line_length > t->line_pos ) {
		ws->text[ws->length++] = t->c_line[ t->line_pos++ ];
	}
	t->_finalize_token();
}

CharTokenizeResults WordToken::commit(Tokenizer *t) {
	// $rest =~ /^((?!\d)\w+(?:(?:\'|::)\w+)*(?:::)?)/
	PredicateAnd< 
		PredicateNot< PredicateFunc< is_digit > >,
		PredicateOneOrMore<
			PredicateFunc< is_word > >,
		PredicateZeroOrMore< 
			PredicateAnd<
				PredicateOr<
					PredicateIsChar< '\'' >,
					PredicateAnd<
						PredicateIsChar< ':' >,
						PredicateIsChar< ':' > > >,
				PredicateOneOrMore<
					PredicateFunc< is_word > > > >,
		PredicateZeroOrOne<
			PredicateAnd<
				PredicateIsChar< ':' >,
				PredicateIsChar< ':' > > > > regex;
	unsigned long new_pos = t->line_pos;
	if ( !regex.test( t->c_line, &new_pos, t->line_length ) ) {
		sprintf(t->ErrorMsg, "ERROR: Word token was not recognized after I was sure about it at pos %d", t->line_pos);
		return error_fail;
	}

	unsigned char new_len = oversuck_protection( t->c_line + t->line_pos, new_pos - t->line_pos );
	if ( new_len > 0 )
		new_pos = t->line_pos + new_len;

	t->_new_token( Token_Word );
	Token *token = t->c_token;
	while ( t->line_pos < new_pos )
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	token->text[token->length] = 0;

	Token *prev = t->_last_significant_token(1);
	if ( ( prev != NULL ) && prev->type->isa( Token_Operator_Attribute ) ) {
		t->changeTokenType(	Token_Attribute );
		if (!( t->line_length > t->line_pos )) {
			// if there is no morecharecters in the line to process - then 
			// this Attribute tiken can not have parameters
			TokenTypeNames zone = t->_finalize_token();
			t->_new_token( zone );
		}
		return done_it_myself;
	}

	if ( !strcmp( token->text, "__END__" ) ) {
		t->changeTokenType( Token_Separator );
		t->_finalize_token();
		t->zone = Token_End;
		TheRestIsCommentAndNewLine(t);
		t->_new_token( Token_End );
		return done_it_myself;
	}

	if ( !strcmp( token->text, "__DATA__" ) ) {
		t->changeTokenType( Token_Separator );
		t->_finalize_token();
		t->zone = Token_Data;
		TheRestIsCommentAndNewLine(t);
		t->_new_token( Token_Data );
		return done_it_myself;
	}

	bool should_finalize;
	TokenTypeNames class_type = commit_detect_type(t, token, prev, &should_finalize);
	if ( class_type != Token_Word ) {
		t->changeTokenType( class_type );
		if (should_finalize == false)
			return done_it_myself;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

//=====================================
// Label Token
//=====================================

CharTokenizeResults LabelToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// should never reach here - the Word token will take care of me
	sprintf(t->ErrorMsg, "Programmer ERROR: LabelToken::tokenize should never be reached at pos %d", t->line_pos);
	return error_fail;
}

//=====================================
// Attribute Token
//=====================================

CharTokenizeResults AttributeToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	// when reached here, the attribute word was already read by Word token. 
	// now checking if the attribute have parameters
	if ( c_char == '(' ) {
		t->changeTokenType( Token_Attribute_Parameterized );
		return my_char;
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

//=====================================
// DashedWordToken
//=====================================

static inline bool is_file_test( char c ) {
	// /^\-[rwxoRWXOezsfdlpSbctugkTBMAC]$/
	return (( c == 'r' ) || ( c == 'w' ) || ( c == 'x' ) || ( c == 'o' ) || 
			( c == 'R' ) || ( c == 'W' ) || ( c == 'X' ) || ( c == 'O' ) || 
			( c == 'e' ) || ( c == 'z' ) || ( c == 's' ) || ( c == 'f' ) || 
			( c == 'd' ) || ( c == 'l' ) || ( c == 'p' ) || ( c == 'S' ) || 
			( c == 'b' ) || ( c == 'c' ) || ( c == 't' ) || ( c == 'u' ) || 
			( c == 'g' ) || ( c == 'k' ) || ( c == 'T' ) || ( c == 'B' ) || 
			( c == 'M' ) || ( c == 'A' ) || ( c == 'C' ) );
}

CharTokenizeResults DashedWordToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	while ( ( t->line_length > t->line_pos ) && is_word(t->c_line[ t->line_pos ] ) ) {
		token->text[ token->length++ ] = t->c_line[ t->line_pos++ ];
	}
	// is that a file test operator?
	if ( ( token->length == 2 ) && ( token->text[0] == '-' ) && is_file_test( token->text[1] ) ) {
		t->changeTokenType( Token_Operator );
	} else {
		t->changeTokenType( Token_Word );
	}
	TokenTypeNames zone = t->_finalize_token();
	t->_new_token(zone);
	return done_it_myself;
}

//=====================================
// Separator Token
//=====================================

CharTokenizeResults SeparatorToken::tokenize(Tokenizer *t, Token *token, unsigned char c_char) {
	sprintf(t->ErrorMsg, "Programmer ERROR: SeparatorToken::tokenize should never be reached at pos %d", t->line_pos);
	return error_fail;
}
